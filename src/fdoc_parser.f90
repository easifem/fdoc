module fdoc_parser
!! Turning a source text into entities: fformat finds the statements and their structure, and this
!! module reads the declarations and doc comments.
!!
!! Doc comments are attached to code statements. A statement's documentation is any `predocmark`
!! block before it, then its inline comments, then the `docmark` lines after it.
!!
!! Each file is parsed into a list of its own, in parallel with others, so nothing here calls a
!! function returning a deferred-length string (see `example/slen_race.f90`).
use ffmt_tokens
use ffmt_statements, only: statement_view_t, SK_CODE, SK_COMMENT, SK_BLANK
use ffmt_source, only: source_t, parse_source, set_views
use ffmt_structure, only: analyze_structure, structure_t, diagnostic_t
use ffmt_constructs
use fdoc_util
use fdoc_model
use fdoc_settings, only: settings_t
use fdoc_project_file, only: parse_metadata, metadata_t
use fdoc_decl
use fdoc_intrinsics, only: is_intrinsic
implicit none
private

public :: parse_file

integer, parameter :: MAX_DEPTH = 256

character(len=*), parameter :: ATTRIBUTE_WORDS(*) = [character(len=12) :: 'asynchronous', 'allocatable', 'data', 'dimension', &
                                                     'external', 'optional', 'parameter', 'pointer', 'private', 'protected', &
                                                     'public', 'save', 'target', 'value', 'volatile']
character(len=*), parameter :: META_KEYS = &
    ' author category copy_subdir date deprecated display graph graph_maxdepth graph_maxnodes license num_lines '// &
    'ordered_subpage proc_internals since source summary title version '

type :: association_t
    !! A name given by an `associate` statement.
    character(len=:), allocatable :: name       !! the name, in lowercase
    character(len=:), allocatable :: chain      !! what it stands for, `%`-separated
    integer :: level = 0                        !! how many `associate` constructs are open
end type association_t

type :: doc_lines_t
    !! Documentation lines of one item.
    type(string_t), allocatable :: lines(:) !! the lines, without the comment marker
end type doc_lines_t

contains

!> Length of the result of [[inherited_permission]].
pure integer function permission_length(list, id)
    type(entity_list_t), intent(in) :: list !! the entities
    integer, intent(in) :: id               !! the entity
    permission_length = 6
    if (allocated(list%box(id)%e%child_permission)) permission_length = len(list%box(id)%e%child_permission)
end function permission_length

!> Number of commas in `text`.
pure integer function comma_count(text)
    character(len=*), intent(in) :: text    !! the text
    integer :: k
    comma_count = 0
    do k = 1, len(text)
        if (text(k:k) == ',') comma_count = comma_count + 1
    end do
end function comma_count

!> Parse source `text` of file `path` into `list`, whose first entity is the file.
subroutine parse_file(path, text, s, list)
    character(len=*), intent(in) :: path        !! the file
    character(len=*), intent(in) :: text        !! the text to parse
    type(settings_t), intent(in) :: s           !! the settings
    type(entity_list_t), intent(out) :: list    !! the entities
    type(source_t) :: src
    type(statement_view_t), allocatable :: views(:)
    type(structure_t) :: st
    type(diagnostic_t), allocatable :: diags(:)
    type(doc_lines_t), allocatable :: docs(:)
    type(string_t), allocatable :: file_doc(:)
    type(association_t), allocatable :: associations(:)
    character(len=:), allocatable :: line
    integer :: stack(0:MAX_DEPTH)
    integer :: top, k, root, current, id, depth, caller, level

    call parse_source(text, src)
    call set_views(src, views)
    call analyze_structure(src, views, st, diags)
    call collect_docs(src, s, docs, file_doc)

    root = list%add(E_FILE, 0)
    list%box(root)%e%name = path
    list%box(root)%e%file = root
    call set_doc(list%box(root)%e, s, file_doc)
    call inherit_display(list, root, s)
    stack(0) = root
    top = 0
    level = 0
    allocate (associations(0))

    do k = 1, src%stmts%n
        if (src%stmts%s(k)%kind /= SK_CODE) cycle
        associate (info => st%info(k))
            ! fformat knows the structure, including what a statement label closes: close what it
            ! says is closed here. A middle statement such as `contains` is at its construct's depth.
            depth = st%depth(k)
            if (info%role == ROLE_MIDDLE) depth = depth + 1
            do while (top > depth)
                if (stack(top) > 0) call close_unit(list, stack(top), s)
                top = top - 1
            end do
            current = stack(top)
            caller = nearest_caller(list, stack, top)
            if (caller > 0) call statement_calls(src, k, views(k), info, list%box(caller)%e, associations, level)
            select case (info%role)
            case (ROLE_OPEN)
                id = 0
                if (current > 0) then
                    call statement_text(src, k, line)
                    call open_unit(list, current, info%construct, line, k, src, docs(k), s, id)
                end if
                if (top < MAX_DEPTH) then
                    top = top + 1
                    stack(top) = id
                end if
            case (ROLE_MIDDLE)
                if (current > 0 .and. info%construct == C_CONTAINS) then
                    list%box(current)%e%in_contains = .true.
                    if (list%box(current)%e%kind == E_TYPE) list%box(current)%e%child_permission = 'public'
                end if
            case (ROLE_CLOSE)
                continue
            case default
                if (current > 0) then
                    call statement_text(src, k, line)
                    call parse_statement(list, current, line, docs(k), s)
                end if
            end select
        end associate
    end do
    do while (top > 0)
        if (stack(top) > 0) call close_unit(list, stack(top), s)
        top = top - 1
    end do
end subroutine parse_file

!> The innermost entity on `stack` that can call procedures, or 0 if there is none or a declaration
!> scope such as a type is inside it.
pure integer function nearest_caller(list, stack, top) result(caller)
    type(entity_list_t), intent(in) :: list !! the entities
    integer, intent(in) :: top              !! the top of the stack
    integer, intent(in) :: stack(0:top)     !! the open constructs
    integer :: k

    caller = 0
    do k = top, 0, -1
        if (stack(k) == 0) cycle
        select case (list%box(stack(k))%e%kind)
        case (E_SUBROUTINE, E_FUNCTION, E_MODPROC, E_PROGRAM)
            caller = stack(k)
        end select
        return
    end do
end function nearest_caller

