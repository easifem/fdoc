module fdoc_input
!! Finding, reading and preprocessing source files.
use iso_fortran_env, only: error_unit
use iso_c_binding, only: c_int
use ffmt_fs, only: is_directory, parent_directory, join_path
use ffmt_io, only: read_file
use ffmt_walk, only: collect_files
use fregex, only: regex_t, regex, re_escape, match_t
use fdoc_util
use fdoc_settings, only: settings_t
implicit none
private

public :: find_sources, load_source, expand_includes, is_fixed_form

interface
    !> C `getpid`.
    function c_getpid() bind(c, name='getpid') result(pid)
        import :: c_int
        integer(c_int) :: pid
    end function c_getpid
end interface

integer, parameter :: MAX_INCLUDE_DEPTH = 32

contains

!> The extension of `path`, without the dot, or `''`.
pure function extension_of(path) result(ext)
    character(len=*), intent(in) :: path    !! the path
    character(len=merge(0, len(path) - index(path, '.', back=.true.), index(path, '.', back=.true.) == 0)) :: ext
    ext = path(len(path) - len(ext) + 1:)
end function extension_of

!> True if `path` has one of the fixed-form extensions.
logical function is_fixed_form(s, path)
    type(settings_t), intent(in) :: s       !! the settings
    character(len=*), intent(in) :: path    !! the file
    is_fixed_form = contains_string(s%fixed_extensions, extension_of(path))
end function is_fixed_form

