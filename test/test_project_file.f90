module test_project_file
!! Project file metadata, which must split exactly as FORD splits it.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc_project_file, only: parse_metadata, metadata_t, load_project
use fdoc_settings, only: settings_t
use fdoc_shell, only: make_directory
use ffmt_io, only: write_file
use fdoc_util, only: join
implicit none
private

public :: collect_project_file

character, parameter :: NL = achar(10)

contains

!> The tests of this module.
subroutine collect_project_file(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests
    testsuite = [ &
                new_unittest("plain metadata", test_plain), &
                new_unittest("yaml fences", test_fences), &
                new_unittest("continuation lines", test_continuation), &
                new_unittest("repeated keys", test_repeated), &
                new_unittest("empty values", test_empty_value), &
                new_unittest("no metadata", test_no_metadata), &
                new_unittest("keys are lowercased", test_case), &
                new_unittest("settings in fpm.toml", test_fpm_table), &
                new_unittest("fpm.toml without a table", test_fpm_no_table) &
                ]
end subroutine collect_project_file

!> Checks: plain metadata.
subroutine test_plain(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(metadata_t) :: m
    call parse_metadata('project: x'//NL//'author: a b'//NL//NL//'Body'//NL//'more', m)
    call check(error, size(m%items), 2)
    if (allocated(error)) return
    call check(error, m%items(2)%key, 'author')
    if (allocated(error)) return
    call check(error, m%items(2)%values(1)%s, 'a b')
    if (allocated(error)) return
    call check(error, join(m%body, NL), 'Body'//NL//'more')
end subroutine test_plain

!> Checks: yaml fences.
subroutine test_fences(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(metadata_t) :: m
    call parse_metadata('---'//NL//'project: x'//NL//'---'//NL//'Body', m)
    call check(error, size(m%items), 1)
    if (allocated(error)) return
    call check(error, join(m%body, NL), 'Body')
end subroutine test_fences

!> Checks: continuation lines.
subroutine test_continuation(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(metadata_t) :: m
    call parse_metadata('display: public'//NL//'         private'//NL//'    protected'//NL, m)
    call check(error, size(m%items(1)%values), 3)
    if (allocated(error)) return
    call check(error, m%items(1)%values(3)%s, 'protected')
end subroutine test_continuation

!> Checks: repeated keys.
subroutine test_repeated(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(metadata_t) :: m
    call parse_metadata('src_dir: a'//NL//'project: x'//NL//'src_dir: b'//NL, m)
    call check(error, size(m%items), 2)
    if (allocated(error)) return
    call check(error, size(m%items(1)%values), 2)
    if (allocated(error)) return
    call check(error, m%items(1)%values(2)%s, 'b')
end subroutine test_repeated

!> Checks: empty values.
subroutine test_empty_value(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(metadata_t) :: m
    call parse_metadata('docmark_alt:'//NL//'docmark: !'//NL, m)
    call check(error, m%items(1)%values(1)%s, '')
    if (allocated(error)) return
    call check(error, m%items(2)%values(1)%s, '!')
end subroutine test_empty_value

!> Checks: no metadata.
subroutine test_no_metadata(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(metadata_t) :: m
    call parse_metadata('Just text, not a key'//NL//'second line', m)
    call check(error, size(m%items), 0)
    if (allocated(error)) return
    call check(error, join(m%body, NL), 'Just text, not a key'//NL//'second line')
end subroutine test_no_metadata

!> Checks: keys are lowercased.
subroutine test_case(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(metadata_t) :: m
    call parse_metadata('Project: Mixed Value'//NL, m)
    call check(error, m%items(1)%key, 'project')
    if (allocated(error)) return
    call check(error, m%items(1)%values(1)%s, 'Mixed Value')
end subroutine test_case

!> Checks: an `fpm.toml` given as the project file must have settings in it.
subroutine test_fpm_no_table(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    character(len=*), parameter :: DIRECTORY = 'build/test_project_file_empty'
    type(settings_t) :: s
    character(len=:), allocatable :: body, msg
    integer :: stat

    call make_directory(DIRECTORY, stat)
    !$omp critical (file_io)
    call write_file(DIRECTORY//'/fpm.toml', 'name = "x"'//NL, stat, msg)
    !$omp end critical (file_io)
    call check(error, stat, 0)
    if (allocated(error)) return
    call load_project(DIRECTORY//'/fpm.toml', DIRECTORY, s, body, stat, msg)
    call check(error, stat /= 0, 'no settings is an error')
end subroutine test_fpm_no_table

!> Checks: settings in fpm.toml.
subroutine test_fpm_table(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    character(len=*), parameter :: DIRECTORY = 'build/test_project_file'
    type(settings_t) :: s
    character(len=:), allocatable :: body, msg
    integer :: stat

    call make_directory(DIRECTORY, stat)
    !$omp critical (file_io)
    call write_file(DIRECTORY//'/fpm.toml', 'name = "x"'//NL//'[extra.fdoc]'//NL//'project = "Mine"'//NL// &
                    'front_page = "Hello"'//NL//'[extra.ford]'//NL//'project = "Not this"'//NL, stat, msg)
    !$omp end critical (file_io)
    call check(error, stat, 0)
    if (allocated(error)) return
    call load_project('', DIRECTORY, s, body, stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, s%project, 'Mine', 'fdoc comes first')
    if (allocated(error)) return
    call check(error, body, 'Hello')
    if (allocated(error)) return

    !$omp critical (file_io)
    call write_file(DIRECTORY//'/front.md', 'From a file', stat, msg)
    !$omp end critical (file_io)
    !$omp critical (file_io)
    call write_file(DIRECTORY//'/fpm.toml', 'name = "x"'//NL//'[extra.fdoc]'//NL//'front_page_file = "front.md"'//NL, stat, msg)
    !$omp end critical (file_io)
    call load_project('', DIRECTORY, s, body, stat, msg)
    call check(error, stat, 0)
    if (allocated(error)) return
    call check(error, body, 'From a file')
end subroutine test_fpm_table

end module test_project_file
