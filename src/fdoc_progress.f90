module fdoc_progress
!! Progress in the terminal: a live bar for each stage of the run, leaving a line with its time, and
!! warnings that do not get mixed up with the bar. When standard output is not a terminal there are
!! no bars or colours, just a line for each stage.
!!
!! Stages run in parallel loops. Any thread can count, and only the first draws. Nothing here calls a
!! function returning a deferred-length string (see `example/slen_race.f90`).
use iso_fortran_env, only: output_unit, error_unit, int64
use iso_c_binding, only: c_int
use omp_lib, only: omp_get_thread_num
implicit none
private

public :: progress_enable, progress_start, progress_tick, progress_finish, progress_summary, warn, bar_text

interface
    !> C `isatty`.
    function c_isatty(fd) bind(c, name='isatty') result(tty)
        import :: c_int
        integer(c_int), value :: fd     !! the file descriptor
        integer(c_int) :: tty
    end function c_isatty
end interface

character(len=*), parameter :: ESC = achar(27)
character(len=*), parameter :: FULL = achar(226)//achar(148)//achar(129)    !! `━`, in UTF-8
character(len=*), parameter :: EMPTY = achar(226)//achar(148)//achar(128)   !! `─`, in UTF-8
integer, parameter :: LABEL_WIDTH = 24
integer, parameter :: BAR_WIDTH = 30
integer(int64), parameter :: REDRAW_MILLISECONDS = 40

logical :: enabled = .false.            !! true to report progress
logical :: live = .false.               !! true if standard output is a terminal
logical :: colour = .false.             !! true to use colours
logical :: drawn = .false.              !! true if a bar is on the screen
character(len=LABEL_WIDTH) :: label = ' '   !! the current stage
integer :: total = 0                    !! how many steps the stage has
integer :: done = 0                     !! how many are finished
integer(int64) :: stage_start = 0       !! when the stage started
integer(int64) :: run_start = 0         !! when the run started
integer(int64) :: last_draw = 0         !! when the bar was last drawn
integer(int64) :: rate = 1000           !! clock ticks in a second

contains

!> Turn progress reports on.
subroutine progress_enable()
    integer :: n, stat

    enabled = .true.
    live = c_isatty(1_c_int) == 1
    call get_environment_variable('NO_COLOR', length=n, status=stat)
    colour = live .and. stat /= 0
    call system_clock(run_start, rate)
end subroutine progress_enable

!> Start stage `name`, of `steps` steps, or of unknown length if that is 0.
subroutine progress_start(name, steps)
    character(len=*), intent(in) :: name    !! the stage
    integer, intent(in) :: steps            !! how many steps it has

    if (.not. enabled) return
    label = name
    total = steps
    done = 0
    call system_clock(stage_start)
    last_draw = stage_start
    if (live) call draw()
end subroutine progress_start

!> Count a step, or `steps` of them. This can be called from any thread.
subroutine progress_tick(steps)
    integer, intent(in), optional :: steps  !! how many steps
    integer(int64) :: now
    integer :: amount

    if (.not. enabled) return
    amount = 1
    if (present(steps)) amount = steps
    !$omp atomic
    done = done + amount
    if (.not. live .or. omp_get_thread_num() /= 0) return
    call system_clock(now)
    if ((now - last_draw)*1000 < REDRAW_MILLISECONDS*rate) return
    last_draw = now
    !$omp critical (file_io)
    call draw()
    !$omp end critical (file_io)
end subroutine progress_tick

!> Finish the stage, leaving its line.
subroutine progress_finish()
    character(len=24) :: time
    character(len=16) :: count_text
    integer(int64) :: now

    if (.not. enabled) return
    call system_clock(now)
    call seconds_text(now - stage_start, time)
    write (count_text, '(i0)') total
    if (live) then
        done = total
        call draw()
        write (output_unit, '(a)', advance='no') ' '//trim(time)
        write (output_unit, '(a)') ''
    else if (total > 0) then
        write (output_unit, '(a)') '  '//label//' '//trim(count_text)//' in '//trim(time)
    else
        write (output_unit, '(a)') '  '//label//' '//trim(time)
    end if
    drawn = .false.
    flush (output_unit)
end subroutine progress_finish

!> Report the end of the run.
subroutine progress_summary(message)
    character(len=*), intent(in) :: message !! what was done
    character(len=24) :: time
    integer(int64) :: now

    if (.not. enabled) return
    call system_clock(now)
    call seconds_text(now - run_start, time)
    if (colour) then
        write (output_unit, '(a)') ESC//'[1;32m'//message//' in '//trim(time)//ESC//'[0m'
    else
        write (output_unit, '(a)') message//' in '//trim(time)
    end if
end subroutine progress_summary

!> Write warning `message` to standard error, keeping the bar intact. This can be called from any
!> thread.
subroutine warn(message)
    character(len=*), intent(in) :: message !! the warning

    !$omp critical (file_io)
    if (drawn) write (output_unit, '(a)', advance='no') achar(13)//ESC//'[2K'
    if (drawn) flush (output_unit)
    write (error_unit, '(a)') 'Warning: '//message
    flush (error_unit)
    if (drawn) call draw()
    !$omp end critical (file_io)
end subroutine warn

!> `ticks` of the clock as text.
subroutine seconds_text(ticks, text)
    integer(int64), intent(in) :: ticks     !! the time
    character(len=*), intent(out) :: text   !! the text

    write (text, '(f0.2,a)') real(ticks)/real(rate), ' s'
    if (text(1:1) == '.') text = '0'//text
end subroutine seconds_text

!> The bar for `steps` of `size` steps, `width` characters wide, with its filled and empty parts.
pure subroutine bar_text(steps, size, width, filled, unfilled, percent)
    integer, intent(in) :: steps        !! how many steps are done
    integer, intent(in) :: size         !! how many there are
    integer, intent(in) :: width        !! the width of the bar
    integer, intent(out) :: filled      !! how much of the bar is filled
    integer, intent(out) :: unfilled    !! how much of it is not
    integer, intent(out) :: percent     !! the percentage done

    filled = width
    percent = 100
    if (size > 0) then
        filled = int(min(1.0, real(steps)/real(size))*width)
        percent = int(min(1.0, real(steps)/real(size))*100)
    end if
    unfilled = width - filled
end subroutine bar_text

!> Draw the bar of the current stage.
subroutine draw()
    character(len=64) :: numbers
    integer :: filled, unfilled, percent, k

    write (output_unit, '(a)', advance='no') achar(13)//ESC//'[2K  '//label
    if (total > 0) then
        call bar_text(done, total, BAR_WIDTH, filled, unfilled, percent)
        if (colour) write (output_unit, '(a)', advance='no') ESC//'[36m'
        do k = 1, filled
            write (output_unit, '(a)', advance='no') FULL
        end do
        if (colour) write (output_unit, '(a)', advance='no') ESC//'[2m'
        do k = 1, unfilled
            write (output_unit, '(a)', advance='no') EMPTY
        end do
        if (colour) write (output_unit, '(a)', advance='no') ESC//'[0m'
        write (numbers, '(1x,i3,a,2x,i0,a,i0)') percent, '%', min(done, total), '/', total
        write (output_unit, '(a)', advance='no') trim(numbers)
    end if
    flush (output_unit)
    drawn = .true.
end subroutine draw

end module fdoc_progress
