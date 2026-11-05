module fdoc_highlight
!! Syntax highlighting of Fortran, from fformat's tokens. Classes: `k` keywords and intrinsics,
!! `c` comments, `d` doc comments, `s` strings, `n` numbers, `p` preprocessor lines.
!!
!! JSON and TOML get a simple scan of their own, with the same classes: `k` keys, `s` strings, `n`
!! numbers, dates and literals such as `true`, `p` TOML table headers and `c` TOML comments.
use ffmt_tokens, only: token_list_t, TK_COMMENT, TK_PREPROC, TK_NAME, TK_INT, TK_REAL, TK_STRING, TK_BOZ, TK_DOTOP
use ffmt_lexer, only: tokenize
use fdoc_buffer
use fdoc_util, only: lowercase
use fdoc_intrinsics, only: is_intrinsic
implicit none
private

public :: highlight_fortran, highlight_data

contains

!> Write `code` as highlighted HTML. With `line_anchors`, each line starts with an anchor `ln-N`.
subroutine highlight_fortran(code, out, line_anchors)
    character(len=*), intent(in) :: code    !! the source
    type(buffer_t), intent(inout) :: out    !! the HTML
    logical, intent(in) :: line_anchors     !! true to number the lines
    type(token_list_t) :: tokens
    character(len=:), allocatable :: class
    integer :: k, line

    call tokenize(code, tokens)
    line = 1
    if (line_anchors) call line_start(out, line)
    do k = 1, tokens%n
        associate (t => tokens%tok(k))
            class = ''
            select case (t%kind)
            case (TK_COMMENT)
                class = 'c'
                if (t%last > t%first) then
                    if (scan(code(t%first + 1:t%first + 1), '!<>|*') == 1) class = 'd'
                end if
            case (TK_PREPROC)
                class = 'p'
            case (TK_STRING)
                class = 's'
            case (TK_INT, TK_REAL, TK_BOZ)
                class = 'n'
            case (TK_DOTOP)
                class = 'k'
            case (TK_NAME)
                if (is_intrinsic(lowercase(code(t%first:t%last)))) class = 'k'
            end select
            if (len(class) > 0) call add(out, '<span class="'//class//'">')
            call write_text(code(t%first:t%last))
            if (len(class) > 0) call add(out, '</span>')
        end associate
    end do

contains

    !> Write token text, starting a new numbered line at each line feed.
    subroutine write_text(text)
        character(len=*), intent(in) :: text    !! the text
        integer :: start, at

        if (.not. line_anchors) then
            call html_escape(text, out, .false.)
            return
        end if
        start = 1
        do
            at = index(text(start:), achar(10))
            if (at == 0) exit
            call html_escape(text(start:start + at - 1), out, .false.)
            start = start + at
            line = line + 1
            call line_start(out, line)
        end do
        call html_escape(text(start:), out, .false.)
    end subroutine write_text

end subroutine highlight_fortran

!> Write `code`, JSON or TOML, as highlighted HTML. A key is a string followed by `:` in JSON, and what
!> comes before `=` at the start of a line or after `{` or `,` in TOML.
subroutine highlight_data(code, toml, out)
    character(len=*), intent(in) :: code    !! the text
    logical, intent(in) :: toml             !! true for TOML, false for JSON
    type(buffer_t), intent(inout) :: out    !! the HTML
    character(len=*), parameter :: BARE = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-'
    character(len=*), parameter :: NUMBER = '0123456789abcdefABCDEFxXoO_.:+-TZ'
    logical :: key_next
    integer :: i, j, n

    n = len(code)
    i = 1
    key_next = .true.
    do while (i <= n)
        select case (code(i:i))
        case (achar(10))
            call add(out, achar(10))
            key_next = .true.
            i = i + 1
        case (' ', achar(9), achar(13))
            call add(out, code(i:i))
            i = i + 1
        case ('#')
            if (.not. toml) then
                call plain(i, i)
                cycle
            end if
            j = line_end(i)
            call span('c', i, j)
            i = j + 1
        case ('"', "'")
            if (code(i:i) == "'" .and. .not. toml) then
                call plain(i, i)
                cycle
            end if
            j = string_end(i)
            if (is_key(j)) then
                call span('k', i, j)
            else
                call span('s', i, j)
            end if
            key_next = .false.
            i = j + 1
        case ('[')
            ! a table header starts a line, and runs to the last `]` before a comment
            if (toml .and. key_next .and. line_start(i)) then
                j = header_end(i)
                call span('p', i, j)
                i = j + 1
                key_next = .false.
            else
                call plain(i, i)
            end if
        case ('{', ',')
            call plain(i, i)
            key_next = toml
        case ('0':'9', '+', '-')
            j = i
            do while (j < n)
                if (index(NUMBER, code(j + 1:j + 1)) == 0) exit
                j = j + 1
            end do
            if (toml .and. key_next .and. is_key(j)) then
                call span('k', i, j)
            else
                call span('n', i, j)
            end if
            key_next = .false.
            i = j + 1
        case default
            if (index(BARE, code(i:i)) == 0) then
                call plain(i, i)
                cycle
            end if
            j = i
            do while (j < n)
                if (index(BARE//'.', code(j + 1:j + 1)) == 0) exit
                j = j + 1
            end do
            if (toml .and. key_next .and. is_key(j)) then
                call span('k', i, j)
            else if (literal(code(i:j))) then
                call span('n', i, j)
            else
                call html_escape(code(i:j), out, .false.)
            end if
            key_next = .false.
            i = j + 1
        end select
    end do

contains

    !> Write `code(first:last)` as it is.
    subroutine plain(first, last)
        integer, intent(in) :: first    !! where it starts
        integer, intent(in) :: last     !! where it ends

        call html_escape(code(first:last), out, .false.)
        i = last + 1
        key_next = .false.
    end subroutine plain

    !> Write `code(first:last)` in class `class`.
    subroutine span(class, first, last)
        character(len=*), intent(in) :: class   !! the class
        integer, intent(in) :: first            !! where it starts
        integer, intent(in) :: last             !! where it ends

        call add(out, '<span class="'//class//'">')
        call html_escape(code(first:last), out, .false.)
        call add(out, '</span>')
    end subroutine span

    !> The end of the line at `at`, before its line feed.
    pure integer function line_end(at)
        integer, intent(in) :: at   !! a position in the line

        line_end = index(code(at:), achar(10))
        if (line_end == 0) then
            line_end = n
        else
            line_end = at + line_end - 2
        end if
    end function line_end

    !> True if only blanks come before `at` on its line.
    pure logical function line_start(at)
        integer, intent(in) :: at   !! the position

        integer :: k

        line_start = .true.
        do k = at - 1, 1, -1
            if (code(k:k) == achar(10)) return
            if (code(k:k) /= ' ' .and. code(k:k) /= achar(9)) then
                line_start = .false.
                return
            end if
        end do
    end function line_start

    !> The end of the string that starts at `at`: three quotes in TOML end three, and in a basic string
    !> a backslash escapes the next character. An unfinished string ends with its line.
    pure integer function string_end(at)
        integer, intent(in) :: at   !! where it starts
        character :: quote
        integer :: k

        quote = code(at:at)
        if (toml .and. at + 2 <= n) then
            if (code(at:at + 2) == repeat(quote, 3)) then
                k = index(code(at + 3:), repeat(quote, 3))
                string_end = n
                if (k > 0) string_end = at + 2 + k + 2
                return
            end if
        end if
        k = at + 1
        do while (k <= n)
            if (code(k:k) == achar(10)) then
                string_end = k - 1
                return
            end if
            if (code(k:k) == '\' .and. quote == '"') then
                k = k + 2
                cycle
            end if
            if (code(k:k) == quote) then
                string_end = k
                return
            end if
            k = k + 1
        end do
        string_end = n
    end function string_end

    !> True if what ends at `last` is a key: the next character that is not a blank is `:` in JSON, and
    !> `=` or a `.` of a dotted key in TOML.
    pure logical function is_key(last)
        integer, intent(in) :: last     !! where it ends
        integer :: k

        is_key = .false.
        if (toml .and. .not. key_next) return
        do k = last + 1, n
            if (code(k:k) == ' ' .or. code(k:k) == achar(9)) cycle
            if (toml) then
                is_key = code(k:k) == '=' .or. code(k:k) == '.'
            else
                is_key = code(k:k) == ':'
            end if
            return
        end do
    end function is_key

    !> The end of the table header that starts at `at`.
    pure integer function header_end(at)
        integer, intent(in) :: at   !! where it starts
        integer :: k, last

        last = line_end(at)
        header_end = last
        k = index(code(at:last), ']', back=.true.)
        if (k > 0) header_end = at + k - 1
    end function header_end

    !> True if `word` is a literal of the format.
    pure logical function literal(word)
        character(len=*), intent(in) :: word    !! the word

        select case (word)
        case ('true', 'false', 'inf', 'nan')
            literal = word /= 'inf' .and. word /= 'nan' .or. toml
        case ('null')
            literal = .not. toml
        case default
            literal = .false.
        end select
    end function literal

end subroutine highlight_data

!> Write the anchor of line `line`.
subroutine line_start(out, line)
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(in) :: line             !! the line
    character(len=12) :: number

    number = int_text(line)
    call add(out, '<a class="ln" id="ln-'//trim(number)//'" href="#ln-'//trim(number)//'"></a>')
end subroutine line_start

end module fdoc_highlight
