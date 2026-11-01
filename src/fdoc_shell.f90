module fdoc_shell
!! What standard Fortran cannot do with the file system, through the shell of the platform: `cmd.exe` on
!! Windows, and `sh` elsewhere. All commands that differ between them are here. These routines run
!! commands, so they are for serial code only.
use ffmt_fs, only: is_directory
implicit none
private

public :: is_windows, quoted, quoted_path, make_directory, remove_directory, copy_file, copy_path
public :: program_exists, temporary_directory

contains

!> True on Windows, which sets the variable `OS` to this value.
logical function is_windows()
    character(len=16) :: value
    integer :: status

    call get_environment_variable('OS', value, status=status)
    is_windows = status == 0 .and. value == 'Windows_NT'
end function is_windows

!> `text` in quotes, as one argument of a command.
function quoted(text) result(out)
    character(len=*), intent(in) :: text    !! the text
    character(len=:), allocatable :: out

    if (is_windows()) then
        out = '"'//text//'"'
    else
        out = "'"//text//"'"
    end if
end function quoted

!> `path` in quotes, with the separator of the platform, as one argument of a command.
function quoted_path(path) result(out)
    character(len=*), intent(in) :: path    !! the path
    character(len=:), allocatable :: out
    character(len=len(path)) :: native
    integer :: k

    native = path
    if (is_windows()) then
        do k = 1, len(native)
            if (native(k:k) == '/') native(k:k) = '\'
        end do
    end if
    out = quoted(native)
end function quoted_path

!> Create directory `path` with those above it, if it does not exist.
subroutine make_directory(path, stat)
    character(len=*), intent(in) :: path    !! the directory
    integer, intent(out) :: stat            !! nonzero on failure

    if (is_windows()) then
        call execute_command_line('if not exist '//quoted_path(path)//' mkdir '//quoted_path(path), exitstat=stat)
    else
        call execute_command_line('mkdir -p '//quoted_path(path), exitstat=stat)
    end if
end subroutine make_directory

!> Delete directory `path` with what it holds, if it exists.
subroutine remove_directory(path)
    character(len=*), intent(in) :: path    !! the directory
    integer :: stat

    if (is_windows()) then
        call execute_command_line('if exist '//quoted_path(path)//' rmdir /s /q '//quoted_path(path), exitstat=stat)
    else
        call execute_command_line('rm -rf '//quoted_path(path), exitstat=stat)
    end if
end subroutine remove_directory

!> Copy file `from` to `to`.
subroutine copy_file(from, to, stat)
    character(len=*), intent(in) :: from    !! the file
    character(len=*), intent(in) :: to      !! the copy
    integer, intent(out) :: stat            !! nonzero on failure

    if (is_windows()) then
        call execute_command_line('copy /y '//quoted_path(from)//' '//quoted_path(to)//' >nul', exitstat=stat)
    else
        call execute_command_line('cp '//quoted_path(from)//' '//quoted_path(to), exitstat=stat)
    end if
end subroutine copy_file

!> Copy file or directory `from` to `to`, with what a directory holds.
subroutine copy_path(from, to, stat)
    character(len=*), intent(in) :: from    !! the file or directory
    character(len=*), intent(in) :: to      !! the copy
    integer, intent(out) :: stat            !! nonzero on failure

    if (.not. is_directory(from)) then
        call copy_file(from, to, stat)
    else if (is_windows()) then
        call execute_command_line('xcopy '//quoted_path(from)//' '//quoted_path(to)//' /e /i /y /q >nul', exitstat=stat)
    else
        call execute_command_line('cp -R '//quoted_path(from)//' '//quoted_path(to), exitstat=stat)
    end if
end subroutine copy_path

!> True if program `name` can be run.
logical function program_exists(name)
    character(len=*), intent(in) :: name    !! the program
    integer :: stat

    if (is_windows()) then
        call execute_command_line('where '//name//' >nul 2>nul', exitstat=stat)
    else
        call execute_command_line('command -v '//name//' > /dev/null 2>&1', exitstat=stat)
    end if
    program_exists = stat == 0
end function program_exists

!> The directory for temporary files.
subroutine temporary_directory(path)
    character(len=:), allocatable, intent(out) :: path  !! the directory
    character(len=*), parameter :: NAMES(*) = [character(len=6) :: 'TMPDIR', 'TEMP', 'TMP']
    integer :: k, n, status

    do k = 1, size(NAMES)
        call get_environment_variable(trim(NAMES(k)), length=n, status=status)
        if (status /= 0 .or. n == 0) cycle
        allocate (character(len=n) :: path)
        call get_environment_variable(trim(NAMES(k)), path)
        return
    end do
    path = merge('.   ', '/tmp', is_windows())
    path = trim(path)
end subroutine temporary_directory

end module fdoc_shell
