module fdoc_output
!! Writing the documentation.
use json_module, only: json_core, json_value
use ffmt_io, only: write_file
use ffmt_fs, only: join_path
use fdoc_util
use fdoc_model
use fdoc_settings, only: settings_t
use fdoc_project, only: project_t, public_symbols, symbol_t
use fdoc_urls, only: entity_url, object_word
implicit none
private

public :: write_modules

contains

!> Write `modules.json`, which other projects can use to link to this one.
subroutine write_modules(p, s, stat, errmsg)
    type(project_t), intent(in) :: p                    !! the project
    type(settings_t), intent(in) :: s                   !! the settings
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    type(json_core) :: json
    type(json_value), pointer :: root, meta, modules, item
    character(len=:), allocatable :: text
    integer :: k

    call json%initialize(no_whitespace=.true.)
    call json%create_object(root, '')
    call json%create_object(meta, 'ford-metadata')
    call json%add(root, meta)
    call json%add(meta, 'version', 'fdoc')
    call json%create_array(modules, 'modules')
    call json%add(root, modules)
    do k = 1, size(p%modules)
        if (allocated(p%list%box(p%modules(k))%e%external_url)) cycle
        call entity_json(json, p, p%modules(k), '', k, item)
        call json%add(modules, item)
    end do
    call json%serialize(root, text)
    call json%destroy(root)
    call execute_command_line("mkdir -p '"//s%output_dir//"'", exitstat=stat)
    call write_file(join_path(s%output_dir, 'modules.json'), text, stat, errmsg)
end subroutine write_modules

!> The JSON form of entity `id`, for `modules.json`.
recursive subroutine entity_json(json, p, id, key, module_index, node)
    type(json_core), intent(inout) :: json          !! the JSON handler
    type(project_t), intent(in) :: p                !! the project
    integer, intent(in) :: id                       !! the entity
    character(len=*), intent(in) :: key             !! its key in the parent's JSON
    integer, intent(in) :: module_index             !! position in `p%modules`, or 0 if not a module
    type(json_value), pointer, intent(out) :: node  !! the result
    character(len=:), allocatable :: word, url
    type(json_value), pointer :: array
    integer :: k

    call json%create_object(node, key)
    associate (e => p%list%box(id)%e)
        call object_word(e, word)
        call entity_url(p%list, id, url)
        call json%add(node, 'name', e%name)
        call json%add(node, 'external_url', './'//url)
        call json%add(node, 'obj', word)
        select case (e%kind)
        case (E_SUBROUTINE, E_FUNCTION, E_MODPROC)
            if (e%iface /= IFACE_NONE) then
                call json%add(node, 'proctype', 'Interface')
                call json%add(node, 'generic', 'False')
                call empty_array('variables')
            else
                call json%add(node, 'proctype', trim(merge('Function  ', 'Subroutine', e%kind == E_FUNCTION)))
                call children('functions', [E_FUNCTION], .false.)
                call children('subroutines', [E_SUBROUTINE], .false.)
                call children_iface('interfaces', .false.)
                call children_iface('absinterfaces', .true.)
                call children('types', [E_TYPE], .false.)
                call children('variables', [E_VARIABLE], .false.)
                call strings('attribs', e%attribs)
            end if
        case (E_MODULE, E_SUBMODULE)
            if (module_index > 0) call public_dicts(module_index)
            call children('functions', [E_FUNCTION], .false.)
            call children('subroutines', [E_SUBROUTINE], .false.)
            call children_iface('interfaces', .false.)
            call children_iface('absinterfaces', .true.)
            call children('types', [E_TYPE], .false.)
            call children('variables', [E_VARIABLE], .false.)
        case (E_INTERFACE)
            call json%add(node, 'proctype', 'Interface')
            call json%add(node, 'generic', 'True')
            call children('functions', [E_FUNCTION], .true.)
            call children('subroutines', [E_SUBROUTINE], .true.)
            call empty_array('variables')
        case (E_TYPE)
            call strings('attribs', e%attribs)
            call children('variables', [E_VARIABLE], .false.)
            call children('boundprocs', [E_BOUNDPROC], .false.)
        case (E_BOUNDPROC)
            call strings('attribs', e%attribs)
            call json%add(node, 'deferred', trim(merge('True ', 'False', e%deferred)))
            call json%add(node, 'generic', trim(merge('True ', 'False', e%generic)))
        case (E_VARIABLE)
            call strings('attribs', e%attribs)
            call json%add(node, 'vartype', e%vartype)
        end select
        call json%add(node, 'permission', e%permission)
    end associate

contains

    !> Add an empty array.
    subroutine empty_array(name)
        character(len=*), intent(in) :: name    !! its key
        call json%create_array(array, name)
        call json%add(node, array)
    end subroutine empty_array

    !> Add an array of strings.
    subroutine strings(name, list)
        character(len=*), intent(in) :: name    !! its key
        type(string_t), intent(in) :: list(:)   !! the strings
        integer :: j
        type(json_value), pointer :: a
        call json%create_array(a, name)
        call json%add(node, a)
        do j = 1, size(list)
            call json%add(a, '', list(j)%s)
        end do
    end subroutine strings

    !> Add an array of the visible children of the kinds given.
    recursive subroutine children(name, kinds, all)
        character(len=*), intent(in) :: name    !! its key
        integer, intent(in) :: kinds(:)         !! the `E_*` constants
        logical, intent(in) :: all              !! true to include those of interfaces
        type(json_value), pointer :: a, item
        integer :: j, child
        call json%create_array(a, name)
        call json%add(node, a)
        do j = 1, size(p%list%box(id)%e%children)
            child = p%list%box(id)%e%children(j)
            associate (c => p%list%box(child)%e)
                if (.not. any(c%kind == kinds)) cycle
                if (.not. c%visible) cycle
                if (c%kind == E_VARIABLE .and. c%var_role /= VAR_PLAIN) cycle
                if (c%iface /= IFACE_NONE .and. .not. all) cycle
                call entity_json(json, p, child, '', 0, item)
                call json%add(a, item)
            end associate
        end do
        if (.not. allocated(p%list%box(id)%e%inherited)) return
        do j = 1, size(p%list%box(id)%e%inherited)
            child = p%list%box(id)%e%inherited(j)
            if (.not. any(p%list%box(child)%e%kind == kinds)) cycle
            if (.not. contains_string(p%list%box(id)%e%display, p%list%box(child)%e%permission)) cycle
            call entity_json(json, p, child, '', 0, item)
            call json%add(a, item)
        end do
    end subroutine children

    !> Add an array of the visible interfaces.
    recursive subroutine children_iface(name, abstract)
        character(len=*), intent(in) :: name    !! its key
        logical, intent(in) :: abstract         !! true for abstract interfaces
        type(json_value), pointer :: a, item
        integer :: j, child
        logical :: wanted
        call json%create_array(a, name)
        call json%add(node, a)
        do j = 1, size(p%list%box(id)%e%children)
            child = p%list%box(id)%e%children(j)
            associate (c => p%list%box(child)%e)
                if (.not. c%visible) cycle
                wanted = (abstract .and. c%iface == IFACE_ABSTRACT) .or. &
                         (.not. abstract .and. (c%iface == IFACE_EXPLICIT .or. c%kind == E_INTERFACE))
                if (.not. wanted) cycle
                call entity_json(json, p, child, '', 0, item)
                call json%add(a, item)
            end associate
        end do
    end subroutine children_iface

    !> Add the public names of the module.
    recursive subroutine public_dicts(which)
        integer, intent(in) :: which    !! position in `p%modules`
        call dict('pub_procs', public_symbols(p, which, 1))
        call dict('pub_absints', public_symbols(p, which, 2))
        call dict('pub_types', public_symbols(p, which, 3))
        call dict('pub_vars', public_symbols(p, which, 4))
    end subroutine public_dicts

    !> Add an object of `symbols`.
    recursive subroutine dict(name, symbols)
        character(len=*), intent(in) :: name        !! its key
        type(symbol_t), intent(in) :: symbols(:)    !! the names
        type(json_value), pointer :: object, item
        integer :: j
        call json%create_object(object, name)
        call json%add(node, object)
        do j = 1, size(symbols)
            if (allocated(p%list%box(symbols(j)%id)%e%external_url)) cycle
            call entity_json(json, p, symbols(j)%id, symbols(j)%name, 0, item)
            call json%add(object, item)
        end do
    end subroutine dict

end subroutine entity_json

end module fdoc_output
