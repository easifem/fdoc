program stress_parallel
!! Parallel read and parse, checked file by file against a serial run.
!!
!!     fpm test stress_parallel -- [--parallel-read] [--passes N] [--files-from LIST]
!!
!! Files are read serially unless `--parallel-read` is given. Without a list, the Fortran files under
!! `build/dependencies` are used. Set `OMP_NUM_THREADS` to choose the number of threads.
!!
!! This needs fformat 1.0.2 or later. Earlier releases call deferred-length functions while parsing,
!! which is not thread-safe (see `slen_race`).
use iso_fortran_env, only: int64, error_unit
use omp_lib, only: omp_get_max_threads
use ffmt_source, only: source_t, parse_source, statement_views
use ffmt_statements, only: statement_view_t
use ffmt_structure, only: analyze_structure, structure_t, diagnostic_t
use ffmt_io, only: read_file
use ffmt_walk, only: collect_files, default_extensions, default_exclude
use fdoc_util, only: string_t, push, strip
implicit none

type :: result_t
    !! What is compared between runs for one file.
    integer :: nbytes = -1              !! length of the file
    integer :: ntokens = -1             !! number of tokens
    integer :: nitems = -1              !! number of statements and standalone lines
    integer(int64) :: checksum = 0      !! checksum of the file's bytes
end type result_t

type(string_t), allocatable :: files(:), texts(:)
type(result_t), allocatable :: reference(:), got(:)
logical :: parallel_read
integer :: passes, pass, k, bad, total

call get_options(files, parallel_read, passes)
allocate (reference(size(files)), got(size(files)), texts(size(files)))
do k = 1, size(files)
    call read_one(files(k)%s, texts(k)%s)
    call parse_one(texts(k)%s, reference(k))
end do

total = 0
do pass = 1, passes
    if (parallel_read) then
        !$omp parallel do schedule(dynamic) default(shared)
        do k = 1, size(files)
            call read_and_parse(files(k)%s, got(k))
        end do
        !$omp end parallel do
    else
        !$omp parallel do schedule(dynamic) default(shared)
        do k = 1, size(files)
            call parse_one(texts(k)%s, got(k))
        end do
        !$omp end parallel do
    end if
    bad = 0
    do k = 1, size(files)
        if (same(reference(k), got(k))) cycle
        bad = bad + 1
        if (bad == 1) write (error_unit, '(a)') 'first mismatch: '//files(k)%s
    end do
    total = total + bad
end do
print '(a,i0,a,i0,a,i0,a,l1,a,i0)', 'files=', size(files), ' threads=', omp_get_max_threads(), ' passes=', passes, &
    ' parallel_read=', parallel_read, ' mismatches=', total
if (total > 0) error stop 'parallel results differ from serial results'

contains

!> Read the command line.
subroutine get_options(files, parallel_read, passes)
    type(string_t), allocatable, intent(out) :: files(:)    !! the files to use
    logical, intent(out) :: parallel_read                   !! true to read files inside the parallel loop
    integer, intent(out) :: passes                          !! how many times to repeat
    character(len=4096) :: arg
    character(len=:), allocatable :: list
    integer :: k, unit, ios

    parallel_read = .false.
    passes = 3
    k = 1
    do while (k <= command_argument_count())
        call get_command_argument(k, arg)
        select case (trim(arg))
        case ('--parallel-read')
            parallel_read = .true.
        case ('--passes')
            k = k + 1
            call get_command_argument(k, arg)
            read (arg, *) passes
        case ('--files-from')
            k = k + 1
            call get_command_argument(k, arg)
            list = trim(arg)
        case default
            error stop 'unknown option'
        end select
        k = k + 1
    end do

    if (allocated(list)) then
        allocate (files(0))
        open (newunit=unit, file=list, status='old', action='read')
        do
            read (unit, '(a)', iostat=ios) arg
            if (ios /= 0) exit
            call push(files, strip(arg))
        end do
        close (unit)
    else
        call collect_files('build/dependencies', default_extensions(), default_exclude(), files)
    end if
end subroutine get_options

!> Read a file, giving `''` if it cannot be read.
subroutine read_one(path, text)
    character(len=*), intent(in) :: path                !! the file
    character(len=:), allocatable, intent(out) :: text  !! its contents
    character(len=:), allocatable :: msg
    integer :: stat
    call read_file(path, text, stat, msg)
    if (stat /= 0) text = ''
end subroutine read_one

!> Read and parse a file.
subroutine read_and_parse(path, r)
    character(len=*), intent(in) :: path    !! the file
    type(result_t), intent(out) :: r        !! the result
    character(len=:), allocatable :: text
    call read_one(path, text)
    call parse_one(text, r)
end subroutine read_and_parse

!> Parse source text and summarize the result.
subroutine parse_one(text, r)
    character(len=*), intent(in) :: text    !! the source text
    type(result_t), intent(out) :: r        !! the result
    type(source_t) :: s
    type(structure_t) :: st
    type(diagnostic_t), allocatable :: diags(:)
    type(statement_view_t), allocatable :: views(:)
    integer :: k

    r%nbytes = len(text)
    r%checksum = 0
    do k = 1, len(text)
        r%checksum = mod(r%checksum*31_int64 + ichar(text(k:k)), 1000000007_int64)
    end do
    call parse_source(text, s)
    call analyze_structure(s, statement_views(s), st, diags)
    r%ntokens = s%tokens%n
    r%nitems = s%stmts%n
end subroutine parse_one

!> True if two results are equal.
logical function same(a, b)
    type(result_t), intent(in) :: a     !! one result
    type(result_t), intent(in) :: b     !! the other
    same = a%nbytes == b%nbytes .and. a%ntokens == b%ntokens .and. a%nitems == b%nitems .and. a%checksum == b%checksum
end function same

end program stress_parallel
