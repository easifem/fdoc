module fdoc_svg
!! Making the drawings of `dot` smaller, without changing what they show. This runs in parallel, so
!! it uses no internal `read` or `write` statements, which take a lock.
use iso_fortran_env, only: real64
use fdoc_util
use fdoc_buffer
implicit none
private

public :: slim_svg

character(len=*), parameter, public :: FONT_SIZE = '13'         !! points, of the names in a graph
character(len=*), parameter, public :: EDGE_COLOUR = '#8a93a5'  !! the colour of most edges

contains

!> The value of attribute `name` in `line`, or `''`.
pure subroutine attribute(line, name, value)
    character(len=*), intent(in) :: line                !! the element
    character(len=*), intent(in) :: name                !! the attribute
    character(len=:), allocatable, intent(out) :: value !! its value
    integer :: at, close

    value = ''
    at = index(line, ' '//name//'="')
    if (at == 0) return
    at = at + len(name) + 3
    close = index(line(at:), '"')
    if (close > 0) value = line(at:at + close - 2)
end subroutine attribute

!> Append `text` with its numbers rounded to one decimal.
pure subroutine rounded(text, b)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: b      !! where it goes
    integer :: i, j, k, start, tenths, status

    i = 1
    start = 1
    do while (i <= len(text))
        if (.not. is_digit(text(i:i))) then
            i = i + 1
            cycle
        end if
        j = end_of_digits(text, i)
        if (j >= len(text)) then
            i = j
            cycle
        else if (text(j:j) /= '.') then
            i = j
            cycle
        end if
        k = end_of_digits(text, j + 1)
        if (i > start) call add(b, text(start:i - 1))
        call digits_value(text(i:j - 1), tenths, status)
        tenths = tenths*10
        if (k > j + 1) tenths = tenths + iachar(text(j + 1:j + 1)) - iachar('0')
        if (k > j + 2) then
            if (text(j + 2:j + 2) >= '5') tenths = tenths + 1
        end if
        call add(b, trim(int_text(tenths/10)))
        if (mod(tenths, 10) /= 0) then
            call add(b, '.')
            call add(b, achar(iachar('0') + mod(tenths, 10)))
        end if
        i = k
        start = k
    end do
    if (start <= len(text)) call add(b, text(start:))
end subroutine rounded

!> Where the digits of `text` starting at `from` end: the position after the last one.
pure integer function end_of_digits(text, from)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: from             !! where to start
    integer :: k

    k = from
    do while (k <= len(text))
        if (.not. is_digit(text(k:k))) exit
        k = k + 1
    end do
    end_of_digits = k
end function end_of_digits

!> The extent of the points in path data `d`.
subroutine path_box(d, left, top, right, bottom)
    character(len=*), intent(in) :: d   !! the path data
    real, intent(out) :: left           !! the smallest x
    real, intent(out) :: top            !! the smallest y
    real, intent(out) :: right          !! the largest x
    real, intent(out) :: bottom         !! the largest y
    character(len=*), parameter :: DIGITS = '0123456789.-'
    real :: value
    logical :: is_x
    integer :: i, j

    left = huge(left)
    top = huge(top)
    right = -huge(right)
    bottom = -huge(bottom)
    is_x = .true.
    i = 1
    do while (i <= len(d))
        if (scan(d(i:i), DIGITS) == 0) then
            i = i + 1
            cycle
        end if
        j = i
        do while (j < len(d))
            if (scan(d(j + 1:j + 1), DIGITS) == 0) exit
            j = j + 1
        end do
        call parse_real(d(i:j), value)
        if (is_x) then
            left = min(left, value)
            right = max(right, value)
        else
            top = min(top, value)
            bottom = max(bottom, value)
        end if
        is_x = .not. is_x
        i = j + 1
    end do
end subroutine path_box

!> The value of `text`, a decimal number. Internal `read` and `write` statements are avoided here, as
!> they take a lock that threads end up spending most of their time on.
pure subroutine parse_real(text, value)
    character(len=*), intent(in) :: text    !! the number
    real, intent(out) :: value              !! its value
    real(real64) :: digits, scale
    logical :: negative, fraction
    integer :: k

    digits = 0
    scale = 1
    negative = .false.
    fraction = .false.
    do k = 1, len(text)
        select case (text(k:k))
        case ('-')
            negative = .true.
        case ('.')
            fraction = .true.
        case default
            digits = 10*digits + (iachar(text(k:k)) - iachar('0'))
            if (fraction) scale = 10*scale
        end select
    end do
    value = real(digits/scale)
    if (negative) value = -value
end subroutine parse_real

!> Write a real with one decimal, rounded like the format `f0.1`: a tie goes to the even digit.
pure subroutine real_text(value, b)
    real, intent(in) :: value           !! the value
    type(buffer_t), intent(inout) :: b  !! where it goes
    real(real64) :: exact, rest
    integer :: tenths

    exact = 10*abs(real(value, real64))
    tenths = floor(exact)
    rest = exact - tenths
    if (rest > 0.5_real64) then
        tenths = tenths + 1
    else if (rest == 0.5_real64 .and. mod(tenths, 2) == 1) then
        tenths = tenths + 1
    end if
    if (value < 0) call add(b, '-')
    call add(b, trim(int_text(tenths/10)))
    call add(b, '.')
    call add(b, achar(iachar('0') + mod(tenths, 10)))
end subroutine real_text

!> Rewrite a drawing from `dot` to draw the same thing in fewer bytes: the boxes of nodes become
!> rectangles, what most elements share goes on the group around them, and comments, ids and titles
!> that nothing shows are left out. Coordinates keep one decimal, a tenth of a point.
subroutine slim_svg(svg, out)
    character(len=*), intent(in) :: svg                 !! the drawing
    character(len=:), allocatable, intent(out) :: out   !! the result
    type(string_t), allocatable :: lines(:)
    character(len=:), allocatable :: fill, stroke, width, dash, data, x, y, size, href
    type(buffer_t) :: b
    logical :: dropped(0:16), in_link
    real :: left, top, right, bottom
    integer :: k, depth, at

    allocate (character(len=len(svg)) :: b%s)
    lines = split_lines(svg)
    depth = 0
    dropped = .false.
    in_link = .false.
    do k = 1, size_of(lines)
        associate (line => lines(k)%s)
            if (starts_with(line, '<!--') .or. starts_with(line, '<title>')) then
                cycle
            else if (starts_with(line, '<g id="node') .or. starts_with(line, '<g id="edge')) then
                depth = min(depth + 1, 16)
                dropped(depth) = .true.
            else if (starts_with(line, '<g id="a_')) then
                depth = min(depth + 1, 16)
                dropped(depth) = .true.
                call attribute(line, 'xlink:href', href)
                if (len(href) > 0) then
                    call add(b, '<a href="'//href//'" fill="white" stroke="none">')
                    in_link = .true.
                else
                    call add(b, '<a>')
                end if
            else if (starts_with(line, '<g ')) then
                depth = min(depth + 1, 16)
                dropped(depth) = .false.
                at = index(line, 'transform=')
                call add(b, '<g '//line(at:len(line) - 1)//' fill="none" stroke="'//EDGE_COLOUR// &
                         '" font-family="Helvetica,sans-Serif" font-size="'//FONT_SIZE//'" text-anchor="middle">')
            else if (line == '</g>') then
                if (.not. dropped(depth)) call add(b, line)
                depth = max(depth - 1, 0)
            else if (line == '</a>') then
                in_link = .false.
                call add(b, line)
            else if (starts_with(line, '<path ')) then
                call attribute(line, 'fill', fill)
                call attribute(line, 'stroke', stroke)
                call attribute(line, 'stroke-width', width)
                call attribute(line, 'stroke-dasharray', dash)
                call attribute(line, 'd', data)
                if (fill /= 'none') then
                    call path_box(data, left, top, right, bottom)
                    call add(b, '<rect fill="'//fill//'"')
                    if (stroke /= 'none' .or. .not. in_link) call add(b, ' stroke="'//stroke//'"')
                    if (len(width) > 0) call add(b, ' stroke-width="'//width//'"')
                    call add(b, ' rx="7.2" x="')
                    call real_text(left, b)
                    call add(b, '" y="')
                    call real_text(top, b)
                    call add(b, '" width="')
                    call real_text(right - left, b)
                    call add(b, '" height="')
                    call real_text(bottom - top, b)
                    call add(b, '"/>')
                else
                    call add(b, '<path')
                    if (stroke /= EDGE_COLOUR) call add(b, ' stroke="'//stroke//'"')
                    if (len(width) > 0) call add(b, ' stroke-width="'//width//'"')
                    if (len(dash) > 0) call add(b, ' stroke-dasharray="'//dash//'"')
                    call add(b, ' d="')
                    call rounded(data, b)
                    call add(b, '"/>')
                end if
            else if (starts_with(line, '<polygon ')) then
                call attribute(line, 'fill', fill)
                call attribute(line, 'stroke', stroke)
                if (fill == 'none' .and. stroke == 'none') cycle
                call attribute(line, 'points', data)
                call add(b, '<polygon fill="'//fill//'"')
                if (stroke /= EDGE_COLOUR) call add(b, ' stroke="'//stroke//'"')
                call add(b, ' points="')
                call rounded(data, b)
                call add(b, '"/>')
            else if (starts_with(line, '<text ')) then
                call attribute(line, 'x', x)
                call attribute(line, 'y', y)
                call attribute(line, 'font-size', size)
                call attribute(line, 'fill', fill)
                call add(b, '<text x="')
                call rounded(x, b)
                call add(b, '" y="')
                call rounded(y, b)
                call add(b, '"')
                if (size /= FONT_SIZE//'.00') call add(b, ' font-size="'//size//'"')
                if (fill /= 'white' .or. .not. in_link) call add(b, ' fill="'//fill//'"')
                call add(b, line(index(line, '>'):))
            else
                call add(b, line)
                if (k < 3) call add(b, achar(10))
            end if
        end associate
    end do
    call take(b, out)
end subroutine slim_svg

!> The number of strings in `lines`.
pure integer function size_of(lines)
    type(string_t), intent(in) :: lines(:)  !! the strings
    size_of = size(lines)
end function size_of

end module fdoc_svg
