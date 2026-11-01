module fdoc_generics
!! The overview of a generic interface: which ways there are to call it, and which types and ranks each
!! one takes. Specific procedures with the same arguments make a call form, and each form gets a table
!! with a row for each combination of types and a column for each rank. Types are compared as written,
!! so two names of one kind count as different types. Pages are rendered in parallel, so nothing here
!! calls a function returning a deferred-length string (see `example/slen_race.f90`).
use fdoc_util
use fdoc_buffer
use fdoc_model
use fdoc_urls, only: entity_anchor
implicit none
private

public :: write_call_forms

integer, parameter :: ANY_RANK = -1     !! the rank of an assumed-rank argument

contains

!> Write the call forms of generic `name`, if it has more than one specific procedure. `shown` says
!> whether anything was written.
subroutine write_call_forms(list, name, specifics, b, shown)
    type(entity_list_t), intent(in) :: list !! the entities
    character(len=*), intent(in) :: name    !! the generic
    integer, intent(in) :: specifics(:)     !! its specific procedures
    type(buffer_t), intent(inout) :: b      !! the HTML
    logical, intent(out) :: shown           !! whether anything was written
    type(string_t), allocatable :: keys(:)
    integer, allocatable :: form_of(:)
    logical, allocatable :: usable(:)
    character(len=:), allocatable :: key
    integer :: k, j, forms

    shown = .false.
    allocate (keys(size(specifics)), form_of(size(specifics)), usable(size(specifics)))
    do k = 1, size(specifics)
        usable(k) = allocated(list%box(specifics(k))%e%more%arg_ids)
    end do
    if (count(usable) < 2) return
    shown = .true.
    forms = 0
    form_of = 0
    do k = 1, size(specifics)
        if (.not. usable(k)) cycle
        call form_key(list, specifics(k), key)
        do j = 1, forms
            if (keys(j)%s == key) form_of(k) = j
        end do
        if (form_of(k) == 0) then
            forms = forms + 1
            keys(forms)%s = key
            form_of(k) = forms
        end if
    end do
    call add(b, '<h2 id="call-forms">Call forms</h2>'//achar(10))
    do j = 1, forms
        call write_form(list, name, pack(specifics, form_of == j), b)
    end do
end subroutine write_call_forms

!> What specific procedure `id` has in common with those of its call form.
subroutine form_key(list, id, key)
    type(entity_list_t), intent(in) :: list             !! the entities
    integer, intent(in) :: id                           !! the procedure
    character(len=:), allocatable, intent(out) :: key   !! the key
    type(buffer_t) :: b
    integer :: k

    associate (e => list%box(id)%e)
        call add(b, merge('f', 's', e%kind == E_FUNCTION))
        do k = 1, size(e%more%arg_ids)
            call add(b, ',')
            if (e%more%arg_ids(k) == 0) cycle
            associate (a => list%box(e%more%arg_ids(k))%e)
                call add(b, lowercase(a%name))
                if (a%optional) call add(b, '?')
            end associate
        end do
    end associate
    call take(b, key)
end subroutine form_key

!> Write one call form, whose specific procedures are `ids`.
subroutine write_form(list, name, ids, b)
    type(entity_list_t), intent(in) :: list !! the entities
    character(len=*), intent(in) :: name    !! the generic
    integer, intent(in) :: ids(:)           !! the specific procedures of the form
    type(buffer_t), intent(inout) :: b      !! the HTML
    type(string_t), allocatable :: types(:, :), labels(:, :), result_types(:), result_labels(:), rows(:)
    integer, allocatable :: ranks(:, :), result_ranks(:), row_of(:), columns(:), offset(:)
    logical, allocatable :: in_table(:), varies(:), tied(:)
    character(len=:), allocatable :: key, relative
    logical :: has_result, elemental, new
    integer :: n, m, a, j, r, c, primary, num_rows, column

    n = size(ids)
    m = size(list%box(ids(1))%e%more%arg_ids)
    allocate (types(m, n), labels(m, n), ranks(m, n), result_types(n), result_labels(n), result_ranks(n))
    allocate (rows(n), row_of(n), in_table(m), varies(m), tied(m), offset(m))
    has_result = .true.
    elemental = .true.
    do j = 1, n
        associate (e => list%box(ids(j))%e)
            do a = 1, m
                call describe(list, e%more%arg_ids(a), types(a, j)%s, ranks(a, j))
            end do
            has_result = has_result .and. e%kind == E_FUNCTION .and. e%result > 0
            elemental = elemental .and. is_elemental(e)
        end associate
    end do
    if (has_result) then
        do j = 1, n
            call describe(list, list%box(ids(j))%e%result, result_types(j)%s, result_ranks(j))
        end do
    end if

    ! the first argument of varying rank gives the columns
    primary = 0
    do a = 1, m
        varies(a) = any(ranks(a, :) /= ranks(a, 1))
        if (varies(a) .and. primary == 0) primary = a
    end do
    relative = ''
    if (primary > 0) relative = 'rank('//list%box(list%box(ids(1))%e%more%arg_ids(primary))%e%name//')'
    do a = 1, m
        tied(a) = .false.
        if (primary > 0 .and. a /= primary) tied(a) = all(ranks(a, :) - ranks(primary, :) == ranks(a, 1) - ranks(primary, 1))
        in_table(a) = (varies(a) .and. a /= primary .and. .not. tied(a))
        do j = 2, n
            if (types(a, j)%s /= types(a, 1)%s) in_table(a) = .true.
        end do
    end do
    if (.not. any(in_table) .and. primary > 0) in_table(primary) = .true.
    do a = 1, m
        offset(a) = 0
        if (tied(a)) offset(a) = ranks(a, 1) - ranks(primary, 1)
    end do
    do j = 1, n
        do a = 1, m
            call rank_label(types(a, j)%s, ranks(a, j), a == primary, tied(a), relative, &
                            offset(a), labels(a, j)%s)
        end do
    end do
    if (has_result) then
        call label_results(ranks, primary, relative, result_types, result_ranks, result_labels)
    end if

    ! a row for each combination of types
    num_rows = 0
    do j = 1, n
        key = ''
        do a = 1, m
            if (in_table(a)) key = key//labels(a, j)%s//'|'
        end do
        if (has_result) key = key//result_labels(j)%s
        if (primary == 0) key = key//'|'//trim(int_text(j))
        new = .true.
        do r = 1, num_rows
            if (rows(r)%s /= key) cycle
            row_of(j) = r
            new = .false.
        end do
        if (new) then
            num_rows = num_rows + 1
            rows(num_rows)%s = key
            row_of(j) = num_rows
        end if
    end do

    ! a column for each rank, in order
    allocate (columns(0))
    if (primary > 0) then
        do j = 1, n
            if (.not. any(columns == ranks(primary, j))) call push_int(columns, ranks(primary, j))
        end do
        call sort_ints(columns)
    end if

    call add(b, '<div class="form">'//achar(10)//'<div class="sig">')
    call call_text(list, name, ids(1), has_result, b)
    if (elemental) call add(b, ' <span class="attr attr-elemental">elemental</span>')
    call add(b, '</div>'//achar(10))
    call shared_summary(list, ids, b)
    call add(b, '<table class="forms">'//achar(10)//'<thead><tr>')
    do a = 1, m
        if (.not. in_table(a)) cycle
        call add(b, '<th>')
        call html_escape(list%box(list%box(ids(1))%e%more%arg_ids(a))%e%name, b, .false.)
        call add(b, '</th>')
    end do
    if (primary == 0) call add(b, '<th>Procedure</th>')
    do c = 1, size(columns)
        call add(b, '<th class="rank">')
        call html_escape(relative, b, .false.)
        call add(b, ' = ')
        if (columns(c) == ANY_RANK) then
            call add(b, 'any')
        else
            call add(b, trim(int_text(columns(c))))
        end if
        call add(b, '</th>')
    end do
    if (has_result) call add(b, '<th>Result</th>')
    call add(b, '</tr></thead>'//achar(10)//'<tbody>'//achar(10))
    do r = 1, num_rows
        j = findloc(row_of, r, 1)
        call add(b, '<tr>')
        do a = 1, m
            if (.not. in_table(a)) cycle
            call add(b, '<td class="type">')
            call html_escape(labels(a, j)%s, b, .false.)
            call add(b, '</td>')
        end do
        if (primary == 0) then
            call add(b, '<td class="name">')
            call specific_link(list, ids(j), list%box(ids(j))%e%name, b)
            call add(b, '</td>')
        end if
        do c = 1, size(columns)
            call add(b, '<td class="rank">')
            do column = 1, n
                if (row_of(column) /= r) cycle
                if (ranks(primary, column) == columns(c)) call specific_link(list, ids(column), '&#10003;', b)
            end do
            call add(b, '</td>')
        end do
        if (has_result) then
            call add(b, '<td class="type">')
            call html_escape(result_labels(j)%s, b, .false.)
            call add(b, '</td>')
        end if
        call add(b, '</tr>'//achar(10))
    end do
    call add(b, '</tbody>'//achar(10)//'</table>'//achar(10))

    ! what is the same in every specific procedure of the form
    new = .true.
    do a = 1, m
        if (in_table(a) .or. a == primary) cycle
        if (new) then
            call add(b, '<p class="fixed">')
        else
            call add(b, ', ')
        end if
        new = .false.
        call add(b, '<code>')
        call html_escape(list%box(list%box(ids(1))%e%more%arg_ids(a))%e%name, b, .false.)
        call add(b, '</code> is ')
        call html_escape(labels(a, 1)%s, b, .false.)
    end do
    if (.not. new) call add(b, '</p>'//achar(10))
    call add(b, '</div>'//achar(10))
end subroutine write_form

!> The text and rank of the type of variable `id`. Anything else, such as a dummy procedure, is `procedure`.
subroutine describe(list, id, text, rank)
    type(entity_list_t), intent(in) :: list             !! the entities
    integer, intent(in) :: id                           !! the variable
    character(len=:), allocatable, intent(out) :: text  !! its type
    integer, intent(out) :: rank                        !! its rank
    type(buffer_t) :: b

    rank = 0
    text = 'procedure'
    if (id == 0) return
    associate (e => list%box(id)%e)
        if (e%kind /= E_VARIABLE .or. .not. allocated(e%vartype)) return
        call add(b, e%vartype)
        if (allocated(e%type_kind) .and. allocated(e%strlen)) then
            call add(b, '(len='//e%strlen//', '//e%type_kind//')')
        else if (allocated(e%type_kind)) then
            call add(b, '('//e%type_kind//')')
        else if (allocated(e%strlen)) then
            call add(b, '(len='//e%strlen//')')
        else if (allocated(e%proto)) then
            call add(b, '('//e%proto(1)%s//')')
        end if
        if (allocated(e%dimension)) rank = rank_of(e%dimension)
    end associate
    call take(b, text)
end subroutine describe

!> The rank given by `dimension`, such as `(:,:)`: one more than the commas outside inner parentheses.
pure integer function rank_of(dimension)
    character(len=*), intent(in) :: dimension   !! the dimensions
    integer :: k, depth

    rank_of = 0
    if (len(dimension) < 2) return
    if (dimension(1:1) /= '(') return
    if (index(dimension, '..') > 0) then
        rank_of = ANY_RANK
        return
    end if
    rank_of = 1
    depth = 0
    do k = 1, len(dimension)
        select case (dimension(k:k))
        case ('('); depth = depth + 1
        case (')'); depth = depth - 1
        case (','); if (depth == 1) rank_of = rank_of + 1
        end select
    end do
end function rank_of

!> The text of type `text` with its rank. A rank in `columns` is left out, and a tied one is relative.
subroutine rank_label(text, rank, in_columns, tied, relative, offset, label)
    character(len=*), intent(in) :: text                !! the type
    integer, intent(in) :: rank                         !! the rank
    logical, intent(in) :: in_columns                   !! true if the columns of the table show the rank
    logical, intent(in) :: tied                         !! true if it is a fixed distance from the columns
    character(len=*), intent(in) :: relative            !! the rank of the columns, as text
    integer, intent(in) :: offset                       !! that distance
    character(len=:), allocatable, intent(out) :: label !! the result
    type(buffer_t) :: b

    call add(b, text)
    if (rank == ANY_RANK) then
        call add(b, ', any rank')
    else if (in_columns) then
        continue
    else if (tied) then
        call add(b, ', '//relative)
        if (offset > 0) call add(b, ' + '//trim(int_text(offset)))
        if (offset < 0) call add(b, ' - '//trim(int_text(-offset)))
    else if (rank > 0) then
        call add(b, ', rank '//trim(int_text(rank)))
    end if
    call take(b, label)
end subroutine rank_label

!> The text of each result.
subroutine label_results(ranks, primary, relative, types, result_ranks, labels)
    integer, intent(in) :: ranks(:, :)                  !! the rank of each argument of each procedure
    integer, intent(in) :: primary                      !! the argument of the columns, or 0
    character(len=*), intent(in) :: relative            !! its rank, as text
    type(string_t), intent(in) :: types(:)              !! the type of each result
    integer, intent(in) :: result_ranks(:)              !! the rank of each result
    type(string_t), intent(inout) :: labels(:)          !! the text of each result
    logical :: tied
    integer :: j, offset

    tied = .false.
    offset = 0
    if (primary > 0) then
        offset = result_ranks(1) - ranks(primary, 1)
        tied = all(result_ranks - ranks(primary, :) == offset) .and. any(result_ranks /= result_ranks(1))
    end if
    do j = 1, size(types)
        call rank_label(types(j)%s, result_ranks(j), .false., tied, relative, offset, labels(j)%s)
    end do
end subroutine label_results

!> True if procedure `e` is elemental.
pure logical function is_elemental(e)
    type(entity_t), intent(in) :: e !! the procedure
    integer :: k

    is_elemental = .false.
    if (.not. allocated(e%attribs)) return
    do k = 1, size(e%attribs)
        if (lowercase(e%attribs(k)%s) == 'elemental') is_elemental = .true.
    end do
end function is_elemental

!> Write the summary of the procedures `ids`, if they all have the same one.
subroutine shared_summary(list, ids, b)
    type(entity_list_t), intent(in) :: list !! the entities
    integer, intent(in) :: ids(:)           !! the procedures
    type(buffer_t), intent(inout) :: b      !! the HTML
    integer :: j

    do j = 1, size(ids)
        if (.not. allocated(list%box(ids(j))%e%summary)) return
        if (list%box(ids(j))%e%summary /= list%box(ids(1))%e%summary) return
    end do
    call add(b, list%box(ids(1))%e%summary//achar(10))
end subroutine shared_summary

!> Write how a call of a form looks. Square brackets mark what is optional.
subroutine call_text(list, name, id, has_result, b)
    type(entity_list_t), intent(in) :: list !! the entities
    character(len=*), intent(in) :: name    !! the generic
    integer, intent(in) :: id               !! a procedure of the form
    logical, intent(in) :: has_result       !! true for a function
    type(buffer_t), intent(inout) :: b      !! the HTML
    character(len=:), allocatable :: low, symbol, left, right
    integer :: k, n

    associate (e => list%box(id)%e)
        n = size(e%more%arg_ids)
        low = lowercase(name)
        if (index(low, 'operator(') == 1 .and. n >= 1 .and. n <= 2) then
            symbol = name(10:len(name) - 1)
            call argument_name(list, e%more%arg_ids(1), left)
            call add(b, 'result = ')
            if (n == 1) then
                call html_escape(symbol//' '//left, b, .false.)
            else
                call argument_name(list, e%more%arg_ids(2), right)
                call html_escape(left//' '//symbol//' '//right, b, .false.)
            end if
            return
        end if
        if (index(low, 'assignment(') == 1 .and. n == 2) then
            call argument_name(list, e%more%arg_ids(1), left)
            call argument_name(list, e%more%arg_ids(2), right)
            call html_escape(left//' = '//right, b, .false.)
            return
        end if
        if (has_result) then
            call add(b, 'result = ')
        else
            call add(b, 'call ')
        end if
        call html_escape(name, b, .false.)
        call add(b, '(')
        do k = 1, n
            call argument_name(list, e%more%arg_ids(k), left)
            if (e%more%arg_ids(k) > 0) then
                if (list%box(e%more%arg_ids(k))%e%optional) then
                    if (k > 1) call add(b, ' ')
                    call add(b, '[')
                    if (k > 1) call add(b, ', ')
                    call html_escape(left, b, .false.)
                    call add(b, ']')
                    cycle
                end if
            end if
            if (k > 1) call add(b, ', ')
            call html_escape(left, b, .false.)
        end do
        call add(b, ')')
    end associate
end subroutine call_text

!> The name of argument `id`.
subroutine argument_name(list, id, name)
    type(entity_list_t), intent(in) :: list             !! the entities
    integer, intent(in) :: id                           !! the argument, or 0
    character(len=:), allocatable, intent(out) :: name  !! its name

    name = '*'
    if (id > 0) name = list%box(id)%e%name
end subroutine argument_name

!> Write a link to specific procedure `id`, further down the page.
subroutine specific_link(list, id, text, b)
    type(entity_list_t), intent(in) :: list !! the entities
    integer, intent(in) :: id               !! the procedure
    character(len=*), intent(in) :: text    !! the text, as HTML
    type(buffer_t), intent(inout) :: b      !! the HTML

    call add(b, '<a href="#')
    call entity_anchor(list, id, b)
    call add(b, '" title="')
    call html_escape(list%box(id)%e%name, b, .true.)
    call add(b, '">'//text//'</a>')
end subroutine specific_link

!> Put `list` in order.
pure subroutine sort_ints(list)
    integer, intent(inout) :: list(:)   !! the list
    integer :: k, j, value

    do k = 2, size(list)
        value = list(k)
        j = k - 1
        do while (j >= 1)
            if (list(j) <= value) exit
            list(j + 1) = list(j)
            j = j - 1
        end do
        list(j + 1) = value
    end do
end subroutine sort_ints

end module fdoc_generics
