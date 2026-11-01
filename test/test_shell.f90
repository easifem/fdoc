module test_shell
!! File system operations, on real files, so that they are checked on each platform.
use testdrive, only: new_unittest, unittest_type, error_type, check
use ffmt_fs, only: is_directory
use ffmt_io, only: read_file, write_file
use fdoc_shell, only: make_directory, remove_directory, copy_file, copy_path, program_exists, &
                      temporary_directory
implicit none
private

public :: collect_shell

! each test has its own directory, as tests run in parallel. Their names have a blank, to be quoted
character(len=*), parameter :: MADE = 'build/test shell made'
character(len=*), parameter :: COPIED = 'build/test shell copied'

contains

!> The tests of this module.
subroutine collect_shell(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests

    testsuite = [ &
                new_unittest("directories", test_directories), &
                new_unittest("copies", test_copies), &
                new_unittest("programs", test_programs), &
                new_unittest("temporary directory", test_temporary) &
                ]
end subroutine collect_shell

!> Checks: nested directories are made, twice without failing, and removed with what they hold.
subroutine test_directories(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: msg
    integer :: stat

    call remove_directory(MADE)
    call check(error, .not. is_directory(MADE), 'removing what is not there is fine')
    if (allocated(error)) return
    call make_directory(MADE//'/a/b', stat)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, is_directory(MADE//'/a/b'), 'the directories exist')
    if (allocated(error)) return
    call make_directory(MADE//'/a/b', stat)
    call check(error, stat, 0, 'making it again is fine')
    if (allocated(error)) return
    call write_file(MADE//'/a/b/f.txt', 'x', stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call remove_directory(MADE)
    call check(error, .not. is_directory(MADE), 'it is gone')
end subroutine test_directories

!> Checks: files and directories are copied.
subroutine test_copies(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: msg, text
    integer :: stat

    call remove_directory(COPIED)
    call make_directory(COPIED//'/from/sub', stat)
    call check(error, stat, 0)
    if (allocated(error)) return
    call write_file(COPIED//'/from/sub/f.txt', 'hello', stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call copy_file(COPIED//'/from/sub/f.txt', COPIED//'/g.txt', stat)
    call check(error, stat, 0)
    if (allocated(error)) return
    call read_file(COPIED//'/g.txt', text, stat, msg)
    call check(error, stat == 0 .and. text == 'hello', 'a file')
    if (allocated(error)) return
    call copy_path(COPIED//'/from', COPIED//'/to', stat)
    call check(error, stat, 0)
    if (allocated(error)) return
    call read_file(COPIED//'/to/sub/f.txt', text, stat, msg)
    call check(error, stat == 0 .and. text == 'hello', 'a directory')
    if (allocated(error)) return
    call copy_path(COPIED//'/g.txt', COPIED//'/h.txt', stat)
    call check(error, stat, 0, 'a file through copy_path')
    call remove_directory(COPIED)
end subroutine test_copies

!> Checks: programs are found. The tests run under fpm, which runs the compiler.
subroutine test_programs(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any

    call check(error, program_exists('gfortran'), 'the compiler is there')
    if (allocated(error)) return
    call check(error, .not. program_exists('no-such-program-fdoc'), 'this is not')
end subroutine test_programs

!> Checks: the directory for temporary files exists.
subroutine test_temporary(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: path

    call temporary_directory(path)
    call check(error, is_directory(path), path)
end subroutine test_temporary

end module test_shell
