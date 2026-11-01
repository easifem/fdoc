program io_race
!! Shows a problem in libgfortran 16: threads doing file I/O crash, although no unit or file is shared.
!! Each thread writes and reads back files of its own, in standard Fortran.
!!
!! Run it a few hundred times, from an empty directory `d`. On macOS arm64 with gfortran 16.2, about one
!! run in 20 ends in a segmentation fault in `check_for_recursive`, called from `data_transfer_init`.
!! With one thread, it does not crash.
use omp_lib
implicit none
integer, parameter :: FILES = 4000
character(len=*), parameter :: DIR = 'd'
character(len=2000) :: payload
integer :: k
payload = repeat('x', 2000)
!$omp parallel do schedule(dynamic) private(k) shared(payload)
do k = 1, FILES
    call one(k)
end do
!$omp end parallel do
print *, 'ok'
contains

!> Write and read back file `k`.
subroutine one(k)
    integer, intent(in) :: k    !! the file
    character(len=32) :: path
    character(len=2000) :: back
    integer :: u, s
    path = ''
    call name(k, path)
    open (newunit=u, file=trim(path), access='stream', form='unformatted', status='replace', iostat=s)
    if (s /= 0) error stop 'open'
    write (u) payload
    close (u)
    open (newunit=u, file=trim(path), access='stream', form='unformatted', status='old', action='read', iostat=s)
    if (s /= 0) error stop 'reopen'
    read (u) back
    close (u, status='delete')
    if (back /= payload) error stop 'mismatch'
end subroutine one

!> The name of file `k`, made without an internal write.
subroutine name(k, path)
    integer, intent(in) :: k                !! the file
    character(len=*), intent(out) :: path   !! its name
    integer :: n, at
    character(len=12) :: d
    d = ''
    at = 12
    n = k
    do
        d(at:at) = achar(48 + mod(n, 10))
        n = n/10
        at = at - 1
        if (n == 0) exit
    end do
    path = DIR//'/f'//d(at + 1:)
end subroutine name
end program io_race