!> True if statement `v` can have procedure references: not a declaration.
logical function is_executable(v, info, source_low)
    type(statement_view_t), intent(in) :: v     !! the statement
    type(stmt_info_t), intent(in) :: info       !! its classification
    character(len=*), intent(in) :: source_low  !! its first words, in lowercase

    is_executable = .false.
    select case (info%role)
    case (ROLE_CLOSE)
        return
    case (ROLE_OPEN)
        select case (info%construct)
        case (C_IF, C_DO, C_SELECT, C_ASSOCIATE, C_WHERE, C_FORALL)
            is_executable = .true.
        end select
        return
    case (ROLE_MIDDLE)
        is_executable = info%construct /= C_CONTAINS
        return
    end select
    if (v%n == 0) return
    if (is_type_declaration(source_low) .or. is_attribute_statement(source_low)) return
    if (starts_word(source_low, 'use') .or. starts_word(source_low, 'implicit') .or. &
        starts_word(source_low, 'import') .or. starts_word(source_low, 'namelist') .or. &
        starts_word(source_low, 'common') .or. starts_word(source_low, 'format') .or. &
        starts_word(source_low, 'equivalence') .or. starts_word(source_low, 'module')) return
    if (starts_word(source_low, 'goto') .or. starts_word(source_low, 'go')) then
        is_executable = index(source_low, '(') == 0
        return
    end if
    is_executable = .true.
end function is_executable

!> The first code tokens of `v` from token `j`, in lowercase and joined by blanks, up to about 80
!> characters.
pure function leading_text(v, j) result(text)
    type(statement_view_t), intent(in) :: v     !! the statement
    integer, intent(in) :: j                    !! the first token
    character(len=80) :: text
    integer :: k, n, w

    text = ''
    n = 0
    do k = j, v%n
        w = v%hi(k) - v%lo(k) + 1
        if (n + w >= len(text)) exit
        text(n + 1:n + w) = v%low(v%lo(k):v%hi(k))
        n = n + w + merge(1, 0, v%kind_of(k) == TK_NAME .and. v%kind_of(k + 1) == TK_NAME)
    end do
end function leading_text

!> Add the procedures that a statement refers to to `e%calls`.
subroutine statement_calls(src, item, v, info, e, associations, level)
    type(source_t), intent(in) :: src                   !! the source
    integer, intent(in) :: item                         !! the statement
    type(statement_view_t), intent(in) :: v             !! the statement's tokens
    type(stmt_info_t), intent(in) :: info               !! its classification
    type(entity_t), intent(inout) :: e                  !! the entity it is in
    type(association_t), allocatable, intent(inout) :: associations(:)  !! the names in scope
    integer, intent(inout) :: level                     !! how many `associate` constructs are open
    character(len=80) :: first
    integer :: j, call_at, last, target

    if (info%role == ROLE_CLOSE .and. info%construct == C_ASSOCIATE) then
        associations = pack(associations, associations%level /= level)
        level = max(0, level - 1)
        return
    end if
    if (v%n == 0) return
    first = leading_text(v, v%first)
    if (.not. is_executable(v, info, trim(first))) return

    ! a computed `go to` looks like a function reference
    do j = v%first, v%n - 1
        if (v%is(j + 1, '(') .and. (v%is(j, 'goto') .or. (v%is(j, 'to') .and. v%is(j - 1, 'go')))) return
    end do

    ! `call` may follow a logical `if`
    call_at = 0
    do j = v%first, v%n
        if (v%depth(j) == 0 .and. v%is(j, 'call')) then
            if (j == v%first .or. v%is(j - 1, ')')) then
                call_at = j
                exit
            end if
        end if
    end do
    target = 0
    if (call_at > 0) then
        last = call_at + 1
        target = chain_end(v, last)
        if (target > 0) call add_call(v, target, e, associations)
    end if

    do j = v%first, v%n - 1
        if (v%kind_of(j) /= TK_NAME .or. .not. v%is(j + 1, '(')) cycle
        if (call_at > 0 .and. j > call_at .and. v%depth(j) == 0) cycle
        if (v%closing(j + 1) > 0) then
            if (v%is(v%closing(j + 1) + 1, '%')) cycle
        end if
        call add_call(v, j, e, associations)
    end do

    if (info%role == ROLE_OPEN .and. info%construct == C_ASSOCIATE) call read_associations(v, associations, level)
end subroutine statement_calls

!> The last name of the component chain starting at token `j`, or 0.
function chain_end(v, j) result(last)
    type(statement_view_t), intent(in) :: v     !! the statement
    integer, intent(in) :: j                    !! the first name
    integer :: last, k

    last = 0
    k = j
    do
        if (v%kind_of(k) /= TK_NAME) return
        last = k
        k = k + 1
        if (v%is(k, '(')) then
            if (v%closing(k) == 0) return
            k = v%closing(k) + 1
        end if
        if (.not. v%is(k, '%')) return
        k = k + 1
    end do
end function chain_end

!> The first token of the component chain ending at name `j`.
function chain_start(v, j) result(first)
    type(statement_view_t), intent(in) :: v     !! the statement
    integer, intent(in) :: j                    !! the last name
    integer :: first, k, depth

    first = j
    do
        if (.not. v%is(first - 1, '%')) return
        k = first - 2
        if (v%is(k, ')')) then
            depth = 0
            do while (k >= 1)
                if (v%is(k, ')')) depth = depth + 1
                if (v%is(k, '(')) depth = depth - 1
                if (depth == 0) exit
                k = k - 1
            end do
            k = k - 1
        end if
        if (k < 1) return
        if (v%kind_of(k) /= TK_NAME) return
        first = k
    end do
end function chain_start

!> Add the reference ending at name `j` to `e%calls`, unless it is intrinsic or already there.
subroutine add_call(v, j, e, associations)
    type(statement_view_t), intent(in) :: v     !! the statement
    integer, intent(in) :: j                    !! the last name
    type(entity_t), intent(inout) :: e          !! the entity it is in
    type(association_t), intent(in) :: associations(:)  !! the names in scope
    character(len=:), allocatable :: chain
    integer :: k, depth, a, first
    logical :: start

    if (is_intrinsic(v%low(v%lo(j):v%hi(j)))) return
    if (.not. allocated(e%calls)) allocate (e%calls(0))
    do k = 1, size(e%calls)
        if (ends_with(e%calls(k)%s, v%low(v%lo(j):v%hi(j)))) then
            if (e%calls(k)%s == v%low(v%lo(j):v%hi(j))) return
            a = len(e%calls(k)%s) - (v%hi(j) - v%lo(j) + 1)
            if (e%calls(k)%s(a:a) == '%') return
        end if
    end do

    first = chain_start(v, j)
    chain = ''
    start = .true.
    depth = v%depth(first)
    do k = first, j
        if (v%depth(k) /= depth .or. v%kind_of(k) /= TK_NAME) cycle
        if (start) then
            start = .false.
            chain = v%low(v%lo(k):v%hi(k))
            do a = size(associations), 1, -1
                if (associations(a)%name == chain) then
                    chain = associations(a)%chain
                    exit
                end if
            end do
        else
            chain = chain//'%'//v%low(v%lo(k):v%hi(k))
        end if
    end do
    call push(e%calls, chain)
end subroutine add_call

