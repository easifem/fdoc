module test_site
!! The pages of a small project on real files, through the whole program.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc, only: run
use fdoc_util, only: string_t, read_whole_file, write_whole_file
use fdoc_shell, only: make_directory, remove_directory
use fdoc_stats, only: file_stats_t, count_source
implicit none
private

public :: collect_site

! each test has its own directory, as tests run in parallel
character(len=*), parameter :: WITH_LOGO = 'build/test site logo'
character(len=*), parameter :: NO_LOGO = 'build/test site no logo'
character(len=*), parameter :: NL = new_line('a')

contains

!> The tests of this module.
subroutine collect_site(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests

    testsuite = [new_unittest("logo", test_logo), new_unittest("logo that is missing", test_missing_logo), &
                 new_unittest("lines of a source file", test_lines), new_unittest("list of source files", test_file_list)]
end subroutine collect_site

!> Write a project with the setting `logo: small.svg` in `root`, and run fdoc on it.
subroutine make_site(root, error)
    character(len=*), intent(in) :: root                    !! the directory
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: errmsg
    integer :: stat

    call remove_directory(root)
    call make_directory(root//'/src', stat)
    call write_whole_file(root//'/ford.md', 'project: logos'//NL//'src_dir: ./src'//NL//'output_dir: ./doc'//NL// &
                          'logo: small.svg'//NL//NL//'The project.'//NL, stat, errmsg)
    call check(error, stat, 0, 'the project file')
    if (allocated(error)) return
    call write_whole_file(root//'/src/a.f90', 'module m'//NL//'end module m'//NL, stat, errmsg)
    call check(error, stat, 0, 'the source')
end subroutine make_site

!> Run fdoc on the project in `root`.
subroutine run_site(root, error)
    character(len=*), intent(in) :: root                    !! the directory
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    type(string_t) :: args(2)

    args(1)%s = '-q'
    args(2)%s = root//'/ford.md'
    call check(error, run(args), 0, 'the run')
end subroutine run_site

!> Checks: the logo goes in the site, and on the main page.
subroutine test_logo(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: text, errmsg
    logical :: copied
    integer :: stat

    call make_site(WITH_LOGO, error)
    if (allocated(error)) return
    call write_whole_file(WITH_LOGO//'/small.svg', '<svg xmlns="http://www.w3.org/2000/svg"/>', stat, errmsg)
    call run_site(WITH_LOGO, error)
    if (allocated(error)) return
    inquire (file=WITH_LOGO//'/doc/logo.svg', exist=copied)
    call check(error, copied, 'it is copied, keeping its extension')
    if (allocated(error)) return
    call read_whole_file(WITH_LOGO//'/doc/index.html', text, stat, errmsg)
    call check(error, stat, 0, 'the main page')
    if (allocated(error)) return
    call check(error, index(text, 'class="hero with-logo"') > 0, 'the box makes room for it')
    if (allocated(error)) return
    call check(error, index(text, '<img class="hero-logo" src="logo.svg"') > 0, 'it is on the page')
    call remove_directory(WITH_LOGO)
end subroutine test_logo

!> Checks: a logo that is not there does not stop the run, or leave a broken image.
subroutine test_missing_logo(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: text, errmsg
    integer :: stat

    call make_site(NO_LOGO, error)
    if (allocated(error)) return
    call run_site(NO_LOGO, error)
    if (allocated(error)) return
    call read_whole_file(NO_LOGO//'/doc/index.html', text, stat, errmsg)
    call check(error, stat, 0, 'the main page')
    if (allocated(error)) return
    call check(error, index(text, '<img class="hero-logo"') == 0, 'there is no image')
    call remove_directory(NO_LOGO)
end subroutine test_missing_logo

!> Checks: lines are told apart, with a `!` in a string, a comment after code, spaces and CRLF.
subroutine test_lines(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    type(file_stats_t) :: stats

    call count_source('! one'//NL//'x = "!" ! two'//NL//NL//'   '//NL//'  !! three'//achar(13)//NL//'y = 1', stats)
    call check(error, stats%lines, 6, 'all lines, with the last having no line ending')
    if (allocated(error)) return
    call check(error, stats%code, 2, 'a comment after code is code')
    if (allocated(error)) return
    call check(error, stats%comments, 2, 'comments alone on a line')
    if (allocated(error)) return
    call check(error, stats%blank, 2, 'empty lines and lines of spaces')
    if (allocated(error)) return
    call check(error, int(stats%bytes), 42, 'bytes')
end subroutine test_lines

!> Checks: the list of files shows the counts of a file and the total.
subroutine test_file_list(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=*), parameter :: ROOT = 'build/test site files'
    character(len=:), allocatable :: text, errmsg
    integer :: stat

    call make_site(ROOT, error)
    if (allocated(error)) return
    call write_whole_file(ROOT//'/src/b.f90', 'module b'//NL//'contains'//NL//'! here'//NL//'subroutine s'//NL// &
                          'end subroutine s'//NL//'end module b'//NL, stat, errmsg)
    call run_site(ROOT, error)
    if (allocated(error)) return
    call read_whole_file(ROOT//'/doc/lists/files.html', text, stat, errmsg)
    call check(error, stat, 0, 'the list')
    if (allocated(error)) return
    call check(error, index(text, 'class="listing sortable"') > 0, 'it can be sorted')
    if (allocated(error)) return
    call check(error, index(text, '<td class="num" data-sort="6">6</td><td class="num" data-sort="5">5</td>') > 0, 'lines of b')
    if (allocated(error)) return
    call check(error, index(text, '<tfoot><tr><td>Total</td><td class="num" data-sort="8">8</td>') > 0, 'the total')
    call remove_directory(ROOT)
end subroutine test_file_list

end module test_site
