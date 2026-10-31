module fdoc_project_file
!! Reading settings from a project file, `fpm.toml` or a TOML string.
!!
!! A project file starts with Markdown metadata, optionally between `---` lines: `key: value` lines,
!! with values continued on lines indented by four or more blanks. Metadata ends at the first blank
!! line, at an end marker, or at a line that fits neither form. The rest of the file is the text of
!! the front page. An `[extra.ford]` table in `fpm.toml` next to the project file replaces its
!! metadata, as in FORD; the text of the project file is then used whole.
use iso_fortran_env, only: error_unit
use tomlf, only: toml_table, toml_array, toml_keyval, toml_key, toml_value, toml_error, toml_load, toml_loads, &
                 get_value, len
use tomlf_constants, only: toml_type
use ffmt_io, only: read_file
use ffmt_fs, only: join_path
use ffmt_strings, only: to_s
use fdoc_util
use fdoc_settings, only: settings_t, new_settings, set_option, is_option
implicit none
private

public :: parse_metadata, load_project, apply_toml_string, metadata_t

type :: meta_item_t
    !! A metadata key and the values given for it.
    character(len=:), allocatable :: key
    type(string_t), allocatable :: values(:)
end type meta_item_t

type :: metadata_t
    !! The metadata of a project file and what follows it.
    type(meta_item_t), allocatable :: items(:)
    type(string_t), allocatable :: body(:)      !! the lines after the metadata
end type metadata_t

contains

!> Split project file `text` into metadata and body.
subroutine parse_metadata(text, meta)
    character(len=*), intent(in) :: text    !! the file
    type(metadata_t), intent(out) :: meta   !! the result
    type(string_t), allocatable :: lines(:)
    character(len=:), allocatable :: key, value
    integer :: n, current

    lines = split_lines(text)
    allocate (meta%items(0))
    n = 1
    if (size(lines) > 0) then
        if (is_marker(lines(1)%s, '-')) n = 2
    end if
    current = 0
    do while (n <= size(lines))
        associate (line => lines(n)%s)
            if (strip(line) == '' .or. is_marker(line, '-') .or. is_marker(line, '.')) then
                n = n + 1
                exit
            end if
            if (match_key(line, key, value)) then
                call add_value(meta, key, value, current)
            else if (current > 0 .and. leading_blanks(line) >= 4) then
                call push(meta%items(current)%values, strip(line))
            else
                exit
            end if
        end associate
        n = n + 1
    end do
    meta%body = lines(n:)
end subroutine parse_metadata

!> Add a value for `key`, whose position in `meta%items` is returned in `current`.
subroutine add_value(meta, key, value, current)
    type(metadata_t), intent(inout) :: meta !! the metadata
    character(len=*), intent(in) :: key     !! the key
    character(len=*), intent(in) :: value   !! the value
    integer, intent(out) :: current         !! the item for `key`
    type(meta_item_t), allocatable :: items(:)
    integer :: k

    do k = 1, size(meta%items)
        if (meta%items(k)%key == key) then
            current = k
            call push(meta%items(k)%values, value)
            return
        end if
    end do
    allocate (items(size(meta%items) + 1))
    do k = 1, size(meta%items)
        call move_alloc(meta%items(k)%key, items(k)%key)
        call move_alloc(meta%items(k)%values, items(k)%values)
    end do
    current = size(items)
    items(current)%key = key
    call push(items(current)%values, value)
    call move_alloc(items, meta%items)
end subroutine add_value

!> Number of blanks at the start of `line`.
pure integer function leading_blanks(line)
    character(len=*), intent(in) :: line    !! the line
    leading_blanks = verify(line, ' ') - 1
    if (leading_blanks < 0) leading_blanks = len(line)
end function leading_blanks

!> True if `line` is three of `c`, alone or followed by whitespace and anything else.
pure logical function is_marker(line, c)
    character(len=*), intent(in) :: line    !! the line
    character, intent(in) :: c              !! the marker character
    is_marker = len(line) >= 3
    if (.not. is_marker) return
    is_marker = line(1:3) == c//c//c
    if (is_marker .and. len(line) > 3) is_marker = line(4:4) == ' ' .or. line(4:4) == achar(9)
end function is_marker

!> True if `line` is `key: value`, indented by at most three blanks.
logical function match_key(line, key, value)
    character(len=*), intent(in) :: line                !! the line
    character(len=:), allocatable, intent(out) :: key   !! the key, in lowercase
    character(len=:), allocatable, intent(out) :: value !! the value
    character(len=*), parameter :: KEY_CHARS = &
                                   'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-'
    integer :: a, b

    match_key = .false.
    a = leading_blanks(line) + 1
    if (a > 4 .or. a > len(line)) return
    b = verify(line(a:), KEY_CHARS)
    if (b <= 1) return
    b = a + b - 1
    if (line(b:b) /= ':') return
    key = lowercase(line(a:b - 1))
    value = strip(line(b + 1:))
    match_key = .true.
end function match_key

!> Read the settings and front page text of the project in file `path`.
subroutine load_project(path, directory, s, body, stat, errmsg)
    character(len=*), intent(in) :: path                !! the project file
    character(len=*), intent(in) :: directory           !! its directory
    type(settings_t), intent(out) :: s                  !! the settings
    character(len=:), allocatable, intent(out) :: body  !! the front page text
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    type(metadata_t) :: meta
    character(len=:), allocatable :: text
    logical :: found
    integer :: k

    s = new_settings()
    call read_file(path, text, stat, errmsg)
    if (stat /= 0) return
    call load_fpm_settings(join_path(directory, 'fpm.toml'), s, found, stat, errmsg)
    if (stat /= 0) return
    if (found) then
        body = text
        return
    end if
    call parse_metadata(text, meta)
    body = join(meta%body, achar(10))
    do k = 1, size(meta%items)
        associate (item => meta%items(k))
            if (.not. is_option(item%key)) then
                write (error_unit, '(a)') "Warning: In '"//path//"': Ignoring unknown Ford metadata key '"//item%key//"'"
                cycle
            end if
            call set_option(s, item%key, item%values, stat, errmsg)
            if (stat /= 0) then
                errmsg = "Error parsing settings from '"//path//"': "//errmsg
                return
            end if
        end associate
    end do
