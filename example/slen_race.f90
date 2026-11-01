module slen_race_module
!! Shows a gfortran 15 and 16 problem in valid code, best seen at `-O0`: the length of a deferred-length function result is
!! kept by the caller in static storage (`slen.N`, see `nm` on the object file), which threads share.
!!
!! An `intent(out)` deferred-length argument has no such variable. No compiler option or `recursive`
!! attribute helps. This is why functions returning `character(len=:), allocatable` must not be
!! called in parallel regions.
implicit none
private

public :: length_from_function, length_from_argument

contains

!> A string of `n` blanks, as a function result.
function blanks(n) result(text)
    integer, intent(in) :: n    !! the length wanted
    character(len=:), allocatable :: text
    allocate (character(len=n) :: text)
end function blanks

!> A string of `n` blanks, as an argument.
subroutine get_blanks(n, text)
    integer, intent(in) :: n                            !! the length wanted
    character(len=:), allocatable, intent(out) :: text  !! the string
    allocate (character(len=n) :: text)
end subroutine get_blanks

!> The length seen by the caller of [[blanks]]: `n`, unless another thread interfered.
integer function length_from_function(n)
    integer, intent(in) :: n    !! the length wanted
    length_from_function = len(blanks(n))
end function length_from_function

!> The length seen by the caller of [[get_blanks]]: always `n`.
integer function length_from_argument(n)
    integer, intent(in) :: n    !! the length wanted
    character(len=:), allocatable :: text
    call get_blanks(n, text)
    length_from_argument = len(text)
end function length_from_argument

end module slen_race_module

program slen_race
!! Counts wrong lengths for both forms. Run the debug build with `OMP_NUM_THREADS=8`, and expect some
!! for the function; in a release build it can be inlined, which hides the problem here.
use slen_race_module, only: length_from_function, length_from_argument
implicit none
integer :: i, n, function_errors, argument_errors

function_errors = 0
argument_errors = 0
!$omp parallel do schedule(dynamic, 64) private(n) reduction(+:function_errors, argument_errors)
do i = 1, 6000000
    n = mod(i*7, 4001) + 1
    if (length_from_function(n) /= n) function_errors = function_errors + 1
    if (length_from_argument(n) /= n) argument_errors = argument_errors + 1
end do
!$omp end parallel do
print '(a,i0,a,i0)', 'wrong lengths: function result ', function_errors, ', intent(out) argument ', argument_errors
end program slen_race
