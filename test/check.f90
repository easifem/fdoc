program check
!! Unit tests.
use iso_fortran_env, only: error_unit
use testdrive, only: run_testsuite, new_testsuite, testsuite_type
use test_project_file, only: collect_project_file
use test_settings, only: collect_settings
use test_cli, only: collect_cli
use test_parser, only: collect_parser
implicit none

type(testsuite_type), allocatable :: testsuites(:)
integer :: stat, is

stat = 0
testsuites = [ &
             new_testsuite("project file", collect_project_file), &
             new_testsuite("settings", collect_settings), &
             new_testsuite("cli", collect_cli), &
             new_testsuite("parser", collect_parser) &
             ]
do is = 1, size(testsuites)
    write (error_unit, '(a)') '# Testing: '//testsuites(is)%name
    call run_testsuite(testsuites(is)%collect, error_unit, stat)
end do
if (stat > 0) then
    write (error_unit, '(i0, a)') stat, ' test(s) failed!'
    error stop
end if
end program check
