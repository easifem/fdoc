module test_cli
!! The command line.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc_cli, only: args_t, parse_args, ACTION_VERSION
use fdoc_util, only: string_t
use fdoc_progress, only: bar_text, progress_line
use fdoc_pages, only: page_file
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
                new_unittest("version needs no project file", test_version), &
                new_unittest("progress bar", test_bar), &
                new_unittest("progress lines", test_progress_lines), &
                new_unittest("names of static pages", test_page_names) &
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
    call parse_args([string_t('p'), string_t('q')], a, stat, msg)
    call check(error, stat /= 0, 'only one project file')
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

!> Checks: the lines for another program, and the option that turns them on.
subroutine test_progress_lines(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    type(args_t) :: parsed
    character(len=64) :: line
    integer :: stat
    character(len=:), allocatable :: msg

    call progress_line(7, 'Laying out graphs', 83, 1198, line)
    call check(error, trim(line), '[  7%] Laying out graphs 83/1198')
    if (allocated(error)) return
    call progress_line(100, 'Parsing files', 2, 2, line)
    call check(error, trim(line), '[100%] Parsing files 2/2')
    if (allocated(error)) return
    call parse_args([string_t('--progress-lines'), string_t('ford.md')], parsed, stat, msg)
    call check(error, stat, 0, 'the option')
    if (allocated(error)) return
    call check(error, parsed%progress_lines, 'it is on')
end subroutine test_progress_lines

!> Checks: progress bar.
subroutine test_bar(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    integer :: filled, unfilled, percent

    call bar_text(1, 4, 20, filled, unfilled, percent)
    call check(error, filled, 5)
    if (allocated(error)) return
    call check(error, unfilled, 15)
    if (allocated(error)) return
    call check(error, percent, 25)
    if (allocated(error)) return
    call bar_text(9, 4, 20, filled, unfilled, percent)
    call check(error, filled, 20, 'more steps than expected must not overflow the bar')
end subroutine test_bar

!> Checks: names of static pages.
subroutine test_page_names(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any

    call check(error, page_file('index.md'), 'index.html')
    if (allocated(error)) return
    call check(error, page_file('CI.yml.md'), 'CI.html')
end subroutine test_page_names

end module test_cli
