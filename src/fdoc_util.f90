module fdoc_util
!! String, date and path helpers shared by the rest of fdoc.
use, intrinsic :: iso_c_binding, only: c_char, c_null_char, c_ptr, c_associated, c_null_ptr, c_size_t, c_f_pointer
use ffmt_strings, only: string_t, lowercase
use ffmt_fs, only: absolute_path, join_path, parent_directory
implicit none
private

public :: string_t, lowercase
public :: strip, starts_with, ends_with, split_lines, split_words, split_on, join, push, contains_string
public :: parse_bool, parse_int, expand_vars, strftime, resolve_path, sort_strings

character(len=*), parameter :: WHITESPACE = ' '//achar(9)//achar(10)//achar(11)//achar(12)//achar(13)

interface
    !> C `realpath`: the canonical form of a path.
    function c_realpath(path, resolved) bind(c, name='realpath') result(p)
        import :: c_char, c_ptr
        character(kind=c_char), intent(in) :: path(*)   !! the path, null-terminated
        type(c_ptr), value :: resolved                  !! buffer, or null to allocate one
        type(c_ptr) :: p
    end function c_realpath
    !> C `free`.
    subroutine c_free(p) bind(c, name='free')
        import :: c_ptr
        type(c_ptr), value :: p     !! the memory to release
    end subroutine c_free
    !> C `strlen`.
    function c_strlen(p) bind(c, name='strlen') result(n)
        import :: c_ptr, c_size_t
        type(c_ptr), value :: p     !! the null-terminated string
        integer(c_size_t) :: n
    end function c_strlen
end interface

contains

!> `s` without leading and trailing whitespace.
pure function strip(s) result(t)
    character(len=*), intent(in) :: s   !! the string
    character(len=:), allocatable :: t
    integer :: a, b
    a = verify(s, WHITESPACE)
    if (a == 0) then
        t = ''
        return
    end if
    b = verify(s, WHITESPACE, back=.true.)
    t = s(a:b)
end function strip

!> True if `s` begins with `prefix`.
pure logical function starts_with(s, prefix)
    character(len=*), intent(in) :: s        !! the string
    character(len=*), intent(in) :: prefix   !! the start wanted
    starts_with = len(s) >= len(prefix)
    if (starts_with) starts_with = s(1:len(prefix)) == prefix
end function starts_with

!> True if `s` finishes with `suffix`.
pure logical function ends_with(s, suffix)
    character(len=*), intent(in) :: s        !! the string
    character(len=*), intent(in) :: suffix   !! the end wanted
    ends_with = len(s) >= len(suffix)
    if (ends_with) ends_with = s(len(s) - len(suffix) + 1:) == suffix
end function ends_with

!> Append `s` to `list`, allocating it if needed.
subroutine push(list, s)
    type(string_t), allocatable, intent(inout) :: list(:)   !! the list
    character(len=*), intent(in) :: s                       !! the string to append
    type(string_t), allocatable :: tmp(:)
    integer :: n, k

    n = 0
    if (allocated(list)) n = size(list)
    allocate (tmp(n + 1))
    do k = 1, n
        call move_alloc(list(k)%s, tmp(k)%s)
    end do
    tmp(n + 1)%s = s
    call move_alloc(tmp, list)
end subroutine push

!> True if `s` is in `list`.
logical function contains_string(list, s)
    type(string_t), intent(in) :: list(:)   !! the list
    character(len=*), intent(in) :: s       !! the string to find
    integer :: k
    contains_string = .false.
    do k = 1, size(list)
        if (list(k)%s == s .and. len(list(k)%s) == len(s)) then
            contains_string = .true.
            return
        end if
    end do
end function contains_string

!> The lines of `text`, ended by LF, CRLF or CR. As in Python's `splitlines`, a final line ending
!> does not start another line.
function split_lines(text) result(lines)
    character(len=*), intent(in) :: text    !! the text
    type(string_t), allocatable :: lines(:)
    integer :: i, start, n

    n = 0
    do i = 1, len(text)
        if (text(i:i) == achar(10)) n = n + 1
        if (text(i:i) == achar(13)) n = n + 1
    end do
    allocate (lines(n + 1))
    n = 0
    start = 1
    i = 1
    do while (i <= len(text))
        if (text(i:i) == achar(10) .or. text(i:i) == achar(13)) then
            n = n + 1
            lines(n)%s = text(start:i - 1)
            if (text(i:i) == achar(13) .and. i < len(text)) then
                if (text(i + 1:i + 1) == achar(10)) i = i + 1
            end if
            start = i + 1
        end if
        i = i + 1
    end do
    if (start <= len(text)) then
        n = n + 1
        lines(n)%s = text(start:)
    end if
    lines = lines(1:n)
end function split_lines

!> The blank-separated words of `text`.
function split_words(text) result(words)
    character(len=*), intent(in) :: text    !! the text
    type(string_t), allocatable :: words(:)
    integer :: i, j

    allocate (words(0))
    i = 1
    do
        j = verify(text(i:), WHITESPACE)
        if (j == 0) exit
        i = i + j - 1
        j = scan(text(i:), WHITESPACE)
        if (j == 0) then
            call push(words, text(i:))
            exit
        end if
        call push(words, text(i:i + j - 2))
        i = i + j
    end do
