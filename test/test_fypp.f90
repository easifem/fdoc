module test_fypp
!! The port of Fypp.
use omp_lib, only: omp_get_thread_num
use testdrive, only: new_unittest, unittest_type, error_type, check
use ffmt_io, only: write_file
use fdoc_buffer, only: int_text
use fdoc_fypp, only: fypp_process
use fdoc_shell, only: make_directory
use fdoc_util, only: string_t
implicit none
private

public :: collect_fypp

character, parameter :: NL = achar(10)
character(len=*), parameter :: DIRECTORY = 'build/test_fypp'

contains

!> The tests of this module.
subroutine collect_fypp(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests

    testsuite = [ &
                new_unittest("evaluation", test_eval), &
                new_unittest("Python expressions", test_expressions), &
                new_unittest("control directives", test_control), &
                new_unittest("macros", test_macros), &
                new_unittest("blocks, comments and mute", test_blocks), &
                new_unittest("line continuation", test_continuation), &
                new_unittest("folding", test_folding), &
                new_unittest("errors", test_errors) &
                ]
end subroutine collect_fypp

!> Process `source`, as `MAXRANK` is set to 3.
subroutine run(source, output, stat, errmsg)
    character(len=*), intent(in) :: source                  !! the text
    character(len=:), allocatable, intent(out) :: output    !! the output
    integer, intent(out) :: stat                            !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg    !! what is wrong
    type(string_t) :: defines(1), includes(0)
    character(len=12) :: thread

    ! tests run in parallel, so each thread has its own file
    thread = int_text(omp_get_thread_num())
    defines(1)%s = 'MAXRANK=3'
    call make_directory(DIRECTORY, stat)
    !$omp critical (file_io)
    call write_file(DIRECTORY//'/a'//trim(thread)//'.fypp', source, stat, errmsg)
    !$omp end critical (file_io)
    if (stat /= 0) return
    call fypp_process(DIRECTORY//'/a'//trim(thread)//'.fypp', defines, includes, output, stat, errmsg)
end subroutine run

!> Check that `source` gives `expected`.
subroutine expect(error, source, expected)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=*), intent(in) :: source                  !! the text
    character(len=*), intent(in) :: expected                !! the output
    character(len=:), allocatable :: output, errmsg
    integer :: stat

    call run(source, output, stat, errmsg)
    call check(error, stat, 0, errmsg)
    if (allocated(error)) return
    call check(error, output, expected)
end subroutine expect

!> Check that `source` fails, naming `message`.
subroutine expect_failure(error, source, message)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=*), intent(in) :: source                  !! the text
    character(len=*), intent(in) :: message                 !! part of the message
    character(len=:), allocatable :: output, errmsg
    integer :: stat

    call run(source, output, stat, errmsg)
    call check(error, stat /= 0, 'this should fail: '//source)
    if (allocated(error)) return
    call check(error, index(errmsg, message) > 0, errmsg)
end subroutine expect_failure

!> Checks: evaluation directives.
subroutine test_eval(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any

    call expect(error, 'a ${MAXRANK}$ b'//NL, 'a 3 b'//NL)
    if (allocated(error)) return
    call expect(error, '$:MAXRANK + 1'//NL//'x', '4'//NL//'x')
    if (allocated(error)) return
    call expect(error, '${None}$|${"s"}$|${[1, "a"]}$|${(1,)}$|${True}$', '|s|[1, ''a'']|(1,)|True')
end subroutine test_eval

!> Checks: the Python that is supported.
subroutine test_expressions(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any

    call expect(error, '${[i*2 for i in range(1, 4) if i != 2]}$', '[2, 6]')
    if (allocated(error)) return
    call expect(error, '${",".join(f"i{j}" for j in range(MAXRANK))}$', 'i0,i1,i2')
    if (allocated(error)) return
    call expect(error, '${"{0}_{1}".format("a", 1)}$ ${"{}{}".format(1, 2)}$', 'a_1 12')
    if (allocated(error)) return
    call expect(error, '${list(zip(["a", "b"], [1, 2]))}$', '[(''a'', 1), (''b'', 2)]')
    if (allocated(error)) return
    call expect(error, '${"abc"[0:2]}$ ${[1, 2, 3][:-1]}$ ${[1, 2][-1]}$ ${len(2*[""])}$', 'ab [1, 2] 2 2')
    if (allocated(error)) return
    call expect(error, '${1 if "a" in "cat" and 2 not in [1] else 0}$', '1')
    if (allocated(error)) return
    call expect(error, '${dict([(1, "x")]).get(1, ":")}$ ${dict([(1, "x")]).get(2, ":")}$', 'x :')
    if (allocated(error)) return
    call expect(error, '${"char(a)".startswith("char")}$ ${list(reversed([1, 2]))}$', 'True [2, 1]')
    if (allocated(error)) return
    call expect(error, '${defined("MAXRANK")}$ ${defined("OTHER")}$', 'True False')
    if (allocated(error)) return
    call expect(error, '${"-".join(x.strip() for x in " a\n b ".split("\n"))}$', 'a-b')
end subroutine test_expressions

!> Checks: conditions, loops and assignments.
subroutine test_control(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any

    call expect(error, '#:if MAXRANK > 5'//NL//'a'//NL//'#:elif MAXRANK == 3'//NL//'b'//NL//'#:else'//NL// &
                'c'//NL//'#:endif'//NL, 'b'//NL)
    if (allocated(error)) return
    call expect(error, '#:for a, b in [(1, 2, 3), (4, 5, 6)]'//NL//'${a}$${b}$'//NL//'#:endfor'//NL, &
                '12'//NL//'45'//NL)
    if (allocated(error)) return
    call expect(error, '#{for i in range(3)}#${i}$#{if i < 2}#,#{endif}##{endfor}#', '0,1,2')
    if (allocated(error)) return
    call expect(error, '#:set a, b = 1, 2'//NL//'#:set c'//NL//'${a + b}$${c}$', '3')
end subroutine test_control

!> Checks: macros.
subroutine test_macros(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any

    call expect(error, '#:def f(a, b=2, c=" "*2)'//NL//'${a}$${c}$${b}$'//NL//'#:enddef'//NL// &
                '${f(1)}$ ${f(1, c="-")}$ ${f(1, 3)}$', '1  2 1-2 1  3')
    if (allocated(error)) return
    call expect(error, '#:set i = 9'//NL//'#:def g(i)'//NL//'$:i'//NL//'#:enddef'//NL// &
                '${[g(j) for j in [1, 2]]}$ ${i}$', '[''1'', ''2''] 9')
end subroutine test_macros

!> Checks: block calls, comments and muted output.
subroutine test_blocks(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any

    call expect(error, '#:def w(code, p)'//NL//'<${p}$>${code}$'//NL//'#:enddef'//NL// &
                '#:block w(p=1)'//NL//'body'//NL//'#:endblock'//NL, '<1>body'//NL)
    if (allocated(error)) return
    call expect(error, '#:def w(txt, s="")'//NL//'${txt}$${s}$'//NL//'#:enddef'//NL// &
                '#:call w(s=")")'//NL//'(a'//NL//'#:endcall'//NL, '(a)'//NL)
    if (allocated(error)) return
    call expect(error, 'a'//NL//'#! gone'//NL//'  #! gone too'//NL//'b'//NL, 'a'//NL//'b'//NL)
    if (allocated(error)) return
    call expect(error, '#:mute'//NL//'x'//NL//'#:set a = 1'//NL//'#:endmute'//NL//'${a}$', '1')
end subroutine test_blocks

!> Checks: directives over several lines, and comments in them.
subroutine test_continuation(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any

    call expect(error, '#:set a = [1, &'//NL//'  & 2, &'//NL//'    3]'//NL//'${a}$', '[1, 2, 3]')
    if (allocated(error)) return
    call expect(error, '#:for i in [1] # a comment'//NL//'$:i'//NL//'#:endfor'//NL, '1'//NL)
end subroutine test_continuation

!> Checks: long lines are folded only if they hold something evaluated.
subroutine test_folding(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=*), parameter :: LONG = repeat('x', 140)

    call expect(error, LONG//NL, LONG//NL)
    if (allocated(error)) return
    call expect(error, '${"a"}$'//LONG//NL, 'a'//repeat('x', 130)//'&'//NL//'    &'//repeat('x', 10)//NL)
    if (allocated(error)) return
    call expect(error, '  ! ${"a"}$'//LONG//NL, '  ! a'//LONG//NL)
    if (allocated(error)) return
    call expect(error, '${"a"}$'//repeat('y', 100)//' '//repeat('z', 40)//NL, &
                'a'//repeat('y', 100)//'&'//NL//'    & '//repeat('z', 40)//NL)
end subroutine test_folding

!> Checks: what is not supported is reported, not ignored.
subroutine test_errors(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any

    call expect_failure(error, '#:stop "x"'//NL, 'stop')
    if (allocated(error)) return
    call expect_failure(error, '@:f()'//NL, 'direct calls')
    if (allocated(error)) return
    call expect_failure(error, '${sum([1])}$', 'sum')
    if (allocated(error)) return
    call expect_failure(error, '${"a".upper()}$', 'upper')
    if (allocated(error)) return
    call expect_failure(error, '${undefined_name}$', 'undefined_name')
    if (allocated(error)) return
    call expect_failure(error, '#:if True'//NL, 'not closed')
    if (allocated(error)) return
    call expect_failure(error, '#:assert 1 == 2'//NL, 'assertion failed')
end subroutine test_errors

end module test_fypp
