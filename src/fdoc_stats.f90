module fdoc_stats
!! The size of source files: how many lines hold code, comments or nothing. This uses fformat's tokens,
!! so that a `!` in a string is not taken for a comment. It runs in parallel, so nothing here calls a
!! function returning a deferred-length string (see `example/slen_race.f90`).
use iso_fortran_env, only: int64
use ffmt_tokens, only: token_list_t, TK_SPACE, TK_NEWLINE, TK_COMMENT, TK_BOM
use ffmt_lexer, only: tokenize
implicit none
private

public :: file_stats_t, count_source, add_stats

type :: file_stats_t
    !! The size of a source file, or of several.
    integer :: lines = 0                !! all lines
    integer :: code = 0                 !! lines with code, which may also have a comment
    integer :: comments = 0             !! lines with only a comment
    integer :: blank = 0                !! lines with nothing
    integer :: procedures = 0           !! procedures defined in it
    integer(int64) :: bytes = 0         !! its size
end type file_stats_t

contains

!> Count the lines of `text`. A last line with no line ending counts as a line.
subroutine count_source(text, stats)
    character(len=*), intent(in) :: text    !! the source
    type(file_stats_t), intent(inout) :: stats  !! where the counts go
    type(token_list_t) :: tokens
    logical :: code, comment, open
    integer :: k

    stats%bytes = len(text, int64)
    call tokenize(text, tokens)
    code = .false.
    comment = .false.
    open = .false.
    do k = 1, tokens%n
        select case (tokens%tok(k)%kind)
        case (TK_NEWLINE)
            call end_line()
            cycle
        case (TK_COMMENT)
            comment = .true.
        case (TK_SPACE, TK_BOM)
            continue
        case default
            code = .true.
        end select
        open = .true.
    end do
    if (open) call end_line()

contains

    !> Count the line that ends here.
    subroutine end_line()

        stats%lines = stats%lines + 1
        if (code) then
            stats%code = stats%code + 1
        else if (comment) then
            stats%comments = stats%comments + 1
        else
            stats%blank = stats%blank + 1
        end if
        code = .false.
        comment = .false.
        open = .false.
    end subroutine end_line

end subroutine count_source

!> Add the counts of `item` to `total`.
pure subroutine add_stats(total, item)
    type(file_stats_t), intent(inout) :: total  !! the total
    type(file_stats_t), intent(in) :: item      !! what to add

    total%lines = total%lines + item%lines
    total%code = total%code + item%code
    total%comments = total%comments + item%comments
    total%blank = total%blank + item%blank
    total%procedures = total%procedures + item%procedures
    total%bytes = total%bytes + item%bytes
end subroutine add_stats

end module fdoc_stats
