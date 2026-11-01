module fdoc_highlight
!! Syntax highlighting of Fortran, from fformat's tokens. Classes: `k` keywords and intrinsics,
!! `c` comments, `d` doc comments, `s` strings, `n` numbers, `p` preprocessor lines.
use ffmt_tokens, only: token_list_t, TK_COMMENT, TK_PREPROC, TK_NAME, TK_INT, TK_REAL, TK_STRING, TK_BOZ, TK_DOTOP
use ffmt_lexer, only: tokenize
use fdoc_buffer
use fdoc_util, only: lowercase
use fdoc_intrinsics, only: is_intrinsic
implicit none
private

public :: highlight_fortran

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

!> Write the anchor of line `line`.
subroutine line_start(out, line)
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(in) :: line             !! the line
    character(len=12) :: number

    write (number, '(i0)') line
    call add(out, '<a class="ln" id="ln-'//trim(number)//'" href="#ln-'//trim(number)//'"></a>')
end subroutine line_start

end module fdoc_highlight
