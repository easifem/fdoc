module test_parser
!! Reading entities and doc comments from source text.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc_model
use fdoc_parser, only: parse_file
use fdoc_project, only: project_t, prune
use fdoc_settings, only: settings_t, new_settings
use fdoc_util, only: join, lowercase
implicit none
private

public :: collect_parser

character, parameter :: NL = achar(10)

contains

!> The tests of this module.
subroutine collect_parser(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests
    testsuite = [ &
                new_unittest("doc comments after a statement", test_post_doc), &
                new_unittest("doc comments before a statement", test_pre_doc), &
                new_unittest("doc comments in a continued declaration", test_inline_doc), &
                new_unittest("a declaration of several names", test_several_names), &
                new_unittest("declaration attributes", test_attributes), &
                new_unittest("private by default", test_private_default), &
                new_unittest("public statements", test_public_statement), &
                new_unittest("function result types", test_function_result), &
                new_unittest("dummy arguments", test_arguments), &
                new_unittest("derived types and bindings", test_type), &
                new_unittest("interface blocks", test_interfaces), &
                new_unittest("metadata in doc comments", test_metadata), &
                new_unittest("labelled do loops", test_labelled_do), &
                new_unittest("several bindings on a line", test_several_bindings), &
                new_unittest("common blocks", test_common), &
                new_unittest("calls", test_calls), &
                new_unittest("calls through associate", test_associate_calls), &
                new_unittest("private modules stay visible", test_private_module), &
                new_unittest("variables share what they do not use", test_shared_part) &
                ]
end subroutine collect_parser

!> Parse `text` with default settings.
subroutine parse(text, list)
    character(len=*), intent(in) :: text        !! the source
    type(entity_list_t), intent(out) :: list    !! the entities
    type(settings_t) :: s
    s = new_settings()
    call parse_file('test.f90', text, s, list)
end subroutine parse

!> The index of the first entity of kind `kind` named `name`, or 0.
integer function find(list, kind, name)
    type(entity_list_t), intent(in) :: list !! the entities
    integer, intent(in) :: kind             !! one of the `E_*` constants
    character(len=*), intent(in) :: name    !! the name, in lowercase
    integer :: k

    find = 0
    do k = 1, list%n
        if (list%box(k)%e%kind /= kind) cycle
        if (lowercase(list%box(k)%e%name) == name) then
            find = k
            return
        end if
    end do
end function find

!> Checks: doc comments after a statement.
subroutine test_post_doc(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: m

    call parse('module m'//NL//'!! first'//NL//'!! second'//NL//'end module m'//NL, l)
    m = find(l, E_MODULE, 'm')
    call check(error, m > 0)
    if (allocated(error)) return
    call check(error, join(l%box(m)%e%doc, '|'), ' first| second')
end subroutine test_post_doc

!> Checks: a `private` statement hides what a module holds, not the module.
subroutine test_private_module(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(project_t) :: p
    integer :: m, x

    call parse('module m'//NL//'private'//NL//'integer :: x'//NL//'end module m'//NL, p%list)
    call prune(p, new_settings())
    m = find(p%list, E_MODULE, 'm')
    call check(error, m > 0)
    if (allocated(error)) return
    call check(error, p%list%box(m)%e%visible, 'the module is shown')
    if (allocated(error)) return
    x = find(p%list, E_VARIABLE, 'x')
    call check(error, x > 0)
    if (allocated(error)) return
    call check(error, .not. p%list%box(x)%e%visible, 'its private variable is not')
end subroutine test_private_module

!> Checks: parsing leaves the part that all variables share empty, and gives others their own.
subroutine test_shared_part(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: x, f

    call parse('module m'//NL//'integer :: x'//NL//'contains'//NL//'subroutine f(a)'//NL// &
               'integer :: a'//NL//'call g()'//NL//'end subroutine f'//NL//'end module m'//NL, l)
    x = find(l, E_VARIABLE, 'x')
    f = find(l, E_SUBROUTINE, 'f')
    call check(error, x > 0 .and. f > 0)
    if (allocated(error)) return
    call check(error, associated(l%box(x)%e%more, no_more), 'a variable uses the shared part')
    if (allocated(error)) return
    call check(error, .not. associated(l%box(f)%e%more, no_more), 'a procedure has its own')
    if (allocated(error)) return
    call check(error, allocated(l%box(f)%e%more%args), 'its arguments are in it')
    if (allocated(error)) return
    call check(error, .not. allocated(no_more%args) .and. .not. allocated(no_more%calls) .and. &
               .not. allocated(no_more%uses) .and. .not. allocated(no_more%pending), 'the shared part stays empty')
end subroutine test_shared_part

!> Checks: doc comments before a statement.
subroutine test_pre_doc(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: m, s

    call parse('module m'//NL//'contains'//NL//'!> before'//NL//'subroutine s'//NL//'!! after'//NL// &
               'end subroutine s'//NL//'end module m'//NL, l)
    m = find(l, E_MODULE, 'm')
    s = find(l, E_SUBROUTINE, 's')
    call check(error, size(l%box(m)%e%doc), 0, 'documentation of the next statement went to the module')
    if (allocated(error)) return
    call check(error, join(l%box(s)%e%doc, '|'), ' before| after')
end subroutine test_pre_doc

!> Checks: doc comments in a continued declaration.
subroutine test_inline_doc(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: v

    call parse('module m'//NL//'integer :: x = & !! one'//NL//'   1 !! two'//NL//'end module m'//NL, l)
    v = find(l, E_VARIABLE, 'x')
    call check(error, join(l%box(v)%e%doc, '|'), ' one| two')
    if (allocated(error)) return
    call check(error, l%box(v)%e%initial, '1')
end subroutine test_inline_doc

!> Checks: a declaration of several names.
subroutine test_several_names(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: a, b

    call parse('module m'//NL//'real(kind=8) :: a(3,2), b = 2.0 !! both'//NL//'end module m'//NL, l)
    a = find(l, E_VARIABLE, 'a')
    b = find(l, E_VARIABLE, 'b')
    call check(error, a > 0 .and. b > 0)
    if (allocated(error)) return
    call check(error, l%box(a)%e%dimension, '(3,2)')
    if (allocated(error)) return
    call check(error, l%box(a)%e%type_kind, '8')
    if (allocated(error)) return
    call check(error, join(l%box(b)%e%doc, '|'), ' both')
end subroutine test_several_names

!> Checks: declaration attributes.
subroutine test_attributes(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: v

    call parse('subroutine s(a)'//NL//'character(len=*,kind=c_char),intent(in),optional,dimension(:,:) :: a'//NL// &
               'end subroutine s'//NL, l)
    v = find(l, E_VARIABLE, 'a')
    associate (e => l%box(v)%e)
        call check(error, e%vartype, 'character')
        if (allocated(error)) return
        call check(error, e%strlen, '*')
        if (allocated(error)) return
        call check(error, e%type_kind, 'c_char')
        if (allocated(error)) return
        call check(error, e%intent, 'in')
        if (allocated(error)) return
        call check(error, e%optional)
        if (allocated(error)) return
        call check(error, join(e%attribs, '|'), 'dimension(:,:)')
    end associate
end subroutine test_attributes

!> Checks: private by default.
subroutine test_private_default(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l

    call parse('module m'//NL//'private'//NL//'integer :: a'//NL//'integer, public :: b'//NL//'contains'//NL// &
               'subroutine s'//NL//'end subroutine s'//NL//'end module m'//NL, l)
    call check(error, l%box(find(l, E_VARIABLE, 'a'))%e%permission, 'private')
    if (allocated(error)) return
    call check(error, l%box(find(l, E_VARIABLE, 'b'))%e%permission, 'public')
    if (allocated(error)) return
    call check(error, l%box(find(l, E_SUBROUTINE, 's'))%e%permission, 'private')
end subroutine test_private_default

!> Checks: public statements.
subroutine test_public_statement(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l

    call parse('module m'//NL//'private'//NL//'public :: s, a'//NL//'integer :: a'//NL//'contains'//NL// &
               'subroutine s'//NL//'end subroutine s'//NL//'end module m'//NL, l)
    call check(error, l%box(find(l, E_VARIABLE, 'a'))%e%permission, 'public')
    if (allocated(error)) return
    call check(error, l%box(find(l, E_SUBROUTINE, 's'))%e%permission, 'public')
end subroutine test_public_statement

!> Checks: function result types.
subroutine test_function_result(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: f, g

    call parse('pure integer(ik) function f(x) result(y)'//NL//'end function f'//NL// &
               'function g(x)'//NL//'real :: g'//NL//'end function g'//NL, l)
    f = find(l, E_FUNCTION, 'f')
    g = find(l, E_FUNCTION, 'g')
    call check(error, join(l%box(f)%e%attribs, '|'), 'pure')
    if (allocated(error)) return
    call check(error, l%box(l%box(f)%e%result)%e%name, 'y')
    if (allocated(error)) return
    call check(error, l%box(l%box(f)%e%result)%e%type_kind, 'ik')
    if (allocated(error)) return
    call check(error, l%box(l%box(g)%e%result)%e%vartype, 'real')
end subroutine test_function_result

!> Checks: dummy arguments.
subroutine test_arguments(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: s

    call parse('subroutine s(a, i)'//NL//'real :: a'//NL//'end subroutine s'//NL, l)
    s = find(l, E_SUBROUTINE, 's')
    associate (p => l%box(s)%e)
        call check(error, size(p%more%arg_ids), 2)
        if (allocated(error)) return
        call check(error, l%box(p%more%arg_ids(1))%e%var_role, VAR_ARGUMENT)
        if (allocated(error)) return
        call check(error, l%box(p%more%arg_ids(2))%e%vartype, 'integer', 'implicit typing')
    end associate
end subroutine test_arguments

!> Checks: derived types and bindings.
subroutine test_type(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: t, b, g

    call parse('module m'//NL//'type, extends(base), public :: t'//NL//'integer, private :: x'//NL//'contains'//NL// &
               'private'//NL//'procedure, public :: a => impl'//NL//'procedure :: b, c'//NL// &
               'generic, public :: g => a, b'//NL//'end type t'//NL//'end module m'//NL, l)
    t = find(l, E_TYPE, 't')
    call check(error, l%box(t)%e%more%extends, 'base')
    if (allocated(error)) return
    b = find(l, E_BOUNDPROC, 'a')
    call check(error, join(l%box(b)%e%more%bindings, '|'), 'impl')
    if (allocated(error)) return
    call check(error, l%box(b)%e%permission, 'public')
    if (allocated(error)) return
    call check(error, l%box(find(l, E_BOUNDPROC, 'c'))%e%permission, 'private')
    if (allocated(error)) return
    g = find(l, E_BOUNDPROC, 'g')
    call check(error, l%box(g)%e%generic)
    if (allocated(error)) return
    call check(error, join(l%box(g)%e%more%bindings, '|'), 'a|b')
end subroutine test_type

!> Checks: interface blocks.
subroutine test_interfaces(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: g, f, m

    call parse('module m'//NL//'interface g'//NL//'module procedure a, b'//NL//'end interface'//NL// &
               'abstract interface'//NL//'function f(x)'//NL//'real :: f, x'//NL//'end function f'//NL// &
               'end interface'//NL//'end module m'//NL, l)
    m = find(l, E_MODULE, 'm')
    g = find(l, E_INTERFACE, 'g')
    call check(error, join(l%box(g)%e%more%modprocs, '|'), 'a|b')
    if (allocated(error)) return
    f = find(l, E_FUNCTION, 'f')
    call check(error, l%box(f)%e%iface, IFACE_ABSTRACT)
    if (allocated(error)) return
    call check(error, l%box(f)%e%parent, m, 'the block dissolves into the module')
end subroutine test_interfaces

!> Checks: metadata in doc comments.
subroutine test_metadata(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: m

    call parse('module m'//NL//'!! author: me'//NL//'!! display: private'//NL//'!!'//NL//'!! Text'//NL// &
               'end module m'//NL, l)
    m = find(l, E_MODULE, 'm')
    call check(error, join(l%box(m)%e%doc, '|'), ' Text')
    if (allocated(error)) return
    call check(error, size(l%box(m)%e%meta), 2)
    if (allocated(error)) return
    call check(error, l%box(m)%e%display(1)%s, 'private')
end subroutine test_metadata

!> Checks: labelled do loops.
subroutine test_labelled_do(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: m, b

    call parse('module m'//NL//'contains'//NL//'subroutine a'//NL//'integer :: i'//NL//'do 10 i = 1, 2'//NL// &
               '10 continue'//NL//'end subroutine a'//NL//'subroutine b'//NL//'end subroutine b'//NL// &
               'end module m'//NL, l)
    m = find(l, E_MODULE, 'm')
    b = find(l, E_SUBROUTINE, 'b')
    call check(error, l%box(b)%e%parent, m, 'the loop must not keep the first subroutine open')
end subroutine test_labelled_do

!> Checks: several bindings on a line.
subroutine test_several_bindings(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l

    call parse('module m'//NL//'type :: t'//NL//'contains'//NL//'procedure :: a => x, b => y'//NL//'end type t'//NL// &
               'end module m'//NL, l)
    call check(error, join(l%box(find(l, E_BOUNDPROC, 'a'))%e%more%bindings, '|'), 'x')
    if (allocated(error)) return
    call check(error, join(l%box(find(l, E_BOUNDPROC, 'b'))%e%more%bindings, '|'), 'y')
end subroutine test_several_bindings

!> Checks: common blocks.
subroutine test_common(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: b

    call parse('module m'//NL//'real :: a, x(2)'//NL//'common /one/ a /two/ x(2)'//NL//'end module m'//NL, l)
    b = find(l, E_COMMON, 'two')
    call check(error, b > 0)
    if (allocated(error)) return
    call check(error, join(l%box(b)%e%more%args, '|'), 'x(2)')
    if (allocated(error)) return
    call check(error, l%box(find(l, E_VARIABLE, 'a'))%e%var_role, VAR_COMMON)
    if (allocated(error)) return
    call check(error, l%box(find(l, E_VARIABLE, 'x'))%e%var_role, VAR_COMMON)
end subroutine test_common

!> Checks: calls.
subroutine test_calls(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: s

    call parse('subroutine s(x)'//NL//'real :: y = f0(1)'//NL//"if (g(x) > 0) call a%b%c(h(1), 'k(2)')"//NL// &
               'go to (1, 2) i'//NL//'y = sin(x) + a(3)%d(4)'//NL//'call e'//NL//'end subroutine s'//NL, l)
    s = find(l, E_SUBROUTINE, 's')
    call check(error, join(l%box(s)%e%more%calls, ' '), 'a%b%c g h a%d e')
end subroutine test_calls

!> Checks: calls through associate.
subroutine test_associate_calls(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(entity_list_t) :: l
    integer :: s

    call parse('subroutine s(w)'//NL//'associate (e => w%e)'//NL//'associate (t => e%tmp(1:2))'//NL// &
               'y = t(1)'//NL//'end associate'//NL//'end associate'//NL//'y = t(1)'//NL// &
               'end subroutine s'//NL, l)
    s = find(l, E_SUBROUTINE, 's')
    call check(error, l%box(s)%e%more%calls(2)%s, 'w%e%tmp')
end subroutine test_associate_calls

end module test_parser