end subroutine load_project

!> Read the `[extra.ford]` table of `fpm.toml` file `path`, if there is one.
subroutine load_fpm_settings(path, s, found, stat, errmsg)
    character(len=*), intent(in) :: path                !! the file
    type(settings_t), intent(inout) :: s                !! the settings
    logical, intent(out) :: found                       !! true if the table exists
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    type(toml_table), allocatable :: top
    type(toml_table), pointer :: extra, table
    type(toml_error), allocatable :: error
    logical :: exists

    stat = 0
    found = .false.
    inquire (file=path, exist=exists)
    if (.not. exists) return
    call toml_load(top, path, error=error)
    if (allocated(error)) then
        stat = 1
        errmsg = path//': '//error%message
        return
    end if
    call get_value(top, 'extra', extra, requested=.false.)
    if (.not. associated(extra)) return
    call get_value(extra, 'ford', table, requested=.false.)
    if (.not. associated(table)) return
    found = .true.
    call apply_table(table, s, stat, errmsg)
end subroutine load_fpm_settings

!> Apply `--config` options: TOML with `;` between lines.
subroutine apply_toml_string(text, s, stat, errmsg)
    character(len=*), intent(in) :: text                !! the options
    type(settings_t), intent(inout) :: s                !! the settings
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    type(toml_table), allocatable :: top
    type(toml_error), allocatable :: error

    call toml_loads(top, join(split_on(text, ';'), achar(10)), error=error)
    if (allocated(error)) then
        stat = 1
        errmsg = '--config: '//error%message
        return
    end if
    call apply_table(top, s, stat, errmsg)
end subroutine apply_toml_string

!> Apply the keys of TOML `table` as options.
subroutine apply_table(table, s, stat, errmsg)
    type(toml_table), intent(inout) :: table            !! the table
    type(settings_t), intent(inout) :: s                !! the settings
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    type(toml_key), allocatable :: keys(:)
    class(toml_value), pointer :: v
    type(string_t), allocatable :: values(:)
    character(len=:), allocatable :: key
    integer :: k

    stat = 0
    call table%get_keys(keys)
    do k = 1, size(keys)
        key = keys(k)%key
        if (.not. is_option(key)) then
            write (error_unit, '(a)') "Warning: Ignoring unknown Ford option '"//key//"'"
            cycle
        end if
        call table%get(key, v)
        allocate (values(0))
        select type (v)
        type is (toml_keyval)
            call push(values, scalar_text(table, key, v%get_type()))
        type is (toml_array)
            call array_values(v, values, stat, errmsg)
        type is (toml_table)
            call map_values(v, merge(':', '=', key == 'extra_mods'), values)
        class default
            stat = 1
            errmsg = "unexpected value for option '"//key//"'"
        end select
        if (stat == 0) call set_option(s, key, values, stat, errmsg)
        deallocate (values)
        if (stat /= 0) return
    end do
end subroutine apply_table

!> A string, integer or logical value of `table` as text.
function scalar_text(table, key, kind) result(text)
    type(toml_table), intent(inout) :: table    !! the table
    character(len=*), intent(in) :: key         !! the key
    integer, intent(in) :: kind                 !! the value's `toml_type`
    character(len=:), allocatable :: text
    integer :: i
    logical :: flag

    text = ''
    if (kind == toml_type%string) then
        call get_value(table, key, text)
    else if (kind == toml_type%int) then
        call get_value(table, key, i)
        text = to_s(i)
    else if (kind == toml_type%boolean) then
        call get_value(table, key, flag)
        text = trim(merge('true ', 'false', flag))
    end if
end function scalar_text

!> The items of a TOML array as text. An array of tables is taken to be `extra_filetypes`.
subroutine array_values(array, values, stat, errmsg)
    type(toml_array), intent(inout) :: array            !! the array
    type(string_t), allocatable, intent(inout) :: values(:)   !! the items
    integer, intent(inout) :: stat                      !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    type(toml_table), pointer :: item
    character(len=:), allocatable :: text, part
    integer :: k, ios

    do k = 1, len(array)
        call get_value(array, k, text, stat=ios)
        if (ios == 0 .and. allocated(text)) then
            call push(values, text)
            cycle
        end if
        call get_value(array, k, item, stat=ios)
        if (ios /= 0 .or. .not. associated(item)) then
            stat = 1
            errmsg = 'expected strings or tables in an array'
            return
        end if
        text = ''
        call get_value(item, 'extension', part, '')
        text = part
        call get_value(item, 'comment', part, '')
        text = text//' '//part
        call get_value(item, 'lexer', part, '')
        if (part /= '') text = text//' '//part
        call push(values, text)
    end do
end subroutine array_values

!> The string entries of `table` in the form `key<sep>value`.
subroutine map_values(table, sep, values)
    type(toml_table), intent(inout) :: table    !! the table
    character, intent(in) :: sep                !! the separator
    type(string_t), allocatable, intent(inout) :: values(:) !! the entries
    type(toml_key), allocatable :: keys(:)
    character(len=:), allocatable :: text
    integer :: k

    call table%get_keys(keys)
    do k = 1, size(keys)
        call get_value(table, keys(k)%key, text, '')
        call push(values, keys(k)%key//sep//text)
    end do
end subroutine map_values

end module fdoc_project_file
