module fdoc_decl
!! Reading declarations and procedure headers from the text of a statement.
!!
!! Everything here runs inside the parallel parsing loop, so it does not call functions returning
!! deferred-length strings (see `example/slen_race.f90`).
use fdoc_util
implicit none
private

public :: parse_type, split_attributes, parse_declarator, is_type_declaration, parse_procedure_header

type, public :: parsed_type_t
    !! The type part of a declaration.
    character(len=:), allocatable :: vartype    !! the type keyword, in lowercase
    character(len=:), allocatable :: kind       !! the kind, if any
    character(len=:), allocatable :: strlen     !! the character length, if any
    type(string_t), allocatable :: proto(:)     !! the type or interface name and its arguments, if any
    character(len=:), allocatable :: rest       !! what follows the type
    logical :: ok = .false.                     !! false if this is not a type
end type parsed_type_t

type, public :: procedure_header_t
    !! The parts of a `subroutine` or `function` statement.
    character(len=:), allocatable :: name           !! the name
    character(len=:), allocatable :: prefix         !! what comes before the keyword, without attributes
    type(string_t), allocatable :: attribs(:)       !! the prefix attributes (`pure`, `module`, ...)
    type(string_t), allocatable :: args(:)          !! the dummy arguments
    character(len=:), allocatable :: result_name    !! the name in `result(...)`, if any
    character(len=:), allocatable :: bind_c         !! the text in `bind(...)`, if any
    logical :: is_function = .false.                !! true for a function
    logical :: ok = .false.                         !! false if this is no such statement
end type procedure_header_t

character(len=*), parameter :: TYPE_WORDS(*) = [character(len=16) :: 'integer', 'real', 'doubleprecision', 'character', &
                                                'complex', 'doublecomplex', 'logical', 'type', 'class', 'procedure', &
                                                'enumerator']

contains

