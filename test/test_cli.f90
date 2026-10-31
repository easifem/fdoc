module test_cli
!! The command line.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc_cli, only: args_t, parse_args, ACTION_VERSION
use fdoc_util, only: string_t
implicit none
private

public :: collect_cli

contains

!> The tests of this module.
subroutine collect_cli(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests
    testsuite = [ &
                new_unittest("project file and repeated options", test_repeat), &
                new_unittest("forms of option values", test_forms), &
                new_unittest("errors", test_errors), &
                new_unittest("version needs no project file", test_version) &
                ]
end subroutine collect_cli

!> Checks: project file and repeated options.
subroutine test_repeat(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(args_t) :: a
    character(len=:), allocatable :: msg
    integer :: stat

    call parse_args([string_t('-d'), string_t('a'), string_t('ford.md'), string_t('--src_dir'), string_t('b')], &
                    a, stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, a%project_file, 'ford.md')
    if (allocated(error)) return
    call check(error, size(a%options), 1)
    if (allocated(error)) return
    call check(error, a%options(1)%values(2)%s, 'b')
end subroutine test_repeat

!> Checks: forms of option values.
subroutine test_forms(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(args_t) :: a
    character(len=:), allocatable :: msg
    integer :: stat

    call parse_args([string_t('--output_dir=out'), string_t('-Iinc'), string_t('--no-search'), string_t('p')], &
                    a, stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, a%options(1)%values(1)%s, 'out')
    if (allocated(error)) return
    call check(error, a%options(2)%key, 'include')
    if (allocated(error)) return
    call check(error, a%options(2)%values(1)%s, 'inc')
    if (allocated(error)) return
    call check(error, a%options(3)%key, 'search')
    if (allocated(error)) return
    call check(error, a%options(3)%values(1)%s, 'false')
end subroutine test_forms

!> Checks: errors.
subroutine test_errors(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(args_t) :: a
    character(len=:), allocatable :: msg
    integer :: stat

    call parse_args([string_t('--nonsense'), string_t('p')], a, stat, msg)
    call check(error, stat /= 0)
    if (allocated(error)) return
    call parse_args([string_t('-d')], a, stat, msg)
    call check(error, stat /= 0)
    if (allocated(error)) return
    call parse_args([string_t('-w')], a, stat, msg)
    call check(error, stat /= 0, 'a project file is required')
end subroutine test_errors

!> Checks: version needs no project file.
subroutine test_version(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(args_t) :: a
    character(len=:), allocatable :: msg
    integer :: stat

    call parse_args([string_t('-V')], a, stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, a%action, ACTION_VERSION)
end subroutine test_version

end module test_cli