!> The source files of the project, sorted, without those excluded. Fixed-form files are left out
!> with a warning, as they are not supported yet.
subroutine find_sources(s, files)
    type(settings_t), intent(in) :: s                       !! the settings
    type(string_t), allocatable, intent(out) :: files(:)    !! paths of the files
    type(string_t), allocatable :: found(:), extensions(:), no_exclusions(:)
    integer :: d, k, j, skipped
    logical :: keep

    allocate (files(0), no_exclusions(0))
    extensions = [s%extensions, s%fixed_extensions]
    skipped = 0
    do d = 1, size(s%src_dir)
        if (.not. is_directory(s%src_dir(d)%s)) cycle
        call collect_files(s%src_dir(d)%s, extensions, no_exclusions, found)
        do k = 1, size(found)
            keep = .true.
            do j = 1, size(s%exclude_dir)
                if (starts_with(found(k)%s, s%exclude_dir(j)%s//'/')) keep = .false.
            end do
            do j = 1, size(s%exclude)
                if (glob_matches(s%exclude(j)%s, found(k)%s)) keep = .false.
            end do
            if (keep .and. contains_string(s%fixed_extensions, extension_of(found(k)%s)) .and. &
                .not. contains_string(s%extensions, extension_of(found(k)%s))) then
                skipped = skipped + 1
                write (error_unit, '(a)') 'Warning: skipping fixed-form file (not supported yet): '//found(k)%s
                keep = .false.
            end if
            if (keep) call push(files, found(k)%s)
        end do
    end do
    call sort_strings(files)
end subroutine find_sources

!> True if `path` matches exclusion `pattern`, like Python's `fnmatch`: a `*` crosses `/`. A pattern
!> that is not absolute may match the end of the path.
function glob_matches(pattern, path) result(matches)
    character(len=*), intent(in) :: pattern     !! the pattern
    character(len=*), intent(in) :: path        !! the path
    logical :: matches
    character(len=:), allocatable :: bare, re
    type(regex_t) :: compiled
    integer :: k

    bare = pattern
    if (starts_with(bare, '**/')) bare = bare(4:)
    re = '(.*/)?'
    do k = 1, len(bare)
        select case (bare(k:k))
        case ('*'); re = re//'.*'
        case ('?'); re = re//'.'
        case default; re = re//re_escape(bare(k:k))
        end select
    end do
    compiled = regex(re)
    matches = compiled%fullmatch(path)
end function glob_matches

!> Read source file `path`, preprocessing it if its extension calls for that, with `include` lines
!> replaced by the files they name.
subroutine load_source(s, path, raw, text, stat, errmsg)
    type(settings_t), intent(in) :: s                   !! the settings
    character(len=*), intent(in) :: path                !! the file
    character(len=:), allocatable, intent(out) :: raw   !! the file as it is
    character(len=:), allocatable, intent(out) :: text  !! the text to parse
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong

    call read_file(path, raw, stat, errmsg)
    if (stat /= 0) return
    text = raw
    if (s%preprocess .and. contains_string(s%fpp_extensions, extension_of(path))) call preprocess(s, path, text)
    call expand_includes(s%include, parent_directory(path), text, 1)
end subroutine load_source

!> The preprocessor command for `path`. FORD's default of `pcpp` is Python, so it is replaced.
function preprocessor_command(s, path) result(command)
    type(settings_t), intent(in) :: s       !! the settings
    character(len=*), intent(in) :: path    !! the file
    character(len=:), allocatable :: command
    integer :: k

    command = s%preprocessor
    if (starts_word(command, 'pcpp')) command = 'gfortran -E -cpp -D__GFORTRAN__'
    do k = 1, size(s%macro)
        if (len(strip(s%macro(k)%s)) > 0) command = command//" '-D"//strip(s%macro(k)%s)//"'"
    end do
    do k = 1, size(s%include)
        command = command//" '-I"//s%include(k)%s//"'"
    end do
    command = command//" '"//path//"'"
end function preprocessor_command

!> Replace `text` by the output of the preprocessor for `path`, or keep it if that fails.
subroutine preprocess(s, path, text)
    type(settings_t), intent(in) :: s                   !! the settings
    character(len=*), intent(in) :: path                !! the file
    character(len=:), allocatable, intent(inout) :: text  !! the text
    character(len=:), allocatable :: output, errors, command, directory, result, msg
    character(len=32) :: tag
    integer :: exit_code, stat, n, unit

    call get_environment_variable('TMPDIR', length=n)
    allocate (character(len=n) :: directory)
    if (n > 0) call get_environment_variable('TMPDIR', directory)
    if (n == 0) directory = '/tmp'
    write (tag, '(i0)') c_getpid()
    output = join_path(directory, 'fdoc-'//trim(tag)//'.out')
    errors = join_path(directory, 'fdoc-'//trim(tag)//'.err')
    command = preprocessor_command(s, path)
    call execute_command_line(command//" > '"//output//"' 2> '"//errors//"'", exitstat=exit_code, cmdstat=stat)
    if (stat == 0 .and. exit_code == 0) then
        call read_file(output, result, stat, msg)
        if (stat == 0) call move_alloc(result, text)
    else
        write (error_unit, '(a)') 'Warning: preprocessing failed, reverting to the file itself: '//command
    end if
    open (newunit=unit, file=output, status='old', iostat=stat)
    if (stat == 0) close (unit, status='delete')
    open (newunit=unit, file=errors, status='old', iostat=stat)
    if (stat == 0) close (unit, status='delete')
end subroutine preprocess

!> Replace `include` lines in `text` by the files they name, found in `directory` or `search`.
recursive subroutine expand_includes(search, directory, text, depth)
    type(string_t), intent(in) :: search(:)             !! other directories to look in
    character(len=*), intent(in) :: directory           !! the directory of the including file
    character(len=:), allocatable, intent(inout) :: text  !! the text
    integer, intent(in) :: depth                        !! how many includes deep this is
    type(string_t), allocatable :: lines(:)
    character(len=:), allocatable :: name, found, contents, msg
    logical :: changed
    integer :: k, stat

    if (depth > MAX_INCLUDE_DEPTH) return
    if (index(lowercase(text), 'include') == 0) return
    lines = split_lines(text)
    changed = .false.
    do k = 1, size(lines)
        if (.not. include_name(lines(k)%s, name)) cycle
        found = locate(search, directory, name)
        if (len(found) == 0) then
            write (error_unit, '(a)') 'Warning: Can not find include file "'//name//'"'
            cycle
        end if
        call read_file(found, contents, stat, msg)
        if (stat /= 0) cycle
        call expand_includes(search, parent_directory(found), contents, depth + 1)
        lines(k)%s = contents
        changed = .true.
    end do
    if (changed) text = join(lines, achar(10))//achar(10)
end subroutine expand_includes

!> True if `line` is an `include` line, returning the file it names.
logical function include_name(line, name)
    character(len=*), intent(in) :: line                !! the line
    character(len=:), allocatable, intent(out) :: name  !! the file named
    character(len=:), allocatable :: code
    integer :: last

    include_name = .false.
    code = strip(line)
    if (len(code) < 10) return
    if (lowercase(code(1:8)) /= 'include ') return
    code = strip(code(9:))
    if (code(1:1) /= '"' .and. code(1:1) /= "'") return
    last = index(code(2:), code(1:1))
    if (last == 0) return
    name = code(2:last)
    include_name = .true.
end function include_name

!> The path of include file `name`, or `''` if it is not found.
function locate(search, directory, name) result(path)
    type(string_t), intent(in) :: search(:)     !! other directories to look in
    character(len=*), intent(in) :: directory   !! the directory of the including file
    character(len=*), intent(in) :: name        !! the file
    character(len=:), allocatable :: path
    logical :: exists
    integer :: k

    path = join_path(directory, name)
    inquire (file=path, exist=exists)
    if (exists) return
    do k = 1, size(search)
        path = join_path(search(k)%s, name)
        inquire (file=path, exist=exists)
        if (exists) return
    end do
    path = ''
end function locate

end module fdoc_input
