module fdoc_buffer
!! Building text piece by piece, without functions returning deferred-length strings, so that it can be
!! used in parallel regions (see `example/slen_race.f90`).
implicit none
private

public :: buffer_t, add, take, html_escape

type :: buffer_t
    !! Text being built.
    character(len=:), allocatable :: s      !! storage; only `s(1:n)` is in use
    integer :: n = 0                        !! length of the text
end type buffer_t

contains

!> Append `text` to `b`.
pure subroutine add(b, text)
    type(buffer_t), intent(inout) :: b      !! the buffer
    character(len=*), intent(in) :: text    !! the text
    character(len=:), allocatable :: grown
    integer :: capacity

    if (.not. allocated(b%s)) allocate (character(len=max(256, 2*len(text))) :: b%s)
    capacity = len(b%s)
    if (b%n + len(text) > capacity) then
        allocate (character(len=max(2*capacity, b%n + len(text))) :: grown)
        grown(1:b%n) = b%s(1:b%n)
        call move_alloc(grown, b%s)
    end if
    b%s(b%n + 1:b%n + len(text)) = text
    b%n = b%n + len(text)
end subroutine add

!> Move the text of `b` to `text`.
pure subroutine take(b, text)
    type(buffer_t), intent(inout) :: b                  !! the buffer
    character(len=:), allocatable, intent(out) :: text  !! its text

    if (allocated(b%s)) then
        text = b%s(1:b%n)
    else
        text = ''
    end if
    b%n = 0
end subroutine take

!> Append `text`, escaped for HTML.
pure subroutine html_escape(text, b, quotes)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: b      !! the buffer
    logical, intent(in) :: quotes           !! true to escape `"` as well, for attribute values
    integer :: k, start

    start = 1
    do k = 1, len(text)
        select case (text(k:k))
        case ('&', '<', '>', '"')
            if (text(k:k) == '"' .and. .not. quotes) cycle
            if (k > start) call add(b, text(start:k - 1))
            start = k + 1
            select case (text(k:k))
            case ('&'); call add(b, '&amp;')
            case ('<'); call add(b, '&lt;')
            case ('>'); call add(b, '&gt;')
            case default; call add(b, '&quot;')
            end select
        end select
    end do
    if (start <= len(text)) call add(b, text(start:))
end subroutine html_escape

end module fdoc_buffer
