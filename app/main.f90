program main
!! The `fdoc` command. See [[fdoc]].
use fdoc, only: run
use fdoc_util, only: string_t
implicit none

type(string_t), allocatable :: args(:)
integer :: k, n, status

allocate (args(command_argument_count()))
do k = 1, size(args)
    call get_command_argument(k, length=n)
    allocate (character(len=n) :: args(k)%s)
    call get_command_argument(k, args(k)%s)
end do

status = run(args)
if (status /= 0) stop status, quiet = .true.
end program main
