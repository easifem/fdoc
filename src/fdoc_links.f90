module fdoc_links
!! Connecting names to entities: bindings, interfaces, implementations and procedure calls.
use json_module, only: json_core, json_value
use fdoc_util
use fdoc_model
use fdoc_project, only: project_t, find_symbol
implicit none
private

public :: link_project, dump_links

contains

!> Connect what the names in the project refer to.
subroutine link_project(p)
    type(project_t), intent(inout) :: p     !! the project
    integer :: k, n

    n = p%list%n
    do k = 1, n
        if (allocated(p%list%box(k)%e%external_url)) cycle
        select case (p%list%box(k)%e%kind)
        case (E_SUBROUTINE, E_FUNCTION, E_MODPROC)
            call link_implementation(p, k)
            call link_calls(p, k)
        case (E_PROGRAM)
            call link_calls(p, k)
        case (E_SUBMODULE)
            call link_submodule(p, k)
        case (E_INTERFACE)
            call link_module_procedures(p, k)
        case (E_BOUNDPROC)
            call link_binding(p, k)
        case (E_TYPE)
            call link_constructor(p, k)
        case (E_FINAL)
            p%list%box(k)%e%proto_id = find_symbol(p, k, lowercase(p%list%box(k)%e%name), 1)
        case (E_VARIABLE)
            call link_variable(p, k)
        end select
    end do
end subroutine link_project

