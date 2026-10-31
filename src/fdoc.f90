module fdoc
!! The `fdoc` program: documentation for modern Fortran, from FORD project files.
use iso_fortran_env, only: error_unit, output_unit
use ffmt_fs, only: parent_directory
use fdoc_util, only: string_t
use fdoc_cli, only: args_t, parse_args, apply_args, usage, VERSION, ACTION_HELP, ACTION_VERSION, ACTION_DUMP
use fdoc_settings, only: settings_t, check_settings, finish_settings, dump_settings
use fdoc_project_file, only: load_project, apply_toml_string
use fdoc_project, only: project_t, load_project_sources, correlate, prune
use fdoc_output, only: write_modules
implicit none
private

public :: run

contains

!> Run with command line `args`, returning the exit status.
integer function run(args) result(status)
    type(string_t), intent(in) :: args(:)   !! the arguments, in order
    type(args_t) :: parsed
    type(settings_t) :: s
    type(project_t) :: p
    character(len=:), allocatable :: errmsg, body, directory
    integer :: stat

    status = 0
    call parse_args(args, parsed, stat, errmsg)
    if (stat /= 0) then
        write (error_unit, '(a)') 'fdoc: '//errmsg
        write (error_unit, '(a)') 'Try "fdoc --help".'
        status = 2
        return
    end if
    if (parsed%action == ACTION_HELP) then
        write (output_unit, '(a)', advance='no') usage()
        return
    end if
    if (parsed%action == ACTION_VERSION) then
        write (output_unit, '(a)') 'fdoc version '//VERSION
        return
    end if

    directory = parent_directory(parsed%project_file)
    call load_project(parsed%project_file, directory, s, body, stat, errmsg)
    if (stat == 0) call check_settings(s, stat, errmsg)
    if (stat == 0 .and. allocated(parsed%config)) call apply_toml_string(parsed%config, s, stat, errmsg)
    if (stat == 0) call apply_args(parsed, s, stat, errmsg)
    if (stat == 0) call finish_settings(s, directory, stat, errmsg)
    if (stat /= 0) then
        write (error_unit, '(a)') 'fdoc: '//errmsg
        status = 1
        return
    end if

    if (parsed%action == ACTION_DUMP) then
        write (output_unit, '(a)', advance='no') dump_settings(s)
        return
    end if

    call load_project_sources(s, p, stat, errmsg)
    if (stat /= 0) then
        write (error_unit, '(a)') 'fdoc: '//errmsg
        status = 1
        return
    end if
    call correlate(p)
    call prune(p, s)
    if (s%externalize) call write_modules(p, s, stat, errmsg)
    if (stat /= 0) then
        write (error_unit, '(a)') 'fdoc: '//errmsg
        status = 1
        return
    end if
    write (error_unit, '(a)') 'fdoc: only modules.json is generated so far; the HTML site is not implemented yet'
end function run

end module fdoc
