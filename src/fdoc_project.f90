module fdoc_project
!! The whole project: loads and parses the files, merges them into one list of entities, and
!! connects the entities with each other.
use iso_fortran_env, only: error_unit
use fdoc_util
use fdoc_model
use fdoc_settings, only: settings_t
use fdoc_input, only: find_sources, load_source
use fdoc_parser, only: parse_file
implicit none
private

public :: load_project_sources, correlate, prune, public_symbols

type, public :: symbol_t
    !! An entity under the name it is known by in some scope.
    character(len=:), allocatable :: name   !! the name, in lowercase
    integer :: id = 0                       !! the entity
end type symbol_t

type :: rename_t
    !! A name in the `only` list of a `use` statement.
    character(len=:), allocatable :: used   !! the name in the used module, in lowercase
    character(len=:), allocatable :: local  !! the name in the using scope, in lowercase
end type rename_t

type :: symbols_t
    !! The names a module makes public, by category.
    type(symbol_t), allocatable :: procs(:)     !! procedures and interfaces
    type(symbol_t), allocatable :: absints(:)   !! abstract interfaces
    type(symbol_t), allocatable :: types(:)     !! derived types
    type(symbol_t), allocatable :: vars(:)      !! variables
    integer :: state = 0                        !! 0 not computed, 1 being computed, 2 computed
end type symbols_t

type, public :: project_t
    !! The parsed project.
    type(entity_list_t) :: list             !! all entities
    integer, allocatable :: files(:)        !! the file entities
    integer, allocatable :: modules(:)      !! the module entities
    type(symbols_t), allocatable :: pub(:)  !! the public names of each entity in `modules`
end type project_t

contains

!> The public names of module `which` in a category: 1 procedures, 2 abstract interfaces, 3 types,
!> 4 variables.
function public_symbols(p, which, category) result(symbols)
    type(project_t), intent(in) :: p    !! the project
    integer, intent(in) :: which        !! position in `p%modules`
    integer, intent(in) :: category     !! the category
    type(symbol_t), allocatable :: symbols(:)

    select case (category)
    case (1); symbols = p%pub(which)%procs
    case (2); symbols = p%pub(which)%absints
    case (3); symbols = p%pub(which)%types
    case default; symbols = p%pub(which)%vars
    end select
end function public_symbols

!> Find, load and parse the source files, and merge the results into `p`.
subroutine load_project_sources(s, p, stat, errmsg)
    type(settings_t), intent(in) :: s                   !! the settings
    type(project_t), intent(out) :: p                   !! the project
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    type(string_t), allocatable :: paths(:), texts(:)
    type(entity_list_t), allocatable :: lists(:)
    character(len=:), allocatable :: raw, msg
    integer :: k, ios

    stat = 0
    call find_sources(s, paths)
    if (size(paths) == 0) then
        stat = 1
        errmsg = 'No source files with appropriate extension found in specified directory.'
        return
    end if
    allocate (texts(size(paths)), lists(size(paths)))
    do k = 1, size(paths)
        call load_source(s, paths(k)%s, raw, texts(k)%s, ios, msg)
        if (ios /= 0) then
            write (error_unit, '(a)') 'Warning: could not read '//paths(k)%s//': '//msg
            texts(k)%s = ''
        end if
    end do

    !$omp parallel do schedule(dynamic) num_threads(max(1, s%parallel)) default(shared)
    do k = 1, size(paths)
        call parse_file(paths(k)%s, texts(k)%s, s, lists(k))
    end do
    !$omp end parallel do

    do k = 1, size(lists)
        call merge_list(p, lists(k))
    end do
end subroutine load_project_sources

!> Move the entities of `from` to the end of `p%list`, adjusting their indices.
subroutine merge_list(p, from)
    type(project_t), intent(inout) :: p         !! the project
    type(entity_list_t), intent(inout) :: from  !! the entities of a file
    type(entity_box_t), allocatable :: grown(:)
    integer :: offset, k, needed

    offset = p%list%n
    needed = offset + from%n
    if (.not. allocated(p%list%box)) allocate (p%list%box(max(needed, 64)))
    if (needed > size(p%list%box)) then
        allocate (grown(2*needed))
        do k = 1, offset
            call move_alloc(p%list%box(k)%e, grown(k)%e)
        end do
        call move_alloc(grown, p%list%box)
    end if
    do k = 1, from%n
        call move_alloc(from%box(k)%e, p%list%box(offset + k)%e)
        associate (e => p%list%box(offset + k)%e)
            if (e%parent > 0) e%parent = e%parent + offset
            e%file = e%file + offset
            e%children = e%children + offset
            if (e%result > 0) e%result = e%result + offset
            if (allocated(e%arg_ids)) e%arg_ids = e%arg_ids + offset
            if (e%kind == E_MODULE) call push_int(p%modules, offset + k)
            if (e%kind == E_FILE) call push_int(p%files, offset + k)
        end associate
    end do
    p%list%n = needed
