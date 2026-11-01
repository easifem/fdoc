module test_graphs
!! Graphs, from a small project on real files, through the whole program.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc, only: run
use fdoc_util, only: string_t, read_whole_file, write_whole_file
use fdoc_shell, only: make_directory, remove_directory
implicit none
private

public :: collect_graphs

! this test's own directory, as tests run in parallel
character(len=*), parameter :: ROOT = 'build/test graphs'
character(len=*), parameter :: NL = new_line('a')

contains

!> The tests of this module.
subroutine collect_graphs(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests

    testsuite = [new_unittest("drawn in pages", test_drawn)]
end subroutine collect_graphs

!> Checks: pages show drawings with links and labels, a cycle is drawn, and `graph_dir` keeps the graphs.
subroutine test_drawn(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    type(string_t) :: args(4)
    character(len=:), allocatable :: text, errmsg
    integer :: stat

    call remove_directory(ROOT)
    call make_directory(ROOT//'/src', stat)
    call write_whole_file(ROOT//'/ford.md', 'project: graphs'//NL//'src_dir: ./src'//NL//'output_dir: ./doc'//NL// &
                          'graph: true'//NL//NL//'The project.'//NL, stat, errmsg)
    call check(error, stat, 0, 'the project file')
    if (allocated(error)) return
    call write_whole_file(ROOT//'/src/a.f90', &
                          'module low'//NL//'type :: inner'//NL//'end type inner'//NL//'contains'//NL// &
                          'recursive subroutine ping()'//NL//'call pong()'//NL//'end subroutine ping'//NL// &
                          'recursive subroutine pong()'//NL//'call ping()'//NL//'end subroutine pong'//NL// &
                          'end module low'//NL//'module high'//NL//'use low'//NL//'type :: outer'//NL// &
                          'type(inner) :: part'//NL//'end type outer'//NL//'end module high'//NL, stat, errmsg)
    call check(error, stat, 0, 'the source')
    if (allocated(error)) return

    args(1)%s = '-q'
    args(2)%s = '--config'
    args(3)%s = "graph_dir='"//ROOT//"/kept'"
    args(4)%s = ROOT//'/ford.md'
    call check(error, run(args), 0, 'the run')
    if (allocated(error)) return

    call read_whole_file(ROOT//'/doc/module/high.html', text, stat, errmsg)
    call check(error, stat, 0, 'the page of a module')
    if (allocated(error)) return
    call check(error, index(text, '<svg') > 0, 'it has a drawing')
    if (allocated(error)) return
    call check(error, index(text, 'href="../module/low.html"') > 0, 'nodes link to their pages')
    if (allocated(error)) return
    call read_whole_file(ROOT//'/doc/type/outer.html', text, stat, errmsg)
    call check(error, stat, 0, 'the page of a type')
    if (allocated(error)) return
    call check(error, index(text, '>part</text>') > 0, 'a component labels its edge')
    if (allocated(error)) return
    call check(error, index(text, 'stroke-dasharray') > 0, 'and it is dashed')
    if (allocated(error)) return
    call read_whole_file(ROOT//'/doc/proc/ping.html', text, stat, errmsg)
    call check(error, stat, 0, 'the page of a procedure')
    if (allocated(error)) return
    call check(error, index(text, '>pong</text>') > 0, 'a cycle is drawn')
    call remove_directory(ROOT)
end subroutine test_drawn

end module test_graphs