end function split_words

!> The parts of `text` between the characters `sep`, including empty ones.
function split_on(text, sep) result(parts)
    character(len=*), intent(in) :: text    !! the text
    character, intent(in) :: sep            !! the separator
    type(string_t), allocatable :: parts(:)
    integer :: i, j

    allocate (parts(0))
    i = 1
    do
        j = index(text(i:), sep)
        if (j == 0) then
            call push(parts, text(i:))
            exit
        end if
        call push(parts, text(i:i + j - 2))
        i = i + j
    end do
end function split_on

!> The strings of `list` with `sep` between them.
function join(list, sep) result(text)
    type(string_t), intent(in) :: list(:)   !! the strings
    character(len=*), intent(in) :: sep     !! the separator
    character(len=:), allocatable :: text
    integer :: k

    text = ''
    do k = 1, size(list)
        if (k > 1) text = text//sep
        text = text//list(k)%s
    end do
end function join

!> Sort `list` by byte value, removing duplicates.
subroutine sort_strings(list)
    type(string_t), allocatable, intent(inout) :: list(:)   !! the list
    type(string_t), allocatable :: out(:)
    character(len=:), allocatable :: t
    integer :: i, j

    do i = 2, size(list)
        call move_alloc(list(i)%s, t)
        j = i - 1
        do while (j >= 1)
            if (.not. llt(t, list(j)%s)) exit
            call move_alloc(list(j)%s, list(j + 1)%s)
            j = j - 1
        end do
        call move_alloc(t, list(j + 1)%s)
    end do
    allocate (out(0))
    do i = 1, size(list)
        if (i > 1) then
            if (list(i)%s == list(i - 1)%s) cycle
        end if
        call push(out, list(i)%s)
    end do
    call move_alloc(out, list)
end subroutine sort_strings

!> Read `true` or `false`, in any case.
subroutine parse_bool(text, value, ok)
    character(len=*), intent(in) :: text    !! the text
    logical, intent(out) :: value           !! the value
    logical, intent(out) :: ok              !! false if `text` is neither
    character(len=:), allocatable :: low

    low = lowercase(text)
    ok = low == 'true' .or. low == 'false'
    value = low == 'true'
end subroutine parse_bool

!> Read a decimal integer.
subroutine parse_int(text, value, ok)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(out) :: value           !! the value
    logical, intent(out) :: ok              !! false if `text` is not an integer
    integer :: ios

    ok = verify(strip(text), '+-0123456789') == 0 .and. len(strip(text)) > 0
    value = 0
    if (.not. ok) return
    read (text, *, iostat=ios) value
    ok = ios == 0
end subroutine parse_int

!> `path` with `$NAME` and `${NAME}` replaced by environment variables. Unset variables are left
!> as written.
function expand_vars(path) result(out)
    character(len=*), intent(in) :: path    !! the text
    character(len=:), allocatable :: out, name, value
    character(len=*), parameter :: NAME_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'
    integer :: i, j, n, stat
    logical :: braced

    out = ''
    i = 1
    do while (i <= len(path))
        if (path(i:i) /= '$') then
            out = out//path(i:i)
            i = i + 1
            cycle
        end if
        braced = .false.
        if (i < len(path)) braced = path(i + 1:i + 1) == '{'
        if (braced) then
            j = index(path(i + 2:), '}')
            if (j > 0) j = i + 1 + j
        else
            j = verify(path(i + 1:), NAME_CHARS)
            j = merge(len(path), i + j - 1, j == 0)
        end if
        if (j == 0 .or. j == i) then
            out = out//'$'
            i = i + 1
            cycle
        end if
        if (braced) then
            name = path(i + 2:j - 1)
        else
            name = path(i + 1:j)
        end if
        call get_environment_variable(name, length=n, status=stat)
        if (stat == 0) then
            allocate (character(len=n) :: value)
            call get_environment_variable(name, value)
            out = out//value
            deallocate (value)
        else
            out = out//path(i:j)
        end if
        i = j + 1
    end do
end function expand_vars

