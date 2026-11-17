module fdoc_site_markdown
!! Writing the documentation as Markdown files, one for each page of the HTML site, at the same paths
!! with `.md` in place of `.html`. Documentation is already Markdown by this point: see
!! [[markdown_to_markdown]]. There are no graphs, search or `modules.json`.
!!
!! Pages are rendered and written in parallel, so nothing that renders a page calls a function returning
!! a deferred-length string (see `example/slen_race.f90`).
use fdoc_util
use fdoc_buffer
use fdoc_model
use fdoc_settings, only: settings_t
use fdoc_project, only: project_t
use fdoc_pages, only: page_t
use fdoc_urls, only: entity_url, entity_anchor, markdown_url, is_shown
use fdoc_progress, only: progress_start, progress_tick, progress_finish, warn
use fdoc_shell, only: make_directory, quoted_path, run_command
use fdoc_site, only: site_t, prepare_site, copy_project_files, page_directories, children_of, has_page, display_name, &
                     entity_word, wants_source, logo_name, repeats_module, LIST_FILES, LIST_MODULES, LIST_PROCEDURES, LIST_ABSINT, &
                     LIST_TYPES, LIST_PROGRAMS, LIST_BLOCKDATA, LIST_NAMELISTS, NUM_LISTS, LIST_FILE, LIST_TITLE, LIST_NOUN
implicit none
private

public :: write_markdown_site

character, parameter :: NL = achar(10)
integer, parameter :: MAX_NESTING = 16  !! how many levels of containers a page shows

!> The directories of the output.
character(len=*), parameter :: DIRECTORIES(*) = [character(len=10) :: 'lists', 'module', 'proc', 'type', 'interface', &
                                                 'program', 'blockdata', 'namelist', 'sourcefile', 'page']

contains

