module fdoc_output
!! Writing the documentation.
use json_module, only: json_core, json_value
use ffmt_io, only: write_file
use ffmt_fs, only: join_path
use fdoc_util
use fdoc_model
use fdoc_settings, only: settings_t
use fdoc_project, only: project_t, public_symbols, symbol_t
implicit none
private

public :: write_modules, entity_url

contains

!> `name` as used in file names and anchors.
function page_name(name) result(out)
    character(len=*), intent(in) :: name    !! the name
    character(len=:), allocatable :: out
    integer :: k

    out = ''
    do k = 1, len(name)
        select case (name(k:k))
        case ('<'); out = out//'lt'
        case ('>'); out = out//'gt'
        case ('/'); out = out//'SLASH'
        case ('*'); out = out//'ASTERISK'
        case ('A':'Z'); out = out//achar(iachar(name(k:k)) + 32)
        case default; out = out//name(k:k)
        end select
    end do
    if (len(out) == 0) out = '__unnamed__'
end function page_name

!> `text` with characters that are not safe in a URL percent-encoded.
function url_quote(text) result(out)
    character(len=*), intent(in) :: text    !! the text
    character(len=:), allocatable :: out
    character(len=*), parameter :: HEX = '0123456789ABCDEF'
    character(len=*), parameter :: SAFE = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-~/'
    integer :: k, c

    out = ''
    do k = 1, len(text)
        if (index(SAFE, text(k:k)) > 0) then
            out = out//text(k:k)
        else
            c = iand(ichar(text(k:k)), 255)
            out = out//'%'//HEX(c/16 + 1:c/16 + 1)//HEX(mod(c, 16) + 1:mod(c, 16) + 1)
        end if
    end do
end function url_quote

!> The word FORD uses for the kind of entity `id`.
function object_word(e) result(word)
    type(entity_t), intent(in) :: e     !! the entity
    character(len=:), allocatable :: word

    select case (e%kind)
    case (E_FILE); word = 'sourcefile'
    case (E_MODULE); word = 'module'
    case (E_SUBMODULE); word = 'submodule'
    case (E_PROGRAM); word = 'program'
    case (E_BLOCKDATA); word = 'blockdata'
    case (E_SUBROUTINE, E_FUNCTION, E_MODPROC); word = 'proc'
    case (E_INTERFACE); word = 'interface'
    case (E_TYPE); word = 'type'
    case (E_ENUM); word = 'enum'
    case (E_BOUNDPROC); word = 'boundprocedure'
    case (E_FINAL); word = 'finalproc'
    case (E_VARIABLE); word = 'variable'
    case (E_NAMELIST); word = 'namelist'
    case (E_COMMON); word = 'common'
    case default; word = ''
    end select
    if ((e%kind == E_SUBROUTINE .or. e%kind == E_FUNCTION) .and. e%iface /= IFACE_NONE) word = 'interface'
end function object_word

!> The URL of an entity relative to the base URL, or `''`.
recursive function entity_url(list, id) result(url)
    type(entity_list_t), intent(in) :: list !! the entities
    integer, intent(in) :: id               !! the entity
    character(len=:), allocatable :: url
    integer :: at
    logical :: has_page

    associate (e => list%box(id)%e)
        has_page = .false.
        select case (e%kind)
        case (E_FILE, E_MODULE, E_SUBMODULE, E_PROGRAM, E_BLOCKDATA, E_NAMELIST)
            has_page = .true.
        case (E_TYPE, E_INTERFACE, E_SUBROUTINE, E_FUNCTION, E_MODPROC)
            has_page = e%iface /= IFACE_NONE
            if (e%parent > 0) then
                select case (list%box(e%parent)%e%kind)
                case (E_FILE, E_MODULE, E_SUBMODULE, E_PROGRAM, E_BLOCKDATA)
                    has_page = .true.
                end select
            end if
        end select
        if (has_page) then
            url = merge('module   ', 'XXXXXXXXX', e%kind == E_SUBMODULE)
            if (e%kind == E_SUBMODULE) then
                url = 'module'
            else
                url = object_word(e)
            end if
            url = url//'/'//page_name(e%name)//'.html'
            return
        end if
        url = ''
        if (e%parent == 0) return
        select case (e%kind)
        case (E_BOUNDPROC, E_COMMON, E_VARIABLE, E_ENUM, E_FINAL, E_SUBROUTINE, E_FUNCTION)
            url = entity_url(list, e%parent)
            if (len(url) == 0) return
            at = index(url, '#')
            if (at > 0) url = url(:at - 1)
            url = url//'#'//object_word(e)//'-'//url_quote(page_name(e%name))
        end select
    end associate
end function entity_url

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
    character(len=:), allocatable :: word
    type(json_value), pointer :: array
    integer :: k

    call json%create_object(node, key)
    associate (e => p%list%box(id)%e)
        word = object_word(e)
        call json%add(node, 'name', e%name)
        call json%add(node, 'external_url', './'//entity_url(p%list, id))
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
            call entity_json(json, p, symbols(j)%id, symbols(j)%name, 0, item)
            call json%add(object, item)
        end do
    end subroutine dict

end subroutine entity_json

end module fdoc_output