end subroutine merge_list

!> Connect entities across files: `use` statements, and the public names of each module.
subroutine correlate(p)
    type(project_t), intent(inout) :: p     !! the project
    integer :: k, n

    if (.not. allocated(p%modules)) allocate (p%modules(0))
    allocate (p%pub(size(p%modules)))
    do k = 1, size(p%modules)
        call public_names(p, k)
    end do
    n = p%list%n
    do k = 1, n
        if (p%list%box(k)%e%kind /= E_TYPE) cycle
        call set_constructor(p, k)
        call inherit(p, k)
    end do
end subroutine correlate

!> The type that `name` means in scope `scope`, or 0.
recursive integer function find_type(p, scope, name) result(id)
    type(project_t), intent(in) :: p        !! the project
    integer, intent(in) :: scope            !! the entity to look in
    character(len=*), intent(in) :: name    !! the name, in lowercase
    type(rename_t), allocatable :: renames(:)
    character(len=:), allocatable :: remote
    logical :: only
    integer :: c, child, u, used, k, j

    id = 0
    associate (e => p%list%box(scope)%e)
        do c = 1, size(e%children)
            child = e%children(c)
            if (p%list%box(child)%e%kind /= E_TYPE) cycle
            if (lowercase(p%list%box(child)%e%name) == name) then
                id = child
                return
            end if
        end do
        if (allocated(e%uses)) then
            do u = 1, size(e%uses)
                used = find_module(p, e%uses(u)%module)
                if (used == 0) cycle
                call read_use_spec(e%uses(u)%spec, only, renames)
                remote = name
                if (only) then
                    remote = ''
                    do j = 1, size(renames)
                        if (renames(j)%local == name) remote = renames(j)%used
                    end do
                    if (len(remote) == 0) cycle
                end if
                do k = 1, size(p%pub(used)%types)
                    if (p%pub(used)%types(k)%name == remote) then
                        id = p%pub(used)%types(k)%id
                        return
                    end if
                end do
            end do
        end if
        if (e%kind == E_SUBMODULE) then
            used = find_module(p, e%ancestor)
            if (used > 0) id = find_type(p, p%modules(used), name)
            if (id > 0) return
        end if
        if (e%parent > 0) id = find_type(p, e%parent, name)
    end associate
end function find_type

