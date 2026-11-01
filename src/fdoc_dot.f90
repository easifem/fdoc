module fdoc_dot
!! Laying out graphs with `dot`, in batches of files, so that a process does not have to start for
!! each graph.
use iso_c_binding, only: c_int
use fdoc_util
use fdoc_buffer
use fdoc_progress, only: progress_start, progress_tick, progress_finish
implicit none
private

public :: run_batches, file_name

integer, parameter :: BATCH = 25                        !! graphs for one `dot` process
integer(c_int), parameter :: POLL_MICROSECONDS = 2000   !! how often to look for finished batches

interface
    !> Sleep for a while.
    function c_usleep(microseconds) bind(c, name='usleep') result(status)
        import :: c_int
        integer(c_int), value :: microseconds   !! how long to sleep
        integer(c_int) :: status
    end function c_usleep
end interface

contains

!> The file of graph `k`.
pure function file_name(directory, k, suffix) result(path)
    character(len=*), intent(in) :: directory   !! the directory
    integer, intent(in) :: k                    !! the graph
    character(len=*), intent(in) :: suffix      !! what follows `.gv`
    character(len=len(directory) + 18 + len(suffix)) :: path

    path = directory//'/g'//trim(int_text(k))//'.gv'//suffix
end function file_name

!> Lay out `n` graphs, in batches, running up to `threads` processes at once. This uses a single
!> thread, as `execute_command_line` runs only one waiting command at a time on some systems. The
!> commands are started without waiting, and each writes a file in `directory` when it ends. Where
!> commands cannot be started without waiting, as on Windows, they run in turn with the same result.
!> A batch whose first graph has gone counts as ended, as another run has replaced the directory.
subroutine run_batches(directory, tag, n, threads)
    character(len=*), intent(in) :: directory   !! the directory
    character(len=*), intent(in) :: tag         !! what makes the names of this run's files unique
    integer, intent(in) :: n                    !! how many graphs there are
    integer, intent(in) :: threads              !! how many processes to run at once
    integer :: b, batches, started, finished, active
    integer(c_int) :: status
    logical :: ended, present
    logical, allocatable :: running(:)

    batches = (n + BATCH - 1)/BATCH
    allocate (running(batches), source=.false.)
    started = 0
    finished = 0
    active = 0
    call progress_start('Laying out graphs', n)
    do while (finished < batches)
        do while (started < batches .and. active < threads)
            started = started + 1
            running(started) = .true.
            active = active + 1
            call remove_file(trim(batch_file(directory, tag, started, 'done')))
            call start_dot(directory, tag, started, n)
        end do
        do b = 1, started
            if (.not. running(b)) cycle
            inquire (file=trim(batch_file(directory, tag, b, 'done')), exist=ended)
            inquire (file=trim(file_name(directory, (b - 1)*BATCH + 1, '')), exist=present)
            if (present .and. .not. ended) cycle
            running(b) = .false.
            active = active - 1
            finished = finished + 1
            call remove_file(trim(batch_file(directory, tag, b, 'done')))
            call remove_file(trim(batch_file(directory, tag, b, 'err')))
            call progress_tick(min(n, b*BATCH) - (b - 1)*BATCH)
        end do
        status = c_usleep(POLL_MICROSECONDS)
    end do
    call progress_finish()
end subroutine run_batches

!> Start batch `which` of `n` graphs. The command works in both `sh` and `cmd.exe`, and ends by
!> writing its file whether or not `dot` succeeds.
subroutine start_dot(directory, tag, which, n)
    character(len=*), intent(in) :: directory   !! the directory
    character(len=*), intent(in) :: tag         !! what makes the names of this run's files unique
    integer, intent(in) :: which                !! the batch
    integer, intent(in) :: n                    !! how many graphs there are
    type(buffer_t) :: b
    character(len=:), allocatable :: command
    character(len=:), allocatable :: done, errmsg
    integer :: k, status

    done = trim(batch_file(directory, tag, which, 'done'))
    call add(b, 'dot -Tsvg -O')
    do k = (which - 1)*BATCH + 1, min(n, which*BATCH)
        call add(b, ' "'//trim(file_name(directory, k, ''))//'"')
    end do
    call add(b, ' 2> "'//trim(batch_file(directory, tag, which, 'err'))//'" && echo ok> "'//done)
    call add(b, '" || echo failed> "'//done//'"')
    call take(b, command)
    call execute_command_line(command, wait=.false., cmdstat=status)
    if (status > 0) call write_whole_file(done, 'failed', status, errmsg)
end subroutine start_dot

!> The file of batch `which` with extension `suffix`.
pure function batch_file(directory, tag, which, suffix) result(path)
    character(len=*), intent(in) :: directory   !! the directory
    character(len=*), intent(in) :: tag         !! what makes the names of this run's files unique
    integer, intent(in) :: which                !! the batch
    character(len=*), intent(in) :: suffix      !! the extension
    character(len=len(directory) + len(tag) + 16 + len(suffix)) :: path

    path = directory//'/b'//trim(int_text(which))//'-'//tag//'.'//suffix
end function batch_file

end module fdoc_dot
