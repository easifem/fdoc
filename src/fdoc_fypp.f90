module fdoc_fypp
!! A port to Fortran of the parts of Fypp, the preprocessor by Bálint Aradi, that the Fortran standard
!! library needs, so that fdoc can read Fypp sources without running Python.
!!
!! Fypp's directives hold Python expressions. A small evaluator here covers the ones in use: literals,
!! lists, tuples, comprehensions, f-strings, slices, conditional expressions, and the functions and
!! string methods listed in [[call_builtin]] and [[call_method]]. Anything else stops with an error
!! that names it, and is left for later, as are the directives `del`, `global`, `stop`, `nextarg` and
!! `contains`, direct calls with `@:` and `@{...}@`, and line numbering.
!!
!! All state is in a [[fypp_t]] made for each file, so that files can be processed in parallel. As in
!! the rest of fdoc, no function returns a deferred-length string (see `example/slen_race.f90`).
!!
!! Fypp is Copyright (c) 2016-2023 Bálint Aradi, Universität Bremen, and is distributed under the
!! BSD 2-clause license. This port follows its design and keeps its notice:
!!
!! Redistribution and use in source and binary forms, with or without modification, are permitted
!! provided that the following conditions are met:
!!
!! 1. Redistributions of source code must retain the above copyright notice, this list of conditions
!!    and the following disclaimer.
!! 2. Redistributions in binary form must reproduce the above copyright notice, this list of
!!    conditions and the following disclaimer in the documentation and/or other materials provided
!!    with the distribution.
!!
!! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
!! IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
!! FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
!! CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
!! DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
!! DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
!! IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
!! OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
use fdoc_buffer, only: buffer_t, add, take
use fdoc_util, only: string_t, name_index_t, index_find, index_set, file_read
implicit none
private

public :: fypp_process

character, parameter :: NL = achar(10)
character, parameter :: TAB = achar(9)

integer, parameter :: MAX_LINE = 132    !! Fypp's default longest line
integer, parameter :: FOLD_INDENT = 4   !! Fypp's default indentation of continuation lines
integer, parameter :: MAX_FRAMES = 256  !! how deeply scopes can nest

! kinds of value
integer, parameter :: V_NONE = 0, V_BOOL = 1, V_INT = 2, V_STR = 3, V_LIST = 4, V_TUPLE = 5, V_DICT = 6, V_MACRO = 7

! kinds of token
integer, parameter :: T_END = 0, T_NAME = 1, T_INT = 2, T_STR = 3, T_FSTR = 4, T_OP = 5

! kinds of expression
integer, parameter :: E_CONST = 1, E_NAME = 2, E_LIST = 3, E_TUPLE = 4, E_ADD = 5, E_SUB = 6, E_MUL = 7, E_NEG = 8
integer, parameter :: E_NOT = 9, E_AND = 10, E_OR = 11, E_COMPARE = 12, E_IF = 13, E_CALL = 14, E_METHOD = 15
integer, parameter :: E_INDEX = 16, E_SLICE = 17, E_COMP = 18, E_CLAUSE = 19, E_FSTRING = 20

! comparisons
integer, parameter :: C_EQ = 1, C_NE = 2, C_LT = 3, C_GT = 4, C_LE = 5, C_GE = 6, C_IN = 7, C_NOT_IN = 8

! kinds of node of the document
integer, parameter :: N_TEXT = 1, N_EVAL = 2, N_IF = 3, N_FOR = 4, N_SET = 5, N_DEF = 6, N_CALL = 7
integer, parameter :: N_MUTE = 8, N_ASSERT = 9

type :: value_t
    !! A Python value.
    integer :: kind = V_NONE                !! what it is
    integer :: number = 0                   !! the integer, the truth of a bool, or the macro
    character(len=:), allocatable :: text   !! the string
    type(value_t), allocatable :: items(:)  !! the items of a list or tuple, or a dict's keys and values in turn
contains
    procedure, private :: copy_value
    generic :: assignment(=) => copy_value  !! a deep copy, which gfortran gets wrong for a recursive type
end type value_t

type :: expr_t
    !! An expression, compiled.
    integer :: kind = 0                     !! what it is
    integer :: a = 0                        !! the first operand
    integer :: b = 0                        !! the second operand
    integer :: c = 0                        !! the third operand
    integer :: name = 0                     !! the name
    integer, allocatable :: args(:)         !! the operands of a list, call or comprehension
    integer, allocatable :: names(:)        !! keywords of `args`, 0 if none, or the targets of a loop
    integer, allocatable :: ops(:)          !! the comparisons
    character(len=:), allocatable :: text   !! the method
    type(value_t) :: value                  !! the constant
end type expr_t

type :: scan_t
    !! Reading an expression.
    character(len=:), allocatable :: text   !! the expression
    integer :: pos = 1                      !! where the next token starts
    integer :: kind = T_END                 !! the kind of the current token
    character(len=:), allocatable :: word   !! the current token
    integer :: number = 0                   !! the value of an integer token
end type scan_t

type :: body_t
    !! The nodes of a block.
    integer, allocatable :: ids(:)          !! the nodes
    integer :: n = 0                        !! how many there are
end type body_t

type :: block_t
    !! The parts of a directive.
    integer, allocatable :: conds(:)        !! the conditions of each body, 0 for `else`
    integer, allocatable :: targets(:)      !! the variables assigned
    integer, allocatable :: args(:)         !! the arguments of a call
    integer, allocatable :: keywords(:)     !! keywords of `args`, 0 if none
    type(body_t), allocatable :: bodies(:)  !! the blocks
end type block_t

type :: node_t
    !! A piece of the document.
    integer :: kind = 0                     !! what it is
    logical :: on_lines = .false.           !! true for line directives, which end their line
    integer :: expr = 0                     !! the expression
    integer :: name = 0                     !! the macro
    character(len=:), allocatable :: text   !! the text
    character(len=:), allocatable :: source !! the expression as written, for messages
    type(block_t), allocatable :: block     !! what only directives have, as most nodes are text
end type node_t

type :: macro_t
    !! A macro.
    integer :: node = 0                         !! its definition
    integer, allocatable :: params(:)           !! its arguments
    logical, allocatable :: has_default(:)      !! whether each has a default
    type(value_t), allocatable :: defaults(:)   !! the defaults
    integer, allocatable :: captured(:)         !! the local variables at its definition
    type(value_t), allocatable :: values(:)     !! their values
end type macro_t

type :: frame_t
    !! Local variables.
    integer, allocatable :: ids(:)              !! the names
    type(value_t), allocatable :: values(:)     !! the values
    integer :: n = 0                            !! how many there are
    integer :: up = 0                           !! the frame whose variables are also seen, or 0
end type frame_t

type :: span_t
    !! Where a result of evaluation is in the output.
    integer :: first = 0                        !! the position before it
    integer :: last = 0                         !! its last position
end type span_t

type :: fypp_t
    !! The state of processing a file.
    character(len=:), allocatable :: error      !! what went wrong, once something has
    type(string_t), allocatable :: includes(:)  !! where to look for included files
    type(string_t), allocatable :: names(:)     !! the names seen
    integer :: num_names = 0                    !! how many there are
    type(expr_t), allocatable :: exprs(:)       !! the expressions
    integer :: num_exprs = 0                    !! how many there are
    type(name_index_t) :: compiled              !! the expression for each text, as texts repeat a lot
    type(node_t), allocatable :: nodes(:)       !! the nodes
    integer :: num_nodes = 0                    !! how many there are
    integer :: root = 0                         !! the node holding the document
    integer :: stack(MAX_FRAMES) = 0            !! the blocks open while parsing
    integer :: depth = 0                        !! how many there are
    type(value_t), allocatable :: globals(:)    !! the global variable for each name
    logical, allocatable :: is_set(:)           !! whether each one is set
    type(frame_t), allocatable :: frames(:)     !! the local scopes
    integer :: frame = 0                        !! the current one, or 0
    type(macro_t), allocatable :: macros(:)     !! the macros
    integer :: num_macros = 0                   !! how many there are
    integer, allocatable :: bound(:)            !! the names bound by running comprehensions
    type(value_t), allocatable :: bound_values(:) !! their values
    integer :: num_bound = 0                    !! how many there are
    integer :: first_bound = 1                  !! the first that the code being run can see
    type(span_t), allocatable :: spans(:)       !! the results of evaluation in the output
    integer :: num_spans = 0                    !! how many there are
end type fypp_t

contains

!> The output of Fypp for file `path`. Each of `defines` is `NAME` or `NAME=expression`.
subroutine fypp_process(path, defines, includes, text, stat, errmsg)
    character(len=*), intent(in) :: path                    !! the file
    type(string_t), intent(in) :: defines(:)                !! the variables to set
    type(string_t), intent(in) :: includes(:)               !! where to look for included files
    character(len=:), allocatable, intent(out) :: text      !! the output
    integer, intent(out) :: stat                            !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg    !! what is wrong
    type(fypp_t) :: c
    type(value_t) :: v
    type(buffer_t) :: out
    character(len=:), allocatable :: rendered
    integer, allocatable :: names(:), values(:)
    integer :: k, at

    stat = 0
    text = ''
    errmsg = ''
    c%includes = includes
    allocate (c%names(256), c%exprs(1024), c%nodes(1024), c%frames(MAX_FRAMES), c%macros(32))
    allocate (c%bound(32), c%bound_values(32), c%spans(1024))
    allocate (names(size(defines)), values(size(defines)))
    do k = 1, size(defines)
        at = index(defines(k)%s, '=')
        values(k) = 0
        if (at == 0) then
            call intern(c, trim(adjustl(defines(k)%s)), names(k))
        else
            call intern(c, trim(adjustl(defines(k)%s(:at - 1))), names(k))
            call compile(c, defines(k)%s(at + 1:), values(k))
        end if
    end do
    c%root = new_node(c, 0)
    call add_body(c, c%root, 0)
    call parse_file(c, path)
    if (.not. allocated(c%error) .and. c%depth /= 0) c%error = 'a block is not closed'
    if (allocated(c%error)) then
        stat = 1
        errmsg = c%error
        return
    end if
    allocate (c%globals(c%num_names), c%is_set(c%num_names))
    c%is_set = .false.
    do k = 1, size(defines)
        if (values(k) > 0) then
            call evaluate(c, values(k), v)
        else
            v = value_t()
        end if
        c%globals(names(k)) = v
        c%is_set(names(k)) = .true.
    end do
    call render_body(c, c%nodes(c%root)%block%bodies(1), out, .true.)
    if (allocated(c%error)) then
        stat = 1
        errmsg = c%error
        return
    end if
    call take(out, rendered)
    call fold_output(c, rendered, text)
end subroutine fypp_process

!> Copy a value, with what it holds.
recursive elemental subroutine copy_value(to, from)
    class(value_t), intent(inout) :: to     !! the copy
    type(value_t), intent(in) :: from       !! the value
    integer :: k

    to%kind = from%kind
    to%number = from%number
    if (allocated(to%text)) deallocate (to%text)
    if (allocated(to%items)) deallocate (to%items)
    if (allocated(from%text)) to%text = from%text
    if (allocated(from%items)) then
        allocate (to%items(size(from%items)))
        do k = 1, size(from%items)
            call copy_value(to%items(k), from%items(k))
        end do
    end if
end subroutine copy_value

!> Copy `from` to the new array `to`.
pure subroutine copy_items(from, to)
    type(value_t), intent(in) :: from(:)                !! the values
    type(value_t), allocatable, intent(out) :: to(:)    !! the copies
    integer :: k

    allocate (to(size(from)))
    do k = 1, size(from)
        call copy_value(to(k), from(k))
    end do
end subroutine copy_items

!> Record the first problem.
subroutine fail(c, message)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: message     !! what went wrong

    if (.not. allocated(c%error)) c%error = message
end subroutine fail