!> Work out what type `id` inherits, after its parent type.
recursive subroutine inherit(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the type
    integer, allocatable :: parent_items(:)
    integer :: base, k, item, copy

    if (p%list%box(id)%e%inherit_state /= 0) return
    p%list%box(id)%e%inherit_state = 1
    allocate (p%list%box(id)%e%inherited(0))
    if (allocated(p%list%box(id)%e%extends)) then
        base = find_type(p, p%list%box(id)%e%parent, lowercase(p%list%box(id)%e%extends))
        if (base > 0 .and. base /= id) then
            p%list%box(id)%e%extends_id = base
            call inherit(p, base)
            parent_items = [p%list%box(base)%e%inherited, p%list%box(base)%e%children]
            do k = 1, size(parent_items)
                item = parent_items(k)
                associate (e => p%list%box(item)%e)
                    select case (e%kind)
                    case (E_VARIABLE)
                        if (e%permission == 'public') call push_int(p%list%box(id)%e%inherited, item)
                    case (E_BOUNDPROC)
                        if (e%permission == 'private') cycle
                        if (overrides(p, id, e%name)) cycle
                        if (e%generic) then
                            copy = copy_binding(p, item, id)
                        else
                            call push_int(p%list%box(id)%e%inherited, item)
                        end if
                    end select
                end associate
            end do
        end if
    end if
    p%list%box(id)%e%inherit_state = 2
end subroutine inherit

!> True if type `id` declares a binding named `name` itself.
logical function overrides(p, id, name)
    type(project_t), intent(in) :: p        !! the project
    integer, intent(in) :: id               !! the type
    character(len=*), intent(in) :: name    !! the binding
    integer :: c, child

    overrides = .false.
    do c = 1, size(p%list%box(id)%e%children)
        child = p%list%box(id)%e%children(c)
        if (p%list%box(child)%e%kind /= E_BOUNDPROC) cycle
        if (lowercase(p%list%box(child)%e%name) == lowercase(name)) then
            overrides = .true.
            return
        end if
    end do
end function overrides

!> Add to type `id` a copy of generic binding `item`, returning the copy.
integer function copy_binding(p, item, id) result(copy)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: item             !! the binding
    integer, intent(in) :: id               !! the type
    integer :: file

    copy = p%list%add(E_BOUNDPROC, id)
    file = p%list%box(copy)%e%file
    p%list%box(copy)%e = p%list%box(item)%e
    p%list%box(copy)%e%parent = id
    p%list%box(copy)%e%file = file
end function copy_binding

!> Give a procedure or interface named like type `id`, its constructor, the type's permission.
subroutine set_constructor(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the type
    integer :: c, child, parent

    parent = p%list%box(id)%e%parent
    do c = 1, size(p%list%box(parent)%e%children)
        child = p%list%box(parent)%e%children(c)
        associate (e => p%list%box(child)%e)
            select case (e%kind)
            case (E_INTERFACE, E_SUBROUTINE, E_FUNCTION)
                if (lowercase(e%name) == lowercase(p%list%box(id)%e%name)) e%permission = p%list%box(id)%e%permission
            end select
        end associate
    end do
end subroutine set_constructor

!> Add `name` for entity `id` to `list`, replacing any entity it has.
subroutine add_symbol(list, name, id)
    type(symbol_t), allocatable, intent(inout) :: list(:)   !! the names
    character(len=*), intent(in) :: name                    !! the name
    integer, intent(in) :: id                               !! the entity
    integer :: k

    do k = 1, size(list)
        if (list(k)%name == name) then
            list(k)%id = id
            return
        end if
    end do
    list = [list, symbol_t(name, id)]
end subroutine add_symbol

!> The position in `p%modules` of the module named `name`, or 0.
integer function find_module(p, name)
    type(project_t), intent(in) :: p        !! the project
    character(len=*), intent(in) :: name    !! the name, in lowercase
    integer :: k

    find_module = 0
    do k = 1, size(p%modules)
        if (lowercase(p%list%box(p%modules(k))%e%name) == name) then
            find_module = k
            return
        end if
    end do
end function find_module

!> Compute the public names of module `which`, after those of the modules it uses.
recursive subroutine public_names(p, which)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: which            !! position in `p%modules`
    integer :: id, c, child, u, used

    if (p%pub(which)%state /= 0) return
    p%pub(which)%state = 1
    id = p%modules(which)
    allocate (p%pub(which)%procs(0), p%pub(which)%absints(0), p%pub(which)%types(0), p%pub(which)%vars(0))

    associate (m => p%list%box(id)%e)
        do c = 1, size(m%children)
            child = m%children(c)
            associate (e => p%list%box(child)%e)
                if (.not. allocated(e%permission)) cycle
                if (e%permission /= 'public' .and. e%permission /= 'protected') cycle
                select case (e%kind)
                case (E_TYPE)
                    call add_symbol(p%pub(which)%types, lowercase(e%name), child)
                case (E_VARIABLE)
                    if (e%var_role == VAR_HIDDEN) cycle
                    call add_symbol(p%pub(which)%vars, lowercase(e%name), child)
                    if (e%vartype == 'procedure') call add_symbol(p%pub(which)%procs, lowercase(e%name), child)
                case (E_SUBROUTINE, E_FUNCTION)
                    if (e%iface == IFACE_ABSTRACT) then
                        call add_symbol(p%pub(which)%absints, lowercase(e%name), child)
                    else
                        call add_symbol(p%pub(which)%procs, lowercase(e%name), child)
                    end if
                case (E_INTERFACE)
                    call add_symbol(p%pub(which)%procs, lowercase(e%name), child)
                end select
            end associate
        end do
    end associate
    call generic_bodies(p, which, id)

    do u = 1, size(p%list%box(id)%e%uses)
        used = find_module(p, p%list%box(id)%e%uses(u)%module)
        if (used == 0) cycle
        if (p%pub(used)%state == 1) cycle
        call public_names(p, used)
        call import_names(p, which, used, p%list%box(id)%e%uses(u)%spec)
    end do
    p%pub(which)%state = 2
end subroutine public_names

!> Add the public bodies of the generic interfaces of module `id`.
subroutine generic_bodies(p, which, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: which            !! position in `p%modules`
    integer, intent(in) :: id               !! the module
    integer :: c, b, child, body

    do c = 1, size(p%list%box(id)%e%children)
        child = p%list%box(id)%e%children(c)
        if (p%list%box(child)%e%kind /= E_INTERFACE) cycle
        do b = 1, size(p%list%box(child)%e%children)
            body = p%list%box(child)%e%children(b)
            associate (e => p%list%box(body)%e)
                if (e%kind /= E_SUBROUTINE .and. e%kind /= E_FUNCTION) cycle
                if (e%permission == 'public' .or. e%permission == 'protected') then
                    call add_symbol(p%pub(which)%procs, lowercase(e%name), body)
                end if
            end associate
        end do
    end do
end subroutine generic_bodies

!> Add to module `which` what it makes public of what `use` with `spec` imports from module `used`.
subroutine import_names(p, which, used, spec)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: which            !! position in `p%modules` of the importing module
    integer, intent(in) :: used             !! position in `p%modules` of the used module
    character(len=*), intent(in) :: spec    !! what follows the module name
    type(rename_t), allocatable :: renames(:)
    logical :: only

    call read_use_spec(spec, only, renames)
    call import_category(p%pub(used)%procs, p%pub(which)%procs)
    call import_category(p%pub(used)%absints, p%pub(which)%absints)
    call import_category(p%pub(used)%types, p%pub(which)%types)
    call import_category(p%pub(used)%vars, p%pub(which)%vars)

contains

    !> Import the names of one category.
    subroutine import_category(from, to)
        type(symbol_t), intent(in) :: from(:)               !! the used module's names
        type(symbol_t), allocatable, intent(inout) :: to(:) !! the importing module's names
        character(len=:), allocatable :: local
        integer :: k, j

        do k = 1, size(from)
            local = from(k)%name
            if (only) then
                local = ''
                do j = 1, size(renames)
                    if (renames(j)%used == from(k)%name) then
                        local = renames(j)%local
                        exit
                    end if
                end do
                if (len(local) == 0) cycle
            end if
            if (is_public_here(local)) call add_symbol(to, local, from(k)%id)
        end do
    end subroutine import_category

    !> True if the importing module makes `name` public.
    logical function is_public_here(name)
        character(len=*), intent(in) :: name    !! the name
        associate (m => p%list%box(p%modules(which))%e)
            is_public_here = m%permission == 'public' .or. contains_string(m%public_list, name)
        end associate
    end function is_public_here

end subroutine import_names

!> Read what follows the module name in a `use` statement.
subroutine read_use_spec(spec, only, renames)
    character(len=*), intent(in) :: spec                    !! the text
    logical, intent(out) :: only                            !! true for an `only` list
    type(rename_t), allocatable, intent(out) :: renames(:)  !! the names used
    character(len=:), allocatable :: text
    type(string_t), allocatable :: items(:)
    integer :: k, at

    allocate (renames(0))
    text = strip(lowercase(spec))
    only = starts_with(text, 'only')
    if (.not. only) return
    at = index(text, ':')
    text = text(at + 1:)
    items = top_split(text, ',')
    do k = 1, size(items)
        at = index(items(k)%s, '=>')
        if (at > 0) then
            renames = [renames, rename_t(strip(items(k)%s(at + 2:)), strip(items(k)%s(:at - 1)))]
        else
            renames = [renames, rename_t(items(k)%s, items(k)%s)]
        end if
    end do
end subroutine read_use_spec

!> Hide what should not be displayed.
subroutine prune(p, s)
    type(project_t), intent(inout) :: p     !! the project
    type(settings_t), intent(in) :: s       !! the settings
    integer :: k

    do k = 1, p%list%n
        associate (e => p%list%box(k)%e)
            if (e%kind == E_NONE .or. e%parent == 0) cycle
            if (.not. allocated(e%permission)) cycle
            associate (parent => p%list%box(e%parent)%e)
                if (e%kind == E_VARIABLE .and. e%var_role /= VAR_PLAIN) cycle
                if (allocated(parent%display)) then
                    if (.not. contains_string(parent%display, e%permission)) e%visible = .false.
                end if
                if (s%hide_undoc .and. size(e%doc) == 0) e%visible = .false.
                if ((parent%kind == E_SUBROUTINE .or. parent%kind == E_FUNCTION) .and. .not. parent%internals) then
                    e%visible = .false.
                end if
            end associate
        end associate
    end do
end subroutine prune

end module fdoc_project