!> Write `text` as inline code.
subroutine add_code(text, b)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: b      !! the Markdown

    call add(b, '`'//text//'`')
end subroutine add_code

!> Write `text` as a section heading.
subroutine add_heading(text, b)
    character(len=*), intent(in) :: text    !! the heading
    type(buffer_t), intent(inout) :: b      !! the Markdown

    call add(b, '## '//text//NL//NL)
end subroutine add_heading

!> Write an empty HTML element that a link to entity `id` can go to.
subroutine add_anchor(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the entity
    type(buffer_t), intent(inout) :: b      !! the Markdown

    call add(b, '<a id="')
    call entity_anchor(site%p%list, id, b)
    call add(b, '"></a>')
end subroutine add_anchor

!> Write `name` as code, linked to entity `id` if it can be, from a page one directory below the root.
subroutine link_to(site, id, name, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the entity, or 0
    character(len=*), intent(in) :: name    !! the text
    type(buffer_t), intent(inout) :: b      !! the Markdown
    character(len=:), allocatable :: url, link

    url = ''
    if (id > 0) then
        associate (e => site%p%list%box(id)%e)
            if (is_shown(site%p%list, id) .or. allocated(e%external_url)) call entity_url(site%p%list, id, url)
        end associate
    end if
    if (len(url) == 0) then
        call add_code(name, b)
        return
    end if
    call add(b, '[')
    call add_code(name, b)
    if (allocated(site%p%list%box(id)%e%external_url)) then
        call add(b, ']('//url//')')
    else
        call markdown_url(url, link)
        call add(b, '](../'//link//')')
    end if
end subroutine link_to

!> Write text as a cell of a table, which has to stay on one line. Line breaks become HTML, and lines of
!> a code block become inline code.
subroutine add_cell(text, b)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: b      !! the table
    type(buffer_t) :: line
    character(len=:), allocatable :: piece
    integer :: first, last, at, next, k, stop_at
    logical :: code, started

    call add(b, ' ')
    first = verify(text, ' '//NL)
    last = verify(text, ' '//NL, back=.true.)
    code = .false.
    started = .false.
    at = first
    do while (at > 0 .and. at <= last)
        next = index(text(at:last), NL)
        stop_at = merge(at + next - 2, last, next > 0)
        if (starts_with(adjustl(text(at:stop_at)), '```') .or. starts_with(adjustl(text(at:stop_at)), '~~~')) then
            code = .not. code
        else
            if (started) call add(b, '<br>')
            started = .true.
            if (code) call add(line, '`')
            call add(line, text(at:stop_at))
            if (code) call add(line, '`')
            call take(line, piece)
            do k = 1, len(piece)
                if (piece(k:k) == '|') call add(b, '\')
                call add(b, piece(k:k))
            end do
        end if
        if (next == 0) exit
        at = at + next
    end do
    call add(b, ' |')
end subroutine add_cell

!> Write the contents of buffer `cell` as a cell of a table, leaving it empty.
subroutine add_buffer_cell(cell, b)
    type(buffer_t), intent(inout) :: cell   !! the text
    type(buffer_t), intent(inout) :: b      !! the table
    character(len=:), allocatable :: text

    call take(cell, text)
    call add_cell(text, b)
end subroutine add_buffer_cell

!> Write the head of a table with the columns `titles`, separated by `|`.
subroutine table_head(titles, b)
    character(len=*), intent(in) :: titles  !! the titles
    type(buffer_t), intent(inout) :: b      !! the table
    integer :: k

    call add(b, '| '//titles//' |'//NL//'|')
    do k = 1, count([(titles(k:k) == '|', k=1, len(titles))]) + 1
        call add(b, ' --- |')
    end do
    call add(b, NL)
end subroutine table_head

!> Write the type of variable `e`, with a link to its derived type if `linked` is true. Without it, the
!> result is plain Fortran, for a code block.
subroutine add_type(site, e, linked, b)
    type(site_t), intent(in) :: site        !! the site
    type(entity_t), intent(in) :: e         !! the variable
    logical, intent(in) :: linked           !! true to link, and to mark the rest as code
    type(buffer_t), intent(inout) :: b      !! the Markdown
    logical :: extra

    if (linked .and. .not. allocated(e%proto)) call add(b, '`')
    if (linked .and. allocated(e%proto) .and. (allocated(e%type_kind) .or. allocated(e%strlen))) call add(b, '`')
    call add(b, e%vartype)
    if (allocated(e%type_kind) .and. allocated(e%strlen)) then
        call add(b, '(len='//e%strlen//', kind='//e%type_kind//')')
    else if (allocated(e%type_kind)) then
        call add(b, '(kind='//e%type_kind//')')
    else if (allocated(e%strlen)) then
        call add(b, '(len='//e%strlen//')')
    else if (allocated(e%proto)) then
        call add(b, '(')
        if (linked) then
            call link_to(site, e%proto_id, e%proto(1)%s, b)
        else
            call add(b, e%proto(1)%s)
        end if
        extra = size(e%proto) > 1
        if (extra) extra = len(e%proto(2)%s) > 0
        if (extra) call add(b, '('//e%proto(2)%s//')')
        call add(b, ')')
        return
    end if
    if (linked) call add(b, '`')
end subroutine add_type

!> Write the declaration of a procedure as a code block.
subroutine signature(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the procedure
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    associate (e => site%p%list%box(id)%e)
        call add(b, '```fortran'//NL)
        if (allocated(e%attribs)) then
            do k = 1, size(e%attribs)
                call add(b, e%attribs(k)%s//' ')
            end do
        end if
        if (e%kind == E_FUNCTION .and. e%result > 0) then
            call add_type(site, site%p%list%box(e%result)%e, .false., b)
            call add(b, ' ')
        end if
        select case (e%kind)
        case (E_FUNCTION); call add(b, 'function ')
        case (E_SUBROUTINE); call add(b, 'subroutine ')
        case (E_MODPROC); call add(b, 'module procedure ')
        end select
        call add(b, e%name)
        if (allocated(e%more%args)) then
            call add(b, '(')
            do k = 1, size(e%more%args)
                if (k > 1) call add(b, ', ')
                call add(b, e%more%args(k)%s)
            end do
            call add(b, ')')
        end if
        if (e%kind == E_FUNCTION) then
            if (allocated(e%more%result_name)) then
                if (lowercase(e%more%result_name) /= lowercase(e%name)) call add(b, ' result('//e%more%result_name//')')
            end if
        end if
        if (allocated(e%more%bind_c)) call add(b, ' bind('//e%more%bind_c//')')
        call add(b, NL//'```'//NL//NL)
    end associate
end subroutine signature

!> Write the attributes of argument `e` as code.
subroutine argument_attributes(e, b)
    type(entity_t), intent(in) :: e     !! the argument
    type(buffer_t), intent(inout) :: b  !! the Markdown
    integer :: k

    if (e%parameter) call add(b, '`parameter` ')
    if (e%optional) call add(b, '`optional` ')
    do k = 1, size(e%attribs)
        call add(b, '`'//e%attribs(k)%s//'` ')
    end do
    if (allocated(e%dimension)) then
        if (index(e%dimension, '(') == 1) call add(b, '`dimension'//e%dimension//'` ')
    end if
end subroutine argument_attributes

!> Write the attributes of procedure `e` that say how it behaves, as code. Anything else is left out.
subroutine procedure_attributes(e, b)
    type(entity_t), intent(in) :: e     !! the entity
    type(buffer_t), intent(inout) :: b  !! the Markdown
    integer :: k

    if (.not. is_procedure(e%kind)) return
    if (allocated(e%attribs)) then
        do k = 1, size(e%attribs)
            select case (lowercase(e%attribs(k)%s))
            case ('pure', 'impure', 'elemental', 'recursive', 'non_recursive')
                call add(b, '`'//lowercase(e%attribs(k)%s)//'` ')
            end select
        end do
    end if
    if (allocated(e%more%bind_c)) call add(b, '`bind(C)` ')
    if (e%more%saved_state) call add(b, '`saved state` ')
    if (e%more%common_block) call add(b, '`common` ')
end subroutine procedure_attributes

!> Write a table of dummy arguments, or with `components` of other variables, such as the components of
!> a type. Those have no intent, and may have a default value and a permission.
subroutine argument_table(site, ids, components, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: ids(:)           !! the variables
    logical, intent(in) :: components       !! true for variables that are not arguments
    type(buffer_t), intent(inout) :: b      !! the Markdown
    type(buffer_t) :: cell
    logical :: defaults, intents
    integer :: k

    defaults = .false.
    if (components) defaults = any([(allocated(site%p%list%box(ids(k))%e%initial), k=1, size(ids))])
    intents = .not. components
    if (intents .and. defaults) then
        call table_head('Name | Type | Intent | Attributes | Default | Description', b)
    else if (intents) then
        call table_head('Name | Type | Intent | Attributes | Description', b)
    else if (defaults) then
        call table_head('Name | Type | Attributes | Default | Description', b)
    else
        call table_head('Name | Type | Attributes | Description', b)
    end if
    do k = 1, size(ids)
        associate (e => site%p%list%box(ids(k))%e)
            call add(b, '|')
            call add_anchor(site, ids(k), cell)
            call add_code(e%name, cell)
            call add_buffer_cell(cell, b)
            if (e%kind == E_VARIABLE) then
                call add_type(site, e, .true., cell)
                call add_buffer_cell(cell, b)
                if (intents) then
                    if (allocated(e%intent)) then
                        if (len(e%intent) > 0) call add_code(e%intent, cell)
                    end if
                    call add_buffer_cell(cell, b)
                end if
                if (components .and. allocated(e%permission)) then
                    if (e%permission /= 'public') call add(cell, '`'//e%permission//'` ')
                end if
                call argument_attributes(e, cell)
                call add_buffer_cell(cell, b)
                if (defaults) then
                    if (allocated(e%initial)) then
                        if (e%points) then
                            call add_code('=> '//e%initial, cell)
                        else
                            call add_code(e%initial, cell)
                        end if
                    end if
                    call add_buffer_cell(cell, b)
                end if
                if (allocated(e%html)) then
                    call add_cell(e%html, b)
                else
                    call add(b, '  |')
                end if
            else
                ! a dummy procedure with an interface
                call add(b, ' `procedure` |')
                if (intents) call add(b, '  |')
                call add(b, '  |')
                if (defaults) call add(b, '  |')
                if (allocated(e%summary)) then
                    call add_cell(e%summary, b)
                else
                    call add(b, '  |')
                end if
            end if
            call add(b, NL)
        end associate
    end do
    call add(b, NL)
end subroutine argument_table

!> Write a table of type-bound procedures.
subroutine binding_table(site, ids, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: ids(:)           !! the bindings
    type(buffer_t), intent(inout) :: b      !! the Markdown
    type(buffer_t) :: cell
    integer :: k, j

    call table_head('Name | Binds to | Attributes | Description', b)
    do k = 1, size(ids)
        associate (t => site%p%list%box(ids(k))%e)
            call add(b, '|')
            call add_anchor(site, ids(k), cell)
            call add_code(t%name, cell)
            call add_buffer_cell(cell, b)
            if (allocated(t%more%proto_text)) then
                call link_to(site, t%proto_id, t%more%proto_text, cell)
            else if (allocated(t%more%binding_ids) .and. .not. t%deferred) then
                do j = 1, size(t%more%binding_ids)
                    if (j > 1) call add(cell, ', ')
                    call link_to(site, t%more%binding_ids(j), t%more%bindings(j)%s, cell)
                end do
            end if
            call add_buffer_cell(cell, b)
            if (t%generic) call add(cell, '`generic` ')
            if (t%deferred) call add(cell, '`deferred` ')
            if (t%permission /= 'public') call add(cell, '`'//t%permission//'` ')
            do j = 1, size(t%attribs)
                call add(cell, '`'//t%attribs(j)%s//'` ')
            end do
            call add_buffer_cell(cell, b)
            if (allocated(t%html)) then
                call add_cell(t%html, b)
            else
                call add(b, '  |')
            end if
            call add(b, NL)
        end associate
    end do
    call add(b, NL)
end subroutine binding_table

!> Write a short entry for entity `id`.
subroutine summary_item(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the entity
    type(buffer_t), intent(inout) :: b      !! the Markdown
    type(buffer_t) :: words
    character(len=:), allocatable :: text

    associate (e => site%p%list%box(id)%e)
        call add(b, '### ')
        call add_anchor(site, id, b)
        call link_to(site, id, e%name, b)
        call add(b, NL//NL)
        call procedure_attributes(e, words)
        if (allocated(e%permission)) then
            if (e%permission /= 'public') call add(words, '`'//e%permission//'` ')
        end if
        call take(words, text)
        if (len(text) > 0) call add(b, trim(text)//NL//NL)
        select case (e%kind)
        case (E_SUBROUTINE, E_FUNCTION, E_MODPROC)
            call signature(site, id, b)
        end select
        if (allocated(e%summary)) then
            if (len(e%summary) > 0) call add(b, e%summary//NL//NL)
        end if
    end associate
end subroutine summary_item

!> Write a section of short entries, if there are any.
subroutine summary_section(site, title, ids, b)
    type(site_t), intent(in) :: site        !! the site
    character(len=*), intent(in) :: title   !! the heading
    integer, intent(in) :: ids(:)           !! the entities
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    if (size(ids) == 0) return
    call add_heading(title, b)
    do k = 1, size(ids)
        call summary_item(site, ids(k), b)
    end do
end subroutine summary_section

!> Write links to `ids` as a list.
subroutine link_list(site, ids, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: ids(:)           !! the entities
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    do k = 1, size(ids)
        call add(b, '- ')
        call link_to(site, ids(k), site%p%list%box(ids(k))%e%name, b)
        call add(b, NL)
    end do
    call add(b, NL)
end subroutine link_list

!> Write `words` as a list of code.
subroutine word_list(words, b)
    type(string_t), intent(in) :: words(:)  !! the words
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    do k = 1, size(words)
        call add(b, '- `'//words(k)%s//'`'//NL)
    end do
    call add(b, NL)
end subroutine word_list

!> Write the modules a unit uses, each once, however many `use` statements name it.
subroutine uses_section(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the unit
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    associate (e => site%p%list%box(id)%e)
        if (.not. allocated(e%more%uses)) return
        if (size(e%more%uses) == 0) return
        call add_heading('Uses', b)
        do k = 1, size(e%more%uses)
            if (repeats_module(e%more%uses, k)) cycle
            call add(b, '- ')
            call link_to(site, e%more%uses(k)%target, e%more%uses(k)%module, b)
            call add(b, NL)
        end do
        call add(b, NL)
    end associate
end subroutine uses_section

!> Write what a procedure or program calls.
subroutine calls_section(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the procedure
    type(buffer_t), intent(inout) :: b      !! the Markdown

    associate (e => site%p%list%box(id)%e)
        if (.not. allocated(e%call_ids)) return
        if (size(e%call_ids) == 0) return
        call add_heading('Calls', b)
        call link_list(site, e%call_ids, b)
    end associate
end subroutine calls_section

!> Write what is specific to a module, submodule, program or block data unit.
subroutine unit_body(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the unit
    type(buffer_t), intent(inout) :: b      !! the Markdown

    associate (e => site%p%list%box(id)%e)
        if (e%kind == E_SUBMODULE) then
            call add(b, 'Submodule of ')
            call link_to(site, e%ancestor_id, e%more%ancestor, b)
            call add(b, NL//NL)
        end if
        call uses_section(site, id, b)
        if (allocated(e%more%descendants)) then
            call add_heading('Submodules', b)
            call link_list(site, e%more%descendants, b)
        end if
        if (e%kind == E_PROGRAM) call calls_section(site, id, b)
    end associate
end subroutine unit_body

!> Write what is specific to a procedure.
subroutine procedure_body(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the procedure
    type(buffer_t), intent(inout) :: b      !! the Markdown

    associate (e => site%p%list%box(id)%e)
        if (allocated(e%more%arg_ids)) then
            if (size(e%more%arg_ids) > 0) then
                call add_heading('Arguments', b)
                call argument_table(site, e%more%arg_ids, .false., b)
            end if
        end if
        if (e%result > 0) then
            call add_heading('Result', b)
            call argument_table(site, [e%result], .true., b)
        end if
        if (e%implements > 0) then
            call add(b, merge('Implements  ', 'Implemented ', e%kind == E_MODPROC)//' ')
            call link_to(site, e%implements, site%p%list%box(e%implements)%e%name, b)
            call add(b, NL//NL)
        end if
        call uses_section(site, id, b)
        call calls_section(site, id, b)
    end associate
end subroutine procedure_body

!> Write what is specific to a generic interface: the procedures in it.
subroutine interface_body(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the interface
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    associate (e => site%p%list%box(id)%e)
        call add_heading('Procedures', b)
        do k = 1, size(e%more%modproc_ids)
            if (e%more%modproc_ids(k) == 0) then
                call add(b, '### `'//e%more%modprocs(k)%s//'`'//NL//NL)
            else
                call summary_item(site, e%more%modproc_ids(k), b)
            end if
        end do
        do k = 1, size(e%children)
            if (site%p%list%box(e%children(k))%e%kind == E_NONE) cycle
            if (allocated(site%p%list%box(e%children(k))%e%more%args)) call summary_item(site, e%children(k), b)
        end do
    end associate
end subroutine interface_body

!> Write what is specific to a derived type.
subroutine type_body(site, id, variables, bindings, finals, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the type
    integer, intent(in) :: variables(:)     !! its components
    integer, intent(in) :: bindings(:)      !! its bindings
    integer, intent(in) :: finals(:)        !! its final procedures
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    associate (e => site%p%list%box(id)%e)
        if (allocated(e%more%extends)) then
            call add(b, 'Extends ')
            call link_to(site, e%extends_id, e%more%extends, b)
            call add(b, NL//NL)
        end if
        if (size(e%attribs) > 0) call word_list(e%attribs, b)
        if (size(variables) > 0) then
            call add_heading('Components', b)
            call argument_table(site, variables, .true., b)
        end if
        if (e%constructor > 0) then
            call add_heading('Constructor', b)
            call summary_item(site, e%constructor, b)
        end if
        if (size(bindings) > 0) then
            call add_heading('Type-bound procedures', b)
            call binding_table(site, bindings, b)
        end if
        if (size(finals) > 0) then
            call add_heading('Final procedures', b)
            do k = 1, size(finals)
                call add(b, '- ')
                call link_to(site, site%p%list%box(finals(k))%e%proto_id, site%p%list%box(finals(k))%e%name, b)
                call add(b, NL)
            end do
            call add(b, NL)
        end if
        associate (uses => site%type_uses(site%use_slot(id)))
            if (allocated(uses%arguments) .or. allocated(uses%results) .or. allocated(uses%components) .or. &
                allocated(uses%variables)) call add_heading('Where it is used', b)
            call use_group(site, 'Argument of', uses%arguments, b)
            call use_group(site, 'Returned by', uses%results, b)
            call use_group(site, 'Component of', uses%components, b)
            call use_group(site, 'Module variables', uses%variables, b)
        end associate
    end associate
end subroutine type_body

!> Write a group of `ids` where a type is used.
subroutine use_group(site, title, ids, b)
    type(site_t), intent(in) :: site        !! the site
    character(len=*), intent(in) :: title   !! the heading
    integer, allocatable, intent(in) :: ids(:)  !! the entities, if any
    type(buffer_t), intent(inout) :: b      !! the Markdown

    if (.not. allocated(ids)) return
    call add(b, '### '//title//' ('//trim(int_text(size(ids)))//')'//NL//NL)
    call link_list(site, ids, b)
end subroutine use_group

!> Write what is specific to a source file.
subroutine file_body(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the file
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer, allocatable :: units(:)
    integer :: k

    associate (e => site%p%list%box(id)%e)
        allocate (units(0))
        do k = 1, size(e%children)
            select case (site%p%list%box(e%children(k))%e%kind)
            case (E_MODULE, E_SUBMODULE, E_PROGRAM, E_BLOCKDATA, E_SUBROUTINE, E_FUNCTION)
                call push_int(units, e%children(k))
            end select
        end do
        call summary_section(site, 'Contents', units, b)
    end associate
end subroutine file_body

!> Write enumerations.
subroutine enum_sections(site, ids, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: ids(:)           !! the enumerations
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    if (size(ids) == 0) return
    call add_heading('Enumerations', b)
    do k = 1, size(ids)
        call add_anchor(site, ids(k), b)
        call add(b, NL//NL)
        call argument_table(site, site%p%list%box(ids(k))%e%children, .true., b)
    end do
end subroutine enum_sections

!> Write common blocks.
subroutine common_sections(site, ids, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: ids(:)           !! the common blocks
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k

    if (size(ids) == 0) return
    call add_heading('Common blocks', b)
    do k = 1, size(ids)
        associate (e => site%p%list%box(ids(k))%e)
            call add(b, '### ')
            call add_anchor(site, ids(k), b)
            call add_code(e%name, b)
            call add(b, NL//NL)
            if (allocated(e%html)) call add(b, e%html//NL//NL)
            call word_list(e%more%args, b)
        end associate
    end do
end subroutine common_sections

!> Write `code` as a code block, with a fence longer than any run of backticks in it.
subroutine code_block(code, b)
    character(len=*), intent(in) :: code    !! the code
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: k, run, longest

    longest = 2
    run = 0
    do k = 1, len(code)
        if (code(k:k) == '`') then
            run = run + 1
            longest = max(longest, run)
        else
            run = 0
        end if
    end do
    call add(b, repeat('`', longest + 1)//'fortran'//NL)
    call add(b, code)
    if (len(code) > 0) then
        if (code(len(code):len(code)) /= NL) call add(b, NL)
    end if
    call add(b, repeat('`', longest + 1)//NL//NL)
end subroutine code_block

!> Write the source of entity `id`, if it is wanted.
subroutine source_section(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the entity
    type(buffer_t), intent(inout) :: b      !! the Markdown

    associate (e => site%p%list%box(id)%e)
        select case (e%kind)
        case (E_FILE)
            if (site%s%incl_src .and. allocated(e%source_text)) then
                call add_heading('Source', b)
                call code_block(e%source_text, b)
            end if
        case (E_SUBROUTINE, E_FUNCTION, E_MODPROC, E_TYPE)
            if (.not. wants_source(site, id) .or. e%source_first == 0) return
            call add_heading('Source', b)
            call code_block(site%p%list%box(e%file)%e%source_text(e%source_first:e%source_last), b)
        end select
    end associate
end subroutine source_section

!> Write the entities that hold entity `id`, if any, as a path of links.
subroutine breadcrumbs(site, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the entity
    type(buffer_t), intent(inout) :: b      !! the Markdown
    integer :: chain(MAX_NESTING)
    integer :: k, n, up

    n = 0
    up = site%p%list%box(id)%e%parent
    do while (up > 0 .and. n < MAX_NESTING)
        n = n + 1
        chain(n) = up
        up = site%p%list%box(up)%e%parent
    end do
    if (n == 0) return
    do k = n, 1, -1
        call link_to(site, chain(k), display_name(site%p%list%box(chain(k))%e), b)
        if (k > 1) call add(b, ' > ')
    end do
    call add(b, NL//NL)
end subroutine breadcrumbs

!> Write the title of the page of entity `id`, what is known about it, and its documentation.
subroutine entity_title(site, id, word, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: id               !! the entity
    character(len=*), intent(in) :: word    !! what it is
    type(buffer_t), intent(inout) :: b      !! the Markdown
    type(buffer_t) :: words
    character(len=:), allocatable :: text
    integer :: k

    associate (e => site%p%list%box(id)%e)
        call breadcrumbs(site, id, b)
        call add(b, '# '//word//' ')
        call add_code(display_name(e), b)
        call add(b, NL//NL)
        call procedure_attributes(e, words)
        if (allocated(e%permission)) then
            if (e%permission /= 'public' .and. e%kind /= E_MODULE .and. e%kind /= E_SUBMODULE .and. e%kind /= E_FILE .and. &
                e%kind /= E_PROGRAM) call add(words, '`'//e%permission//'` ')
        end if
        call take(words, text)
        if (len(text) > 0) call add(b, trim(text)//NL//NL)
        k = 0
        do while (k < size(e%meta))
            k = k + 1
            select case (e%meta(k)%key)
            case ('author', 'date', 'version', 'since', 'license', 'category')
                call add(words, '- **'//e%meta(k)%key//':** '//join(e%meta(k)%values, ' ')//NL)
            case ('deprecated')
                call add(words, '- **deprecated**'//NL)
            end select
        end do
        call take(words, text)
        if (len(text) > 0) call add(b, text//NL)
        select case (e%kind)
        case (E_SUBROUTINE, E_FUNCTION, E_MODPROC)
            call signature(site, id, b)
        end select
        if (allocated(e%html)) then
            if (len(e%html) > 0) call add(b, e%html//NL//NL)
        end if
    end associate
end subroutine entity_title

!> Render the page of entity `id`.
subroutine entity_page(site, id, text)
    type(site_t), intent(in) :: site                    !! the site
    integer, intent(in) :: id                           !! the entity
    character(len=:), allocatable, intent(out) :: text  !! the page
    type(buffer_t) :: b
    integer, allocatable :: variables(:), functions(:), subroutines(:), interfaces(:), abstracts(:), types(:)
    integer, allocatable :: bindings(:), finals(:), lists(:), blocks(:), implementations(:), enums(:)
    character(len=:), allocatable :: word

    call children_of(site, id, 1, variables)
    call children_of(site, id, 2, functions)
    call children_of(site, id, 3, subroutines)
    call children_of(site, id, 4, interfaces)
    call children_of(site, id, 5, abstracts)
    call children_of(site, id, 6, types)
    call children_of(site, id, 7, bindings)
    call children_of(site, id, 8, finals)
    call children_of(site, id, 9, lists)
    call children_of(site, id, 10, blocks)
    call children_of(site, id, 11, enums)
    call children_of(site, id, 12, implementations)

    associate (e => site%p%list%box(id)%e)
        call entity_word(e, word)
        call entity_title(site, id, word, b)
        select case (e%kind)
        case (E_SUBROUTINE, E_FUNCTION, E_MODPROC)
            call procedure_body(site, id, b)
        case (E_INTERFACE)
            call interface_body(site, id, b)
        case (E_TYPE)
            call type_body(site, id, variables, bindings, finals, b)
        case (E_NAMELIST)
            if (allocated(e%more%args)) then
                call add_heading('Variables', b)
                call word_list(e%more%args, b)
            end if
        case (E_FILE)
            call file_body(site, id, b)
        case default
            call unit_body(site, id, b)
        end select

        if (e%kind /= E_FILE .and. e%kind /= E_INTERFACE .and. e%kind /= E_TYPE .and. e%kind /= E_NAMELIST) then
            if (size(variables) > 0) then
                call add_heading('Variables', b)
                call argument_table(site, variables, .true., b)
            end if
            call enum_sections(site, enums, b)
            call common_sections(site, blocks, b)
            call summary_section(site, 'Interfaces', interfaces, b)
            call summary_section(site, 'Abstract interfaces', abstracts, b)
            call summary_section(site, 'Types', types, b)
            call summary_section(site, 'Namelists', lists, b)
            call summary_section(site, 'Functions', functions, b)
            call summary_section(site, 'Subroutines', subroutines, b)
            call summary_section(site, 'Module procedures', implementations, b)
        end if
        call source_section(site, id, b)
    end associate
    call finish_page(b, text)
end subroutine entity_page

!> The text of a finished page, ending in one line break.
subroutine finish_page(b, text)
    type(buffer_t), intent(inout) :: b                  !! the page
    character(len=:), allocatable, intent(out) :: text  !! the text
    character(len=:), allocatable :: whole
    integer :: last

    call take(b, whole)
    last = verify(whole, ' '//NL, back=.true.)
    text = whole(:last)//NL
end subroutine finish_page

!> Write the cell for what the entries of list `which` say about entity `id`, besides their name.
subroutine list_columns(site, which, id, b)
    type(site_t), intent(in) :: site        !! the site
    integer, intent(in) :: which            !! the list
    integer, intent(in) :: id               !! the entity
    type(buffer_t), intent(inout) :: b      !! the table
    type(buffer_t) :: cell

    associate (e => site%p%list%box(id)%e)
        select case (which)
        case (LIST_MODULES, LIST_PROGRAMS, LIST_BLOCKDATA)
            call location(e%file)
        case (LIST_PROCEDURES)
            call location(e%parent)
            if (e%iface /= IFACE_NONE .or. e%kind == E_INTERFACE) then
                call add_cell('`interface`', b)
            else if (e%kind == E_FUNCTION) then
                call add_cell('`function`', b)
            else if (e%kind == E_SUBROUTINE) then
                call add_cell('`subroutine`', b)
            else
                call add_cell('`procedure`', b)
            end if
        case (LIST_ABSINT, LIST_NAMELISTS)
            call location(e%parent)
        case (LIST_TYPES)
            call location(e%parent)
            if (allocated(e%more%extends)) call link_to(site, e%extends_id, e%more%extends, cell)
            call add_buffer_cell(cell, b)
        end select
    end associate

contains

    !> Write a column linking to entity `where`.
    subroutine location(where)
        integer, intent(in) :: where    !! the entity

        if (where > 0) call link_to(site, where, display_name(site%p%list%box(where)%e), cell)
        call add_buffer_cell(cell, b)
    end subroutine location

end subroutine list_columns

!> Render a list page.
subroutine list_page(site, which, text)
    type(site_t), intent(in) :: site                    !! the site
    integer, intent(in) :: which                        !! the list
    character(len=:), allocatable, intent(out) :: text  !! the page
    type(buffer_t) :: b, cell
    integer :: k

    call add(b, '# '//trim(LIST_TITLE(which))//NL//NL)
    select case (which)
    case (LIST_MODULES, LIST_PROGRAMS, LIST_BLOCKDATA)
        call table_head(trim(LIST_NOUN(which))//' | Source File | Description', b)
    case (LIST_PROCEDURES)
        call table_head(trim(LIST_NOUN(which))//' | Location | Type | Description', b)
    case (LIST_ABSINT, LIST_NAMELISTS)
        call table_head(trim(LIST_NOUN(which))//' | Location | Description', b)
    case (LIST_TYPES)
        call table_head(trim(LIST_NOUN(which))//' | Location | Extends | Description', b)
    case default
        call table_head(trim(LIST_NOUN(which))//' | Description', b)
    end select
    do k = 1, size(site%members(which)%ids)
        associate (id => site%members(which)%ids(k))
            call add(b, '|')
            call link_to(site, id, display_name(site%p%list%box(id)%e), cell)
            call add_buffer_cell(cell, b)
            call list_columns(site, which, id, b)
            if (allocated(site%p%list%box(id)%e%summary)) then
                call add_cell(site%p%list%box(id)%e%summary, b)
            else
                call add(b, '  |')
            end if
            call add(b, NL)
        end associate
    end do
    call finish_page(b, text)
end subroutine list_page

!> Write a line with a link to `url`, if it is set.
subroutine link_line(url, label, b)
    character(len=:), allocatable, intent(in) :: url    !! the link
    character(len=*), intent(in) :: label               !! what it is
    type(buffer_t), intent(inout) :: b                  !! the Markdown

    if (allocated(url)) call add(b, '- ['//label//']('//url//')'//NL)
end subroutine link_line

!> Render the front page.
subroutine index_page(site, front, text)
    type(site_t), intent(in) :: site                    !! the site
    character(len=*), intent(in) :: front               !! the project file's text
    character(len=:), allocatable, intent(out) :: text  !! the page
    type(buffer_t) :: b, links
    character(len=:), allocatable :: name
    integer :: k, up, depth

    associate (s => site%s)
        call logo_name(s, name)
        if (len(name) > 0) call add(b, '![]('//name//')'//NL//NL)
        call add(b, '# '//s%project//NL//NL)
        if (allocated(s%summary)) call add(b, s%summary//NL//NL)
        if (allocated(s%author)) call add(b, 'By '//s%author//NL//NL)
        call link_line(s%project_github, 'Source on GitHub', links)
        call link_line(s%project_gitlab, 'Source on GitLab', links)
        call link_line(s%project_bitbucket, 'Source on Bitbucket', links)
        call link_line(s%project_sourceforge, 'Source on SourceForge', links)
        call link_line(s%project_website, 'Project website', links)
        call link_line(s%project_download, 'Download', links)
        call take(links, name)
        if (len(name) > 0) call add(b, name//NL)
        do k = 1, NUM_LISTS
            if (size(site%members(k)%ids) == 0) cycle
            call add(b, '- ['//trim(LIST_TITLE(k))//'](lists/'//trim(LIST_FILE(k))//'.md) ('// &
                     trim(int_text(size(site%members(k)%ids)))//')'//NL)
        end do
        call add(b, NL)
        if (size(site%pages) > 0) then
            call add_heading('Pages', b)
            do k = 1, size(site%pages)
                depth = 0
                up = site%pages(k)%parent
                do while (up > 0)
                    depth = depth + 1
                    up = site%pages(up)%parent
                end do
                call add(b, repeat('  ', depth)//'- ['//site%pages(k)%title//'](page/'// &
                         site%pages(k)%path(:len(site%pages(k)%path) - 5)//'.md)'//NL)
            end do
            call add(b, NL)
        end if
        call add(b, front)
    end associate
    call finish_page(b, text)
end subroutine index_page

!> Render static page `k`.
subroutine static_page(site, k, text)
    type(site_t), intent(in) :: site                    !! the site
    integer, intent(in) :: k                            !! the page
    character(len=:), allocatable, intent(out) :: text  !! the page
    type(buffer_t) :: b

    associate (page => site%pages(k))
        call add(b, '# '//page%title//NL//NL)
        if (allocated(page%author)) call add(b, '- **author:** '//page%author//NL)
        if (allocated(page%date)) call add(b, '- **date:** '//page%date//NL)
        if (allocated(page%author) .or. allocated(page%date)) call add(b, NL)
        call add(b, page%html)
    end associate
    call finish_page(b, text)
end subroutine static_page

!> Render the page of entity `id` and write it.
subroutine write_entity_page(site, id, directory, stat)
    type(site_t), intent(in) :: site            !! the site
    integer, intent(in) :: id                   !! the entity
    character(len=*), intent(in) :: directory   !! the output directory
    integer, intent(out) :: stat                !! nonzero on failure
    character(len=:), allocatable :: text, url, errmsg

    call entity_page(site, id, text)
    call entity_url(site%p%list, id, url)
    call write_whole_file(directory//'/'//url(:len(url) - 5)//'.md', text, stat, errmsg)
end subroutine write_entity_page

!> Render the pages of entities `ids` and write them, in parallel.
subroutine write_entity_pages(site, ids, directory, stat, errmsg)
    type(site_t), intent(in) :: site                    !! the site
    integer, intent(in) :: ids(:)                       !! the entities
    character(len=*), intent(in) :: directory           !! the output directory
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg !! what is wrong
    integer, allocatable :: results(:)
    integer :: k

    allocate (results(size(ids)))
    call progress_start('Rendering pages', size(ids))
    !$omp parallel do schedule(dynamic) num_threads(max(1, site%s%parallel)) default(shared) private(k)
    do k = 1, size(ids)
        call write_entity_page(site, ids(k), directory, results(k))
        call progress_tick()
    end do
    !$omp end parallel do
    call progress_finish()
    stat = 0
    do k = 1, size(ids)
        if (results(k) == 0) cycle
        stat = results(k)
        errmsg = 'could not write the page of '//site%p%list%box(ids(k))%e%name
        return
    end do
end subroutine write_entity_pages

!> Run formatter `command` on the Markdown files in `directory`, if there is one. The files are complete
!> without it, so a formatter that is missing or fails only gets a warning.
subroutine format_pages(command, directory)
    character(len=*), intent(in) :: command     !! the command, or empty for none
    character(len=*), intent(in) :: directory   !! the output directory
    integer :: stat
    character(len=16) :: status_text

    if (len_trim(command) == 0) return
    call run_command(command//' '//quoted_path(directory), stat)
    if (stat == 0) return
    write (status_text, '(i0)') stat
    call warn('the Markdown files are not formatted: "'//command//'" failed with status '//trim(status_text))
end subroutine format_pages

!> Write the documentation as Markdown files.
subroutine write_markdown_site(p, s, front, pages_in, count, stat, errmsg)
    type(project_t), intent(inout), target :: p         !! the project
    type(settings_t), intent(in), target :: s           !! the settings
    character(len=*), intent(in) :: front               !! the project file's text
    type(page_t), intent(in), target :: pages_in(:)     !! the static pages
    integer, intent(out) :: count                       !! how many pages were written
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg !! what is wrong
    type(site_t) :: site
    integer, allocatable :: ids(:)
    character(len=:), allocatable :: text, directory
    integer :: k

    call prepare_site(site, p, s, pages_in)
    allocate (ids(0))
    do k = 1, p%list%n
        if (has_page(site, k)) call push_int(ids, k)
    end do

    directory = s%output_dir
    call make_directory(directory, stat)
    do k = 1, size(DIRECTORIES)
        if (stat /= 0) exit
        call make_directory(directory//'/'//trim(DIRECTORIES(k)), stat)
    end do
    if (stat /= 0) then
        errmsg = 'could not create '//directory
        return
    end if
    call page_directories(directory, pages_in)

    call write_entity_pages(site, ids, directory, stat, errmsg)
    if (stat /= 0) return
    count = size(ids)

    do k = 1, NUM_LISTS
        if (size(site%members(k)%ids) == 0) cycle
        call list_page(site, k, text)
        call write_whole_file(directory//'/lists/'//trim(LIST_FILE(k))//'.md', text, stat, errmsg)
        if (stat /= 0) return
        count = count + 1
    end do
    do k = 1, size(pages_in)
        call static_page(site, k, text)
        call write_whole_file(directory//'/page/'//pages_in(k)%path(:len(pages_in(k)%path) - 5)//'.md', text, stat, errmsg)
        if (stat /= 0) return
        count = count + 1
    end do
    call index_page(site, front, text)
    call write_whole_file(directory//'/index.md', text, stat, errmsg)
    if (stat /= 0) return
    count = count + 1
    ! Before the project's own files arrive, as they are not the formatter's to change
    call format_pages(s%markdown_formatter, directory)
    call copy_project_files(s, directory, pages_in)
end subroutine write_markdown_site

end module fdoc_site_markdown