!> The number of name `name`, added if it is new.
subroutine intern(c, name, id)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: name        !! the name
    integer, intent(out) :: id                  !! its number
    type(string_t), allocatable :: grown(:)
    integer :: k

    id = find_name(c, name)
    if (id > 0) return
    if (c%num_names == size(c%names)) then
        allocate (grown(2*c%num_names))
        do k = 1, c%num_names
            call move_alloc(c%names(k)%s, grown(k)%s)
        end do
        call move_alloc(grown, c%names)
    end if
    c%num_names = c%num_names + 1
    c%names(c%num_names)%s = name
    id = c%num_names
end subroutine intern

!> The number of name `name`, or 0.
pure integer function find_name(c, name) result(id)
    type(fypp_t), intent(in) :: c               !! the state
    character(len=*), intent(in) :: name        !! the name
    integer :: k

    id = 0
    do k = 1, c%num_names
        if (len(c%names(k)%s) /= len(name)) cycle
        if (c%names(k)%s == name) then
            id = k
            return
        end if
    end do
end function find_name

! ----------------------------------------------------------------------------------------------------
! Reading expressions
! ----------------------------------------------------------------------------------------------------

!> True if `ch` can start a name.
elemental logical function starts_name(ch)
    character, intent(in) :: ch     !! the character
    starts_name = (ch >= 'a' .and. ch <= 'z') .or. (ch >= 'A' .and. ch <= 'Z') .or. ch == '_'
end function starts_name

!> True if `ch` is a digit.
elemental logical function is_digit(ch)
    character, intent(in) :: ch     !! the character
    is_digit = ch >= '0' .and. ch <= '9'
end function is_digit

!> True if `ch` can be part of a name.
elemental logical function in_name(ch)
    character, intent(in) :: ch     !! the character
    in_name = starts_name(ch) .or. is_digit(ch)
end function in_name

!> True if `ch` is a blank or a tab.
elemental logical function is_blank(ch)
    character, intent(in) :: ch     !! the character
    is_blank = ch == ' ' .or. ch == TAB
end function is_blank

!> Go to the next token.
subroutine next_token(c, s)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer :: n, start
    character :: ch

    n = len(s%text)
    do while (s%pos <= n)
        ch = s%text(s%pos:s%pos)
        if (ch == '#') then
            do while (s%pos <= n)
                if (s%text(s%pos:s%pos) == NL) exit
                s%pos = s%pos + 1
            end do
        else if (is_blank(ch) .or. ch == NL) then
            s%pos = s%pos + 1
        else
            exit
        end if
    end do
    s%word = ''
    if (s%pos > n) then
        s%kind = T_END
        return
    end if
    ch = s%text(s%pos:s%pos)
    start = s%pos
    if (ch == '"' .or. ch == "'") then
        s%kind = T_STR
        call read_string(c, s)
    else if ((ch == 'f' .or. ch == 'F') .and. s%pos < n) then
        if (s%text(s%pos + 1:s%pos + 1) == '"' .or. s%text(s%pos + 1:s%pos + 1) == "'") then
            s%pos = s%pos + 1
            s%kind = T_FSTR
            call read_string(c, s)
        else
            call read_name(s)
        end if
    else if (starts_name(ch)) then
        call read_name(s)
    else if (is_digit(ch)) then
        s%kind = T_INT
        s%number = 0
        do while (s%pos <= n)
            if (.not. is_digit(s%text(s%pos:s%pos))) exit
            s%number = 10*s%number + iachar(s%text(s%pos:s%pos)) - iachar('0')
            s%pos = s%pos + 1
        end do
    else
        s%kind = T_OP
        s%pos = s%pos + 1
        if (s%pos <= n) then
            if (s%text(s%pos:s%pos) == '=' .and. index('=!<>', ch) > 0) s%pos = s%pos + 1
        end if
        s%word = s%text(start:s%pos - 1)
    end if
end subroutine next_token

!> Read a name.
pure subroutine read_name(s)
    type(scan_t), intent(inout) :: s    !! the expression
    integer :: start

    start = s%pos
    do while (s%pos <= len(s%text))
        if (.not. in_name(s%text(s%pos:s%pos))) exit
        s%pos = s%pos + 1
    end do
    s%kind = T_NAME
    s%word = s%text(start:s%pos - 1)
end subroutine read_name