!> The length of the type keyword that `low` starts with, ignoring blanks in `double precision`, or
!> 0. Its normal spelling is returned in `word`.
subroutine type_keyword(low, n, word)
    character(len=*), intent(in) :: low                 !! the statement, in lowercase
    integer, intent(out) :: n                           !! the length of the keyword in `low`
    character(len=:), allocatable, intent(out) :: word  !! the keyword
    integer :: k, at

    n = 0
    word = ''
    if (starts_with(low, 'double')) then
        at = 7 + verify(low(7:)//'x', ' ') - 1
        if (word_at(low, at, 'precision')) then
            n = at + 8
            word = 'double precision'
        else if (word_at(low, at, 'complex')) then
            n = at + 6
            word = 'double complex'
        end if
        return
    end if
    do k = 1, size(TYPE_WORDS)
        associate (w => TYPE_WORDS(k))
            if (w(1:6) == 'double') cycle
            if (starts_with(low, trim(w))) then
                n = len_trim(w)
                word = trim(w)
                return
            end if
        end associate
    end do
end subroutine type_keyword

!> True if `low` starts a type declaration rather than, for example, an assignment.
logical function is_type_declaration(low)
    character(len=*), intent(in) :: low     !! the statement, in lowercase
    character(len=:), allocatable :: word
    integer :: n, next
    character :: c

    call type_keyword(low, n, word)
    is_type_declaration = n > 0
    if (n == 0 .or. n >= len(low)) return
    next = n + verify(low(n + 1:)//'x', ' ')
    c = low(n + 1:n + 1)
    if (index('abcdefghijklmnopqrstuvwxyz0123456789_', c) > 0) then
        is_type_declaration = .false.
        return
    end if
    if (next > len(low)) return
    if (low(next:next) == '=' .or. low(next:next) == '%') is_type_declaration = .false.
end function is_type_declaration

!> The length of the kind selector at the start of `text`, which is `(...)`, `*n` or `*(...)`.
pure integer function selector_length(text)
    character(len=*), intent(in) :: text    !! the text
    integer :: k

    selector_length = 0
    if (len(text) == 0) return
    if (text(1:1) == '(') then
        selector_length = closing_paren(text, 1)
    else if (text(1:1) == '*') then
        k = 1 + verify(text(2:)//'x', ' ')
        if (k > len(text)) return
        if (text(k:k) == '(') then
            selector_length = closing_paren(text, k)
        else
            selector_length = k + verify(text(k:)//'x', '0123456789') - 2
        end if
    end if
end function selector_length

!> Read the type at the start of `line`.
subroutine parse_type(line, t)
    character(len=*), intent(in) :: line    !! the statement
    type(parsed_type_t), intent(out) :: t   !! the result
    character(len=:), allocatable :: rest, args, word
    type(string_t), allocatable :: parts(:)
    integer :: n, k, at, sel
    logical :: star

    call type_keyword(lowercase(line), n, word)
    if (n == 0) return
    t%ok = .true.
    t%vartype = word
    rest = strip(line(n + 1:))
    sel = selector_length(rest)
    t%rest = strip(rest(sel + 1:))
    if (sel == 0) then
        if (t%vartype == 'character') t%strlen = '1'
        return
    end if
    star = rest(1:1) == '*'
    if (star) then
        args = strip(rest(2:sel))
        if (args(1:1) == '(') args = strip(args(2:len(args) - 1))
    else
        args = strip(rest(2:sel - 1))
    end if
    args = remove_blanks(args)

    select case (t%vartype)
    case ('type', 'class', 'procedure')
        at = index(args, '(')
        if (at > 0) then
            t%proto = [string_t(args(:at - 1)), string_t(args(at + 1:len(args) - 1))]
        else
            t%proto = [string_t(args), string_t('')]
        end if
    case ('character')
        if (star) then
            t%strlen = args
            return
        end if
        parts = top_split(args, ',')
        do k = 1, size(parts)
            associate (p => parts(k)%s)
                if (.not. allocated(t%strlen) .and. starts_with(lowercase(p), 'len=')) then
                    t%strlen = p(5:)
                else if (.not. allocated(t%kind) .and. starts_with(lowercase(p), 'kind=')) then
                    t%kind = p(6:)
                else if (.not. allocated(t%strlen)) then
                    t%strlen = p
                else if (.not. allocated(t%kind)) then
                    t%kind = p
                end if
            end associate
        end do
        if (.not. allocated(t%strlen)) t%strlen = '1'
    case default
        if (starts_with(lowercase(args), 'kind=')) then
            t%kind = args(6:)
        else
            t%kind = args
        end if
    end select
end subroutine parse_type

!> Split what follows the type of a declaration into its attributes and the names declared.
subroutine split_attributes(rest, attributes, names)
    character(len=*), intent(in) :: rest                !! what follows the type
    type(string_t), allocatable, intent(out) :: attributes(:)   !! the attributes
    character(len=:), allocatable, intent(out) :: names !! the names declared, with what goes with them
    integer :: at

    allocate (attributes(0))
    at = top_index(rest, '::')
    if (len(rest) > 0) then
        if (rest(1:1) == ',' .and. at > 0) then
            attributes = top_split(rest(2:at - 1), ',')
            names = strip(rest(at + 2:))
            return
        end if
    end if
    if (at > 0) then
        names = strip(rest(at + 2:))
    else
        names = strip(rest)
    end if
end subroutine split_attributes

!> Read one name of a declaration, such as `x(3) = 1`.
subroutine parse_declarator(text, name, dimension, initial, points)
    character(len=*), intent(in) :: text                    !! the text
    character(len=:), allocatable, intent(out) :: name      !! the name
    character(len=:), allocatable, intent(out) :: dimension !! the dimensions, if any
    character(len=:), allocatable, intent(out) :: initial   !! the initial value, if any
    logical, intent(out) :: points                          !! true if initialized with `=>`
    character(len=:), allocatable :: dec
    integer :: at, stop_at

    dec = remove_blanks(text)
    points = .false.
    at = top_index(dec, '=')
    if (at > 0) then
        points = dec(at + 1:min(at + 1, len(dec))) == '>'
        initial = dec(at + merge(2, 1, points):)
        dec = dec(:at - 1)
    end if
    stop_at = scan(dec, '([*')
    if (stop_at > 1) then
        dimension = dec(stop_at:)
        name = dec(:stop_at - 1)
    else
        name = dec
    end if
end subroutine parse_declarator

!> Read a `subroutine` or `function` statement.
subroutine parse_procedure_header(line, h)
    character(len=*), intent(in) :: line            !! the statement
    type(procedure_header_t), intent(out) :: h      !! the result
    character(len=len(line)) :: low
    character(len=:), allocatable :: prefix
    character(len=*), parameter :: PREFIXES(*) = [character(len=13) :: 'impure', 'pure', 'elemental', 'non_recursive', &
                                                  'recursive', 'module']
    integer :: k, at, open, close, depth, n

    low = lowercase(line)
    allocate (h%attribs(0), h%args(0))
    depth = 0
    at = 0
    do k = 1, len(low)
        if (low(k:k) == '(') depth = depth + 1
        if (low(k:k) == ')') depth = depth - 1
        if (depth /= 0) cycle
        if (word_at(low, k, 'subroutine')) then
            at = k + 10
            exit
        end if
        if (word_at(low, k, 'function')) then
            at = k + 8
            h%is_function = .true.
            exit
        end if
    end do
    if (at == 0) return

    prefix = low(1:at - merge(9, 11, h%is_function))
    do k = 1, size(PREFIXES)
        n = len_trim(PREFIXES(k))
        open = index(prefix, PREFIXES(k) (1:n))
        if (open > 0) then
            call push(h%attribs, PREFIXES(k) (1:n))
            prefix = prefix(:open - 1)//prefix(open + n:)
        end if
    end do
    call original_prefix(line, low, at - merge(8, 10, h%is_function) - 1, h%attribs, prefix)
    h%prefix = remove_blanks(prefix)

    open = at + verify(line(at:)//'x', ' ') - 1
    close = open + verify(low(open:)//' ', 'abcdefghijklmnopqrstuvwxyz0123456789_') - 2
    h%name = line(open:close)
    open = close + verify(line(close + 1:)//'x', ' ')
    close = open - 1
    if (open <= len(line)) then
        if (line(open:open) == '(') then
            close = closing_paren(line, open)
            if (close == 0) return
            if (close > open + 1) then
                if (len(strip(line(open + 1:close - 1))) > 0) h%args = top_split(line(open + 1:close - 1), ',')
            end if
        end if
    end if

    do k = close + 1, len(low)
        if (word_at(low, k, 'result')) then
            open = k + index(low(k:), '(') - 1
            at = closing_paren(low, open)
            if (at > 0) h%result_name = strip(line(open + 1:at - 1))
        else if (word_at(low, k, 'bind')) then
            open = k + index(low(k:), '(') - 1
            at = closing_paren(low, open)
            if (at > 0) h%bind_c = strip(line(open + 1:at - 1))
        end if
    end do
    h%ok = .true.
end subroutine parse_procedure_header

!> Set `text` to `line(1:n)` with the words of `attribs` removed, keeping the case of what is left.
subroutine original_prefix(line, low, n, attribs, text)
    character(len=*), intent(in) :: line                !! the statement
    character(len=*), intent(in) :: low                 !! the statement, in lowercase
    integer, intent(in) :: n                            !! the length of the prefix
    type(string_t), intent(in) :: attribs(:)            !! the words to remove
    character(len=:), allocatable, intent(out) :: text  !! the result
    character(len=:), allocatable :: lowered
    integer :: k, at

    text = line(1:n)
    lowered = low(1:n)
    do k = 1, size(attribs)
        at = index(lowered, attribs(k)%s)
        if (at == 0) cycle
        text = text(:at - 1)//text(at + len(attribs(k)%s):)
        lowered = lowered(:at - 1)//lowered(at + len(attribs(k)%s):)
    end do
end subroutine original_prefix

end module fdoc_decl