!> The absolute form of `path` relative to directory `base`, with variables expanded, links
!> resolved and `.` and `..` removed. The trailing components do not have to exist.
function resolve_path(base, path) result(out)
    character(len=*), intent(in) :: base    !! directory for relative paths
    character(len=*), intent(in) :: path    !! the path
    character(len=:), allocatable :: out, head, tail, real
    integer :: guard

    head = expand_vars(path)
    if (head(1:min(1, len(head))) /= '/') head = absolute_path(join_path(base, head))
    tail = ''
    do guard = 1, 4096
        real = real_path(head)
        if (len(real) > 0) exit
        if (head == '/' .or. len(head) == 0) then
            real = '/'
            exit
        end if
        if (len(tail) > 0) tail = '/'//tail
        tail = base_name(head)//tail
        head = parent_directory(head)
    end do
    out = lexical_clean(real//'/'//tail)
end function resolve_path

!> The part of `path` after its last `/`.
pure function base_name(path) result(name)
    character(len=*), intent(in) :: path    !! the path
    character(len=:), allocatable :: name
    name = path(index(path, '/', back=.true.) + 1:)
end function base_name

!> Remove empty, `.` and `..` components from absolute `path`.
function lexical_clean(path) result(out)
    character(len=*), intent(in) :: path    !! the path
    character(len=:), allocatable :: out
    type(string_t), allocatable :: parts(:), kept(:)
    integer :: k, n

    parts = split_on(path, '/')
    allocate (kept(size(parts)))
    n = 0
    do k = 1, size(parts)
        if (parts(k)%s == '' .or. parts(k)%s == '.') cycle
        if (parts(k)%s == '..') then
            n = max(0, n - 1)
            cycle
        end if
        n = n + 1
        kept(n)%s = parts(k)%s
    end do
    out = '/'//join(kept(1:n), '/')
end function lexical_clean

!> The `realpath` of `path`, or `''` if it does not exist.
function real_path(path) result(out)
    character(len=*), intent(in) :: path    !! the path
    character(len=:), allocatable :: out
    character(kind=c_char), pointer :: chars(:)
    type(c_ptr) :: p
    integer :: k, n

    p = c_realpath(path//c_null_char, c_null_ptr)
    if (.not. c_associated(p)) then
        out = ''
        return
    end if
    n = int(c_strlen(p))
    call c_f_pointer(p, chars, [n])
    allocate (character(len=n) :: out)
    do k = 1, n
        out(k:k) = chars(k)
    end do
    call c_free(p)
end function real_path

!> The current local time in a `strftime` format.
function strftime(format) result(out)
    character(len=*), intent(in) :: format  !! the format
    character(len=:), allocatable :: out
    character(len=*), parameter :: MONTHS(12) = [character(len=9) :: 'January', 'February', 'March', 'April', 'May', 'June', &
                                                 'July', 'August', 'September', 'October', 'November', 'December']
    character(len=*), parameter :: DAYS(0:6) = [character(len=9) :: 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', &
                                                'Friday', 'Saturday']
    character(len=32) :: buf
    integer :: t(8), i, off, yday, wday
    character :: c

    call date_and_time(values=t)
    yday = day_of_year(t(1), t(2), t(3))
    wday = weekday(t(1), t(2), t(3))
    out = ''
    i = 1
    do while (i <= len(format))
        c = format(i:i)
        if (c /= '%' .or. i == len(format)) then
            out = out//c
            i = i + 1
            cycle
        end if
        i = i + 1
        c = format(i:i)
        i = i + 1
        select case (c)
        case ('Y'); write (buf, '(i4.4)') t(1)
        case ('y'); write (buf, '(i2.2)') mod(t(1), 100)
        case ('m'); write (buf, '(i2.2)') t(2)
        case ('d'); write (buf, '(i2.2)') t(3)
        case ('H'); write (buf, '(i2.2)') t(5)
        case ('I'); write (buf, '(i2.2)') merge(12, mod(t(5), 12), mod(t(5), 12) == 0)
        case ('M'); write (buf, '(i2.2)') t(6)
        case ('S'); write (buf, '(i2.2)') t(7)
        case ('f'); write (buf, '(i6.6)') t(8)*1000
        case ('j'); write (buf, '(i3.3)') yday
        case ('p'); buf = merge('AM', 'PM', t(5) < 12)
        case ('B'); buf = MONTHS(t(2))
        case ('b'); buf = MONTHS(t(2)) (1:3)
        case ('A'); buf = DAYS(wday)
        case ('a'); buf = DAYS(wday) (1:3)
        case ('z')
            off = abs(t(4))
            write (buf, '(a,i2.2,i2.2)') merge('+', '-', t(4) >= 0), off/60, mod(off, 60)
        case ('%'); buf = '%'
        case default; buf = '%'//c
        end select
        out = out//trim(buf)
    end do
end function strftime

!> Day of the year of a date, from 1.
pure integer function day_of_year(y, m, d)
    integer, intent(in) :: y    !! the year
    integer, intent(in) :: m    !! the month, from 1
    integer, intent(in) :: d    !! the day of the month
    integer, parameter :: BEFORE(12) = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    logical :: leap
    leap = mod(y, 4) == 0 .and. (mod(y, 100) /= 0 .or. mod(y, 400) == 0)
    day_of_year = BEFORE(m) + d + merge(1, 0, leap .and. m > 2)
end function day_of_year

!> Day of the week of a date: 0 for Sunday.
pure integer function weekday(y, m, d)
    integer, intent(in) :: y    !! the year
    integer, intent(in) :: m    !! the month, from 1
    integer, intent(in) :: d    !! the day of the month
    integer, parameter :: T(12) = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    integer :: yy
    yy = merge(y - 1, y, m < 3)
    weekday = mod(yy + yy/4 - yy/100 + yy/400 + T(m) + d, 7)
end function weekday

end module fdoc_util
