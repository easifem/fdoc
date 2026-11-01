module fdoc_shell
!! What standard Fortran cannot do with the file system, through the shell of the platform: `cmd.exe` on
!! Windows, and `sh` elsewhere. All commands that differ between them are here. These routines run
!! commands, so they are for serial code only.
use ffmt_fs, only: is_directory
implicit none
private

public :: is_windows, quoted, quoted_path, make_directory, remove_directory, copy_file, copy_path
public :: program_exists, temporary_directory, run_command

contains

!> Run `command` and wait for it. Without `cmdstat`, a program can stop with an error if the command
!> is not found, which some shells report with status 127.
subroutine run_command(command, stat)
    character(len=*), intent(in) :: command !! the command
    integer, intent(out) :: stat            !! nonzero on failure
    integer :: exit_status, command_status

    exit_status = 0
    call execute_command_line(command, exitstat=exit_status, cmdstat=command_status)
    stat = merge(exit_status, command_status, command_status == 0)
end subroutine run_command

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

!> Create directory `path` with those above it, if it does not exist. It is not a failure if something
!> else creates it first.
subroutine make_directory(path, stat)
    character(len=*), intent(in) :: path    !! the directory
    integer, intent(out) :: stat            !! nonzero on failure

    if (is_windows()) then
        call run_command('if not exist '//quoted_path(path)//' mkdir '//quoted_path(path), stat)
    else
        call run_command('mkdir -p '//quoted_path(path), stat)
    end if
    if (is_directory(path)) stat = 0
end subroutine make_directory

!> Delete directory `path` with what it holds, if it exists.
subroutine remove_directory(path)
    character(len=*), intent(in) :: path    !! the directory
    integer :: stat

    if (is_windows()) then
        call run_command('if exist '//quoted_path(path)//' rmdir /s /q '//quoted_path(path), stat)
    else
        call run_command('rm -rf '//quoted_path(path), stat)
    end if
end subroutine remove_directory

!> Copy file `from` to `to`.
subroutine copy_file(from, to, stat)
    character(len=*), intent(in) :: from    !! the file
    character(len=*), intent(in) :: to      !! the copy
    integer, intent(out) :: stat            !! nonzero on failure

    if (is_windows()) then
        call run_command('copy /y '//quoted_path(from)//' '//quoted_path(to)//' >nul', stat)
    else
        call run_command('cp '//quoted_path(from)//' '//quoted_path(to), stat)
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
        call run_command('xcopy '//quoted_path(from)//' '//quoted_path(to)//' /e /i /y /q >nul', stat)
    else
        call run_command('cp -R '//quoted_path(from)//' '//quoted_path(to), stat)
    end if
end subroutine copy_path

!> True if program `name` can be run.
logical function program_exists(name)
    character(len=*), intent(in) :: name    !! the program
    integer :: stat

    if (is_windows()) then
        call run_command('where '//name//' >nul 2>nul', stat)
    else
        call run_command('command -v '//name//' > /dev/null 2>&1', stat)
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