!> Add the names of an `associate` statement to `associations`.
subroutine read_associations(v, associations, level)
    type(statement_view_t), intent(in) :: v     !! the statement
    type(association_t), allocatable, intent(inout) :: associations(:)  !! the names in scope
    integer, intent(inout) :: level             !! how many `associate` constructs are open
    character(len=:), allocatable :: chain
    integer :: j, k, depth, stop_at, head

    level = level + 1
    do j = v%first, v%n - 1
        if (.not. v%is(j + 1, '=>')) cycle
        if (v%kind_of(j) /= TK_NAME) cycle
        depth = v%depth(j)
        stop_at = j + 2
        do while (stop_at < v%n)
            if (v%depth(stop_at + 1) < depth .or. (v%depth(stop_at + 1) == depth .and. v%is(stop_at + 1, ','))) exit
            stop_at = stop_at + 1
        end do
        chain = ''
        do k = j + 2, stop_at
            if (v%depth(k) /= depth) cycle
            if (v%kind_of(k) == TK_NAME) then
                if (len(chain) > 0) chain = chain//'%'
                chain = chain//v%low(v%lo(k):v%hi(k))
            else if (.not. v%is(k, '%') .and. .not. v%is(k, '(') .and. .not. v%is(k, ')')) then
                chain = ''
                exit
            end if
        end do
        if (len(chain) == 0) cycle
        ! what it stands for may itself be an associated name
        head = index(chain//'%', '%') - 1
        do k = size(associations), 1, -1
            if (associations(k)%name == chain(:head)) then
                chain = associations(k)%chain//chain(head + 1:)
                exit
            end if
        end do
        associations = [associations, association_t(v%low(v%lo(j):v%hi(j)), chain, level)]
    end do
end subroutine read_associations

!> The code of statement `item`: its tokens as written, without comments and continuation marks.
!> Continuation lines are joined as FORD joins them.
subroutine statement_text(src, item, text)
    type(source_t), intent(in) :: src                   !! the source
    integer, intent(in) :: item                         !! the statement
    character(len=:), allocatable, intent(out) :: text  !! its code
    character(len=:), allocatable :: buffer
    logical :: after_break, pending_blank
    integer :: t, first, last, n, width

    first = src%stmts%s(item)%first
    last = src%stmts%s(item)%last
    allocate (character(len=src%tokens%tok(last)%last - src%tokens%tok(first)%first + 2) :: buffer)
    n = 0
    after_break = .false.
    pending_blank = .false.
    do t = first, last
        associate (tok => src%tokens%tok(t))
            select case (tok%kind)
            case (TK_NEWLINE)
                after_break = .true.
            case (TK_COMMENT, TK_PREPROC)
                cycle
            case (TK_CONT)
                if (tok%sub == CT_LEADING) then
                    after_break = .false.
                    pending_blank = .false.
                end if
            case (TK_SPACE)
                if (.not. after_break) pending_blank = .true.
            case default
                if (after_break) pending_blank = .true.
                after_break = .false.
                if (tok%kind == TK_OP .and. src%text(tok%first:tok%last) == ';') cycle
                if (pending_blank .and. n > 0) then
                    n = n + 1
                    buffer(n:n) = ' '
                end if
                pending_blank = .false.
                width = tok%last - tok%first + 1
                buffer(n + 1:n + width) = src%text(tok%first:tok%last)
                n = n + width
            end select
        end associate
    end do
    text = buffer(1:n)
end subroutine statement_text

!> Find the documentation of each code statement.
subroutine collect_docs(src, s, docs, file_doc)
    type(source_t), intent(in) :: src                       !! the source
    type(settings_t), intent(in) :: s                       !! the settings
    type(doc_lines_t), allocatable, intent(out) :: docs(:)  !! the documentation of each item
    type(string_t), allocatable, intent(out) :: file_doc(:) !! documentation before the first statement
    type(string_t), allocatable :: pending(:)
    logical :: in_predoc, in_predoc_alt, in_alt
    integer :: k, t, last

    allocate (docs(src%stmts%n), pending(0), file_doc(0))
    in_predoc = .false.
    in_predoc_alt = .false.
    in_alt = .false.
    last = 0
    do k = 1, src%stmts%n
        associate (item => src%stmts%s(k))
            select case (item%kind)
            case (SK_COMMENT)
                do t = item%first, item%last
                    if (src%tokens%tok(t)%kind == TK_COMMENT) then
                        call comment_line(src%text(src%tokens%tok(t)%first:src%tokens%tok(t)%last))
                    end if
                end do
            case (SK_BLANK)
                in_alt = .false.
                if (last > 0 .and. .not. in_predoc .and. .not. in_predoc_alt .and. size(pending) == 0) then
                    if (allocated(docs(last)%lines)) then
                        if (size(docs(last)%lines) > 0) call push(docs(last)%lines, '')
                    end if
                end if
            case (SK_CODE)
                call move_alloc(pending, docs(k)%lines)
                allocate (pending(0))
                in_predoc = .false.
                in_predoc_alt = .false.
                in_alt = .false.
                last = k
                do t = item%first, item%last
                    if (src%tokens%tok(t)%kind == TK_COMMENT) then
                        call comment_line(src%text(src%tokens%tok(t)%first:src%tokens%tok(t)%last))
                        in_alt = .false.
                    end if
                end do
            end select
        end associate
    end do

contains

    !> Handle one comment.
    subroutine comment_line(c)
        character(len=*), intent(in) :: c   !! the comment, from its `!`

        if (has_mark(c, s%predocmark)) then
            in_predoc = .true.
            in_alt = .false.
            in_predoc_alt = .false.
            call push(pending, strip_trailing(c(2 + len(s%predocmark):)))
        else if (has_mark(c, s%predocmark_alt)) then
            in_predoc_alt = .true.
            in_predoc = .false.
            in_alt = .false.
            call push(pending, strip_trailing(c(2 + len(s%predocmark_alt):)))
        else if (has_mark(c, s%docmark_alt)) then
            in_alt = .true.
            in_predoc = .false.
            in_predoc_alt = .false.
            call add_post(c(2 + len(s%docmark_alt):))
        else if (has_mark(c, s%docmark)) then
            in_alt = .false.
            in_predoc_alt = .false.
            if (in_predoc) then
                call push(pending, strip_trailing(c(2 + len(s%docmark):)))
            else
                call add_post(c(2 + len(s%docmark):))
            end if
        else if (in_predoc_alt) then
            call push(pending, strip_trailing(c(2:)))
        else if (in_alt) then
            call add_post(c(2:))
        end if
    end subroutine comment_line

    !> Add a line to the documentation of the last statement, or of the file before any statement.
    subroutine add_post(line)
        character(len=*), intent(in) :: line    !! the line
        if (last == 0) then
            call push(file_doc, strip_trailing(line))
        else
            if (.not. allocated(docs(last)%lines)) allocate (docs(last)%lines(0))
            call push(docs(last)%lines, strip_trailing(line))
        end if
    end subroutine add_post

end subroutine collect_docs

!> `s` without trailing whitespace.
pure function strip_trailing(s) result(t)
    character(len=*), intent(in) :: s   !! the text
    character(len=len_trim(s)) :: t
    t = s
end function strip_trailing

!> True if comment `c` starts with `!` and doc marker `mark`.
pure logical function has_mark(c, mark)
    character(len=*), intent(in) :: c       !! the comment
    character(len=*), intent(in) :: mark    !! the marker
    has_mark = .false.
    if (len(mark) == 0 .or. len(c) < 1 + len(mark)) return
    has_mark = c(2:1 + len(mark)) == mark
end function has_mark

!> Set the documentation and metadata of `e` from its doc lines.
subroutine set_doc(e, s, lines)
    type(entity_t), intent(inout) :: e      !! the entity
    type(settings_t), intent(in) :: s       !! the settings
    type(string_t), intent(in) :: lines(:)  !! the doc lines
    type(string_t), allocatable :: work(:), moved(:)
    type(metadata_t) :: meta
    integer :: k, at

    allocate (e%meta(0))
    if (size(lines) == 0) then
        allocate (e%doc(0))
        return
    end if
    work = lines
    if (s%doxygen) then
        ! doxygen commands such as `@brief text` are metadata, wherever they are
        allocate (moved(0))
        do k = 1, size(work)
            call doxygen_meta(work(k)%s, moved)
        end do
        work = [moved, work]
    end if
    if (size(work) == 1) then
        at = index(work(1)%s, ':')
        if (at > 0) then
            if (index(META_KEYS, ' '//lowercase(strip(work(1)%s(:at - 1)))//' ') == 0) work = [string_t(''), work]
        end if
    end if
    call parse_metadata(join(work, achar(10)), meta)
    call move_alloc(meta%body, e%doc)
    deallocate (e%meta)
    allocate (e%meta(size(meta%items)))
    do k = 1, size(meta%items)
        e%meta(k)%key = meta%items(k)%key
        e%meta(k)%values = meta%items(k)%values
    end do
end subroutine set_doc

!> If `line` is a doxygen command, blank it and add it to `moved` as a metadata line.
subroutine doxygen_meta(line, moved)
    character(len=:), allocatable, intent(inout) :: line    !! the doc line
    type(string_t), allocatable, intent(inout) :: moved(:)  !! the metadata lines
    character(len=len(line)) :: text
    integer :: at, stop_at

    text = adjustl(line)
    if (text(1:1) /= '@') return
    stop_at = index(trim(text), ' ')
    if (stop_at < 3) return
    at = len_trim(text(:stop_at))
    select case (text(2:at))
    case ('note', 'warning', 'todo', 'bug', 'history', 'param', 'see')
        return
    case ('brief')
        call push(moved, 'summary: '//strip(text(stop_at:)))
    case default
        call push(moved, text(2:at)//': '//strip(text(stop_at:)))
    end select
    line = ''
end subroutine doxygen_meta

!> Copy the display settings that apply to `id` from its parent, and apply its own metadata.
subroutine inherit_display(list, id, s)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: id                   !! the entity
    type(settings_t), intent(in) :: s           !! the settings
    type(string_t), allocatable :: wanted(:)
    logical :: flag, ok
    integer :: k, j

    associate (e => list%box(id)%e)
        if (e%parent > 0) then
            e%display = list%box(e%parent)%e%display
            e%internals = list%box(e%parent)%e%internals
        else
            e%display = s%display
            e%internals = s%proc_internals
        end if
        do k = 1, size(e%meta)
            if (e%meta(k)%key == 'proc_internals') then
                call parse_bool(e%meta(k)%values(1)%s, flag, ok)
                if (ok) e%internals = flag
            else if (e%meta(k)%key == 'display') then
                allocate (wanted(size(e%meta(k)%values)))
                do j = 1, size(wanted)
                    wanted(j)%s = lowercase(e%meta(k)%values(j)%s)
                end do
                if (contains_string(wanted, 'none') .and. e%kind /= E_FILE) then
                    e%display = [string_t ::]
                else if (contains_string(wanted, 'public') .or. contains_string(wanted, 'private') .or. &
                         contains_string(wanted, 'protected')) then
                    call move_alloc(wanted, e%display)
                end if
                if (allocated(wanted)) deallocate (wanted)
            end if
        end do
    end associate
end subroutine inherit_display

!> Create the entity for the statement opening construct `construct`, if it has one.
subroutine open_unit(list, parent, construct, line, item, src, doc, s, id)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: parent               !! the entity around it
    integer, intent(in) :: construct            !! one of the `C_*` constants
    character(len=*), intent(in) :: line        !! the statement
    integer, intent(in) :: item                 !! the statement's item
    type(source_t), intent(in) :: src           !! the source
    type(doc_lines_t), intent(in) :: doc        !! the statement's documentation
    type(settings_t), intent(in) :: s           !! the settings
    integer, intent(out) :: id                  !! the new entity, or 0
    character(len=len(line)) :: low
    character(len=:), allocatable :: words

    id = 0
    low = lowercase(line)
    select case (construct)
    case (C_MODULE)
        id = list%add(E_MODULE, parent)
        words = strip(line(7:))
        list%box(id)%e%name = words
        list%box(id)%e%permission = 'public'
    case (C_SUBMODULE)
        id = list%add(E_SUBMODULE, parent)
        call read_submodule(list%box(id)%e, line)
        list%box(id)%e%permission = 'private'
    case (C_PROGRAM)
        id = list%add(E_PROGRAM, parent)
        words = strip(line(8:))
        list%box(id)%e%name = words
        list%box(id)%e%permission = 'public'
    case (C_BLOCK_DATA)
        id = list%add(E_BLOCKDATA, parent)
        words = strip(line(index(low, 'data') + 4:))
        list%box(id)%e%name = words
        list%box(id)%e%permission = 'public'
    case (C_SUBROUTINE, C_FUNCTION)
        call open_procedure(list, parent, line, doc, s, id)
    case (C_PROCEDURE)
        id = list%add(E_MODPROC, parent)
        words = strip(line(index(low, 'procedure') + 9:))
        list%box(id)%e%name = words
        list%box(id)%e%permission = inherited_permission(list, parent)
    case (C_INTERFACE)
        id = list%add(E_INTERFACE, parent)
        associate (e => list%box(id)%e)
            e%abstract = starts_word(low, 'abstract')
            e%permission = inherited_permission(list, parent)
            words = strip(line(index(low, 'interface') + 9:))
            e%name = words
            e%generic = len(words) > 0
            allocate (e%modprocs(0))
        end associate
    case (C_TYPE)
        id = list%add(E_TYPE, parent)
        list%box(id)%e%permission = inherited_permission(list, parent)
        list%box(id)%e%child_permission = 'public'
        call read_type_statement(list%box(id)%e, line)
    case (C_ENUM)
        id = list%add(E_ENUM, parent)
        list%box(id)%e%name = ''
        list%box(id)%e%permission = inherited_permission(list, parent)
        list%box(id)%e%child_permission = inherited_permission(list, parent)
    end select
    if (id == 0) return

    associate (e => list%box(id)%e)
        e%line = src%tokens%tok(src%stmts%s(item)%first)%line
        if (.not. allocated(e%child_permission)) e%child_permission = e%permission
        if (.not. allocated(e%attribs)) allocate (e%attribs(0))
        if (.not. allocated(e%uses)) allocate (e%uses(0))
        allocate (e%pending(0), e%parameters(0), e%public_list(0))
        if (.not. allocated(e%meta)) then
            if (allocated(doc%lines)) then
                call set_doc(e, s, doc%lines)
            else
                call set_doc(e, s, [string_t ::])
            end if
        end if
    end associate
    call inherit_display(list, id, s)
end subroutine open_unit

!> The permission of what is declared now in `id`.
pure function inherited_permission(list, id) result(permission)
    type(entity_list_t), intent(in) :: list !! the entities
    integer, intent(in) :: id               !! the entity
    character(len=permission_length(list, id)) :: permission

    if (allocated(list%box(id)%e%child_permission)) then
        permission = list%box(id)%e%child_permission
    else
        permission = 'public'
    end if
end function inherited_permission

!> Read a `submodule` statement.
subroutine read_submodule(e, line)
    type(entity_t), intent(inout) :: e      !! the submodule
    character(len=*), intent(in) :: line    !! the statement
    character(len=:), allocatable :: inside
    integer :: open, close, colon

    open = index(line, '(')
    close = index(line, ')')
    e%name = strip(line(close + 1:))
    inside = lowercase(remove_blanks(line(open + 1:close - 1)))
    colon = index(inside, ':')
    if (colon > 0) then
        e%ancestor = inside(:colon - 1)
        e%parent_submodule = inside(colon + 1:)
    else
        e%ancestor = inside
    end if
end subroutine read_submodule

!> Read a `type` statement.
subroutine read_type_statement(e, line)
    type(entity_t), intent(inout) :: e      !! the type
    character(len=*), intent(in) :: line    !! the statement
    type(string_t), allocatable :: parts(:)
    character(len=:), allocatable :: rest, low, base
    integer :: at, k, open

    allocate (e%attribs(0))
    rest = strip(line(5:))
    at = top_index(rest, '::')
    if (at > 0) then
        if (rest(1:1) == ',') then
            parts = top_split(rest(2:at - 1), ',')
            do k = 1, size(parts)
                low = lowercase(parts(k)%s)
                if (starts_with(remove_blanks(low), 'extends(')) then
                    base = parts(k)%s(index(parts(k)%s, '(') + 1:)
                    e%extends = strip(base(:len(base) - 1))
                else if (low == 'public' .or. low == 'private') then
                    e%permission = low
                else
                    call push(e%attribs, parts(k)%s)
                end if
            end do
        end if
        rest = strip(rest(at + 2:))
    end if
    open = index(rest, '(')
    if (open > 0) then
        e%parameters_list = top_split(rest(open + 1:len(rest) - 1), ',')
        e%name = strip(rest(:open - 1))
    else
        e%name = rest
    end if
end subroutine read_type_statement

!> Create the entity for a `subroutine` or `function` statement.
subroutine open_procedure(list, parent, line, doc, s, id)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: parent               !! the entity around it
    character(len=*), intent(in) :: line        !! the statement
    type(doc_lines_t), intent(in) :: doc        !! the statement's documentation
    type(settings_t), intent(in) :: s           !! the settings
    integer, intent(out) :: id                  !! the new entity, or 0
    type(procedure_header_t) :: h
    type(parsed_type_t) :: t
    integer :: var

    call parse_procedure_header(line, h)
    id = 0
    if (.not. h%ok) return
    id = list%add(merge(E_FUNCTION, E_SUBROUTINE, h%is_function), parent)
    associate (e => list%box(id)%e)
        e%name = h%name
        e%permission = inherited_permission(list, parent)
        call move_alloc(h%attribs, e%attribs)
        call move_alloc(h%args, e%args)
        allocate (e%arg_ids(size(e%args)))
        e%arg_ids = 0
        e%is_module = contains_string(e%attribs, 'module')
        if (allocated(h%bind_c)) e%bind_c = h%bind_c
        if (h%is_function) then
            e%result_name = h%name
            if (allocated(h%result_name)) e%result_name = h%result_name
        end if
    end associate
    if (.not. h%is_function) return
    call parse_type(h%prefix, t)
    if (.not. t%ok) return
    var = list%add(E_VARIABLE, id)
    associate (v => list%box(var)%e)
        v%name = list%box(id)%e%result_name
        v%var_role = VAR_RESULT
        v%permission = 'public'
        allocate (v%attribs(0), v%doc(0), v%meta(0))
        call set_type(v, t)
    end associate
    list%box(id)%e%result = var
end subroutine open_procedure

!> Copy a parsed type to variable `v`.
subroutine set_type(v, t)
    type(entity_t), intent(inout) :: v      !! the variable
    type(parsed_type_t), intent(in) :: t    !! the type

    v%vartype = t%vartype
    if (allocated(t%kind)) v%type_kind = t%kind
    if (allocated(t%strlen)) v%strlen = t%strlen
    if (allocated(t%proto)) v%proto = t%proto
end subroutine set_type

!> Finish entity `id` at its closing statement.
subroutine close_unit(list, id, s)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: id                   !! the entity
    type(settings_t), intent(in) :: s           !! the settings

    select case (list%box(id)%e%kind)
    case (E_MODULE, E_SUBMODULE, E_PROGRAM, E_BLOCKDATA, E_MODPROC)
        call apply_attributes(list, id)
    case (E_SUBROUTINE, E_FUNCTION)
        call apply_attributes(list, id)
        call attach_arguments(list, id)
    case (E_INTERFACE)
        call close_interface(list, id, s)
    end select
end subroutine close_unit

!> Apply statements such as `public :: x` to the entities they name.
subroutine apply_attributes(list, id)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: id                   !! the unit
    character(len=:), allocatable :: name
    integer :: c, k, child

    associate (u => list%box(id)%e)
        do c = 1, size(u%children)
            child = u%children(c)
            associate (e => list%box(child)%e)
                select case (e%kind)
                case (E_FUNCTION, E_SUBROUTINE, E_TYPE, E_INTERFACE, E_VARIABLE)
                    if (.not. allocated(e%name)) cycle
                    name = lowercase(e%name)
                    do k = 1, size(u%pending)
                        if (u%pending(k)%name == name) then
                            call apply_one(e, u, u%pending(k)%value)
                            u%pending(k)%name = ''
                        end if
                    end do
                    if (allocated(e%permission)) then
                        if (e%permission == 'public') call push(u%public_list, name)
                    end if
                end select
            end associate
        end do
        do k = 1, size(u%pending)
            if (u%pending(k)%value == 'public' .and. len(u%pending(k)%name) > 0) call push(u%public_list, u%pending(k)%name)
        end do
        do c = 1, size(u%children)
            child = u%children(c)
            if (list%box(child)%e%kind /= E_VARIABLE) cycle
            if (contains_string(list%box(child)%e%attribs, 'external')) list%box(child)%e%var_role = VAR_HIDDEN
        end do
        call mark_common_members(list, id)
    end associate
end subroutine apply_attributes

!> Apply attribute `value`, from a statement in unit `u`, to entity `e`.
subroutine apply_one(e, u, value)
    type(entity_t), intent(inout) :: e      !! the entity
    type(entity_t), intent(in) :: u         !! the unit
    character(len=*), intent(in) :: value   !! the attribute
    integer :: k, at

    select case (value)
    case ('public', 'private', 'protected')
        e%permission = value
        return
    end select
    if (e%kind == E_VARIABLE) then
        if (starts_with(value, 'intent(')) then
            e%intent = value(8:len(value) - 1)
            return
        end if
        if (value == 'parameter') then
            call push(e%attribs, value)
            do k = 1, size(u%parameters)
                if (u%parameters(k)%name == lowercase(e%name)) e%initial = u%parameters(k)%value
            end do
            return
        end if
        at = index(value, '(')
        if (at > 0 .and. (starts_with(value, 'pointer') .or. starts_with(value, 'allocatable'))) then
            call push(e%attribs, value(:at - 1))
            e%dimension = value(at:)
            return
        end if
    else if (starts_with(value, 'bind')) then
        e%bind_c = value(6:len(value) - 1)
        return
    end if
    call push(e%attribs, value)
end subroutine apply_one

!> Connect the dummy arguments and result of a procedure with their declarations.
subroutine attach_arguments(list, id)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: id                   !! the procedure
    integer :: a, c, child, var
    character(len=:), allocatable :: wanted

    associate (p => list%box(id)%e)
        if (p%kind == E_FUNCTION .and. p%result == 0) then
            wanted = lowercase(p%result_name)
            do c = 1, size(p%children)
                child = p%children(c)
                if (list%box(child)%e%kind /= E_VARIABLE) cycle
                if (lowercase(list%box(child)%e%name) == wanted) then
                    p%result = child
                    list%box(child)%e%var_role = VAR_RESULT
                    exit
                end if
            end do
            if (p%result == 0) p%result = implicit_variable(list, id, p%result_name, VAR_RESULT)
        end if
        do a = 1, size(p%args)
            wanted = lowercase(p%args(a)%s)
            do c = 1, size(p%children)
                child = p%children(c)
                if (.not. allocated(list%box(child)%e%name)) cycle
                if (list%box(child)%e%kind == E_VARIABLE) then
                    if (list%box(child)%e%var_role == VAR_PLAIN .and. lowercase(list%box(child)%e%name) == wanted) then
                        p%arg_ids(a) = child
                        list%box(child)%e%var_role = VAR_ARGUMENT
                        exit
                    end if
                else if (list%box(child)%e%iface == IFACE_EXPLICIT .and. lowercase(list%box(child)%e%name) == wanted) then
                    p%arg_ids(a) = child
                    exit
                end if
            end do
            if (p%arg_ids(a) == 0) then
                var = implicit_variable(list, id, p%args(a)%s, VAR_ARGUMENT)
                p%arg_ids(a) = var
            end if
        end do
    end associate
end subroutine attach_arguments

!> Add a variable for `name`, implicitly typed.
function implicit_variable(list, parent, name, role) result(id)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: parent               !! the procedure
    character(len=*), intent(in) :: name        !! the name
    integer, intent(in) :: role                 !! one of the `VAR_*` constants
    integer :: id

    id = list%add(E_VARIABLE, parent)
    associate (v => list%box(id)%e)
        v%name = name
        v%var_role = role
        v%permission = 'public'
        v%vartype = merge('integer', 'real   ', index('ijklmn', lowercase(name(1:1))) > 0)
        v%vartype = trim(v%vartype)
        allocate (v%attribs(0), v%doc(0), v%meta(0))
    end associate
end function implicit_variable

!> Finish an interface block. All but generic interfaces dissolve, leaving their bodies in the unit
!> around them.
subroutine close_interface(list, id, s)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: id                   !! the interface
    type(settings_t), intent(in) :: s           !! the settings
    integer :: parent, c, child, kind_of_body

    if (list%box(id)%e%generic) return
    parent = list%box(id)%e%parent
    kind_of_body = merge(IFACE_ABSTRACT, IFACE_EXPLICIT, list%box(id)%e%abstract)
    do c = 1, size(list%box(id)%e%children)
        child = list%box(id)%e%children(c)
        associate (e => list%box(child)%e)
            if (e%kind /= E_SUBROUTINE .and. e%kind /= E_FUNCTION) cycle
            e%iface = kind_of_body
            e%parent = parent
            e%permission = list%box(id)%e%permission
            call push_int(list%box(parent)%e%children, child)
        end associate
    end do
    call remove_child(list%box(parent)%e, id)
    list%box(id)%e%kind = E_NONE
    list%box(id)%e%visible = .false.
end subroutine close_interface

!> Remove `id` from the children of `e`.
pure subroutine remove_child(e, id)
    type(entity_t), intent(inout) :: e  !! the parent
    integer, intent(in) :: id           !! the child
    e%children = pack(e%children, e%children /= id)
end subroutine remove_child

!> Read a statement that opens nothing, if it declares anything.
subroutine parse_statement(list, unit, line, doc, s)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: unit                 !! the entity it is in
    character(len=*), intent(in) :: line        !! the statement
    type(doc_lines_t), intent(in) :: doc        !! the statement's documentation
    type(settings_t), intent(in) :: s           !! the settings
    character(len=len(line)) :: low

    if (len(line) == 0) return
    low = lowercase(line)
    associate (u => list%box(unit)%e)
        if (.not. allocated(u%name)) return
        select case (trim(low))
        case ('public', 'private', 'protected')
            u%child_permission = trim(low)
            if (u%kind /= E_TYPE) u%permission = trim(low)
            return
        case ('sequence')
            u%sequence = .true.
            return
        end select
        if (u%kind == E_FILE) return

        if (starts_word(low, 'use')) then
            call read_use(u, line)
        else if (u%kind == E_TYPE .and. u%in_contains .and. &
                 (starts_word(low, 'procedure') .or. starts_word(low, 'generic'))) then
            call read_binding(list, unit, line, doc, s)
        else if (u%kind == E_TYPE .and. u%in_contains .and. starts_word(low, 'final')) then
            call read_final(list, unit, line)
        else if (u%kind == E_INTERFACE .and. (starts_word(low, 'module') .or. starts_word(low, 'procedure'))) then
            call read_module_procedures(u, line)
        else if (starts_word(low, 'namelist')) then
            call read_namelist(list, unit, line, doc, s)
        else if (starts_word(low, 'common')) then
            call read_common(list, unit, line, doc, s)
        else if (is_attribute_statement(low)) then
            call read_attribute_statement(u, line, low)
        else if (is_type_declaration(low)) then
            call read_declaration(list, unit, line, doc, s)
        end if
    end associate
end subroutine parse_statement

!> Read a `use` statement.
subroutine read_use(u, line)
    type(entity_t), intent(inout) :: u      !! the unit
    character(len=*), intent(in) :: line    !! the statement
    character(len=:), allocatable :: rest, name, spec
    integer :: at

    rest = strip(line(4:))
    at = top_index(rest, '::')
    if (at > 0 .and. (index(rest, ',') == 0 .or. index(rest, ',') < at .or. at > 0)) then
        if (at < index(rest//',', ',') .or. index(rest, ',') > 0 .and. at > 0) rest = strip(rest(at + 2:))
    end if
    at = index(rest, ',')
    if (at > 0) then
        name = lowercase(strip(rest(:at - 1)))
        spec = strip(rest(at + 1:))
    else
        name = lowercase(rest)
        spec = ''
    end if
    u%uses = [u%uses, use_t(name, spec, 0)]
end subroutine read_use

!> True if `low` starts with a word that gives attributes to names listed after it.
logical function is_attribute_statement(low)
    character(len=*), intent(in) :: low     !! the statement, in lowercase
    character(len=:), allocatable :: compact
    integer :: k, n

    is_attribute_statement = .false.
    if (starts_word(low, 'bind')) then
        is_attribute_statement = index(low, ')') > 0
        return
    end if
    if (starts_word(low, 'intent')) then
        is_attribute_statement = .true.
        return
    end if
    do k = 1, size(ATTRIBUTE_WORDS)
        if (.not. starts_word(low, trim(ATTRIBUTE_WORDS(k)))) cycle
        n = len_trim(ATTRIBUTE_WORDS(k))
        compact = strip(low(n + 1:))
        if (len(compact) == 0) return
        ! not an assignment to a variable named like the attribute
        is_attribute_statement = compact(1:1) /= '=' .and. compact(1:1) /= '%'
        return
    end do
end function is_attribute_statement

!> Read a statement such as `public :: x`, keeping what it says until the unit is finished.
subroutine read_attribute_statement(u, line, low)
    type(entity_t), intent(inout) :: u      !! the unit
    character(len=*), intent(in) :: line    !! the statement
    character(len=*), intent(in) :: low     !! the statement, in lowercase
    character(len=:), allocatable :: attr, rest, name, dims
    type(string_t), allocatable :: names(:), parts(:)
    integer :: k, at, close

    if (starts_word(low, 'bind') .or. starts_word(low, 'intent')) then
        close = closing_paren(low, index(low, '('))
        attr = remove_blanks(low(:close))
        if (starts_with(attr, 'bind')) attr = replace_commas(attr)
        rest = line(close + 1:)
    else
        at = verify(low, 'abcdefghijklmnopqrstuvwxyz_')
        attr = low(:at - 1)
        rest = line(at:)
    end if
    if (attr == 'data' .or. attr == 'save' .and. len(strip(rest)) == 0) return
    if (.not. allocated(u%pending)) return
    rest = strip(rest)
    if (starts_with(rest, '::')) rest = strip(rest(3:))
    if (attr == 'parameter' .and. len(rest) > 1) rest = strip(rest(2:len(rest) - 1))
    names = top_split(rest, ',')
    do k = 1, size(names)
        name = lowercase(names(k)%s)
        if (attr == 'dimension' .or. attr == 'allocatable' .or. attr == 'pointer') then
            at = index(name, '(')
            if (at > 0) then
                dims = name(at:)
                name = strip(name(:at - 1))
                u%pending = [u%pending, attribute_t(name, attr//dims)]
                cycle
            end if
        else if (attr == 'parameter') then
            parts = top_split(names(k)%s, '=')
            if (size(parts) < 2) cycle
            name = lowercase(parts(1)%s)
            u%parameters = [u%parameters, attribute_t(name, parts(2)%s)]
        end if
        u%pending = [u%pending, attribute_t(name, attr)]
    end do
end subroutine read_attribute_statement

!> `attr` with a blank after each comma.
pure function replace_commas(attr) result(out)
    character(len=*), intent(in) :: attr    !! the text
    character(len=len(attr) + comma_count(attr)) :: out
    integer :: k, n

    n = 0
    do k = 1, len(attr)
        n = n + 1
        out(n:n) = attr(k:k)
        if (attr(k:k) == ',') then
            n = n + 1
            out(n:n) = ' '
        end if
    end do
end function replace_commas

!> Read a variable declaration, adding a variable for each name.
subroutine read_declaration(list, unit, line, doc, s)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: unit                 !! the entity it is in
    character(len=*), intent(in) :: line        !! the statement
    type(doc_lines_t), intent(in) :: doc        !! the statement's documentation
    type(settings_t), intent(in) :: s           !! the settings
    type(parsed_type_t) :: t
    type(string_t), allocatable :: attributes(:), names(:), kept(:)
    character(len=:), allocatable :: rest, low, permission, intent, name, dimension, initial
    logical :: optional, parameter, points
    integer :: k, id

    call parse_type(line, t)
    if (.not. t%ok) return
    call split_attributes(t%rest, attributes, rest)
    allocate (kept(0))
    permission = inherited_permission(list, unit)
    intent = ''
    optional = .false.
    parameter = .false.
    do k = 1, size(attributes)
        low = remove_blanks(lowercase(attributes(k)%s))
        select case (low)
        case ('public', 'private', 'protected')
            permission = low
        case ('optional')
            optional = .true.
        case ('parameter')
            parameter = .true.
        case ('intent(in)')
            intent = 'in'
        case ('intent(out)')
            intent = 'out'
        case ('intent(inout)', 'intent(in out)')
            intent = 'inout'
        case default
            call push(kept, attributes(k)%s)
        end select
    end do
    names = top_split(rest, ',')
    do k = 1, size(names)
        call parse_declarator(names(k)%s, name, dimension, initial, points)
        id = list%add(E_VARIABLE, unit)
        associate (v => list%box(id)%e)
            call move_alloc(name, v%name)
            if (allocated(dimension)) call move_alloc(dimension, v%dimension)
            if (allocated(initial)) call move_alloc(initial, v%initial)
            call set_type(v, t)
            v%attribs = kept
            v%permission = permission
            v%intent = intent
            v%optional = optional
            v%parameter = parameter
            v%points = points
            if (allocated(doc%lines)) then
                call set_doc(v, s, doc%lines)
            else
                call set_doc(v, s, [string_t ::])
            end if
        end associate
    end do
end subroutine read_declaration

!> Read a type-bound `procedure` or `generic` statement.
subroutine read_binding(list, unit, line, doc, s)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: unit                 !! the type
    character(len=*), intent(in) :: line        !! the statement
    type(doc_lines_t), intent(in) :: doc        !! the statement's documentation
    type(settings_t), intent(in) :: s           !! the settings
    type(string_t), allocatable :: names(:), attributes(:), kept(:), bindings(:)
    character(len=:), allocatable :: rest, proto, permission, low, name
    logical :: generic, deferred
    integer :: k, id, open, close

    low = lowercase(line)
    generic = starts_word(low, 'generic')
    rest = strip(line(merge(8, 10, generic):))
    proto = ''
    if (len(rest) > 0) then
        if (rest(1:1) == '(') then
            close = closing_paren(rest, 1)
            proto = strip(rest(2:close - 1))
            rest = strip(rest(close + 1:))
        end if
    end if
    call split_attributes(rest, attributes, name)
    rest = name
    allocate (kept(0))
    permission = list%box(unit)%e%child_permission
    deferred = .false.
    do k = 1, size(attributes)
        low = lowercase(attributes(k)%s)
        select case (low)
        case ('public', 'private')
            permission = low
        case ('deferred')
            deferred = .true.
        case default
            call push(kept, low)
        end select
    end do

    if (generic) then
        allocate (names(1))
        names(1)%s = rest
    else
        names = top_split(rest, ',')
    end if
    do k = size(names), 1, -1
        id = list%add(E_BOUNDPROC, unit)
        associate (b => list%box(id)%e, text => names(k)%s)
            open = index(text, '=>')
            if (open > 0) then
                b%name = strip(text(:open - 1))
                b%bindings = top_split(text(open + 2:), ',')
            else
                b%name = strip(text)
                bindings = [string_t(b%name)]
                call move_alloc(bindings, b%bindings)
            end if
            b%generic = generic
            b%deferred = deferred
            b%permission = permission
            b%attribs = kept
            if (len(proto) > 0) b%proto_text = proto
            if (allocated(doc%lines)) then
                call set_doc(b, s, doc%lines)
            else
                call set_doc(b, s, [string_t ::])
            end if
        end associate
    end do
end subroutine read_binding

!> Read a `final` statement.
subroutine read_final(list, unit, line)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: unit                 !! the type
    character(len=*), intent(in) :: line        !! the statement
    type(string_t), allocatable :: names(:)
    integer :: k, id, at

    at = index(line, '::')
    if (at == 0) return
    names = top_split(line(at + 2:), ',')
    do k = 1, size(names)
        id = list%add(E_FINAL, unit)
        list%box(id)%e%name = names(k)%s
        list%box(id)%e%permission = 'public'
        allocate (list%box(id)%e%attribs(0), list%box(id)%e%doc(0), list%box(id)%e%meta(0))
    end do
end subroutine read_final

!> Read a `module procedure` or `procedure` statement in an interface.
subroutine read_module_procedures(u, line)
    type(entity_t), intent(inout) :: u      !! the interface
    character(len=*), intent(in) :: line    !! the statement
    type(string_t), allocatable :: names(:)
    character(len=:), allocatable :: rest
    integer :: at, k

    rest = line(index(lowercase(line), 'procedure') + 9:)
    at = index(rest, '::')
    if (at > 0) rest = rest(at + 2:)
    names = top_split(rest, ',')
    do k = 1, size(names)
        call push(u%modprocs, names(k)%s)
    end do
end subroutine read_module_procedures

!> Read a `common` statement, adding a common block entity for each block it names.
subroutine read_common(list, unit, line, doc, s)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: unit                 !! the entity it is in
    character(len=*), intent(in) :: line        !! the statement
    type(doc_lines_t), intent(in) :: doc        !! the statement's documentation
    type(settings_t), intent(in) :: s           !! the settings
    character(len=:), allocatable :: rest, name
    integer :: a, b, next, id

    rest = strip(line(7:))
    do while (len(rest) > 0)
        name = ''
        if (rest(1:1) == '/') then
            b = index(rest(2:), '/') + 1
            name = strip(rest(2:b - 1))
            rest = strip(rest(b + 1:))
        end if
        next = top_index(rest, '/')
        a = merge(next - 1, len(rest), next > 0)
        id = list%add(E_COMMON, unit)
        associate (c => list%box(id)%e)
            c%name = name
            c%permission = 'public'
            c%args = top_split(rest(:a), ',')
            allocate (c%attribs(0))
            if (allocated(doc%lines)) then
                call set_doc(c, s, doc%lines)
            else
                call set_doc(c, s, [string_t ::])
            end if
        end associate
        rest = strip(rest(a + 1:))
    end do
end subroutine read_common

!> Mark the variables of unit `id` named in its common blocks.
subroutine mark_common_members(list, id)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: id                   !! the unit
    character(len=:), allocatable :: member
    integer :: c, m, v, block, child, at

    do c = 1, size(list%box(id)%e%children)
        block = list%box(id)%e%children(c)
        if (list%box(block)%e%kind /= E_COMMON) cycle
        do m = 1, size(list%box(block)%e%args)
            member = lowercase(list%box(block)%e%args(m)%s)
            at = index(member, '(')
            if (at > 0) member = strip(member(:at - 1))
            do v = 1, size(list%box(id)%e%children)
                child = list%box(id)%e%children(v)
                if (list%box(child)%e%kind /= E_VARIABLE) cycle
                if (list%box(child)%e%var_role /= VAR_PLAIN) cycle
                if (lowercase(list%box(child)%e%name) == member) list%box(child)%e%var_role = VAR_COMMON
            end do
        end do
    end do
end subroutine mark_common_members

!> Read a `namelist` statement.
subroutine read_namelist(list, unit, line, doc, s)
    type(entity_list_t), intent(inout) :: list  !! the entities
    integer, intent(in) :: unit                 !! the entity it is in
    character(len=*), intent(in) :: line        !! the statement
    type(doc_lines_t), intent(in) :: doc        !! the statement's documentation
    type(settings_t), intent(in) :: s           !! the settings
    integer :: a, b, id

    a = index(line, '/')
    b = index(line, '/', back=.true.)
    if (a == 0 .or. b <= a) return
    id = list%add(E_NAMELIST, unit)
    associate (n => list%box(id)%e)
        n%name = strip(line(a + 1:b - 1))
        n%permission = inherited_permission(list, unit)
        n%args = top_split(line(b + 1:), ',')
        allocate (n%attribs(0))
        if (allocated(doc%lines)) then
            call set_doc(n, s, doc%lines)
        else
            call set_doc(n, s, [string_t ::])
        end if
    end associate
end subroutine read_namelist

end module fdoc_parser