!> Add submodule `id` to the descendants of its parent.
subroutine link_submodule(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the submodule
    integer :: parent

    parent = p%list%box(id)%e%parent_submodule_id
    if (parent == 0) parent = p%list%box(id)%e%ancestor_id
    if (parent > 0) call push_int(p%list%box(parent)%e%descendants, id)
end subroutine link_submodule

!> Connect a separate module procedure with its interface, and copy what it does not repeat.
subroutine link_implementation(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the procedure
    integer :: found, parent

    if (p%list%box(id)%e%kind /= E_MODPROC .and. .not. p%list%box(id)%e%is_module) return
    if (p%list%box(id)%e%iface /= IFACE_NONE) return
    parent = p%list%box(id)%e%parent
    found = find_symbol(p, parent, lowercase(p%list%box(id)%e%name), 1)
    if (found == id .or. found == 0) then
        found = 0
        if (p%list%box(parent)%e%parent_submodule_id > 0) then
            found = find_symbol(p, p%list%box(parent)%e%parent_submodule_id, lowercase(p%list%box(id)%e%name), 1)
        else if (p%list%box(parent)%e%ancestor_id > 0) then
            found = find_symbol(p, p%list%box(parent)%e%ancestor_id, lowercase(p%list%box(id)%e%name), 1)
        end if
    end if
    if (found == 0 .or. found == id) return
    p%list%box(id)%e%implements = found
    p%list%box(found)%e%implements = id
    if (p%list%box(id)%e%kind /= E_MODPROC) return
    associate (e => p%list%box(id)%e, base => p%list%box(found)%e)
        if (allocated(base%attribs)) e%attribs = base%attribs
        if (allocated(base%args)) e%args = base%args
        if (allocated(base%arg_ids)) e%arg_ids = base%arg_ids
        e%result = base%result
    end associate
end subroutine link_implementation

!> Find what a generic interface lists with `module procedure`.
subroutine link_module_procedures(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the interface
    integer :: k, found

    allocate (p%list%box(id)%e%modproc_ids(size(p%list%box(id)%e%modprocs)))
    do k = 1, size(p%list%box(id)%e%modprocs)
        found = find_symbol(p, p%list%box(id)%e%parent, lowercase(p%list%box(id)%e%modprocs(k)%s), 1)
        p%list%box(id)%e%modproc_ids(k) = found
    end do
end subroutine link_module_procedures

!> Find what a type-bound procedure binds to and its interface.
subroutine link_binding(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the binding
    integer :: parent, k, found

    parent = p%list%box(id)%e%parent
    associate (b => p%list%box(id)%e)
        allocate (b%binding_ids(size(b%bindings)))
        b%binding_ids = 0
        if (allocated(b%proto_text)) then
            b%proto_id = find_symbol(p, parent, lowercase(b%proto_text), 1)
            if (b%proto_id == 0) b%proto_id = find_symbol(p, parent, lowercase(b%proto_text), 2)
        end if
        do k = 1, size(b%bindings)
            if (b%generic) then
                found = type_binding(p, parent, lowercase(b%bindings(k)%s))
            else if (b%deferred) then
                found = 0
            else
                found = find_symbol(p, parent, lowercase(b%bindings(k)%s), 1)
                if (found > 0) p%list%box(found)%e%bound_to = parent
            end if
            b%binding_ids(k) = found
        end do
    end associate
end subroutine link_binding

!> The binding named `name` of type `id`, including inherited ones, or 0.
integer function type_binding(p, id, name) result(found)
    type(project_t), intent(in) :: p        !! the project
    integer, intent(in) :: id               !! the type
    character(len=*), intent(in) :: name    !! the name, in lowercase

    found = type_member(p, id, name, E_BOUNDPROC)
end function type_binding

!> The component of kind `kind` named `name` of type `id`, including inherited ones, or 0.
integer function type_member(p, id, name, kind) result(found)
    type(project_t), intent(in) :: p        !! the project
    integer, intent(in) :: id               !! the type
    character(len=*), intent(in) :: name    !! the name, in lowercase
    integer, intent(in) :: kind             !! one of the `E_*` constants
    integer :: k

    found = 0
    associate (e => p%list%box(id)%e)
        ! a generic binding can be declared in several statements: the last counts
        do k = size(e%children), 1, -1
            if (p%list%box(e%children(k))%e%kind /= kind) cycle
            if (lowercase(p%list%box(e%children(k))%e%name) == name) then
                found = e%children(k)
                return
            end if
        end do
        if (.not. allocated(e%inherited)) return
        do k = 1, size(e%inherited)
            if (p%list%box(e%inherited(k))%e%kind /= kind) cycle
            if (lowercase(p%list%box(e%inherited(k))%e%name) == name) then
                found = e%inherited(k)
                return
            end if
        end do
    end associate
end function type_member

!> Find the procedure or interface named like type `id`.
subroutine link_constructor(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the type

    p%list%box(id)%e%constructor = find_symbol(p, p%list%box(id)%e%parent, lowercase(p%list%box(id)%e%name), 1)
end subroutine link_constructor

!> Find the type or interface that a variable declaration names.
subroutine link_variable(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the variable
    character(len=:), allocatable :: name

    associate (v => p%list%box(id)%e)
        if (.not. allocated(v%proto)) return
        name = lowercase(v%proto(1)%s)
        if (name == '*') return
        if (v%vartype == 'procedure') then
            v%proto_id = find_symbol(p, v%parent, name, 1)
            if (v%proto_id == 0) v%proto_id = find_symbol(p, v%parent, name, 2)
        else
            v%proto_id = find_symbol(p, v%parent, name, 3)
        end if
    end associate
end subroutine link_variable

!> Find what the calls of entity `id` refer to.
subroutine link_calls(p, id)
    type(project_t), intent(inout) :: p     !! the project
    integer, intent(in) :: id               !! the procedure or program
    type(string_t), allocatable :: parts(:)
    integer :: k, item, context, j

    allocate (p%list%box(id)%e%call_ids(0), p%list%box(id)%e%unknown_calls(0))
    if (.not. allocated(p%list%box(id)%e%calls)) return
    do k = 1, size(p%list%box(id)%e%calls)
        parts = split_on(p%list%box(id)%e%calls(k)%s, '%')
        context = id
        do j = 1, size(parts) - 1
            context = context_of(p, label_item(p, context, parts(j)%s))
            if (context == 0) exit
        end do
        item = 0
        if (context > 0) item = label_item(p, context, parts(size(parts))%s)
        if (item == 0) then
            call push(p%list%box(id)%e%unknown_calls, parts(size(parts))%s)
        else if (p%list%box(item)%e%kind /= E_VARIABLE .and. p%list%box(item)%e%kind /= E_TYPE) then
            call push_int(p%list%box(id)%e%call_ids, item)
        end if
    end do
end subroutine link_calls

!> The entity that `label` means in `context`, a scope or a type, or 0.
integer function label_item(p, context, label) result(item)
    type(project_t), intent(in) :: p        !! the project
    integer, intent(in) :: context          !! the scope or type
    character(len=*), intent(in) :: label   !! the name, in lowercase
    integer :: base, k

    item = 0
    if (p%list%box(context)%e%kind == E_TYPE) then
        item = type_member(p, context, label, E_VARIABLE)
        if (item > 0) return
    end if
    ! the arguments of a separate module procedure are those of its interface
    associate (e => p%list%box(context)%e)
        if (allocated(e%arg_ids)) then
            do k = 1, size(e%arg_ids)
                if (lowercase(p%list%box(e%arg_ids(k))%e%name) == label) then
                    item = e%arg_ids(k)
                    return
                end if
            end do
        end if
        if (e%result > 0) then
            if (lowercase(p%list%box(e%result)%e%name) == label) then
                item = e%result
                return
            end if
        end if
    end associate
    item = find_symbol(p, context, label, 4)
    if (item > 0) return
    if (p%list%box(context)%e%kind == E_TYPE) then
        base = p%list%box(context)%e%extends_id
        do while (base > 0)
            if (lowercase(p%list%box(base)%e%name) == label) then
                item = base
                return
            end if
            base = p%list%box(base)%e%extends_id
        end do
    end if
    item = find_symbol(p, context, label, 3)
    if (item > 0) return
    if (p%list%box(context)%e%kind == E_TYPE) then
        item = type_binding(p, context, label)
        if (item > 0) return
    end if
    item = find_symbol(p, context, label, 1)
end function label_item

!> The type whose members a reference through `item` reaches, or 0.
integer function context_of(p, item) result(context)
    type(project_t), intent(in) :: p    !! the project
    integer, intent(in) :: item         !! the entity, or 0
    integer :: var

    context = 0
    if (item == 0) return
    select case (p%list%box(item)%e%kind)
    case (E_FUNCTION)
        var = p%list%box(item)%e%result
        if (var > 0) context = variable_type(p, var)
    case (E_TYPE)
        context = item
    case (E_VARIABLE)
        context = variable_type(p, item)
    end select
end function context_of

!> The derived type of variable `id`, or 0.
integer function variable_type(p, id) result(found)
    type(project_t), intent(in) :: p    !! the project
    integer, intent(in) :: id           !! the variable

    found = 0
    associate (v => p%list%box(id)%e)
        if (.not. allocated(v%proto)) return
        if (v%vartype /= 'type' .and. v%vartype /= 'class') return
        found = find_symbol(p, v%parent, lowercase(v%proto(1)%s), 3)
    end associate
end function variable_type

!> How entities are connected, as JSON, for comparison with FORD.
function dump_links(p) result(text)
    type(project_t), intent(in) :: p    !! the project
    character(len=:), allocatable :: text
    type(json_core) :: json
    type(json_value), pointer :: root, node
    integer :: k

    call json%initialize()
    call json%create_object(root, '')
    do k = 1, p%list%n
        associate (e => p%list%box(k)%e)
            select case (e%kind)
            case (E_MODULE, E_SUBMODULE, E_PROGRAM, E_SUBROUTINE, E_FUNCTION, E_MODPROC, E_INTERFACE, E_BOUNDPROC, E_TYPE)
                if (allocated(e%external_url) .or. .not. allocated(e%name)) cycle
                if (e%kind == E_BOUNDPROC .and. .not. allocated(e%binding_ids)) cycle
                if (e%kind == E_TYPE) then
                    call json%create_object(node, qualified_name(p, k)//'#type')
                else
                    call json%create_object(node, qualified_name(p, k))
                end if
                call json%add(root, node)
                call add_links(json, node, p, k)
            end select
        end associate
    end do
    call json%serialize(root, text)
    call json%destroy(root)
end function dump_links

!> The name of entity `id` with those around it, up to its top-level unit.
recursive function qualified_name(p, id) result(name)
    type(project_t), intent(in) :: p    !! the project
    integer, intent(in) :: id           !! the entity
    character(len=:), allocatable :: name

    name = lowercase(p%list%box(id)%e%name)
    if (p%list%box(id)%e%parent == 0) return
    if (p%list%box(p%list%box(id)%e%parent)%e%kind == E_FILE) return
    name = qualified_name(p, p%list%box(id)%e%parent)//'/'//name
end function qualified_name

!> Add the links of entity `id` to `node`.
subroutine add_links(json, node, p, id)
    type(json_core), intent(inout) :: json          !! the JSON handler
    type(json_value), pointer, intent(in) :: node   !! the object
    type(project_t), intent(in) :: p                !! the project
    integer, intent(in) :: id                       !! the entity
    type(string_t), allocatable :: names(:)
    integer :: k

    associate (e => p%list%box(id)%e)
        allocate (names(0))
        if (allocated(e%uses) .and. e%kind /= E_BOUNDPROC) then
            do k = 1, size(e%uses)
                call push(names, e%uses(k)%module)
            end do
            call add_list('uses', names)
        end if
        if (allocated(e%call_ids)) then
            names = [string_t ::]
            do k = 1, size(e%call_ids)
                call push(names, lowercase(p%list%box(e%call_ids(k))%e%name))
            end do
            if (allocated(e%unknown_calls)) then
                do k = 1, size(e%unknown_calls)
                    call push(names, e%unknown_calls(k)%s)
                end do
            end if
            call add_list('calls', names)
        end if
        if (allocated(e%binding_ids)) call add_ids('bindings', e%binding_ids, e%bindings)
        if (allocated(e%modproc_ids)) call add_ids('modprocs', e%modproc_ids, e%modprocs)
        if (e%kind == E_SUBMODULE) then
            if (e%ancestor_id > 0) call json%add(node, 'ancestor', lowercase(p%list%box(e%ancestor_id)%e%name))
        end if
        if (e%kind == E_TYPE .and. e%extends_id > 0) then
            call json%add(node, 'extends', lowercase(p%list%box(e%extends_id)%e%name))
        end if
    end associate

contains

    !> Add sorted `list` under `key`.
    subroutine add_list(key, list)
        character(len=*), intent(in) :: key                 !! the key
        type(string_t), allocatable, intent(inout) :: list(:)   !! the strings
        type(json_value), pointer :: array
        integer :: j

        call sort_strings(list)
        call json%create_array(array, key)
        call json%add(node, array)
        do j = 1, size(list)
            call json%add(array, '', list(j)%s)
        end do
    end subroutine add_list

    !> Add the names of `ids`, or of `fallback` where an id is 0, under `key`.
    subroutine add_ids(key, ids, fallback)
        character(len=*), intent(in) :: key         !! the key
        integer, intent(in) :: ids(:)               !! the entities
        type(string_t), intent(in) :: fallback(:)   !! the names as written
        type(string_t), allocatable :: list(:)
        integer :: j

        allocate (list(0))
        do j = 1, size(ids)
            if (ids(j) > 0) then
                call push(list, lowercase(p%list%box(ids(j))%e%name))
            else
                call push(list, lowercase(fallback(j)%s))
            end if
        end do
        call add_list(key, list)
    end subroutine add_ids

end subroutine add_links

end module fdoc_links
