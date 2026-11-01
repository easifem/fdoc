module test_settings
!! Conversion of options from text, and their checks.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc_settings, only: settings_t, new_settings, set_option, check_settings, is_option
use fdoc_util, only: string_t, resolve_path, expand_vars, split_lines, split_words, strip
implicit none
private

public :: collect_settings

contains

!> The tests of this module.
subroutine collect_settings(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests
    testsuite = [ &
                new_unittest("logical options", test_logical), &
                new_unittest("text options join values", test_text), &
                new_unittest("map options", test_map), &
                new_unittest("extra_filetypes", test_filetypes), &
                new_unittest("defaults are completed by the checks", test_checks), &
                new_unittest("equal doc markers are rejected", test_docmarks), &
                new_unittest("option names", test_names), &
                new_unittest("paths", test_paths), &
                new_unittest("project graph limit", test_project_nodes), &
                new_unittest("line splitting", test_lines) &
                ]
end subroutine collect_settings

!> Checks: the limit on graphs of a whole project.
subroutine test_project_nodes(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(settings_t) :: s
    character(len=:), allocatable :: msg
    integer :: stat

    s = new_settings()
    call check(error, s%graph_project_maxnodes, 400)
    if (allocated(error)) return
    call set_option(s, 'graph_project_maxnodes', [string_t('1000')], stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, s%graph_project_maxnodes, 1000)
end subroutine test_project_nodes

!> Checks: logical options.
subroutine test_logical(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(settings_t) :: s
    character(len=:), allocatable :: msg
    integer :: stat

    s = new_settings()
    call set_option(s, 'graph', [string_t('TRUE')], stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, s%graph)
    if (allocated(error)) return
    call set_option(s, 'graph', [string_t('yes')], stat, msg)
    call check(error, stat /= 0)
end subroutine test_logical

!> Checks: text options join values.
subroutine test_text(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(settings_t) :: s
    character(len=:), allocatable :: msg
    integer :: stat

    s = new_settings()
    call set_option(s, 'summary', [string_t('one'), string_t('two')], stat, msg)
    call check(error, s%summary, 'one'//achar(10)//'two')
end subroutine test_text

!> Checks: map options.
subroutine test_map(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(settings_t) :: s
    character(len=:), allocatable :: msg
    integer :: stat

    s = new_settings()
    call set_option(s, 'extra_mods', [string_t('m : https://x.org/a:b'), string_t('')], stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, size(s%extra_mods), 1)
    if (allocated(error)) return
    call check(error, s%extra_mods(1)%key, 'm')
    if (allocated(error)) return
    call check(error, s%extra_mods(1)%value, 'https://x.org/a:b')
    if (allocated(error)) return
    call set_option(s, 'alias', [string_t('no separator')], stat, msg)
    call check(error, stat /= 0)
end subroutine test_map

!> Checks: extra_filetypes.
subroutine test_filetypes(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(settings_t) :: s
    character(len=:), allocatable :: msg
    integer :: stat

    s = new_settings()
    call set_option(s, 'extra_filetypes', [string_t('.inc ! fortran')], stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, s%extra_filetypes(1)%extension, '.inc')
    if (allocated(error)) return
    call check(error, s%extra_filetypes(1)%lexer, 'fortran')
    if (allocated(error)) return
    call set_option(s, 'extra_filetypes', [string_t('.inc')], stat, msg)
    call check(error, stat /= 0)
end subroutine test_filetypes

!> Checks: defaults are completed by the checks.
subroutine test_checks(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(settings_t) :: s
    character(len=:), allocatable :: msg
    integer :: stat

    s = new_settings()
    call check_settings(s, stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, s%relative)
    if (allocated(error)) return
    call check(error, s%exclude_dir(1)%s, './doc')
    if (allocated(error)) return
    call check(error, size(s%extensions), 12)
    if (allocated(error)) return
    call check(error, size(s%extra_mods), 9)
end subroutine test_checks

!> Checks: equal doc markers are rejected.
subroutine test_docmarks(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(settings_t) :: s
    character(len=:), allocatable :: msg
    integer :: stat

    s = new_settings()
    call set_option(s, 'predocmark', [string_t('!')], stat, msg)
    call check_settings(s, stat, msg)
    call check(error, stat /= 0)
    if (allocated(error)) return
    s = new_settings()
    call set_option(s, 'docmark_alt', [string_t('')], stat, msg)
    call set_option(s, 'predocmark_alt', [string_t('')], stat, msg)
    call check_settings(s, stat, msg)
    call check(error, stat, 0, 'empty markers may be equal')
end subroutine test_docmarks

!> Checks: option names.
subroutine test_names(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call check(error, is_option('src_dir'))
    if (allocated(error)) return
    call check(error, .not. is_option('project_dir'))
    if (allocated(error)) return
    call check(error, .not. is_option(''))
    if (allocated(error)) return
    call check(error, .not. is_option('src_dir graph'))
end subroutine test_names

!> Checks: paths.
subroutine test_paths(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call check(error, resolve_path('/', './no-such-dir-fdoc/a/../b'), '/no-such-dir-fdoc/b')
    if (allocated(error)) return
    call check(error, expand_vars('a$FDOC_SURELY_UNSET/b'), 'a$FDOC_SURELY_UNSET/b')
end subroutine test_paths

!> Checks: line splitting.
subroutine test_lines(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(string_t), allocatable :: lines(:)

    lines = split_lines('a'//achar(13)//achar(10)//'b'//achar(10)//achar(10))
    call check(error, size(lines), 3)
    if (allocated(error)) return
    call check(error, lines(3)%s, '')
    if (allocated(error)) return
    call check(error, size(split_words('  x  y'//achar(9)//'z ')), 3)
    if (allocated(error)) return
    call check(error, strip('  x '), 'x')
end subroutine test_lines

end module test_settings