!> Read a string in quotes, undoing its escapes.
subroutine read_string(c, s)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    type(buffer_t) :: b
    character :: quote, ch

    quote = s%text(s%pos:s%pos)
    s%pos = s%pos + 1
    do
        if (s%pos > len(s%text)) then
            call fail(c, 'a string is not closed: '//s%text)
            return
        end if
        ch = s%text(s%pos:s%pos)
        s%pos = s%pos + 1
        if (ch == quote) exit
        if (ch == '\' .and. s%pos <= len(s%text)) then
            ch = s%text(s%pos:s%pos)
            s%pos = s%pos + 1
            if (ch == 'n') ch = NL
            if (ch == 't') ch = TAB
        end if
        call add(b, ch)
    end do
    call take(b, s%word)
end subroutine read_string

!> True if the current token is `word`, as an operator or keyword.
pure logical function at_word(s, word)
    type(scan_t), intent(in) :: s           !! the expression
    character(len=*), intent(in) :: word    !! the word

    at_word = .false.
    if (s%kind /= T_OP .and. s%kind /= T_NAME) return
    if (len(s%word) /= len(word)) return
    at_word = s%word == word
end function at_word

!> Go past token `word`, which must come next.
subroutine expect(c, s, word)
    type(fypp_t), intent(inout) :: c        !! the state
    type(scan_t), intent(inout) :: s        !! the expression
    character(len=*), intent(in) :: word    !! the token

    if (at_word(s, word)) then
        call next_token(c, s)
    else
        call fail(c, "expected '"//word//"' in: "//s%text)
    end if
end subroutine expect

!> A new expression.
integer function new_expr(c, kind, a, b, third) result(id)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: kind         !! what it is
    integer, intent(in), optional :: a  !! the first operand
    integer, intent(in), optional :: b  !! the second operand
    integer, intent(in), optional :: third  !! the third operand
    type(expr_t), allocatable :: grown(:)
    integer :: k

    if (c%num_exprs == size(c%exprs)) then
        allocate (grown(2*c%num_exprs))
        do k = 1, c%num_exprs
            call move_expr(c%exprs(k), grown(k))
        end do
        call move_alloc(grown, c%exprs)
    end if
    c%num_exprs = c%num_exprs + 1
    id = c%num_exprs
    c%exprs(id)%kind = kind
    if (present(a)) c%exprs(id)%a = a
    if (present(b)) c%exprs(id)%b = b
    if (present(third)) c%exprs(id)%c = third
end function new_expr

!> Move an expression, without copying what it holds.
pure subroutine move_expr(from, to)
    type(expr_t), intent(inout) :: from     !! the expression
    type(expr_t), intent(inout) :: to       !! where it goes

    to%kind = from%kind
    to%a = from%a
    to%b = from%b
    to%c = from%c
    to%name = from%name
    if (allocated(from%args)) call move_alloc(from%args, to%args)
    if (allocated(from%names)) call move_alloc(from%names, to%names)
    if (allocated(from%ops)) call move_alloc(from%ops, to%ops)
    if (allocated(from%text)) call move_alloc(from%text, to%text)
    to%value%kind = from%value%kind
    to%value%number = from%value%number
    if (allocated(from%value%text)) call move_alloc(from%value%text, to%value%text)
    if (allocated(from%value%items)) call move_alloc(from%value%items, to%value%items)
end subroutine move_expr

!> Append `value` to `list`.
pure subroutine push_id(list, value)
    integer, allocatable, intent(inout) :: list(:)  !! the list
    integer, intent(in) :: value                    !! the value

    if (allocated(list)) then
        list = [list, value]
    else
        list = [value]
    end if
end subroutine push_id

!> Compile expression `text`.
subroutine compile(c, text, id)
    type(fypp_t), intent(inout) :: c        !! the state
    character(len=*), intent(in) :: text    !! the expression
    integer, intent(out) :: id              !! the result
    type(scan_t) :: s

    id = index_find(c%compiled, text)
    if (id > 0) return
    s%text = text
    call next_token(c, s)
    call parse_list(c, s, id)
    if (s%kind /= T_END) call fail(c, 'cannot read the expression: '//text)
    if (id > 0) call index_set(c%compiled, text, id)
end subroutine compile

!> An expression, or several separated by commas, which make a tuple.
recursive subroutine parse_list(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: item

    call parse_test(c, s, id)
    if (.not. at_word(s, ',')) return
    item = id
    id = new_expr(c, E_TUPLE)
    call push_id(c%exprs(id)%args, item)
    do while (at_word(s, ','))
        call next_token(c, s)
        if (s%kind == T_END) exit
        call parse_test(c, s, item)
        call push_id(c%exprs(id)%args, item)
    end do
end subroutine parse_list

!> An expression, which may be conditional.
recursive subroutine parse_test(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: condition, other, value

    call parse_or(c, s, id)
    if (.not. at_word(s, 'if')) return
    value = id
    call next_token(c, s)
    call parse_or(c, s, condition)
    call expect(c, s, 'else')
    call parse_test(c, s, other)
    id = new_expr(c, E_IF, condition, value, other)
end subroutine parse_test

!> Operands of `or`.
recursive subroutine parse_or(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: right

    call parse_and(c, s, id)
    do while (at_word(s, 'or'))
        call next_token(c, s)
        call parse_and(c, s, right)
        id = new_expr(c, E_OR, id, right)
    end do
end subroutine parse_or

!> Operands of `and`.
recursive subroutine parse_and(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: right

    call parse_not(c, s, id)
    do while (at_word(s, 'and'))
        call next_token(c, s)
        call parse_not(c, s, right)
        id = new_expr(c, E_AND, id, right)
    end do
end subroutine parse_and

!> An operand of `not`.
recursive subroutine parse_not(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: operand

    if (at_word(s, 'not')) then
        call next_token(c, s)
        call parse_not(c, s, operand)
        id = new_expr(c, E_NOT, operand)
    else
        call parse_compare(c, s, id)
    end if
end subroutine parse_not

!> Comparisons.
recursive subroutine parse_compare(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: first, op, right

    call parse_sum(c, s, first)
    id = first
    do
        op = 0
        if (at_word(s, '==')) op = C_EQ
        if (at_word(s, '!=')) op = C_NE
        if (at_word(s, '<')) op = C_LT
        if (at_word(s, '>')) op = C_GT
        if (at_word(s, '<=')) op = C_LE
        if (at_word(s, '>=')) op = C_GE
        if (at_word(s, 'in')) op = C_IN
        if (at_word(s, 'not')) op = C_NOT_IN
        if (op == 0) return
        call next_token(c, s)
        if (op == C_NOT_IN) call expect(c, s, 'in')
        call parse_sum(c, s, right)
        if (id == first) id = new_expr(c, E_COMPARE, first)
        call push_id(c%exprs(id)%args, right)
        call push_id(c%exprs(id)%ops, op)
    end do
end subroutine parse_compare

!> Terms added and subtracted.
recursive subroutine parse_sum(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: right, kind

    call parse_product(c, s, id)
    do while (at_word(s, '+') .or. at_word(s, '-'))
        kind = merge(E_ADD, E_SUB, at_word(s, '+'))
        call next_token(c, s)
        call parse_product(c, s, right)
        id = new_expr(c, kind, id, right)
    end do
end subroutine parse_sum

!> Factors multiplied.
recursive subroutine parse_product(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: right

    call parse_unary(c, s, id)
    do while (at_word(s, '*'))
        call next_token(c, s)
        call parse_unary(c, s, right)
        id = new_expr(c, E_MUL, id, right)
    end do
end subroutine parse_product

!> A factor, perhaps negated.
recursive subroutine parse_unary(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    integer :: operand

    if (at_word(s, '-')) then
        call next_token(c, s)
        call parse_unary(c, s, operand)
        id = new_expr(c, E_NEG, operand)
    else
        call parse_postfix(c, s, id)
    end if
end subroutine parse_unary

!> A primary with what follows it: calls, subscripts and methods.
recursive subroutine parse_postfix(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    character(len=:), allocatable :: method
    integer :: object

    call parse_primary(c, s, id)
    do
        if (allocated(c%error)) return
        if (at_word(s, '(')) then
            object = id
            id = new_expr(c, E_CALL, object)
            call next_token(c, s)
            call parse_arguments(c, s, id, ')')
            call expect(c, s, ')')
        else if (at_word(s, '[')) then
            object = id
            call next_token(c, s)
            call parse_subscript(c, s, object, id)
            call expect(c, s, ']')
        else if (at_word(s, '.')) then
            object = id
            call next_token(c, s)
            method = s%word
            call next_token(c, s)
            call expect(c, s, '(')
            id = new_expr(c, E_METHOD, object)
            c%exprs(id)%text = method
            call parse_arguments(c, s, id, ')')
            call expect(c, s, ')')
        else
            return
        end if
    end do
end subroutine parse_postfix

!> The arguments of call `id`, up to `closing`.
recursive subroutine parse_arguments(c, s, id, closing)
    type(fypp_t), intent(inout) :: c            !! the state
    type(scan_t), intent(inout) :: s            !! the expression
    integer, intent(in) :: id                   !! the call
    character(len=*), intent(in) :: closing     !! the token that ends them
    integer :: value, keyword, saved
    character(len=:), allocatable :: word

    allocate (c%exprs(id)%args(0), c%exprs(id)%names(0))
    do while (.not. at_word(s, closing) .and. s%kind /= T_END .and. .not. allocated(c%error))
        keyword = 0
        if (s%kind == T_NAME) then
            word = s%word
            saved = s%pos
            call next_token(c, s)
            if (at_word(s, '=')) then
                call intern(c, word, keyword)
                call next_token(c, s)
            else
                s%pos = saved - len(word)
                call next_token(c, s)
            end if
        end if
        call parse_test(c, s, value)
        if (at_word(s, 'for')) call parse_comprehension(c, s, value, value)
        call push_id(c%exprs(id)%args, value)
        call push_id(c%exprs(id)%names, keyword)
        if (.not. at_word(s, ',')) exit
        call next_token(c, s)
    end do
end subroutine parse_arguments

!> A subscript of `object`, or a slice.
recursive subroutine parse_subscript(c, s, object, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(in) :: object       !! what is subscripted
    integer, intent(out) :: id          !! the result
    integer :: first, last

    first = 0
    last = 0
    if (.not. at_word(s, ':')) call parse_test(c, s, first)
    if (at_word(s, ':')) then
        call next_token(c, s)
        if (.not. at_word(s, ']')) call parse_test(c, s, last)
        id = new_expr(c, E_SLICE, object, first, last)
    else
        id = new_expr(c, E_INDEX, object, first)
    end if
end subroutine parse_subscript

!> The `for` clauses after the item `element`.
recursive subroutine parse_comprehension(c, s, element, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(in) :: element      !! the item
    integer, intent(out) :: id          !! the result
    integer :: clause, iterable, condition, name, comprehension

    comprehension = new_expr(c, E_COMP, element)
    do while (at_word(s, 'for') .and. .not. allocated(c%error))
        call next_token(c, s)
        clause = new_expr(c, E_CLAUSE)
        allocate (c%exprs(clause)%args(0), c%exprs(clause)%names(0))
        do
            if (s%kind /= T_NAME) call fail(c, 'cannot read the loop in: '//s%text)
            if (allocated(c%error)) return
            call intern(c, s%word, name)
            call push_id(c%exprs(clause)%names, name)
            call next_token(c, s)
            if (.not. at_word(s, ',')) exit
            call next_token(c, s)
        end do
        call expect(c, s, 'in')
        call parse_or(c, s, iterable)
        c%exprs(clause)%a = iterable
        do while (at_word(s, 'if'))
            call next_token(c, s)
            call parse_or(c, s, condition)
            call push_id(c%exprs(clause)%args, condition)
        end do
        call push_id(c%exprs(comprehension)%args, clause)
    end do
    id = comprehension
end subroutine parse_comprehension

!> A primary: a literal, a name, or something in brackets.
recursive subroutine parse_primary(c, s, id)
    type(fypp_t), intent(inout) :: c    !! the state
    type(scan_t), intent(inout) :: s    !! the expression
    integer, intent(out) :: id          !! the result
    type(buffer_t) :: b
    character(len=:), allocatable :: text
    integer :: item, name

    id = 0
    select case (s%kind)
    case (T_INT)
        id = new_expr(c, E_CONST)
        c%exprs(id)%value%kind = V_INT
        c%exprs(id)%value%number = s%number
        call next_token(c, s)
    case (T_STR)
        do while (s%kind == T_STR)
            call add(b, s%word)
            call next_token(c, s)
        end do
        id = new_expr(c, E_CONST)
        c%exprs(id)%value%kind = V_STR
        call take(b, text)
        call move_alloc(text, c%exprs(id)%value%text)
    case (T_FSTR)
        text = s%word
        call next_token(c, s)
        call parse_fstring(c, text, id)
    case (T_NAME)
        select case (s%word)
        case ('True', 'False')
            id = new_expr(c, E_CONST)
            c%exprs(id)%value%kind = V_BOOL
            c%exprs(id)%value%number = merge(1, 0, s%word == 'True')
        case ('None')
            id = new_expr(c, E_CONST)
        case default
            call intern(c, s%word, name)
            id = new_expr(c, E_NAME)
            c%exprs(id)%name = name
        end select
        call next_token(c, s)
    case (T_OP)
        if (at_word(s, '(')) then
            call next_token(c, s)
            if (at_word(s, ')')) then
                id = new_expr(c, E_TUPLE)
                allocate (c%exprs(id)%args(0))
            else
                call parse_test(c, s, item)
                if (at_word(s, 'for')) then
                    call parse_comprehension(c, s, item, id)
                else if (at_word(s, ',')) then
                    id = new_expr(c, E_TUPLE)
                    call parse_items(c, s, id, item, ')')
                else
                    id = item
                end if
            end if
            call expect(c, s, ')')
        else if (at_word(s, '[')) then
            call next_token(c, s)
            if (at_word(s, ']')) then
                id = new_expr(c, E_LIST)
                allocate (c%exprs(id)%args(0))
            else
                call parse_test(c, s, item)
                if (at_word(s, 'for')) then
                    call parse_comprehension(c, s, item, id)
                else
                    id = new_expr(c, E_LIST)
                    call parse_items(c, s, id, item, ']')
                end if
            end if
            call expect(c, s, ']')
        else
            call fail(c, 'not supported in Fypp expressions: '//s%text)
        end if
    case default
        call fail(c, 'an expression ends too soon: '//s%text)
    end select
end subroutine parse_primary

!> The items of a list or tuple, after the first, which is `first`.
recursive subroutine parse_items(c, s, id, first, closing)
    type(fypp_t), intent(inout) :: c            !! the state
    type(scan_t), intent(inout) :: s            !! the expression
    integer, intent(in) :: id                   !! the list
    integer, intent(in) :: first                !! its first item
    character(len=*), intent(in) :: closing     !! the token after the last item
    integer :: item

    call push_id(c%exprs(id)%args, first)
    do while (at_word(s, ','))
        call next_token(c, s)
        if (at_word(s, closing)) exit
        call parse_test(c, s, item)
        call push_id(c%exprs(id)%args, item)
    end do
end subroutine parse_items

!> An f-string, whose quotes and escapes are already gone.
recursive subroutine parse_fstring(c, text, id)
    type(fypp_t), intent(inout) :: c        !! the state
    character(len=*), intent(in) :: text    !! the string
    integer, intent(out) :: id              !! the result
    type(buffer_t) :: b
    character(len=:), allocatable :: piece
    integer :: i, close, item

    id = new_expr(c, E_FSTRING)
    allocate (c%exprs(id)%args(0))
    i = 1
    do while (i <= len(text))
        if (text(i:i) /= '{') then
            call add(b, text(i:i))
            i = i + 1
            cycle
        end if
        if (i < len(text)) then
            if (text(i + 1:i + 1) == '{') then
                call add(b, '{')
                i = i + 2
                cycle
            end if
        end if
        call take(b, piece)
        if (len(piece) > 0) then
            item = new_expr(c, E_CONST)
            c%exprs(item)%value%kind = V_STR
            call move_alloc(piece, c%exprs(item)%value%text)
            call push_id(c%exprs(id)%args, item)
        end if
        close = index(text(i:), '}')
        if (close == 0) then
            call fail(c, 'an f-string is not closed: '//text)
            return
        end if
        call compile(c, text(i + 1:i + close - 2), item)
        call push_id(c%exprs(id)%args, item)
        i = i + close
    end do
    call take(b, piece)
    if (len(piece) > 0) then
        item = new_expr(c, E_CONST)
        c%exprs(item)%value%kind = V_STR
        call move_alloc(piece, c%exprs(item)%value%text)
        call push_id(c%exprs(id)%args, item)
    end if
end subroutine parse_fstring

! ----------------------------------------------------------------------------------------------------
! Reading the document
! ----------------------------------------------------------------------------------------------------

!> A new node.
integer function new_node(c, kind) result(id)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: kind         !! what it is
    type(node_t), allocatable :: grown(:)
    integer :: k

    if (c%num_nodes == size(c%nodes)) then
        allocate (grown(2*c%num_nodes))
        do k = 1, c%num_nodes
            call move_node(c%nodes(k), grown(k))
        end do
        call move_alloc(grown, c%nodes)
    end if
    c%num_nodes = c%num_nodes + 1
    id = c%num_nodes
    c%nodes(id)%kind = kind
    if (kind /= N_TEXT .and. kind /= N_EVAL) allocate (c%nodes(id)%block)
end function new_node

!> Move a node, without copying what it holds.
pure subroutine move_node(from, to)
    type(node_t), intent(inout) :: from     !! the node
    type(node_t), intent(inout) :: to       !! where it goes

    to%kind = from%kind
    to%on_lines = from%on_lines
    to%expr = from%expr
    to%name = from%name
    if (allocated(from%text)) call move_alloc(from%text, to%text)
    if (allocated(from%source)) call move_alloc(from%source, to%source)
    if (allocated(from%block)) call move_alloc(from%block, to%block)
end subroutine move_node

!> Add a block to `node`, with condition `condition`.
subroutine add_body(c, node, condition)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: node         !! the node
    integer, intent(in) :: condition    !! its condition, or 0
    type(body_t), allocatable :: grown(:)
    integer :: k, n

    n = 0
    if (allocated(c%nodes(node)%block%bodies)) n = size(c%nodes(node)%block%bodies)
    allocate (grown(n + 1))
    do k = 1, n
        grown(k)%n = c%nodes(node)%block%bodies(k)%n
        call move_alloc(c%nodes(node)%block%bodies(k)%ids, grown(k)%ids)
    end do
    allocate (grown(n + 1)%ids(16))
    call move_alloc(grown, c%nodes(node)%block%bodies)
    call push_id(c%nodes(node)%block%conds, condition)
end subroutine add_body

!> Put `node` at the end of the block being read.
subroutine append(c, node)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: node         !! the node
    integer, allocatable :: grown(:)
    integer :: parent, body, n

    parent = c%root
    if (c%depth > 0) parent = c%stack(c%depth)
    body = size(c%nodes(parent)%block%bodies)
    associate (b => c%nodes(parent)%block%bodies(body))
        n = b%n
        if (n == size(b%ids)) then
            allocate (grown(2*n))
            grown(1:n) = b%ids(1:n)
            call move_alloc(grown, b%ids)
        end if
        b%ids(n + 1) = node
        b%n = n + 1
    end associate
end subroutine append

!> Enter block `node`.
subroutine open_block(c, node)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: node         !! the block

    call append(c, node)
    if (c%depth == MAX_FRAMES) then
        call fail(c, 'blocks are nested too deeply')
        return
    end if
    c%depth = c%depth + 1
    c%stack(c%depth) = node
end subroutine open_block

!> Leave a block, which must be of kind `kind`.
subroutine close_block(c, kind, word)
    type(fypp_t), intent(inout) :: c        !! the state
    integer, intent(in) :: kind             !! the kind
    character(len=*), intent(in) :: word    !! the directive closing it

    if (c%depth == 0) then
        call fail(c, word//' without a block to close')
    else if (c%nodes(c%stack(c%depth))%kind /= kind) then
        call fail(c, word//' does not match the block it closes')
    else
        c%depth = c%depth - 1
    end if
end subroutine close_block

!> Read file `path` into the block being read.
recursive subroutine parse_file(c, path)
    type(fypp_t), intent(inout) :: c        !! the state
    character(len=*), intent(in) :: path    !! the file
    character(len=:), allocatable :: text
    integer :: stat

    call file_read(path, text, stat)
    if (stat /= 0) then
        call fail(c, 'cannot read '//path)
        return
    end if
    call parse_text(c, text, path)
end subroutine parse_file

!> The position of the end of the line with position `from`: of its newline, or after the last line.
pure integer function end_of_line(text, from) result(at)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: from             !! a position
    integer :: found

    found = index(text(from:), NL)
    at = merge(from + found - 1, len(text) + 1, found > 0)
end function end_of_line

!> The first position from `from` that is not a blank.
pure integer function skip_blanks(text, from) result(at)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: from             !! where to start

    at = from
    do while (at <= len(text))
        if (.not. is_blank(text(at:at))) exit
        at = at + 1
    end do
end function skip_blanks

!> Split `text`, the contents of file `path`, into text and directives.
recursive subroutine parse_text(c, text, path)
    type(fypp_t), intent(inout) :: c        !! the state
    character(len=*), intent(in) :: text    !! the text
    character(len=*), intent(in) :: path    !! the file
    character(len=:), allocatable :: content
    integer :: pos, start, n, q, e, close
    logical :: line_start
    character :: ch

    n = len(text)
    pos = 1
    start = 1
    line_start = .true.
    do while (pos <= n .and. .not. allocated(c%error))
        if (line_start) then
            line_start = .false.
            q = skip_blanks(text, pos)
            if (q < n) then
                if (text(q:q + 1) == '#!') then
                    call flush_text(c, text, start, pos - 1)
                    do
                        e = end_of_line(text, q)
                        pos = e + 1
                        q = skip_blanks(text, pos)
                        if (q >= n) exit
                        if (text(q:q + 1) /= '#!') exit
                    end do
                    pos = min(pos, n + 1)
                    start = pos
                    line_start = .true.
                    cycle
                end if
                if (index('#$@', text(q:q)) > 0 .and. text(q + 1:q + 1) == ':') then
                    call flush_text(c, text, start, pos - 1)
                    call read_line_directive(text, q + 2, content, pos)
                    start = pos
                    line_start = .true.
                    call handle_directive(c, text(q:q), content, .true., path)
                    cycle
                end if
            end if
        end if
        ch = text(pos:pos)
        if (ch == NL) then
            line_start = .true.
        else if (pos < n .and. index('$#@', ch) > 0) then
            if (text(pos + 1:pos + 1) == '{') then
                e = end_of_line(text, pos)
                close = index(text(pos + 2:e - 1), '}'//ch)
                if (close > 0) then
                    call flush_text(c, text, start, pos - 1)
                    q = skip_blanks(text, pos + 2)
                    content = trim_right(text(q:pos + close))
                    pos = pos + close + 3
                    start = pos
                    call handle_directive(c, ch, content, .false., path)
                    cycle
                end if
            end if
        end if
        pos = pos + 1
    end do
    call flush_text(c, text, start, n)
end subroutine parse_text

!> The length of `text` without blanks at its end.
pure function trim_length(text) result(n)
    character(len=*), intent(in) :: text    !! the text
    integer :: n

    n = len(text)
    do while (n > 0)
        if (.not. is_blank(text(n:n))) exit
        n = n - 1
    end do
end function trim_length

!> `text` without blanks at its end.
pure function trim_right(text) result(out)
    character(len=*), intent(in) :: text    !! the text
    character(len=trim_length(text)) :: out

    out = text(:len(out))
end function trim_right

!> Add the text between `first` and `last` as a text node.
subroutine flush_text(c, text, first, last)
    type(fypp_t), intent(inout) :: c        !! the state
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: first            !! its start
    integer, intent(in) :: last             !! its end
    integer :: node

    if (last < first) return
    node = new_node(c, N_TEXT)
    c%nodes(node)%text = text(first:last)
    call append(c, node)
end subroutine flush_text

!> Read a line directive whose text starts at `from`, joining continuation lines.
pure subroutine read_line_directive(text, from, content, next)
    character(len=*), intent(in) :: text                    !! the text
    integer, intent(in) :: from                             !! where the directive's text starts
    character(len=:), allocatable, intent(out) :: content   !! the directive's text
    integer, intent(out) :: next                            !! the position after the directive
    type(buffer_t) :: b
    integer :: start, e, last, q

    start = skip_blanks(text, from)
    do
        e = end_of_line(text, start)
        last = start + trim_length(text(start:e - 1)) - 1
        if (last < start .or. e > len(text)) exit
        if (text(last:last) /= '&') exit
        call add(b, text(start:last - 1))
        start = e + 1
        q = skip_blanks(text, start)
        if (q <= len(text)) then
            if (text(q:q) == '&') start = q + 1
        end if
    end do
    if (last >= start) call add(b, text(start:last))
    call take(b, content)
    next = min(e + 1, len(text) + 1)
end subroutine read_line_directive

!> Act on a directive of type `kind`, which is `$`, `#` or `@`.
recursive subroutine handle_directive(c, kind, content, on_lines, path)
    type(fypp_t), intent(inout) :: c            !! the state
    character, intent(in) :: kind               !! the type of directive
    character(len=*), intent(in) :: content     !! its text
    logical, intent(in) :: on_lines             !! true for a line directive
    character(len=*), intent(in) :: path        !! the file
    integer :: node, expr, at

    if (len(content) == 0) then
        call fail(c, 'a directive has no content in '//path)
    else if (kind == '$') then
        call compile(c, content, expr)
        node = new_node(c, N_EVAL)
        c%nodes(node)%expr = expr
        c%nodes(node)%on_lines = on_lines
        call append(c, node)
    else if (kind == '#') then
        at = 1
        do while (at <= len(content))
            if (.not. in_name(content(at:at))) exit
            at = at + 1
        end do
        call control_directive(c, content(:at - 1), content(skip_blanks(content, at):), on_lines, path)
    else
        call fail(c, 'direct calls are not supported: '//content)
    end if
end subroutine handle_directive

!> Act on control directive `word`.
recursive subroutine control_directive(c, word, param, on_lines, path)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: word        !! the directive
    character(len=*), intent(in) :: param       !! what follows it
    logical, intent(in) :: on_lines             !! true for a line directive
    character(len=*), intent(in) :: path        !! the file
    integer :: node, expr

    select case (word)
    case ('if')
        call compile(c, param, expr)
        node = new_node(c, N_IF)
        c%nodes(node)%source = param
        call add_body(c, node, expr)
        call open_block(c, node)
    case ('elif', 'else')
        expr = 0
        if (word == 'elif') call compile(c, param, expr)
        if (c%depth == 0) then
            call fail(c, word//' outside of an if block')
        else if (c%nodes(c%stack(c%depth))%kind /= N_IF) then
            call fail(c, word//' outside of an if block')
        else
            call add_body(c, c%stack(c%depth), expr)
        end if
    case ('endif')
        call close_block(c, N_IF, word)
    case ('for')
        call for_directive(c, param)
    case ('endfor')
        call close_block(c, N_FOR, word)
    case ('set')
        call set_directive(c, param)
    case ('def')
        call def_directive(c, param)
    case ('enddef')
        call close_block(c, N_DEF, word)
    case ('call', 'block')
        call call_directive(c, param, on_lines)
    case ('endcall', 'endblock')
        call close_block(c, N_CALL, word)
    case ('include')
        call include_directive(c, param, path)
    case ('mute')
        node = new_node(c, N_MUTE)
        call add_body(c, node, 0)
        call open_block(c, node)
    case ('endmute')
        call close_block(c, N_MUTE, word)
    case ('assert')
        call compile(c, param, expr)
        node = new_node(c, N_ASSERT)
        c%nodes(node)%expr = expr
        c%nodes(node)%source = param
        call append(c, node)
    case default
        call fail(c, 'the directive '//word//' is not supported')
    end select
end subroutine control_directive

!> Read the names separated by commas at the start of `text`.
subroutine read_targets(c, text, targets, next)
    type(fypp_t), intent(inout) :: c                !! the state
    character(len=*), intent(in) :: text            !! the text
    integer, allocatable, intent(out) :: targets(:) !! the names
    integer, intent(out) :: next                    !! the position after them
    integer :: at, start, id
    logical :: bracket

    allocate (targets(0))
    at = skip_blanks(text, 1)
    bracket = .false.
    if (at <= len(text)) then
        if (text(at:at) == '(') then
            bracket = .true.
            at = skip_blanks(text, at + 1)
        end if
    end if
    do
        start = at
        do while (at <= len(text))
            if (.not. in_name(text(at:at))) exit
            at = at + 1
        end do
        if (at == start) then
            call fail(c, 'cannot read the variables in: '//text)
            exit
        end if
        call intern(c, text(start:at - 1), id)
        call push_id(targets, id)
        at = skip_blanks(text, at)
        if (at > len(text)) exit
        if (text(at:at) /= ',') exit
        at = skip_blanks(text, at + 1)
    end do
    if (bracket .and. at <= len(text)) then
        if (text(at:at) == ')') at = skip_blanks(text, at + 1)
    end if
    next = at
end subroutine read_targets

!> `#:for names in iterable`.
subroutine for_directive(c, param)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: param       !! what follows the directive
    integer, allocatable :: targets(:)
    integer :: at, node, expr

    call read_targets(c, param, targets, at)
    if (allocated(c%error)) return
    if (at + 2 > len(param)) then
        call fail(c, 'cannot read the loop: '//param)
        return
    end if
    if (param(at:at + 1) /= 'in' .or. .not. is_blank(param(at + 2:at + 2))) then
        call fail(c, 'cannot read the loop: '//param)
        return
    end if
    call compile(c, param(at + 2:), expr)
    node = new_node(c, N_FOR)
    c%nodes(node)%expr = expr
    c%nodes(node)%source = param
    call move_alloc(targets, c%nodes(node)%block%targets)
    call add_body(c, node, 0)
    call open_block(c, node)
end subroutine for_directive

!> `#:set names = expression`.
subroutine set_directive(c, param)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: param       !! what follows the directive
    integer, allocatable :: targets(:)
    integer :: at, node, expr

    call read_targets(c, param, targets, at)
    if (allocated(c%error)) return
    expr = 0
    if (at <= len(param)) then
        if (param(at:at) /= '=') then
            call fail(c, 'cannot read the assignment: '//param)
            return
        end if
        call compile(c, param(at + 1:), expr)
    end if
    node = new_node(c, N_SET)
    c%nodes(node)%expr = expr
    c%nodes(node)%source = param
    call move_alloc(targets, c%nodes(node)%block%targets)
    call append(c, node)
end subroutine set_directive

!> `#:def name(arguments)`. Each argument's default is compiled to an entry of `args`, or 0 if none.
subroutine def_directive(c, param)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: param       !! what follows the directive
    type(scan_t) :: s
    integer :: at, close, node, name, id, default

    at = index(param, '(')
    close = index(param, ')', back=.true.)
    if (at == 0 .or. close < at) then
        call fail(c, 'cannot read the macro definition: '//param)
        return
    end if
    call intern(c, trim_right(param(:at - 1)), name)
    node = new_node(c, N_DEF)
    c%nodes(node)%name = name
    c%nodes(node)%source = param
    allocate (c%nodes(node)%block%targets(0), c%nodes(node)%block%args(0))
    s%text = param(at + 1:close - 1)
    call next_token(c, s)
    do while (s%kind == T_NAME .and. .not. allocated(c%error))
        call intern(c, s%word, id)
        call next_token(c, s)
        default = 0
        if (at_word(s, '=')) then
            call next_token(c, s)
            call parse_test(c, s, default)
        end if
        call push_id(c%nodes(node)%block%targets, id)
        call push_id(c%nodes(node)%block%args, default)
        if (.not. at_word(s, ',')) exit
        call next_token(c, s)
    end do
    if (s%kind /= T_END) call fail(c, 'cannot read the arguments of: '//param)
    call add_body(c, node, 0)
    call open_block(c, node)
end subroutine def_directive

!> `#:call name(arguments)` or `#:block name(arguments)`.
subroutine call_directive(c, param, on_lines)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: param       !! what follows the directive
    logical, intent(in) :: on_lines             !! true for a line directive
    type(scan_t) :: s
    integer :: at, close, node, name, holder

    at = index(param, '(')
    if (at == 0) then
        at = len(param) + 1
        close = at
    else
        close = index(param, ')', back=.true.)
    end if
    call intern(c, trim_right(param(:at - 1)), name)
    node = new_node(c, N_CALL)
    c%nodes(node)%name = name
    c%nodes(node)%on_lines = on_lines
    c%nodes(node)%source = param
    holder = new_expr(c, E_CALL)
    if (close > at) then
        s%text = param(at + 1:close - 1)
        call next_token(c, s)
        call parse_arguments(c, s, holder, '')
        if (s%kind /= T_END) call fail(c, 'cannot read the arguments of: '//param)
    else
        allocate (c%exprs(holder)%args(0), c%exprs(holder)%names(0))
    end if
    c%nodes(node)%expr = holder
    call add_body(c, node, 0)
    call open_block(c, node)
end subroutine call_directive

!> `#:include "file"`.
recursive subroutine include_directive(c, param, path)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: param       !! what follows the directive
    character(len=*), intent(in) :: path        !! the file holding the directive
    character(len=:), allocatable :: name, candidate
    logical :: exists
    integer :: k, slash

    if (len(param) < 2) then
        call fail(c, 'cannot read the include: '//param)
        return
    end if
    name = param(2:len(param) - 1)
    slash = index(path, '/', back=.true.)
    candidate = path(:slash)//name
    !$omp critical (file_io)
    inquire (file=candidate, exist=exists)
    k = 0
    do while (.not. exists .and. k < size(c%includes))
        k = k + 1
        candidate = c%includes(k)%s//'/'//name
        inquire (file=candidate, exist=exists)
    end do
    !$omp end critical (file_io)
    if (exists) then
        call parse_file(c, candidate)
    else
        call fail(c, 'cannot find the include file '//name)
    end if
end subroutine include_directive

! ----------------------------------------------------------------------------------------------------
! Evaluation
! ----------------------------------------------------------------------------------------------------

!> Find the value of name `id`.
subroutine lookup(c, id, v, found)
    type(fypp_t), intent(in) :: c       !! the state
    integer, intent(in) :: id           !! the name
    type(value_t), intent(out) :: v     !! the value
    logical, intent(out) :: found       !! false if it is not set
    integer :: k, f

    found = .true.
    do k = c%num_bound, c%first_bound, -1
        if (c%bound(k) == id) then
            v = c%bound_values(k)
            return
        end if
    end do
    f = c%frame
    do while (f > 0)
        do k = c%frames(f)%n, 1, -1
            if (c%frames(f)%ids(k) == id) then
                v = c%frames(f)%values(k)
                return
            end if
        end do
        f = c%frames(f)%up
    end do
    found = c%is_set(id)
    if (found) v = c%globals(id)
end subroutine lookup

!> Set variable `id` in the current scope.
subroutine define(c, id, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the name
    type(value_t), intent(in) :: v      !! the value
    integer :: k, f

    f = c%frame
    if (f == 0) then
        c%globals(id) = v
        c%is_set(id) = .true.
        return
    end if
    do k = 1, c%frames(f)%n
        if (c%frames(f)%ids(k) == id) then
            c%frames(f)%values(k) = v
            return
        end if
    end do
    call frame_room(c%frames(f))
    c%frames(f)%n = c%frames(f)%n + 1
    c%frames(f)%ids(c%frames(f)%n) = id
    c%frames(f)%values(c%frames(f)%n) = v
end subroutine define

!> Make sure that one more variable fits in `frame`.
subroutine frame_room(frame)
    type(frame_t), intent(inout) :: frame   !! the scope
    integer, allocatable :: ids(:)
    type(value_t), allocatable :: values(:)
    integer :: k

    if (.not. allocated(frame%ids)) then
        allocate (frame%ids(16), frame%values(16))
    else if (frame%n == size(frame%ids)) then
        allocate (ids(2*frame%n), values(2*frame%n))
        ids(1:frame%n) = frame%ids(1:frame%n)
        do k = 1, frame%n
            call move_value(frame%values(k), values(k))
        end do
        call move_alloc(ids, frame%ids)
        call move_alloc(values, frame%values)
    end if
end subroutine frame_room

!> Move a value, without copying what it holds.
pure subroutine move_value(from, to)
    type(value_t), intent(inout) :: from    !! the value
    type(value_t), intent(inout) :: to      !! where it goes

    to%kind = from%kind
    to%number = from%number
    if (allocated(to%text)) deallocate (to%text)
    if (allocated(to%items)) deallocate (to%items)
    if (allocated(from%text)) call move_alloc(from%text, to%text)
    if (allocated(from%items)) call move_alloc(from%items, to%items)
end subroutine move_value

!> Open a scope that also sees frame `up`.
subroutine open_scope(c, up)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: up           !! the frame, or 0; this can be `c%frame` itself

    if (c%frame == MAX_FRAMES) then
        call fail(c, 'macro calls are nested too deeply')
        return
    end if
    c%frames(c%frame + 1)%n = 0
    c%frames(c%frame + 1)%up = up
    c%frame = c%frame + 1
end subroutine open_scope

!> Close the current scope.
subroutine close_scope(c)
    type(fypp_t), intent(inout) :: c    !! the state

    c%frame = max(c%frame - 1, 0)
end subroutine close_scope

!> Make a string value.
pure subroutine make_string(text, v)
    character(len=*), intent(in) :: text    !! the string
    type(value_t), intent(out) :: v         !! the value

    v%kind = V_STR
    v%text = text
end subroutine make_string

!> Make a bool value.
pure subroutine make_bool(truth, v)
    logical, intent(in) :: truth        !! the truth
    type(value_t), intent(out) :: v     !! the value

    v%kind = V_BOOL
    v%number = merge(1, 0, truth)
end subroutine make_bool

!> Make an integer value.
pure subroutine make_int(number, v)
    integer, intent(in) :: number       !! the integer
    type(value_t), intent(out) :: v     !! the value

    v%kind = V_INT
    v%number = number
end subroutine make_int

!> The truth of `v`.
pure logical function truth_of(v) result(truth)
    type(value_t), intent(in) :: v      !! the value

    select case (v%kind)
    case (V_NONE)
        truth = .false.
    case (V_BOOL, V_INT)
        truth = v%number /= 0
    case (V_STR)
        truth = len(v%text) > 0
    case (V_MACRO)
        truth = .true.
    case default
        truth = size(v%items) > 0
    end select
end function truth_of

!> True if `a` equals `b`.
pure recursive logical function equal(a, b) result(same)
    type(value_t), intent(in) :: a      !! a value
    type(value_t), intent(in) :: b      !! another
    integer :: k
    logical :: a_number, b_number

    a_number = a%kind == V_BOOL .or. a%kind == V_INT
    b_number = b%kind == V_BOOL .or. b%kind == V_INT
    same = .false.
    if (a_number .and. b_number) then
        same = a%number == b%number
    else if (a%kind /= b%kind) then
        return
    else if (a%kind == V_NONE) then
        same = .true.
    else if (a%kind == V_STR) then
        same = len(a%text) == len(b%text)
        if (same) same = a%text == b%text
    else if (a%kind == V_MACRO) then
        same = a%number == b%number
    else
        if (size(a%items) /= size(b%items)) return
        do k = 1, size(a%items)
            if (.not. equal(a%items(k), b%items(k))) return
        end do
        same = .true.
    end if
end function equal

!> Write `v` as `str()` does, or as `repr()` does if `quoted`.
pure recursive subroutine write_value(v, quoted, b)
    type(value_t), intent(in) :: v      !! the value
    logical, intent(in) :: quoted       !! true for `repr()`
    type(buffer_t), intent(inout) :: b  !! where it goes
    character(len=12) :: digits
    integer :: k, step

    select case (v%kind)
    case (V_NONE)
        call add(b, 'None')
    case (V_BOOL)
        call add(b, merge('True ', 'False', v%number /= 0))
        if (v%number /= 0) b%n = b%n - 1
    case (V_INT)
        call write_int(v%number, digits, k)
        call add(b, digits(k:))
    case (V_STR)
        if (quoted) call add(b, "'")
        call add(b, v%text)
        if (quoted) call add(b, "'")
    case (V_MACRO)
        call add(b, '<macro>')
    case default
        step = merge(2, 1, v%kind == V_DICT)
        call add(b, merge('[', '(', v%kind == V_LIST))
        do k = 1, size(v%items), step
            if (k > 1) call add(b, ', ')
            call write_value(v%items(k), .true., b)
        end do
        if (v%kind == V_TUPLE .and. size(v%items) == 1) call add(b, ',')
        call add(b, merge(']', ')', v%kind == V_LIST))
    end select
end subroutine write_value

!> Write integer `number` at the end of `digits`, from position `first`.
pure subroutine write_int(number, digits, first)
    integer, intent(in) :: number               !! the integer
    character(len=*), intent(out) :: digits     !! the digits
    integer, intent(out) :: first               !! where they start
    integer :: rest

    digits = ''
    first = len(digits) + 1
    rest = abs(number)
    do
        first = first - 1
        digits(first:first) = achar(iachar('0') + mod(rest, 10))
        rest = rest/10
        if (rest == 0) exit
    end do
    if (number < 0) then
        first = first - 1
        digits(first:first) = '-'
    end if
end subroutine write_int

!> The items of `v`, which is iterated over.
subroutine items_of(c, v, list)
    type(fypp_t), intent(inout) :: c                !! the state
    type(value_t), intent(in) :: v                  !! the value
    type(value_t), allocatable, intent(out) :: list(:)  !! its items
    integer :: k

    select case (v%kind)
    case (V_LIST, V_TUPLE)
        call copy_items(v%items, list)
    case (V_DICT)
        allocate (list(size(v%items)/2))
        do k = 1, size(list)
            list(k) = v%items(2*k - 1)
        end do
    case (V_STR)
        allocate (list(len(v%text)))
        do k = 1, size(list)
            call make_string(v%text(k:k), list(k))
        end do
    case default
        call fail(c, 'a value cannot be iterated over')
    end select
end subroutine items_of

!> Evaluate expression `id`.
recursive subroutine evaluate(c, id, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the expression
    type(value_t), intent(out) :: v     !! the result
    type(value_t) :: a, b
    type(value_t), allocatable :: shrunk(:)
    logical :: found
    integer :: k, j

    if (allocated(c%error)) return
    select case (c%exprs(id)%kind)
    case (E_CONST)
        v = c%exprs(id)%value
    case (E_NAME)
        call lookup(c, c%exprs(id)%name, v, found)
        if (.not. found) call fail(c, "the name '"//c%names(c%exprs(id)%name)%s//"' is not defined")
    case (E_LIST, E_TUPLE)
        v%kind = merge(V_LIST, V_TUPLE, c%exprs(id)%kind == E_LIST)
        allocate (v%items(size(c%exprs(id)%args)))
        do k = 1, size(v%items)
            call evaluate(c, c%exprs(id)%args(k), v%items(k))
        end do
    case (E_ADD, E_SUB, E_MUL)
        call evaluate(c, c%exprs(id)%a, a)
        call evaluate(c, c%exprs(id)%b, b)
        if (.not. allocated(c%error)) call arithmetic(c, c%exprs(id)%kind, a, b, v)
    case (E_NEG)
        call evaluate(c, c%exprs(id)%a, a)
        call make_int(-a%number, v)
    case (E_NOT)
        call evaluate(c, c%exprs(id)%a, a)
        call make_bool(.not. truth_of(a), v)
    case (E_AND)
        call evaluate(c, c%exprs(id)%a, v)
        if (truth_of(v)) call evaluate(c, c%exprs(id)%b, v)
    case (E_OR)
        call evaluate(c, c%exprs(id)%a, v)
        if (.not. truth_of(v)) call evaluate(c, c%exprs(id)%b, v)
    case (E_IF)
        call evaluate(c, c%exprs(id)%a, a)
        if (truth_of(a)) then
            call evaluate(c, c%exprs(id)%b, v)
        else
            call evaluate(c, c%exprs(id)%c, v)
        end if
    case (E_COMPARE)
        call compare(c, id, v)
    case (E_CALL)
        call evaluate_call(c, id, v)
    case (E_METHOD)
        call call_method(c, id, v)
    case (E_INDEX)
        call evaluate(c, c%exprs(id)%a, a)
        call evaluate(c, c%exprs(id)%b, b)
        if (.not. allocated(c%error)) call subscript(c, a, b%number, v)
    case (E_SLICE)
        call evaluate_slice(c, id, v)
    case (E_COMP)
        v%kind = V_LIST
        allocate (v%items(16))
        k = 0
        call run_clause(c, id, 1, v%items, k)
        allocate (shrunk(k))
        do j = 1, k
            call move_value(v%items(j), shrunk(j))
        end do
        call move_alloc(shrunk, v%items)
    case (E_FSTRING)
        call evaluate_fstring(c, id, v)
    case default
        call fail(c, 'an expression cannot be evaluated')
    end select
end subroutine evaluate

!> `a + b`, `a - b` or `a * b`.
recursive subroutine arithmetic(c, kind, a, b, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: kind         !! which
    type(value_t), intent(in) :: a      !! the first operand
    type(value_t), intent(in) :: b      !! the second operand
    type(value_t), intent(out) :: v     !! the result
    type(buffer_t) :: text
    character(len=:), allocatable :: joined
    integer :: k, n, base
    logical :: a_number, b_number

    a_number = a%kind == V_INT .or. a%kind == V_BOOL
    b_number = b%kind == V_INT .or. b%kind == V_BOOL
    if (a_number .and. b_number) then
        select case (kind)
        case (E_ADD); call make_int(a%number + b%number, v)
        case (E_SUB); call make_int(a%number - b%number, v)
        case default; call make_int(a%number*b%number, v)
        end select
    else if (kind == E_ADD .and. a%kind == V_STR .and. b%kind == V_STR) then
        call make_string(a%text//b%text, v)
    else if (kind == E_ADD .and. a%kind == b%kind .and. (a%kind == V_LIST .or. a%kind == V_TUPLE)) then
        v%kind = a%kind
        n = size(a%items)
        allocate (v%items(n + size(b%items)))
        v%items(1:n) = a%items
        v%items(n + 1:) = b%items
    else if (kind == E_MUL .and. a_number .and. b%kind >= V_STR .and. b%kind <= V_TUPLE) then
        call arithmetic(c, kind, b, a, v)
    else if (kind == E_MUL .and. a%kind == V_STR .and. b_number) then
        do k = 1, b%number
            call add(text, a%text)
        end do
        call take(text, joined)
        call make_string(joined, v)
    else if (kind == E_MUL .and. (a%kind == V_LIST .or. a%kind == V_TUPLE) .and. b_number) then
        n = size(a%items)
        v%kind = a%kind
        allocate (v%items(n*max(b%number, 0)))
        do k = 1, max(b%number, 0)
            base = (k - 1)*n
            v%items(base + 1:base + n) = a%items
        end do
    else
        call fail(c, 'unsupported operand types in arithmetic')
    end if
end subroutine arithmetic

!> A chain of comparisons.
recursive subroutine compare(c, id, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the expression
    type(value_t), intent(out) :: v     !! the result
    type(value_t) :: left, right
    integer :: k
    logical :: holds

    call evaluate(c, c%exprs(id)%a, left)
    holds = .true.
    do k = 1, size(c%exprs(id)%args)
        call evaluate(c, c%exprs(id)%args(k), right)
        if (allocated(c%error)) return
        call compare_two(c, c%exprs(id)%ops(k), left, right, holds)
        if (.not. holds) exit
        left = right
    end do
    call make_bool(holds, v)
end subroutine compare

!> One comparison.
subroutine compare_two(c, op, a, b, holds)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: op           !! the comparison
    type(value_t), intent(in) :: a      !! the first operand
    type(value_t), intent(in) :: b      !! the second operand
    logical, intent(out) :: holds       !! the result
    integer :: k, step

    holds = .false.
    select case (op)
    case (C_EQ)
        holds = equal(a, b)
    case (C_NE)
        holds = .not. equal(a, b)
    case (C_IN, C_NOT_IN)
        if (b%kind == V_STR .and. a%kind == V_STR) then
            holds = index(b%text, a%text) > 0
        else if (b%kind == V_LIST .or. b%kind == V_TUPLE .or. b%kind == V_DICT) then
            step = merge(2, 1, b%kind == V_DICT)
            do k = 1, size(b%items), step
                if (equal(a, b%items(k))) holds = .true.
            end do
        else
            call fail(c, "the right operand of 'in' cannot be searched")
        end if
        if (op == C_NOT_IN) holds = .not. holds
    case default
        if (a%kind == V_STR .and. b%kind == V_STR) then
            select case (op)
            case (C_LT); holds = llt(a%text, b%text)
            case (C_GT); holds = lgt(a%text, b%text)
            case (C_LE); holds = lle(a%text, b%text)
            case default; holds = lge(a%text, b%text)
            end select
        else if (a%kind == V_STR .or. b%kind == V_STR .or. a%kind > V_INT .or. b%kind > V_INT) then
            call fail(c, 'values cannot be ordered')
        else
            select case (op)
            case (C_LT); holds = a%number < b%number
            case (C_GT); holds = a%number > b%number
            case (C_LE); holds = a%number <= b%number
            case default; holds = a%number >= b%number
            end select
        end if
    end select
end subroutine compare_two

!> Item `index` of `a`, counting from 0, and from the end if negative.
subroutine subscript(c, a, index, v)
    type(fypp_t), intent(inout) :: c    !! the state
    type(value_t), intent(in) :: a      !! the value
    integer, intent(in) :: index        !! the index
    type(value_t), intent(out) :: v     !! the item
    integer :: n, at

    select case (a%kind)
    case (V_STR); n = len(a%text)
    case (V_LIST, V_TUPLE); n = size(a%items)
    case default
        call fail(c, 'a value cannot be subscripted')
        return
    end select
    at = merge(index + n, index, index < 0) + 1
    if (at < 1 .or. at > n) then
        call fail(c, 'an index is out of range')
    else if (a%kind == V_STR) then
        call make_string(a%text(at:at), v)
    else
        v = a%items(at)
    end if
end subroutine subscript

!> `a[first:last]`.
recursive subroutine evaluate_slice(c, id, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the expression
    type(value_t), intent(out) :: v     !! the result
    type(value_t) :: a, bound
    integer :: n, first, last

    call evaluate(c, c%exprs(id)%a, a)
    if (allocated(c%error)) return
    select case (a%kind)
    case (V_STR); n = len(a%text)
    case (V_LIST, V_TUPLE); n = size(a%items)
    case default
        call fail(c, 'a value cannot be sliced')
        return
    end select
    first = 0
    last = n
    if (c%exprs(id)%b > 0) then
        call evaluate(c, c%exprs(id)%b, bound)
        first = bound%number
    end if
    if (c%exprs(id)%c > 0) then
        call evaluate(c, c%exprs(id)%c, bound)
        last = bound%number
    end if
    if (first < 0) first = max(first + n, 0)
    if (last < 0) last = max(last + n, 0)
    first = min(first, n)
    last = min(last, n)
    if (a%kind == V_STR) then
        call make_string(a%text(first + 1:last), v)
    else
        v%kind = a%kind
        call copy_items(a%items(first + 1:last), v%items)
    end if
end subroutine evaluate_slice

!> Run clause `k` of comprehension `id`, collecting items.
recursive subroutine run_clause(c, id, k, items, n)
    type(fypp_t), intent(inout) :: c                    !! the state
    integer, intent(in) :: id                           !! the comprehension
    integer, intent(in) :: k                            !! the clause
    type(value_t), allocatable, intent(inout) :: items(:)   !! the items
    integer, intent(inout) :: n                         !! how many there are
    type(value_t), allocatable :: list(:), grown(:)
    type(value_t) :: iterable, test
    integer :: j, m, clause, saved
    logical :: keep

    if (allocated(c%error)) return
    if (k > size(c%exprs(id)%args)) then
        if (n == size(items)) then
            allocate (grown(2*n))
            do j = 1, n
                call move_value(items(j), grown(j))
            end do
            call move_alloc(grown, items)
        end if
        n = n + 1
        call evaluate(c, c%exprs(id)%a, items(n))
        return
    end if
    clause = c%exprs(id)%args(k)
    call evaluate(c, c%exprs(clause)%a, iterable)
    if (allocated(c%error)) return
    call items_of(c, iterable, list)
    if (allocated(c%error)) return
    saved = c%num_bound
    do j = 1, size(list)
        c%num_bound = saved
        call bind_targets(c, c%exprs(clause)%names, list(j))
        keep = .true.
        do m = 1, size(c%exprs(clause)%args)
            call evaluate(c, c%exprs(clause)%args(m), test)
            keep = keep .and. truth_of(test)
        end do
        if (keep) call run_clause(c, id, k + 1, items, n)
    end do
    c%num_bound = saved
end subroutine run_clause

!> Bind the names of a loop to `v` in a comprehension.
subroutine bind_targets(c, targets, v)
    type(fypp_t), intent(inout) :: c        !! the state
    integer, intent(in) :: targets(:)       !! the names
    type(value_t), intent(in) :: v          !! the value
    integer :: k

    if (size(targets) == 1) then
        call bind_one(c, targets(1), v)
    else if (v%kind /= V_LIST .and. v%kind /= V_TUPLE) then
        call fail(c, 'a value cannot be unpacked')
    else if (size(v%items) /= size(targets)) then
        call fail(c, 'a value has the wrong number of items to unpack')
    else
        do k = 1, size(targets)
            call bind_one(c, targets(k), v%items(k))
        end do
    end if
end subroutine bind_targets

!> Bind one name in a comprehension.
subroutine bind_one(c, id, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the name
    type(value_t), intent(in) :: v      !! the value
    integer, allocatable :: ids(:)
    type(value_t), allocatable :: values(:)
    integer :: k

    if (c%num_bound == size(c%bound)) then
        allocate (ids(2*c%num_bound), values(2*c%num_bound))
        ids(1:c%num_bound) = c%bound(1:c%num_bound)
        do k = 1, c%num_bound
            call move_value(c%bound_values(k), values(k))
        end do
        call move_alloc(ids, c%bound)
        call move_alloc(values, c%bound_values)
    end if
    c%num_bound = c%num_bound + 1
    c%bound(c%num_bound) = id
    c%bound_values(c%num_bound) = v
end subroutine bind_one

!> An f-string.
recursive subroutine evaluate_fstring(c, id, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the expression
    type(value_t), intent(out) :: v     !! the result
    type(buffer_t) :: b
    type(value_t) :: part
    character(len=:), allocatable :: text
    integer :: k

    do k = 1, size(c%exprs(id)%args)
        call evaluate(c, c%exprs(id)%args(k), part)
        if (allocated(c%error)) return
        call write_value(part, .false., b)
    end do
    call take(b, text)
    call make_string(text, v)
end subroutine evaluate_fstring

!> Evaluate the arguments of call `id`.
recursive subroutine evaluate_args(c, id, positional, num_positional, keywords, by_keyword)
    type(fypp_t), intent(inout) :: c                        !! the state
    integer, intent(in) :: id                               !! the call
    type(value_t), allocatable, intent(out) :: positional(:)    !! the positional arguments
    integer, intent(out) :: num_positional                  !! how many there are
    integer, allocatable, intent(out) :: keywords(:)        !! the keywords
    type(value_t), allocatable, intent(out) :: by_keyword(:)    !! the arguments given by keyword
    integer :: k, n, m

    n = size(c%exprs(id)%args)
    m = count(c%exprs(id)%names > 0)
    allocate (positional(n), keywords(m), by_keyword(m))
    num_positional = 0
    m = 0
    do k = 1, n
        if (c%exprs(id)%names(k) > 0) then
            m = m + 1
            keywords(m) = c%exprs(id)%names(k)
            call evaluate(c, c%exprs(id)%args(k), by_keyword(m))
        else
            num_positional = num_positional + 1
            call evaluate(c, c%exprs(id)%args(k), positional(num_positional))
        end if
    end do
end subroutine evaluate_args

!> A call of a macro or a builtin function.
recursive subroutine evaluate_call(c, id, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the expression
    type(value_t), intent(out) :: v     !! the result
    type(value_t), allocatable :: positional(:), by_keyword(:)
    integer, allocatable :: keywords(:)
    type(value_t) :: target
    integer :: n, name
    logical :: found

    if (c%exprs(c%exprs(id)%a)%kind /= E_NAME) then
        call fail(c, 'only names can be called')
        return
    end if
    name = c%exprs(c%exprs(id)%a)%name
    call evaluate_args(c, id, positional, n, keywords, by_keyword)
    if (allocated(c%error)) return
    call lookup(c, name, target, found)
    if (found) then
        if (target%kind /= V_MACRO) then
            call fail(c, c%names(name)%s//' is not a macro')
            return
        end if
        call call_macro(c, target%number, positional(:n), keywords, by_keyword, v)
    else
        call call_builtin(c, c%names(name)%s, positional(:n), v)
    end if
end subroutine evaluate_call

!> A builtin function: `defined`, `dict`, `len`, `list`, `range`, `reversed`, `str`, `zip`.
recursive subroutine call_builtin(c, name, args, v)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: name        !! the function
    type(value_t), intent(in) :: args(:)        !! the arguments
    type(value_t), intent(out) :: v             !! the result
    type(value_t), allocatable :: list(:)
    type(buffer_t) :: b
    character(len=:), allocatable :: text
    logical :: found
    type(value_t) :: unused
    integer :: k, j, n, id

    select case (name)
    case ('defined')
        id = find_name(c, args(1)%text)
        found = .false.
        if (id > 0) call lookup(c, id, unused, found)
        call make_bool(found, v)
    case ('len')
        if (args(1)%kind == V_STR) then
            call make_int(len(args(1)%text), v)
        else
            call items_of(c, args(1), list)
            if (.not. allocated(c%error)) call make_int(size(list), v)
        end if
    case ('list')
        v%kind = V_LIST
        call items_of(c, args(1), v%items)
    case ('reversed')
        call items_of(c, args(1), list)
        if (allocated(c%error)) return
        v%kind = V_LIST
        call copy_items(list(size(list):1:-1), v%items)
    case ('str')
        call write_value(args(1), .false., b)
        call take(b, text)
        call make_string(text, v)
    case ('range')
        call make_range(c, args, v)
    case ('zip')
        call make_zip(c, args, v)
    case ('dict')
        if (args(1)%kind == V_DICT) then
            v = args(1)
            return
        end if
        call items_of(c, args(1), list)
        if (allocated(c%error)) return
        v%kind = V_DICT
        n = size(list)
        allocate (v%items(2*n))
        do k = 1, n
            do j = 1, 2
                v%items(2*(k - 1) + j) = list(k)%items(j)
            end do
        end do
    case default
        call fail(c, 'the function '//name//' is not supported')
    end select
end subroutine call_builtin

!> `range(...)`, as a list.
subroutine make_range(c, args, v)
    type(fypp_t), intent(inout) :: c            !! the state
    type(value_t), intent(in) :: args(:)        !! the arguments
    type(value_t), intent(out) :: v             !! the result
    integer :: first, last, step, n, k

    first = 0
    step = 1
    select case (size(args))
    case (1)
        last = args(1)%number
    case (2)
        first = args(1)%number
        last = args(2)%number
    case (3)
        first = args(1)%number
        last = args(2)%number
        step = args(3)%number
    case default
        call fail(c, 'range takes one to three arguments')
        return
    end select
    n = max((last - first + step - sign(1, step))/step, 0)
    v%kind = V_LIST
    allocate (v%items(n))
    do k = 1, n
        call make_int(first + (k - 1)*step, v%items(k))
    end do
end subroutine make_range

!> `zip(...)`, as a list of tuples.
subroutine make_zip(c, args, v)
    type(fypp_t), intent(inout) :: c            !! the state
    type(value_t), intent(in) :: args(:)        !! the arguments
    type(value_t), intent(out) :: v             !! the result
    integer :: n, k, j

    v%kind = V_LIST
    n = huge(n)
    do k = 1, size(args)
        if (args(k)%kind /= V_LIST .and. args(k)%kind /= V_TUPLE) then
            call fail(c, 'zip takes lists and tuples')
            return
        end if
        n = min(n, size(args(k)%items))
    end do
    if (size(args) == 0) n = 0
    allocate (v%items(n))
    do k = 1, n
        v%items(k)%kind = V_TUPLE
        allocate (v%items(k)%items(size(args)))
        do j = 1, size(args)
            v%items(k)%items(j) = args(j)%items(k)
        end do
    end do
end subroutine make_zip

!> A method: of strings `startswith`, `format`, `join`, `strip` and `split`, and of dicts `get`.
recursive subroutine call_method(c, id, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the expression
    type(value_t), intent(out) :: v     !! the result
    type(value_t), allocatable :: args(:), by_keyword(:), list(:)
    integer, allocatable :: keywords(:)
    type(value_t) :: object
    type(buffer_t) :: b
    character(len=:), allocatable :: text
    integer :: n, k, first, last

    call evaluate(c, c%exprs(id)%a, object)
    call evaluate_args(c, id, args, n, keywords, by_keyword)
    if (allocated(c%error)) return
    if (object%kind == V_DICT .and. c%exprs(id)%text == 'get') then
        if (n == 2) v = args(2)
        do k = 1, size(object%items), 2
            if (equal(object%items(k), args(1))) then
                v = object%items(k + 1)
                return
            end if
        end do
        return
    end if
    if (object%kind /= V_STR) then
        call fail(c, 'the method '//c%exprs(id)%text//' is not supported')
        return
    end if
    select case (c%exprs(id)%text)
    case ('startswith')
        k = len(args(1)%text)
        if (k > len(object%text)) then
            call make_bool(.false., v)
        else
            call make_bool(object%text(:k) == args(1)%text, v)
        end if
    case ('format')
        call format_string(c, object%text, args(:n), v)
    case ('join')
        call items_of(c, args(1), list)
        if (allocated(c%error)) return
        do k = 1, size(list)
            if (k > 1) call add(b, object%text)
            call write_value(list(k), .false., b)
        end do
        call take(b, text)
        call make_string(text, v)
    case ('strip')
        first = 1
        last = len(object%text)
        do while (first <= last)
            if (.not. is_space(object%text(first:first))) exit
            first = first + 1
        end do
        do while (last >= first)
            if (.not. is_space(object%text(last:last))) exit
            last = last - 1
        end do
        call make_string(object%text(first:last), v)
    case ('split')
        call split_string(object%text, args(1)%text, v)
    case default
        call fail(c, 'the method '//c%exprs(id)%text//' is not supported')
    end select
end subroutine call_method

!> True if `ch` is white space.
elemental logical function is_space(ch)
    character, intent(in) :: ch     !! the character
    is_space = is_blank(ch) .or. ch == NL .or. ch == achar(13)
end function is_space

!> `text.format(args)`, for fields `{}` and `{n}`.
subroutine format_string(c, text, args, v)
    type(fypp_t), intent(inout) :: c            !! the state
    character(len=*), intent(in) :: text        !! the format
    type(value_t), intent(in) :: args(:)        !! the arguments
    type(value_t), intent(out) :: v             !! the result
    type(buffer_t) :: b
    character(len=:), allocatable :: joined
    integer :: i, close, field, automatic, k

    i = 1
    automatic = 0
    do while (i <= len(text))
        if (text(i:i) /= '{') then
            call add(b, text(i:i))
            i = i + 1
            cycle
        end if
        close = index(text(i:), '}')
        if (close == 0) then
            call fail(c, 'a format is not closed: '//text)
            return
        end if
        if (close == 2) then
            field = automatic
            automatic = automatic + 1
        else
            field = 0
            do k = i + 1, i + close - 2
                if (.not. is_digit(text(k:k))) then
                    call fail(c, 'the format is not supported: '//text)
                    return
                end if
                field = 10*field + iachar(text(k:k)) - iachar('0')
            end do
        end if
        if (field >= size(args)) then
            call fail(c, 'a format has too few arguments: '//text)
            return
        end if
        call write_value(args(field + 1), .false., b)
        i = i + close
    end do
    call take(b, joined)
    call make_string(joined, v)
end subroutine format_string

!> `text.split(separator)`.
pure subroutine split_string(text, separator, v)
    character(len=*), intent(in) :: text        !! the string
    character(len=*), intent(in) :: separator   !! what separates the parts
    type(value_t), intent(out) :: v             !! the result
    integer :: n, at, found, k

    n = 1
    at = 1
    do
        found = index(text(at:), separator)
        if (found == 0) exit
        n = n + 1
        at = at + found - 1 + len(separator)
    end do
    v%kind = V_LIST
    allocate (v%items(n))
    at = 1
    do k = 1, n
        found = index(text(at:), separator)
        if (found == 0) then
            call make_string(text(at:), v%items(k))
        else
            call make_string(text(at:at + found - 2), v%items(k))
            at = at + found - 1 + len(separator)
        end if
    end do
end subroutine split_string

! ----------------------------------------------------------------------------------------------------
! Rendering
! ----------------------------------------------------------------------------------------------------

!> Call macro `which`.
recursive subroutine call_macro(c, which, positional, keywords, by_keyword, v)
    type(fypp_t), intent(inout) :: c            !! the state
    integer, intent(in) :: which                !! the macro
    type(value_t), intent(in) :: positional(:)  !! the positional arguments
    integer, intent(in) :: keywords(:)          !! the keywords
    type(value_t), intent(in) :: by_keyword(:)  !! the arguments given by keyword
    type(value_t), intent(out) :: v             !! the result
    type(buffer_t) :: out
    character(len=:), allocatable :: text
    integer :: k, j, saved, node, n
    logical :: given

    if (size(positional) > size(c%macros(which)%params)) then
        call fail(c, 'a macro is called with too many arguments')
        return
    end if
    do k = 1, size(keywords)
        if (.not. any(c%macros(which)%params == keywords(k))) then
            call fail(c, 'a macro is called with the unknown keyword '//c%names(keywords(k))%s)
            return
        end if
    end do
    call open_scope(c, 0)
    if (allocated(c%error)) return
    do k = 1, size(c%macros(which)%captured)
        call define(c, c%macros(which)%captured(k), c%macros(which)%values(k))
    end do
    n = size(c%macros(which)%params)
    do k = 1, n
        given = k <= size(positional)
        if (given) then
            call define(c, c%macros(which)%params(k), positional(k))
            cycle
        end if
        do j = 1, size(keywords)
            if (keywords(j) == c%macros(which)%params(k)) then
                call define(c, keywords(j), by_keyword(j))
                given = .true.
            end if
        end do
        if (given) cycle
        if (c%macros(which)%has_default(k)) then
            call define(c, c%macros(which)%params(k), c%macros(which)%defaults(k))
        else
            call fail(c, 'a macro is called without the argument '//c%names(c%macros(which)%params(k))%s)
        end if
    end do
    saved = c%first_bound
    c%first_bound = c%num_bound + 1
    node = c%macros(which)%node
    call render_body(c, c%nodes(node)%block%bodies(1), out, .false.)
    c%first_bound = saved
    call close_scope(c)
    call take(out, text)
    n = len(text)
    if (n > 0) then
        if (text(n:n) == NL) n = n - 1
    end if
    call make_string(text(:n), v)
end subroutine call_macro

!> Render the nodes of `body`. With `top`, what is evaluated is recorded for line folding.
recursive subroutine render_body(c, body, out, top)
    type(fypp_t), intent(inout) :: c    !! the state
    type(body_t), intent(in) :: body    !! the nodes
    type(buffer_t), intent(inout) :: out    !! the output
    logical, intent(in) :: top          !! true if this is not going into a macro's result
    integer :: k

    do k = 1, body%n
        if (allocated(c%error)) return
        call render_node(c, body%ids(k), out, top)
    end do
end subroutine render_body

!> Render a node.
recursive subroutine render_node(c, id, out, top)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the node
    type(buffer_t), intent(inout) :: out    !! the output
    logical, intent(in) :: top          !! true if this is not going into a macro's result
    type(value_t) :: v
    type(buffer_t) :: discarded
    integer :: k, first

    select case (c%nodes(id)%kind)
    case (N_TEXT)
        call add(out, c%nodes(id)%text)
    case (N_EVAL)
        call evaluate(c, c%nodes(id)%expr, v)
        if (allocated(c%error)) return
        if (v%kind /= V_NONE) then
            first = out%n
            call write_value(v, .false., out)
            if (top) call record_span(c, first, out%n)
        end if
        if (c%nodes(id)%on_lines) call add(out, NL)
    case (N_IF)
        do k = 1, size(c%nodes(id)%block%bodies)
            if (c%nodes(id)%block%conds(k) > 0) then
                call evaluate(c, c%nodes(id)%block%conds(k), v)
                if (allocated(c%error)) return
                if (.not. truth_of(v)) cycle
            end if
            call render_body(c, c%nodes(id)%block%bodies(k), out, top)
            exit
        end do
    case (N_FOR)
        call render_loop(c, id, out, top)
    case (N_SET)
        if (c%nodes(id)%expr > 0) call evaluate(c, c%nodes(id)%expr, v)
        if (.not. allocated(c%error)) call assign_targets(c, c%nodes(id)%block%targets, v)
    case (N_DEF)
        call define_macro(c, id)
    case (N_CALL)
        call render_call(c, id, out, top)
    case (N_MUTE)
        call render_body(c, c%nodes(id)%block%bodies(1), discarded, .false.)
    case (N_ASSERT)
        call evaluate(c, c%nodes(id)%expr, v)
        if (.not. truth_of(v)) call fail(c, 'assertion failed: '//c%nodes(id)%source)
    end select
end subroutine render_node

!> Record that the output from after `first` to `last` was evaluated.
subroutine record_span(c, first, last)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: first        !! the position before it
    integer, intent(in) :: last         !! its last position
    type(span_t), allocatable :: grown(:)

    if (c%num_spans == size(c%spans)) then
        allocate (grown(2*c%num_spans))
        grown(1:c%num_spans) = c%spans(1:c%num_spans)
        call move_alloc(grown, c%spans)
    end if
    c%num_spans = c%num_spans + 1
    c%spans(c%num_spans) = span_t(first, last)
end subroutine record_span

!> Set the variables `targets` to `v`, unpacking it if there are several.
subroutine assign_targets(c, targets, v)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: targets(:)   !! the names
    type(value_t), intent(in) :: v      !! the value
    integer :: k

    if (size(targets) == 1) then
        call define(c, targets(1), v)
    else if (v%kind /= V_LIST .and. v%kind /= V_TUPLE) then
        call fail(c, 'a value cannot be unpacked')
    else if (size(v%items) /= size(targets)) then
        call fail(c, 'a value has the wrong number of items to unpack')
    else
        do k = 1, size(targets)
            call define(c, targets(k), v%items(k))
        end do
    end if
end subroutine assign_targets

!> Render a loop.
recursive subroutine render_loop(c, id, out, top)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the node
    type(buffer_t), intent(inout) :: out    !! the output
    logical, intent(in) :: top          !! true if this is not going into a macro's result
    type(value_t) :: iterable
    type(value_t), allocatable :: list(:)
    integer :: k, j

    call evaluate(c, c%nodes(id)%expr, iterable)
    if (allocated(c%error)) return
    call items_of(c, iterable, list)
    if (allocated(c%error)) return
    do k = 1, size(list)
        if (size(c%nodes(id)%block%targets) == 1) then
            call define(c, c%nodes(id)%block%targets(1), list(k))
        else if (list(k)%kind == V_LIST .or. list(k)%kind == V_TUPLE) then
            ! like Fypp, ignore items beyond the variables
            do j = 1, min(size(c%nodes(id)%block%targets), size(list(k)%items))
                call define(c, c%nodes(id)%block%targets(j), list(k)%items(j))
            end do
        else
            call fail(c, 'a value cannot be unpacked')
        end if
        call render_body(c, c%nodes(id)%block%bodies(1), out, top)
        if (allocated(c%error)) return
    end do
end subroutine render_loop

!> Define the macro of node `id`, evaluating its defaults now.
recursive subroutine define_macro(c, id)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the node
    type(macro_t), allocatable :: grown(:)
    type(value_t) :: v
    integer :: k, n

    if (c%num_macros == size(c%macros)) then
        allocate (grown(2*c%num_macros))
        do k = 1, c%num_macros
            grown(k)%node = c%macros(k)%node
            call move_alloc(c%macros(k)%params, grown(k)%params)
            call move_alloc(c%macros(k)%has_default, grown(k)%has_default)
            call move_alloc(c%macros(k)%defaults, grown(k)%defaults)
            call move_alloc(c%macros(k)%captured, grown(k)%captured)
            call move_alloc(c%macros(k)%values, grown(k)%values)
        end do
        call move_alloc(grown, c%macros)
    end if
    c%num_macros = c%num_macros + 1
    n = size(c%nodes(id)%block%targets)
    associate (m => c%macros(c%num_macros))
        m%node = id
        m%params = c%nodes(id)%block%targets
        allocate (m%has_default(n), m%defaults(n))
        m%has_default = c%nodes(id)%block%args > 0
    end associate
    do k = 1, n
        if (c%nodes(id)%block%args(k) > 0) then
            call evaluate(c, c%nodes(id)%block%args(k), c%macros(c%num_macros)%defaults(k))
        end if
    end do
    if (c%frame > 0) then
        c%macros(c%num_macros)%captured = c%frames(c%frame)%ids(:c%frames(c%frame)%n)
        call copy_items(c%frames(c%frame)%values(:c%frames(c%frame)%n), c%macros(c%num_macros)%values)
    else
        allocate (c%macros(c%num_macros)%captured(0), c%macros(c%num_macros)%values(0))
    end if
    v%kind = V_MACRO
    v%number = c%num_macros
    call define(c, c%nodes(id)%name, v)
end subroutine define_macro

!> Render a call: the block is the last positional argument.
recursive subroutine render_call(c, id, out, top)
    type(fypp_t), intent(inout) :: c    !! the state
    integer, intent(in) :: id           !! the node
    type(buffer_t), intent(inout) :: out    !! the output
    logical, intent(in) :: top          !! true if this is not going into a macro's result
    type(value_t), allocatable :: positional(:), by_keyword(:), args(:)
    integer, allocatable :: keywords(:)
    type(value_t) :: target, v
    type(buffer_t) :: body
    character(len=:), allocatable :: text
    integer :: n, m, first
    logical :: found

    call evaluate_args(c, c%nodes(id)%expr, positional, n, keywords, by_keyword)
    if (allocated(c%error)) return
    call open_scope(c, c%frame)
    if (allocated(c%error)) return
    call render_body(c, c%nodes(id)%block%bodies(1), body, .false.)
    call close_scope(c)
    if (allocated(c%error)) return
    call take(body, text)
    m = len(text)
    if (m > 0) then
        if (text(m:m) == NL) m = m - 1
    end if
    allocate (args(n + 1))
    args(1:n) = positional(1:n)
    call make_string(text(:m), args(n + 1))
    call lookup(c, c%nodes(id)%name, target, found)
    if (.not. found) then
        call fail(c, 'the macro '//c%names(c%nodes(id)%name)%s//' is not defined')
        return
    end if
    if (target%kind /= V_MACRO) then
        call fail(c, c%names(c%nodes(id)%name)%s//' is not a macro')
        return
    end if
    call call_macro(c, target%number, args, keywords, by_keyword, v)
    if (allocated(c%error)) return
    first = out%n
    call write_value(v, .false., out)
    if (top) call record_span(c, first, out%n)
    if (c%nodes(id)%on_lines) call add(out, NL)
end subroutine render_call

! ----------------------------------------------------------------------------------------------------
! Folding long lines
! ----------------------------------------------------------------------------------------------------

!> Fold the long lines of `text` that hold results of evaluation. Others stay as they are.
subroutine fold_output(c, text, out)
    type(fypp_t), intent(in) :: c                       !! the state
    character(len=*), intent(in) :: text                !! the text
    character(len=:), allocatable, intent(out) :: out   !! the result
    type(buffer_t) :: b
    integer :: k, done, first, last, found

    done = 0
    do k = 1, c%num_spans
        if (c%spans(k)%first < done) cycle
        found = index(text(done + 1:c%spans(k)%first), NL, back=.true.)
        first = done + 1
        if (found > 0) first = done + found + 1
        found = index(text(c%spans(k)%last + 1:), NL)
        last = merge(c%spans(k)%last + found, len(text), found > 0)
        call add(b, text(done + 1:first - 1))
        call fold_region(text(first:last), b)
        done = last
    end do
    call add(b, text(done + 1:))
    call take(b, out)
end subroutine fold_output

!> Fold each line of `text`.
pure subroutine fold_region(text, b)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: b      !! where it goes
    integer :: start, e

    start = 1
    do while (start <= len(text))
        e = end_of_line(text, start)
        call fold_line(text(start:e - 1), b)
        if (e <= len(text)) call add(b, NL)
        start = e + 1
    end do
end subroutine fold_region

!> Fold a line in Fypp's default way, at a blank near the end of the line if there is one.
pure subroutine fold_line(line, b)
    character(len=*), intent(in) :: line    !! the line
    type(buffer_t), intent(inout) :: b      !! where it goes
    character(len=:), allocatable :: prefix
    integer :: n, indent, room, room_middle, first, last

    n = len(line)
    indent = skip_blanks(line, 1) - 1
    if (n <= MAX_LINE) then
        call add(b, line)
        return
    end if
    if (line(indent + 1:indent + 1) == '!') then
        call add(b, line)
        return
    end if
    prefix = repeat(' ', indent + FOLD_INDENT)//'&'
    room = MAX_LINE - len(prefix)
    room_middle = room - 1
    first = 0
    last = fold_position(line, first, MAX_LINE - 1)
    call add(b, line(first + 1:last)//'&')
    do while (last < n - room)
        first = last
        last = fold_position(line, first, first + room_middle)
        call add(b, NL//prefix//line(first + 1:last)//'&')
    end do
    call add(b, NL//prefix//line(last + 1:))
end subroutine fold_line

!> Where to end the part of `line` after `first`, at most at `last`. Positions count from 0.
pure integer function fold_position(line, first, last) result(at)
    character(len=*), intent(in) :: line    !! the line
    integer, intent(in) :: first            !! where the part starts
    integer, intent(in) :: last             !! where it could end
    integer :: blank

    at = last
    blank = index(line(first + 1:last), ' ', back=.true.)
    if (blank == 0) return
    blank = first + blank - 1
    if (blank >= first + (2*(last - first))/3) at = blank
end function fold_position

end module fdoc_fypp
