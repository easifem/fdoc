module fdoc_markdown
!! Markdown to HTML, in the dialect of Python-Markdown with the extensions FORD uses: fenced code,
!! tables, footnotes, definition lists, abbreviations, attribute lists, Markdown inside HTML, math,
!! file inclusion, and FORD's links, aliases and admonitions.
!!
!! The block parser follows Python-Markdown: the text is split into chunks at blank lines, and a tree
!! is built by processors tried in a fixed order, so that indentation and lists behave the same.
!! Inline text is then read left to right.
!!
!! Documentation is rendered in parallel, so nothing here calls a function returning a deferred-length
!! string (see `example/slen_race.f90`).
use ffmt_io, only: read_file
use fdoc_util
use fdoc_buffer
use fdoc_highlight, only: highlight_fortran
use fdoc_progress, only: warn
use fdoc_settings, only: map_entry_t
implicit none
private

public :: markdown_to_html, markdown_options_t, dedent

character, parameter :: NL = achar(10)
character, parameter :: STX = achar(2)      !! starts a placeholder for stashed HTML
character, parameter :: ETX = achar(3)      !! ends it
character(len=*), parameter :: ESCAPED = '\`*_{}[]()>#+-.!'
character(len=*), parameter :: WORD_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'
character(len=*), parameter :: BLOCK_TAGS = &
    ' address article aside blockquote body center del details dialog dir div dl fieldset figcaption figure footer '// &
    'form h1 h2 h3 h4 h5 h6 header hgroup hr iframe ins li main menu nav noscript ol p pre section summary table '// &
    'tbody td tfoot th thead tr ul canvas math object script style '

integer, parameter :: MAX_DEPTH = 48

abstract interface
    !> Find what a `[[...]]` link means.
    subroutine link_resolver(data, name, entity, child, child_entity, url, text, found)
        import
        class(*), intent(in) :: data                        !! what the resolver needs
        character(len=*), intent(in) :: name                !! the name
        character(len=*), intent(in) :: entity              !! its entity type, or `''`
        character(len=*), intent(in) :: child               !! the child's name, or `''`
        character(len=*), intent(in) :: child_entity        !! the child's entity type, or `''`
        character(len=:), allocatable, intent(out) :: url   !! the link
        character(len=:), allocatable, intent(out) :: text  !! the text to show
        logical, intent(out) :: found                       !! false if there is no such entity
    end subroutine link_resolver
end interface

type :: markdown_options_t
    !! What rendering depends on.
    type(map_entry_t), allocatable :: aliases(:)    !! the `|alias|` replacements
    character(len=:), allocatable :: base_path      !! where file include directives paths start from
    logical :: toc = .false.                        !! the `toc` extension: ids on headers, `[TOC]`
    logical :: smarty = .false.                     !! the `smarty` extension: typographic punctuation
    procedure(link_resolver), pointer, nopass :: resolver => null() !! finds `[[...]]` links
    class(*), pointer :: resolver_data => null()    !! passed to `resolver`
    type(map_entry_t), allocatable :: abbreviations(:)  !! abbreviations that apply everywhere
end type markdown_options_t

type :: node_t
    !! An element of the tree.
    character(len=:), allocatable :: tag    !! its tag; `code` is a code block, `raw` is finished HTML
    character(len=:), allocatable :: text   !! its text, not yet processed
    character(len=:), allocatable :: attrs  !! its attributes, as HTML
    integer, allocatable :: kids(:)         !! its children, in order
end type node_t

type :: reference_t
    !! A link reference definition.
    character(len=:), allocatable :: id     !! its name, normalized
    character(len=:), allocatable :: url    !! the address
    character(len=:), allocatable :: title  !! the title, or `''`
end type reference_t

type :: footnote_t
    !! A footnote definition.
    character(len=:), allocatable :: id     !! its name
    character(len=:), allocatable :: text   !! its Markdown
    logical :: used = .false.               !! referred to in the text
end type footnote_t

type :: heading_t
    !! A heading, for the table of contents.
    integer :: level = 0                    !! 1 to 6
    character(len=:), allocatable :: id     !! its id
    character(len=:), allocatable :: html   !! its text as HTML
end type heading_t

type :: tree_t
    !! The state of one conversion.
    type(node_t), allocatable :: nodes(:)       !! the elements; 1 is the root
    integer :: n = 0                            !! number of elements
    type(string_t), allocatable :: stash(:)     !! finished HTML kept out of the way
    type(reference_t), allocatable :: refs(:)   !! link references
    type(footnote_t), allocatable :: notes(:)   !! footnotes
    type(map_entry_t), allocatable :: abbreviations(:) !! abbreviations
    type(heading_t), allocatable :: headings(:) !! headings, if the `toc` extension is on
    type(string_t), allocatable :: ids(:)       !! header ids used
    character(len=:), allocatable :: state      !! `,`-separated parser states, innermost last
    integer :: depth = 0                        !! nesting of block parsing
end type tree_t

contains

!> Remove the leading whitespace that all non-blank lines of `lines` share.
subroutine dedent(lines)
    type(string_t), intent(inout) :: lines(:)   !! the lines
    integer :: k, common, at

    common = huge(common)
    do k = 1, size(lines)
        at = verify(lines(k)%s, ' '//achar(9))
        if (at > 0) common = min(common, at - 1)
    end do
    if (common == 0 .or. common == huge(common)) return
    do k = 1, size(lines)
        if (verify(lines(k)%s, ' '//achar(9)) == 0) then
            lines(k)%s = ''
        else
            lines(k)%s = lines(k)%s(common + 1:)
        end if
    end do
end subroutine dedent

!> Convert Markdown `source` to HTML.
recursive subroutine markdown_to_html(source, options, html)
    character(len=*), intent(in) :: source              !! the Markdown
    type(markdown_options_t), intent(in) :: options     !! what rendering depends on
    character(len=:), allocatable, intent(out) :: html  !! the HTML
    type(tree_t) :: t
    type(string_t), allocatable :: lines(:), chunks(:)
    character(len=:), allocatable :: text
    type(buffer_t) :: out

    allocate (t%nodes(32), t%stash(0), t%refs(0), t%notes(0), t%headings(0), t%ids(0))
    if (allocated(options%abbreviations)) then
        t%abbreviations = options%abbreviations
    else
        allocate (t%abbreviations(0))
    end if
    t%state = ''
    t%n = 1
    t%nodes(1)%tag = 'div'
    allocate (t%nodes(1)%kids(0))

    lines = split_lines(source)
    call normalize_lines(lines)
    call expand_file_includes(lines, options, 1)
    call admonition_lines(lines)
    if (allocated(options%aliases)) call substitute_aliases(lines, options%aliases)
    call stash_fenced_code(t, lines, options)
    call stash_html_blocks(t, lines, options)
    call collect_definitions(t, lines)
    text = join(lines, NL)
    call split_chunks(text, chunks)
    call parse_chunks(t, 1, chunks)
    call render_children(t, 1, options, out)
    call render_footnotes(t, options, out)
    call take(out, html)
    if (options%toc) call insert_toc(t, html)
    call unstash(t, html)
end subroutine markdown_to_html

!> Expand tabs and blank lines of only spaces.
subroutine normalize_lines(lines)
    type(string_t), intent(inout) :: lines(:)   !! the lines
    integer :: k, j, column
    type(buffer_t) :: b

    do k = 1, size(lines)
        if (index(lines(k)%s, achar(9)) > 0) then
            column = 0
            do j = 1, len(lines(k)%s)
                if (lines(k)%s(j:j) == achar(9)) then
                    call add(b, repeat(' ', 4 - mod(column, 4)))
                    column = column + 4 - mod(column, 4)
                else
                    call add(b, lines(k)%s(j:j))
                    column = column + 1
                end if
            end do
            call take(b, lines(k)%s)
        end if
        if (verify(lines(k)%s, ' ') == 0) lines(k)%s = ''
    end do
end subroutine normalize_lines

!> Replace file include directives by the contents of the file.
recursive subroutine expand_file_includes(lines, options, depth)
    type(string_t), allocatable, intent(inout) :: lines(:)  !! the lines
    type(markdown_options_t), intent(in) :: options         !! what rendering depends on
    integer, intent(in) :: depth                            !! how many includes deep this is
    type(string_t), allocatable :: out(:), included(:)
    character(len=:), allocatable :: contents, msg, path, before, after
    integer :: k, a, b, stat, j

    if (depth > 16) return
    if (.not. allocated(options%base_path)) return
    if (.not. any([(index(lines(k)%s, '{!') > 0, k=1, size(lines))])) return
    allocate (out(0))
    do k = 1, size(lines)
        a = index(lines(k)%s, '{!')
        b = 0
        if (a > 0) b = index(lines(k)%s(a + 2:), '!}')
        if (a == 0 .or. b == 0) then
            call push(out, lines(k)%s)
            cycle
        end if
        ! not `join_path`, which returns a deferred-length string
        path = strip(lines(k)%s(a + 2:a + b))
        if (.not. starts_with(path, '/')) path = options%base_path//'/'//path
        call read_file(path, contents, stat, msg)
        if (stat /= 0) then
            call warn('could not include '//path)
            call push(out, lines(k)%s)
            cycle
        end if
        included = split_lines(contents)
        call normalize_lines(included)
        call expand_file_includes(included, options, depth + 1)
        before = lines(k)%s(:a - 1)
        after = lines(k)%s(a + b + 3:)
        if (size(included) == 0) then
            call push(out, before//after)
            cycle
        end if
        included(1)%s = before//included(1)%s
        included(size(included))%s = included(size(included))%s//after
        do j = 1, size(included)
            call push(out, included(j)%s)
        end do
    end do
    call move_alloc(out, lines)
end subroutine expand_file_includes

!> The admonition type that starts at `line`, or `''`, with where it is and what follows it.
subroutine admonition_start(line, prefix, kind, rest)
    character(len=*), intent(in) :: line                !! the line
    character(len=*), intent(in) :: prefix              !! `@` or `@end`
    character(len=:), allocatable, intent(out) :: kind  !! the type, in lowercase, or `''`
    character(len=:), allocatable, intent(out) :: rest  !! what follows it
    character(len=*), parameter :: KINDS(*) = [character(len=7) :: 'note', 'warning', 'todo', 'bug', 'history']
    integer :: k, at, n

    kind = ''
    rest = ''
    at = verify(line, ' ')
    if (at == 0) return
    do k = 1, size(KINDS)
        n = len_trim(KINDS(k))
        if (at + len(prefix) + n - 1 > len(line)) cycle
        if (lowercase(line(at:at + len(prefix) + n - 1)) == prefix//KINDS(k) (1:n)) then
            kind = KINDS(k) (1:n)
            rest = strip(line(at + len(prefix) + n:))
            return
        end if
    end do
end subroutine admonition_start

!> Turn `@note` blocks into a line `@note Type` followed by indented lines, ending at `@endnote`, a
!> blank line, another admonition, or the end of the text.
subroutine admonition_lines(lines)
    type(string_t), allocatable, intent(inout) :: lines(:)  !! the lines
    type(string_t), allocatable :: out(:)
    character(len=:), allocatable :: kind, rest, end_kind, end_rest
    integer :: k, j, stop_at, blank
    logical :: explicit

    if (.not. any([(index(lines(k)%s, '@') > 0, k=1, size(lines))])) return
    allocate (out(0))
    k = 1
    do while (k <= size(lines))
        call admonition_start(lines(k)%s, '@', kind, rest)
        if (len(kind) == 0) then
            call push(out, lines(k)%s)
            k = k + 1
            cycle
        end if
        ! the end: an end marker if there is one before the next admonition, or the first blank line
        stop_at = size(lines)
        blank = 0
        explicit = .false.
        do j = k + 1, size(lines)
            call admonition_start(lines(j)%s, '@end', end_kind, end_rest)
            if (len(end_kind) > 0) then
                stop_at = j
                explicit = .true.
                exit
            end if
            call admonition_start(lines(j)%s, '@', end_kind, end_rest)
            if (len(end_kind) > 0) then
                stop_at = j - 1
                exit
            end if
            if (len(lines(j)%s) == 0 .and. blank == 0) blank = j
        end do
        if (.not. explicit .and. blank > 0) stop_at = blank - 1

        call push(out, '')
        call push(out, '@note '//achar(iachar(kind(1:1)) - 32)//kind(2:))
        if (len(rest) > 0) call push(out, '    '//rest)
        do j = k + 1, stop_at
            if (explicit .and. j == stop_at) exit
            if (len(lines(j)%s) == 0) then
                call push(out, '')
            else
                call push(out, '    '//lines(j)%s)
            end if
        end do
        call push(out, '')
        if (explicit) then
            call admonition_start(lines(stop_at)%s, '@end', end_kind, end_rest)
            if (len(end_rest) > 0) call push(out, end_rest)
        end if
        k = stop_at + 1
    end do
    call move_alloc(out, lines)
end subroutine admonition_lines

!> Replace `|alias|` by its value. `\|alias|` gives the text without the backslash.
subroutine substitute_aliases(lines, aliases)
    type(string_t), intent(inout) :: lines(:)       !! the lines
    type(map_entry_t), intent(in) :: aliases(:)     !! the aliases
    type(buffer_t) :: b
    integer :: k, i, j, a
    logical :: found, changed

    do k = 1, size(lines)
        if (index(lines(k)%s, '|') == 0) cycle
        associate (line => lines(k)%s)
            changed = .false.
            i = 1
            do while (i <= len(line))
                if (line(i:i) /= '|') then
                    call add(b, line(i:i))
                    i = i + 1
                    cycle
                end if
                j = 0
                if (i < len(line)) then
                    if (line(i + 1:i + 1) /= ' ') j = index(line(i + 1:), '|')
                end if
                found = .false.
                if (j > 0 .and. (i == 1 .or. line(max(1, i - 1):max(1, i - 1)) /= '\')) then
                    do a = 1, size(aliases)
                        if (aliases(a)%key == line(i + 1:i + j - 1)) then
                            call add(b, aliases(a)%value)
                            i = i + j + 1
                            found = .true.
                            changed = .true.
                            exit
                        end if
                    end do
                end if
                if (found) cycle
                if (i > 1 .and. j > 0) then
                    if (line(i - 1:i - 1) == '\' .and. b%n > 0) then
                        b%n = b%n - 1
                        changed = .true.
                    end if
                end if
                call add(b, '|')
                i = i + 1
            end do
        end associate
        if (changed) then
            call take(b, lines(k)%s)
        else
            b%n = 0
        end if
    end do
end subroutine substitute_aliases

!> Keep `html` aside, returning the placeholder for it.
subroutine stash_html(t, html, placeholder)
    type(tree_t), intent(inout) :: t                            !! the conversion
    character(len=*), intent(in) :: html                        !! the HTML
    character(len=:), allocatable, intent(out) :: placeholder   !! what stands for it
    character(len=12) :: number

    call push(t%stash, html)
    write (number, '(i0)') size(t%stash)
    placeholder = STX//trim(number)//ETX
end subroutine stash_html

!> Put stashed HTML back into `html`.
subroutine unstash(t, html)
    type(tree_t), intent(in) :: t                       !! the conversion
    character(len=:), allocatable, intent(inout) :: html !! the HTML
    type(buffer_t) :: b
    integer :: i, j, k, number, ios
    logical :: changed

    do
        if (index(html, STX) == 0) return
        changed = .false.
        i = 1
        do while (i <= len(html))
            if (html(i:i) /= STX) then
                k = index(html(i:), STX)
                if (k == 0) k = len(html) - i + 2
                call add(b, html(i:i + k - 2))
                i = i + k - 1
                cycle
            end if
            j = index(html(i:), ETX)
            if (j == 0) then
                i = i + 1
                cycle
            end if
            read (html(i + 1:i + j - 2), *, iostat=ios) number
            if (ios == 0 .and. number >= 1 .and. number <= size(t%stash)) then
                call add(b, t%stash(number)%s)
                changed = .true.
            end if
            i = i + j
        end do
        call take(b, html)
        if (.not. changed) return
    end do
end subroutine unstash

!> Replace fenced code blocks by placeholders.
subroutine stash_fenced_code(t, lines, options)
    type(tree_t), intent(inout) :: t                        !! the conversion
    type(string_t), allocatable, intent(inout) :: lines(:)  !! the lines
    type(markdown_options_t), intent(in) :: options         !! what rendering depends on
    type(string_t), allocatable :: out(:)
    character(len=:), allocatable :: info, html, placeholder, lang
    type(buffer_t) :: code
    integer :: k, j, n, m
    character :: fence

    if (.not. any([(index(lines(k)%s, '```') > 0 .or. index(lines(k)%s, '~~~') > 0, k=1, size(lines))])) return
    allocate (out(0))
    k = 1
    do while (k <= size(lines))
        n = fence_length(lines(k)%s)
        j = 0
        if (n > 0) then
            fence = lines(k)%s(1:1)
            do j = k + 1, size(lines)
                m = fence_length(lines(j)%s)
                if (m >= n .and. lines(j)%s(1:1) == fence .and. len(strip(lines(j)%s(m + 1:))) == 0) exit
            end do
            if (j > size(lines)) j = 0
        end if
        if (j == 0) then
            call push(out, lines(k)%s)
            k = k + 1
            cycle
        end if
        info = strip(lines(k)%s(n + 1:))
        call fence_language(info, lang)
        do m = k + 1, j - 1
            call add(code, lines(m)%s)
            call add(code, NL)
        end do
        call take(code, info)
        call code_block_html(info, lang, html)
        call stash_html(t, html, placeholder)
        call push(out, '')
        call push(out, placeholder)
        call push(out, '')
        k = j + 1
    end do
    call move_alloc(out, lines)
end subroutine stash_fenced_code

!> The length of the code fence that `line` starts with, or 0.
pure integer function fence_length(line)
    character(len=*), intent(in) :: line    !! the line
    character :: c

    fence_length = 0
    if (len(line) < 3) return
    c = line(1:1)
    if (c /= '`' .and. c /= '~') return
    fence_length = verify(line//' ', c) - 1
    if (fence_length < 3) fence_length = 0
end function fence_length

!> The language named after a code fence.
subroutine fence_language(info, lang)
    character(len=*), intent(in) :: info                !! what follows the fence
    character(len=:), allocatable, intent(out) :: lang  !! the language, or `''`
    integer :: at

    lang = info
    if (starts_with(lang, '{')) then
        at = index(lang, '.')
        lang = ''
        if (at > 0) lang = info(at + 1:scan(info(at:)//' ', ' }') + at - 2)
        return
    end if
    at = index(lang, ' ')
    if (at > 0) lang = lang(:at - 1)
    if (starts_with(lang, '.')) lang = lang(2:)
end subroutine fence_language

!> The HTML of a code block.
subroutine code_block_html(code, lang, html)
    character(len=*), intent(in) :: code                !! the code
    character(len=*), intent(in) :: lang                !! its language, or `''`
    character(len=:), allocatable, intent(out) :: html  !! the HTML
    type(buffer_t) :: b

    call add(b, '<div class="codehilite"><pre><code')
    if (len(lang) > 0) then
        call add(b, ' class="language-')
        call html_escape(lang, b, .true.)
        call add(b, '"')
    end if
    call add(b, '>')
    select case (lowercase(lang))
    case ('fortran', 'f90', 'f', 'fortranfixed')
        call highlight_fortran(code, b, .false.)
    case default
        call html_escape(code, b, .false.)
    end select
    call add(b, '</code></pre></div>')
    call take(b, html)
end subroutine code_block_html

!> The tag at position `at` of `line`, in lowercase, or `''`.
pure subroutine tag_at(line, at, tag)
    character(len=*), intent(in) :: line                !! the line
    integer, intent(in) :: at                           !! the position of `<`
    character(len=:), allocatable, intent(out) :: tag   !! the tag
    integer :: n

    tag = ''
    if (at + 1 > len(line)) return
    n = verify(line(at + 1:)//' ', 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
    if (n > 1) tag = lowercase(line(at + 1:at + n - 1))
end subroutine tag_at

!> Replace block-level HTML by placeholders, rendering the contents of `markdown="1"` elements.
recursive subroutine stash_html_blocks(t, lines, options)
    type(tree_t), intent(inout) :: t                        !! the conversion
    type(string_t), allocatable, intent(inout) :: lines(:)  !! the lines
    type(markdown_options_t), intent(in) :: options         !! what rendering depends on
    type(string_t), allocatable :: out(:)
    character(len=:), allocatable :: tag, text, placeholder, open_tag, inner, rendered, rest
    type(buffer_t) :: b
    integer :: k, at, stop_at, j, gt
    logical :: previous_blank

    if (.not. any([(index(lines(k)%s, '<') > 0, k=1, size(lines))])) return
    allocate (out(0))
    previous_blank = .true.
    k = 1
    do while (k <= size(lines))
        at = verify(lines(k)%s, ' ')
        tag = ''
        if (at > 0 .and. at <= 4 .and. previous_blank) then
            if (lines(k)%s(at:at) == '<') then
                call tag_at(lines(k)%s, at, tag)
                if (index(BLOCK_TAGS, ' '//tag//' ') == 0) tag = ''
                if (starts_with(lines(k)%s(at:), '<!--')) tag = '!--'
            end if
        end if
        if (len(tag) == 0) then
            call push(out, lines(k)%s)
            previous_blank = len(lines(k)%s) == 0
            k = k + 1
            cycle
        end if

        text = join(lines(k:), NL)
        call element_end(text, at, tag, stop_at)
        if (stop_at == 0) then
            call push(out, lines(k)%s)
            previous_blank = .false.
            k = k + 1
            cycle
        end if
        gt = index(text(at:), '>') + at - 1
        open_tag = text(at:gt)
        if (index(lowercase(open_tag), 'markdown=') > 0 .and. tag /= '!--') then
            call remove_markdown_attribute(open_tag)
            inner = text(gt + 1:stop_at - len(tag) - 3)
            call markdown_to_html(inner, options, rendered)
            call add(b, open_tag//NL)
            call add(b, rendered)
            call add(b, NL//'</'//tag//'>')
            call take(b, rendered)
            call stash_html(t, rendered, placeholder)
        else
            call stash_html(t, text(at:stop_at), placeholder)
        end if
        call push(out, '')
        call push(out, placeholder)
        call push(out, '')

        ! carry on after the element
        j = 1 + count_newlines(text(:stop_at))
        rest = text(stop_at + 1:)
        k = k + j
        if (len(strip(first_line_of(rest))) > 0) then
            k = k - 1
            lines(k)%s = first_line_of(rest)
        end if
        previous_blank = .true.
    end do
    call move_alloc(out, lines)
end subroutine stash_html_blocks

!> The first line of `text`.
pure function first_line_of(text) result(line)
    character(len=*), intent(in) :: text    !! the text
    character(len=merge(len(text), index(text, NL) - 1, index(text, NL) == 0)) :: line
    line = text
end function first_line_of

!> Number of line feeds in `text`.
pure integer function count_newlines(text)
    character(len=*), intent(in) :: text    !! the text
    integer :: k
    count_newlines = 0
    do k = 1, len(text)
        if (text(k:k) == NL) count_newlines = count_newlines + 1
    end do
end function count_newlines

!> Remove `markdown="..."` from an opening tag.
subroutine remove_markdown_attribute(open_tag)
    character(len=:), allocatable, intent(inout) :: open_tag    !! the tag
    integer :: a, b

    a = index(lowercase(open_tag), 'markdown=')
    b = a + 9
    if (open_tag(b:b) == '"' .or. open_tag(b:b) == "'") b = b + index(open_tag(b + 1:), open_tag(b:b))
    open_tag = strip(open_tag(:a - 1))//open_tag(b + 1:)
    a = index(open_tag, ' >')
    if (a > 0) open_tag = open_tag(:a - 1)//open_tag(a + 1:)
end subroutine remove_markdown_attribute

!> The position of the end of the element starting at `start`, or 0.
pure subroutine element_end(text, start, tag, stop_at)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: start            !! where its `<` is
    character(len=*), intent(in) :: tag     !! its tag, or `!--` for a comment
    integer, intent(out) :: stop_at         !! the position of its last `>`
    character(len=len(text)) :: low
    integer :: i, depth, gt

    stop_at = 0
    if (tag == '!--') then
        i = index(text(start:), '-->')
        if (i > 0) stop_at = start + i + 1
        return
    end if
    if (tag == 'hr') then
        i = index(text(start:), '>')
        if (i > 0) stop_at = start + i - 1
        return
    end if
    low = lowercase(text)
    depth = 0
    i = start
    do while (i <= len(text))
        if (low(i:i) /= '<') then
            i = i + 1
            cycle
        end if
        if (word_at(low, i + 1, tag)) then
            gt = index(low(i:), '>')
            if (gt == 0) return
            if (low(i + gt - 2:i + gt - 2) /= '/') depth = depth + 1
            if (depth == 0) then
                stop_at = i + gt - 1
                return
            end if
            i = i + gt
        else if (word_at(low, i + 2, tag) .and. low(i + 1:i + 1) == '/') then
            depth = depth - 1
            gt = index(low(i:), '>')
            if (gt == 0) return
            if (depth == 0) then
                stop_at = i + gt - 1
                return
            end if
            i = i + gt
        else
            i = i + 1
        end if
    end do
end subroutine element_end

!> Remove link references, footnotes and abbreviations from `lines` and keep them.
subroutine collect_definitions(t, lines)
    type(tree_t), intent(inout) :: t                        !! the conversion
    type(string_t), allocatable, intent(inout) :: lines(:)  !! the lines
    type(string_t), allocatable :: out(:)
    character(len=:), allocatable :: id, value, url, title, body
    type(buffer_t) :: b
    integer :: k, close, at, j

    allocate (out(0))
    k = 1
    do while (k <= size(lines))
        associate (line => lines(k)%s)
            close = 0
            at = verify(line, ' ')
            if (at >= 1 .and. at <= 4) then
                if (line(at:at) == '[') close = index(line(at:), ']:') + at - 1
                if (close > at + 0 .and. index(line(at:close - 1), ']') > 0) close = 0
                if (close == at - 1) close = 0
            end if
            if (at == 1 .and. starts_with(line, '*[')) then
                j = index(line, ']:')
                if (j > 3) then
                    t%abbreviations = [t%abbreviations, map_entry_t(line(3:j - 1), strip(line(j + 2:)))]
                    k = k + 1
                    cycle
                end if
            end if
            if (close == 0) then
                call push(out, line)
                k = k + 1
                cycle
            end if
            id = line(at + 1:close - 1)
            value = strip(line(close + 2:))
        end associate
        if (starts_with(id, '^')) then
            ! a footnote: the rest of the line, and the indented lines and blocks after it
            call add(b, value)
            call add(b, NL)
            k = k + 1
            do while (k <= size(lines))
                if (starts_with(lines(k)%s, '    ')) then
                    call add(b, lines(k)%s(5:))
                    call add(b, NL)
                else if (len(lines(k)%s) == 0 .and. k < size(lines)) then
                    if (.not. starts_with(lines(k + 1)%s, '    ')) exit
                    call add(b, NL)
                else
                    exit
                end if
                k = k + 1
            end do
            call take(b, body)
            t%notes = [t%notes, footnote_t(id(2:), body, .false.)]
            cycle
        end if
        if (len(value) == 0 .and. k < size(lines)) then
            k = k + 1
            value = strip(lines(k)%s)
        end if
        if (len(value) == 0) then
            call push(out, lines(k)%s)
            k = k + 1
            cycle
        end if
        title = ''
        at = scan(value, ' ')
        if (at > 0) then
            url = value(:at - 1)
            title = strip(value(at + 1:))
            if (len(title) >= 2 .and. scan(title(1:1), '"''(') > 0) then
                title = title(2:len(title) - 1)
            else
                call push(out, lines(k)%s)
                k = k + 1
                cycle
            end if
        else
            url = value
        end if
        if (starts_with(url, '<') .and. ends_with(url, '>')) url = url(2:len(url) - 1)
        call normal_id(id, value)
        t%refs = [t%refs, reference_t(value, url, title)]
        k = k + 1
        if (k <= size(lines) .and. len(title) == 0) then
            value = strip(lines(k)%s)
            if (len(value) >= 2) then
                if (scan(value(1:1), '"''(') > 0 .and. scan(value(len(value):len(value)), '"'')') > 0) then
                    t%refs(size(t%refs))%title = value(2:len(value) - 1)
                    k = k + 1
                end if
            end if
        end if
    end do
    call move_alloc(out, lines)
end subroutine collect_definitions

!> `id` in lowercase, with runs of whitespace as single blanks.
subroutine normal_id(id, out)
    character(len=*), intent(in) :: id                  !! the reference name
    character(len=:), allocatable, intent(out) :: out   !! its normal form
    type(string_t), allocatable :: words(:)

    words = split_words(lowercase(id))
    out = join(words, ' ')
end subroutine normal_id

!> Split `text` at blank lines, as `text.split('\n\n')` does.
subroutine split_chunks(text, chunks)
    character(len=*), intent(in) :: text                    !! the text
    type(string_t), allocatable, intent(out) :: chunks(:)   !! the chunks
    integer :: start, at

    allocate (chunks(0))
    start = 1
    do
        at = index(text(start:), NL//NL)
        if (at == 0) exit
        call push(chunks, text(start:start + at - 2))
        start = start + at + 1
    end do
    call push(chunks, text(start:))
end subroutine split_chunks

!> Add a child with tag `tag` to node `parent`, returning it.
subroutine new_node(t, parent, tag, id)
    type(tree_t), intent(inout) :: t        !! the conversion
    integer, intent(in) :: parent           !! the parent
    character(len=*), intent(in) :: tag     !! the tag
    integer, intent(out) :: id              !! the new node
    type(node_t), allocatable :: grown(:)
    integer :: k

    if (t%n == size(t%nodes)) then
        allocate (grown(2*t%n))
        do k = 1, t%n
            call move_alloc(t%nodes(k)%tag, grown(k)%tag)
            call move_alloc(t%nodes(k)%text, grown(k)%text)
            call move_alloc(t%nodes(k)%attrs, grown(k)%attrs)
            call move_alloc(t%nodes(k)%kids, grown(k)%kids)
        end do
        call move_alloc(grown, t%nodes)
    end if
    t%n = t%n + 1
    id = t%n
    t%nodes(id)%tag = tag
    t%nodes(id)%text = ''
    t%nodes(id)%attrs = ''
    allocate (t%nodes(id)%kids(0))
    call push_int(t%nodes(parent)%kids, id)
end subroutine new_node

!> The last child of node `parent`, or 0.
pure integer function last_child(t, parent)
    type(tree_t), intent(in) :: t   !! the conversion
    integer, intent(in) :: parent   !! the node

    last_child = 0
    if (size(t%nodes(parent)%kids) > 0) last_child = t%nodes(parent)%kids(size(t%nodes(parent)%kids))
end function last_child

!> True if the innermost parser state is `state`.
pure logical function in_state(t, state)
    type(tree_t), intent(in) :: t           !! the conversion
    character(len=*), intent(in) :: state   !! the state

    in_state = ends_with(t%state, ','//state)
end function in_state

!> Enter parser state `state`.
pure subroutine set_state(t, state)
    type(tree_t), intent(inout) :: t        !! the conversion
    character(len=*), intent(in) :: state   !! the state
    t%state = t%state//','//state
end subroutine set_state

!> Leave the innermost parser state.
pure subroutine reset_state(t)
    type(tree_t), intent(inout) :: t    !! the conversion
    t%state = t%state(:index(t%state, ',', back=.true.) - 1)
end subroutine reset_state

!> Parse `chunks` into node `parent`.
recursive subroutine parse_chunks(t, parent, chunks)
    type(tree_t), intent(inout) :: t                !! the conversion
    integer, intent(in) :: parent                   !! the node
    type(string_t), intent(in) :: chunks(:)         !! the chunks
    type(string_t), allocatable :: stack(:)
    character(len=:), allocatable :: block
    integer :: n, k

    t%depth = t%depth + 1
    n = size(chunks)
    allocate (stack(n))
    do k = 1, n
        stack(n - k + 1)%s = chunks(k)%s
    end do
    do while (n > 0)
        call move_alloc(stack(n)%s, block)
        n = n - 1
        call parse_block(t, parent, block, stack, n)
    end do
    t%depth = t%depth - 1
end subroutine parse_chunks

!> Parse the single chunk `chunk` into node `parent`.
recursive subroutine parse_one(t, parent, chunk)
    type(tree_t), intent(inout) :: t        !! the conversion
    integer, intent(in) :: parent           !! the node
    character(len=*), intent(in) :: chunk   !! the chunk

    call parse_chunks(t, parent, [string_t(chunk)])
end subroutine parse_one

!> Parse text that may hold several chunks into node `parent`.
recursive subroutine parse_text(t, parent, text)
    type(tree_t), intent(inout) :: t        !! the conversion
    integer, intent(in) :: parent           !! the node
    character(len=*), intent(in) :: text    !! the text
    type(string_t), allocatable :: chunks(:)

    call split_chunks(text, chunks)
    call parse_chunks(t, parent, chunks)
end subroutine parse_text

!> Put `text` back on the stack of chunks.
subroutine push_back(stack, n, text)
    type(string_t), allocatable, intent(inout) :: stack(:)  !! the chunks, the next one last
    integer, intent(inout) :: n                             !! how many there are
    character(len=*), intent(in) :: text                    !! the chunk
    type(string_t), allocatable :: grown(:)
    integer :: k

    if (n == size(stack)) then
        allocate (grown(2*n + 4))
        do k = 1, n
            call move_alloc(stack(k)%s, grown(k)%s)
        end do
        call move_alloc(grown, stack)
    end if
    n = n + 1
    stack(n)%s = text
end subroutine push_back

!> True if `tag` is `ul` or `ol`.
pure logical function is_list(tag)
    character(len=*), intent(in) :: tag !! the tag
    is_list = tag == 'ul' .or. tag == 'ol'
end function is_list

!> Find the block processor for `block` and run it.
recursive subroutine parse_block(t, parent, block, stack, n)
    type(tree_t), intent(inout) :: t                        !! the conversion
    integer, intent(in) :: parent                           !! the node
    character(len=:), allocatable, intent(inout) :: block   !! the chunk
    type(string_t), allocatable, intent(inout) :: stack(:)  !! the chunks left, the next one last
    integer, intent(inout) :: n                             !! how many there are
    character(len=:), allocatable :: tag
    integer :: sibling, at, stop_at
    logical :: code_sibling

    sibling = last_child(t, parent)
    code_sibling = .false.
    if (sibling > 0) code_sibling = t%nodes(sibling)%tag == 'code'

    ! empty
    if (len(block) == 0) then
        if (code_sibling) t%nodes(sibling)%text = t%nodes(sibling)%text//NL//NL
        return
    end if
    if (block(1:1) == NL) then
        if (code_sibling) t%nodes(sibling)%text = t%nodes(sibling)%text//NL
        if (len(block) > 1) call push_back(stack, n, block(2:))
        return
    end if

    tag = t%nodes(parent)%tag

    ! list indent
    if (starts_with(block, '    ') .and. .not. in_state(t, 'detabbed')) then
        if (tag == 'li' .or. tag == 'dd') then
            call list_indent(t, parent, block)
            return
        end if
        if (sibling > 0) then
            if (is_list(t%nodes(sibling)%tag)) then
                call list_indent(t, parent, block)
                return
            end if
        end if
    end if

    ! code
    if (starts_with(block, '    ')) then
        call code_block(t, parent, block, stack, n)
        return
    end if

    ! admonition
    if (starts_with(block, '@note ')) then
        call admonition_block(t, parent, block, stack, n)
        return
    end if

    ! headers
    call find_hash_header(block, at, stop_at)
    if (at > 0) then
        call hash_header(t, parent, block, at, stop_at, stack, n)
        return
    end if
    if (is_setext(block)) then
        call setext_header(t, parent, block, stack, n)
        return
    end if

    ! horizontal rule
    call find_rule(block, at, stop_at)
    if (at > 0) then
        if (at > 1) call parse_one(t, parent, trimmed_end(block(:at - 1)))
        call new_node(t, parent, 'hr', sibling)
        if (stop_at < len(block)) call push_back(stack, n, block(stop_at + 2:))
        return
    end if

    ! lists
    if (is_ordered_item(block)) then
        call list_block(t, parent, block, 'ol')
        return
    end if
    if (is_bullet_item(block)) then
        call list_block(t, parent, block, 'ul')
        return
    end if

    ! block quote
    call find_quote(block, at)
    if (at > 0) then
        call quote_block(t, parent, block, at)
        return
    end if

    ! tables, definition lists, paragraphs
    if (is_table(block)) then
        call new_node(t, parent, 'table', sibling)
        t%nodes(sibling)%text = block
        return
    end if
    call find_definition(block, at)
    if (at > 0) then
        call definition_block(t, parent, block, at, stack, n)
        return
    end if
    call paragraph(t, parent, block)
end subroutine parse_block

!> `text` without trailing line feeds.
pure function trimmed_end(text) result(out)
    character(len=*), intent(in) :: text    !! the text
    character(len=max(0, verify(text, NL, back=.true.))) :: out
    out = text
end function trimmed_end

!> The indented block processor: `block` continues a list.
recursive subroutine list_indent(t, parent, block)
    type(tree_t), intent(inout) :: t        !! the conversion
    integer, intent(in) :: parent           !! the node
    character(len=*), intent(in) :: block   !! the chunk
    character(len=:), allocatable :: detabbed
    integer :: level, sibling, last, p, kept

    call indent_level(t, parent, block, level, sibling)
    call loose_detab(block, level, detabbed)
    call set_state(t, 'detabbed')
    if (t%nodes(parent)%tag == 'li' .or. t%nodes(parent)%tag == 'dd') then
        last = last_child(t, parent)
        kept = parent
        if (last > 0) then
            if (is_list(t%nodes(last)%tag)) kept = last
        end if
        call parse_one(t, kept, detabbed)
    else if (t%nodes(sibling)%tag == 'li') then
        call parse_one(t, sibling, detabbed)
    else if (last_child(t, sibling) > 0) then
        last = last_child(t, sibling)
        if (t%nodes(last)%tag == 'li') then
            if (len(t%nodes(last)%text) > 0) then
                ! the item's text becomes a paragraph, before any sublist
                call new_node(t, last, 'p', p)
                t%nodes(p)%text = t%nodes(last)%text
                t%nodes(last)%text = ''
                t%nodes(last)%kids = [p, t%nodes(last)%kids(:size(t%nodes(last)%kids) - 1)]
            end if
            call parse_text(t, last, detabbed)
        else
            call new_node(t, sibling, 'li', p)
            call parse_one(t, p, detabbed)
        end if
    else
        call new_node(t, sibling, 'li', p)
        call parse_one(t, p, detabbed)
    end if
    call reset_state(t)
end subroutine list_indent

!> How deep `block` is in the lists of `parent`, and the node at that depth.
subroutine indent_level(t, parent, block, level, node)
    type(tree_t), intent(in) :: t           !! the conversion
    integer, intent(in) :: parent           !! the node
    character(len=*), intent(in) :: block   !! the chunk
    integer, intent(out) :: level           !! the list depth
    integer, intent(out) :: node            !! the node at that depth
    integer :: indent, child

    indent = (verify(block//'x', ' ') - 1)/4
    level = merge(1, 0, in_state(t, 'list'))
    node = parent
    do while (indent > level)
        child = last_child(t, node)
        if (child == 0) exit
        if (is_list(t%nodes(child)%tag)) then
            level = level + 1
        else if (t%nodes(child)%tag /= 'li') then
            exit
        end if
        node = child
    end do
end subroutine indent_level

!> Remove `level` indents from each line of `block` that has them.
subroutine loose_detab(block, level, out)
    character(len=*), intent(in) :: block               !! the chunk
    integer, intent(in) :: level                        !! how many indents
    character(len=:), allocatable, intent(out) :: out   !! the result
    type(string_t), allocatable :: lines(:)
    integer :: k, width

    lines = split_on(block, NL)
    width = 4*level
    do k = 1, size(lines)
        if (width > 0 .and. starts_with(lines(k)%s, repeat(' ', width))) lines(k)%s = lines(k)%s(width + 1:)
    end do
    out = join(lines, NL)
end subroutine loose_detab

!> The code block processor.
subroutine code_block(t, parent, block, stack, n)
    type(tree_t), intent(inout) :: t                        !! the conversion
    integer, intent(in) :: parent                           !! the node
    character(len=*), intent(in) :: block                   !! the chunk
    type(string_t), allocatable, intent(inout) :: stack(:)  !! the chunks left
    integer, intent(inout) :: n                             !! how many there are
    type(string_t), allocatable :: lines(:)
    character(len=:), allocatable :: code, rest
    integer :: k, last, sibling, node

    lines = split_on(block, NL)
    last = 0
    do k = 1, size(lines)
        if (len(lines(k)%s) > 0 .and. .not. starts_with(lines(k)%s, '    ')) exit
        last = k
        if (len(lines(k)%s) > 0) lines(k)%s = lines(k)%s(5:)
    end do
    code = join(lines(:last), NL)
    code = code(:len_trim(trimmed_end(code)))
    rest = ''
    if (last < size(lines)) rest = join(lines(last + 1:), NL)
    sibling = last_child(t, parent)
    node = 0
    if (sibling > 0) then
        if (t%nodes(sibling)%tag == 'code') node = sibling
    end if
    if (node > 0) then
        t%nodes(node)%text = t%nodes(node)%text//NL//code//NL
    else
        call new_node(t, parent, 'code', node)
        t%nodes(node)%text = code//NL
    end if
    if (len(rest) > 0) call push_back(stack, n, rest)
end subroutine code_block

!> An admonition: a line `@note Type`, then indented text.
recursive subroutine admonition_block(t, parent, block, stack, n)
    type(tree_t), intent(inout) :: t                        !! the conversion
    integer, intent(in) :: parent                           !! the node
    character(len=*), intent(in) :: block                   !! the chunk
    type(string_t), allocatable, intent(inout) :: stack(:)  !! the chunks left
    integer, intent(inout) :: n                             !! how many there are
    character(len=:), allocatable :: kind, css, inner
    integer :: at, node, title

    at = index(block, NL)
    if (at == 0) at = len(block) + 1
    kind = strip(block(7:at - 1))
    select case (lowercase(kind))
    case ('note'); css = 'info'
    case ('warning'); css = 'warning'
    case ('todo'); css = 'success'
    case ('bug'); css = 'danger'
    case default; css = 'history'
    end select
    call new_node(t, parent, 'div', node)
    t%nodes(node)%attrs = ' class="alert alert-'//css//'"'
    call new_node(t, node, 'p', title)
    t%nodes(title)%attrs = ' class="alert-title h4"'
    t%nodes(title)%text = kind
    inner = ''
    if (at < len(block)) call loose_detab(block(at + 1:), 1, inner)
    call set_state(t, 'detabbed')
    if (len(inner) > 0) call parse_one(t, node, inner)
    do while (n > 0)
        ! the following indented chunks belong to it
        if (.not. starts_with(stack(n)%s, '    ')) then
            if (len(stack(n)%s) == 0 .and. n > 1) then
                if (starts_with(stack(n - 1)%s, '    ')) then
                    n = n - 1
                    cycle
                end if
            end if
            exit
        end if
        call loose_detab(stack(n)%s, 1, inner)
        n = n - 1
        call parse_one(t, node, inner)
    end do
    call reset_state(t)
end subroutine admonition_block

!> Find the first `#` header line of `block`.
pure subroutine find_hash_header(block, at, stop_at)
    character(len=*), intent(in) :: block   !! the chunk
    integer, intent(out) :: at              !! where it starts, or 0
    integer, intent(out) :: stop_at         !! where it ends, before its line feed
    integer :: i, j

    at = 0
    stop_at = 0
    i = 1
    do while (i <= len(block))
        if (block(i:i) == '#') then
            at = i
            j = index(block(i:), NL)
            stop_at = merge(len(block), i + j - 2, j == 0)
            return
        end if
        j = index(block(i:), NL)
        if (j == 0) return
        i = i + j
    end do
end subroutine find_hash_header

!> The `#` header processor.
recursive subroutine hash_header(t, parent, block, at, stop_at, stack, n)
    type(tree_t), intent(inout) :: t                        !! the conversion
    integer, intent(in) :: parent                           !! the node
    character(len=*), intent(in) :: block                   !! the chunk
    integer, intent(in) :: at                               !! where the header starts
    integer, intent(in) :: stop_at                          !! where it ends
    type(string_t), allocatable, intent(inout) :: stack(:)  !! the chunks left
    integer, intent(inout) :: n                             !! how many there are
    character(len=:), allocatable :: text
    integer :: level, node, last

    if (at > 1) call parse_one(t, parent, block(:at - 2))
    level = min(6, verify(block(at:stop_at)//' ', '#') - 1)
    text = block(at + level:stop_at)
    last = len_trim(text)
    do while (last > 0)
        if (text(last:last) /= '#') exit
        last = last - 1
    end do
    call new_node(t, parent, 'h'//achar(iachar('0') + level), node)
    t%nodes(node)%text = strip(text(:last))
    if (stop_at + 1 < len(block)) call push_back(stack, n, block(stop_at + 2:))
end subroutine hash_header

!> True if the second line of `block` underlines the first.
pure logical function is_setext(block)
    character(len=*), intent(in) :: block   !! the chunk
    integer :: a, b
    character :: c

    is_setext = .false.
    a = index(block, NL)
    if (a == 0 .or. a == len(block)) return
    b = index(block(a + 1:), NL)
    b = merge(len(block), a + b - 1, b == 0)
    c = block(a + 1:a + 1)
    if (c /= '=' .and. c /= '-') return
    is_setext = verify(block(a + 1:b), c//' ') == 0 .and. verify(strip(block(a + 1:b)), c) == 0
end function is_setext

!> The underlined header processor.
recursive subroutine setext_header(t, parent, block, stack, n)
    type(tree_t), intent(inout) :: t                        !! the conversion
    integer, intent(in) :: parent                           !! the node
    character(len=*), intent(in) :: block                   !! the chunk
    type(string_t), allocatable, intent(inout) :: stack(:)  !! the chunks left
    integer, intent(inout) :: n                             !! how many there are
    integer :: a, b, node

    a = index(block, NL)
    b = index(block(a + 1:), NL)
    call new_node(t, parent, merge('h1', 'h2', block(a + 1:a + 1) == '='), node)
    t%nodes(node)%text = strip(block(:a - 1))
    if (b > 0) call push_back(stack, n, block(a + b + 1:))
end subroutine setext_header

!> Find a line of `block` that is a horizontal rule.
pure subroutine find_rule(block, at, stop_at)
    character(len=*), intent(in) :: block   !! the chunk
    integer, intent(out) :: at              !! where it starts, or 0
    integer, intent(out) :: stop_at         !! where it ends
    integer :: i, j, last

    at = 0
    stop_at = 0
    i = 1
    do while (i <= len(block))
        j = index(block(i:), NL)
        last = merge(len(block), i + j - 2, j == 0)
        if (is_rule(block(i:last))) then
            at = i
            stop_at = last
            return
        end if
        if (j == 0) return
        i = i + j
    end do
end subroutine find_rule

!> True if `line` is a horizontal rule.
pure logical function is_rule(line)
    character(len=*), intent(in) :: line    !! the line
    integer :: first, k, marks
    character :: c

    is_rule = .false.
    first = verify(line, ' ')
    if (first == 0 .or. first > 4) return
    c = line(first:first)
    if (c /= '-' .and. c /= '_' .and. c /= '*') return
    marks = 0
    do k = first, len(line)
        if (line(k:k) == c) then
            marks = marks + 1
        else if (line(k:k) /= ' ') then
            return
        end if
    end do
    is_rule = marks >= 3
end function is_rule

!> The position where the item text of a list line starts, or 0 if it is not one.
pure integer function item_text(line, ordered, bullet)
    character(len=*), intent(in) :: line    !! the line
    logical, intent(in) :: ordered          !! accept `1.`
    logical, intent(in) :: bullet           !! accept `*`, `+` and `-`
    integer :: first, k

    item_text = 0
    first = verify(line, ' ')
    if (first == 0 .or. first > 4) return
    k = first
    if (bullet .and. scan(line(k:k), '*+-') == 1) then
        k = k + 1
    else if (ordered .and. scan(line(k:k), '0123456789') == 1) then
        k = k + verify(line(k:)//' ', '0123456789') - 1
        if (k > len(line)) return
        if (line(k:k) /= '.') return
        k = k + 1
    else
        return
    end if
    if (k > len(line)) return
    if (line(k:k) /= ' ') return
    item_text = k + verify(line(k:)//'x', ' ') - 1
end function item_text

!> True if `block` starts with an ordered list item.
pure logical function is_ordered_item(block)
    character(len=*), intent(in) :: block   !! the chunk
    is_ordered_item = item_text(first_line_of(block), .true., .false.) > 0
end function is_ordered_item

!> True if `block` starts with a bullet list item.
pure logical function is_bullet_item(block)
    character(len=*), intent(in) :: block   !! the chunk
    is_bullet_item = item_text(first_line_of(block), .false., .true.) > 0
end function is_bullet_item

!> The items of a list chunk.
subroutine list_items(block, items)
    character(len=*), intent(in) :: block                   !! the chunk
    type(string_t), allocatable, intent(out) :: items(:)    !! the items
    type(string_t), allocatable :: lines(:)
    integer :: k, at, spaces, n

    lines = split_on(block, NL)
    allocate (items(0))
    do k = 1, size(lines)
        associate (line => lines(k)%s)
            at = item_text(line, .true., .true.)
            n = size(items)
            spaces = verify(line//'x', ' ') - 1
            if (at > 0) then
                call push(items, line(at:))
            else if (spaces >= 4 .and. spaces <= 7 .and. item_text(line(5:), .true., .true.) > 0 .and. n > 0) then
                if (starts_with(items(n)%s, '    ')) then
                    items(n)%s = items(n)%s//NL//line
                else
                    call push(items, line)
                end if
            else if (n > 0) then
                items(n)%s = items(n)%s//NL//line
            end if
        end associate
    end do
end subroutine list_items

!> The list processors.
recursive subroutine list_block(t, parent, block, tag)
    type(tree_t), intent(inout) :: t        !! the conversion
    integer, intent(in) :: parent           !! the node
    character(len=*), intent(in) :: block   !! the chunk
    character(len=*), intent(in) :: tag     !! `ol` or `ul`
    type(string_t), allocatable :: items(:)
    integer :: sibling, list, item, last, p, k, first

    call list_items(block, items)
    sibling = last_child(t, parent)
    first = 1
    list = 0
    if (sibling > 0) then
        if (is_list(t%nodes(sibling)%tag)) list = sibling
    end if
    if (list > 0) then
        last = last_child(t, list)
        if (last > 0) then
            if (len(t%nodes(last)%text) > 0) then
                call new_node(t, last, 'p', p)
                t%nodes(p)%text = t%nodes(last)%text
                t%nodes(last)%text = ''
                t%nodes(last)%kids = [p, t%nodes(last)%kids(:size(t%nodes(last)%kids) - 1)]
            end if
        end if
        call new_node(t, list, 'li', item)
        call set_state(t, 'looselist')
        call parse_one(t, item, items(1)%s)
        call reset_state(t)
        first = 2
    else if (is_list(t%nodes(parent)%tag)) then
        list = parent
    else
        call new_node(t, parent, tag, list)
    end if

    call set_state(t, 'list')
    do k = first, size(items)
        if (starts_with(items(k)%s, '    ')) then
            call parse_one(t, last_child(t, list), items(k)%s)
        else
            call new_node(t, list, 'li', item)
            call parse_one(t, item, items(k)%s)
        end if
    end do
    call reset_state(t)
end subroutine list_block

!> Find the first line of `block` that quotes.
pure subroutine find_quote(block, at)
    character(len=*), intent(in) :: block   !! the chunk
    integer, intent(out) :: at              !! where it starts, or 0
    integer :: i, j, first

    at = 0
    i = 1
    do while (i <= len(block))
        first = verify(block(i:)//'x', ' ')
        if (first <= 4 .and. i + first - 1 <= len(block)) then
            if (block(i + first - 1:i + first - 1) == '>') then
                at = i
                return
            end if
        end if
        j = index(block(i:), NL)
        if (j == 0) return
        i = i + j
    end do
end subroutine find_quote

!> The block quote processor.
recursive subroutine quote_block(t, parent, block, at)
    type(tree_t), intent(inout) :: t        !! the conversion
    integer, intent(in) :: parent           !! the node
    character(len=*), intent(in) :: block   !! the chunk
    integer, intent(in) :: at               !! where the quote starts
    type(string_t), allocatable :: lines(:)
    integer :: k, first, sibling, quote

    if (at > 1) call parse_one(t, parent, block(:at - 2))
    lines = split_on(block(at:), NL)
    do k = 1, size(lines)
        first = verify(lines(k)%s//'x', ' ')
        if (first > 4 .or. first > len(lines(k)%s)) cycle
        if (lines(k)%s(first:first) /= '>') cycle
        first = first + 1
        if (first <= len(lines(k)%s)) then
            if (lines(k)%s(first:first) == ' ') first = first + 1
        end if
        lines(k)%s = lines(k)%s(first:)
    end do
    sibling = last_child(t, parent)
    quote = 0
    if (sibling > 0) then
        if (t%nodes(sibling)%tag == 'blockquote') quote = sibling
    end if
    if (quote == 0) call new_node(t, parent, 'blockquote', quote)
    call set_state(t, 'blockquote')
    call parse_text(t, quote, join(lines, NL))
    call reset_state(t)
end subroutine quote_block

!> True if `block` is a table: a header line with `|`, then a separator line.
pure logical function is_table(block)
    character(len=*), intent(in) :: block   !! the chunk
    integer :: a, b

    is_table = .false.
    a = index(block, NL)
    if (a == 0) return
    if (index(block(:a - 1), '|') == 0) return
    b = index(block(a + 1:), NL)
    b = merge(len(block), a + b - 1, b == 0)
    if (b <= a) return
    is_table = verify(block(a + 1:b), '|:- ') == 0 .and. index(block(a + 1:b), '-') > 0
end function is_table

!> Find a definition line in `block`.
pure subroutine find_definition(block, at)
    character(len=*), intent(in) :: block   !! the chunk
    integer, intent(out) :: at              !! where it starts, or 0
    integer :: i, j, first

    at = 0
    i = 1
    do while (i <= len(block))
        first = verify(block(i:)//'x', ' ')
        if (first <= 4 .and. i + first <= len(block)) then
            if (block(i + first - 1:i + first) == ': ') then
                at = i
                return
            end if
        end if
        j = index(block(i:), NL)
        if (j == 0) return
        i = i + j
    end do
end subroutine find_definition

!> The definition list processor.
recursive subroutine definition_block(t, parent, block, at, stack, n)
    type(tree_t), intent(inout) :: t                        !! the conversion
    integer, intent(in) :: parent                           !! the node
    character(len=*), intent(in) :: block                   !! the chunk
    integer, intent(in) :: at                               !! where the definition starts
    type(string_t), allocatable, intent(inout) :: stack(:)  !! the chunks left
    integer, intent(inout) :: n                             !! how many there are
    type(string_t), allocatable :: terms(:), lines(:)
    character(len=:), allocatable :: def
    integer :: list, sibling, node, k, first, stop_line

    allocate (terms(0))
    if (at > 1) terms = split_on(block(:at - 2), NL)
    sibling = last_child(t, parent)
    list = 0
    if (sibling > 0) then
        if (t%nodes(sibling)%tag == 'dl') then
            list = sibling
        else if (size(terms) == 0 .and. t%nodes(sibling)%tag == 'p') then
            terms = split_on(t%nodes(sibling)%text, NL)
            t%nodes(parent)%kids = t%nodes(parent)%kids(:size(t%nodes(parent)%kids) - 1)
        end if
    end if
    if (size(terms) == 0 .and. list == 0) then
        call paragraph(t, parent, block)
        return
    end if
    if (list == 0) call new_node(t, parent, 'dl', list)
    do k = 1, size(terms)
        call new_node(t, list, 'dt', node)
        t%nodes(node)%text = strip(terms(k)%s)
    end do

    lines = split_on(block(at:), NL)
    stop_line = size(lines)
    do k = 2, size(lines)
        first = verify(lines(k)%s//'x', ' ')
        if (first <= 4 .and. first < len(lines(k)%s)) then
            if (lines(k)%s(first:first + 1) == ': ') then
                stop_line = k - 1
                exit
            end if
        end if
    end do
    first = index(lines(1)%s, ':')
    def = strip(lines(1)%s(first + 1:))
    do k = 2, stop_line
        def = def//NL//strip(lines(k)%s)
    end do
    call new_node(t, list, 'dd', node)
    call set_state(t, 'list')
    call parse_one(t, node, def)
    call reset_state(t)
    if (stop_line < size(lines)) call push_back(stack, n, join(lines(stop_line + 1:), NL))
end subroutine definition_block

!> The paragraph processor. In a tight list an item's text stays in the item.
subroutine paragraph(t, parent, block)
    type(tree_t), intent(inout) :: t        !! the conversion
    integer, intent(in) :: parent           !! the node
    character(len=*), intent(in) :: block   !! the chunk
    character(len=:), allocatable :: text, attrs
    integer :: node, sibling, at

    text = block
    if (verify(text, ' '//NL) == 0) return
    if (in_state(t, 'list')) then
        sibling = last_child(t, parent)
        if (sibling > 0) then
            ! text after a sublist
            call new_node(t, parent, 'p', node)
            t%nodes(node)%text = adjustl_text(text)
        else if (len(t%nodes(parent)%text) > 0) then
            t%nodes(parent)%text = t%nodes(parent)%text//NL//text
        else
            t%nodes(parent)%text = adjustl_text(text)
        end if
        return
    end if
    attrs = ''
    at = index(text, NL//'{:', back=.true.)
    if (at > 0 .and. ends_with(strip(text), '}')) then
        call attribute_list(strip(text(at + 3:len_trim(text) - 1)), attrs)
        text = text(:at - 1)
    end if
    call new_node(t, parent, 'p', node)
    t%nodes(node)%text = adjustl_text(text)
    t%nodes(node)%attrs = attrs
end subroutine paragraph

!> `text` without leading blanks.
pure function adjustl_text(text) result(out)
    character(len=*), intent(in) :: text    !! the text
    character(len=len(text) - verify(text//'x', ' ') + 1) :: out
    out = text(len(text) - len(out) + 1:)
end function adjustl_text

!> Turn the contents of an attribute list, `#id .class key=value`, into HTML attributes.
subroutine attribute_list(text, attrs)
    character(len=*), intent(in) :: text                !! the list
    character(len=:), allocatable, intent(out) :: attrs !! the attributes
    type(string_t), allocatable :: words(:)
    character(len=:), allocatable :: classes, id, others
    integer :: k, at

    words = split_words(text)
    classes = ''
    id = ''
    others = ''
    do k = 1, size(words)
        associate (w => words(k)%s)
            if (w(1:1) == '#') then
                id = w(2:)
            else if (w(1:1) == '.') then
                if (len(classes) > 0) classes = classes//' '
                classes = classes//w(2:)
            else
                at = index(w, '=')
                if (at > 0) others = others//' '//w(:at)//'"'//w(at + 1:)//'"'
            end if
        end associate
    end do
    attrs = others
    if (len(classes) > 0) attrs = ' class="'//classes//'"'//attrs
    if (len(id) > 0) attrs = attrs//' id="'//id//'"'
end subroutine attribute_list

!> Write the children of node `id`.
recursive subroutine render_children(t, id, options, out)
    type(tree_t), intent(inout) :: t                !! the conversion
    integer, intent(in) :: id                       !! the node
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    integer :: k

    do k = 1, size(t%nodes(id)%kids)
        if (k > 1) call add(out, NL)
        call render_node(t, t%nodes(id)%kids(k), options, out)
    end do
end subroutine render_children

!> Write node `id`.
recursive subroutine render_node(t, id, options, out)
    type(tree_t), intent(inout) :: t                !! the conversion
    integer, intent(in) :: id                       !! the node
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    character(len=:), allocatable :: tag, attrs, html, text
    integer :: at

    tag = t%nodes(id)%tag
    attrs = t%nodes(id)%attrs
    select case (tag)
    case ('hr')
        call add(out, '<hr>')
    case ('code')
        call render_code(t%nodes(id)%text, html)
        call add(out, html)
    case ('table')
        call render_table(t, t%nodes(id)%text, options, out)
    case ('p')
        text = t%nodes(id)%text
        if (is_placeholder(strip(text))) then
            call add(out, strip(text))
            return
        end if
        if (strip(text) == '[TOC]' .and. options%toc) then
            call add(out, STX//'toc'//ETX)
            return
        end if
        call add(out, '<p'//attrs//'>')
        call inline(t, strip(text), options, out, 0)
        call add(out, '</p>')
    case ('h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'dt')
        text = t%nodes(id)%text
        at = 0
        if (ends_with(text, '}')) at = index(text, ' {', back=.true.)
        if (at > 0 .and. tag /= 'dt') then
            call attribute_list(strip(text(at + 2:len(text) - 1)), attrs)
            if (starts_with(strip(attrs), ':')) attrs = ''
            text = strip(text(:at - 1))
        end if
        call render_heading(t, tag, attrs, text, options, out)
    case default
        call add(out, '<'//tag//attrs//'>')
        if (len(t%nodes(id)%text) > 0) call inline(t, strip(t%nodes(id)%text), options, out, 0)
        if (size(t%nodes(id)%kids) > 0) then
            if (tag /= 'li' .or. len(t%nodes(id)%text) == 0) call add(out, NL)
            if (tag == 'li' .and. len(t%nodes(id)%text) > 0) call add(out, NL)
            call render_children(t, id, options, out)
            call add(out, NL)
        end if
        call add(out, '</'//tag//'>')
    end select
end subroutine render_node

!> True if `text` is one placeholder.
pure logical function is_placeholder(text)
    character(len=*), intent(in) :: text    !! the text
    is_placeholder = .false.
    if (len(text) < 3) return
    is_placeholder = text(1:1) == STX .and. index(text, ETX) == len(text)
end function is_placeholder

!> Write a heading or definition term. With the `toc` extension headings get ids.
recursive subroutine render_heading(t, tag, attrs, text, options, out)
    type(tree_t), intent(inout) :: t                !! the conversion
    character(len=*), intent(in) :: tag             !! the tag
    character(len=*), intent(in) :: attrs           !! its attributes
    character(len=*), intent(in) :: text            !! its text
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    type(buffer_t) :: inner
    character(len=:), allocatable :: html, id, final_attrs

    call inline(t, text, options, inner, 0)
    call take(inner, html)
    final_attrs = attrs
    if (options%toc .and. tag /= 'dt') then
        if (index(attrs, ' id="') == 0) then
            call unique_id(t, html, id)
            final_attrs = final_attrs//' id="'//id//'"'
        else
            id = attrs(index(attrs, ' id="') + 5:)
            id = id(:index(id, '"') - 1)
        end if
        t%headings = [t%headings, heading_t(iachar(tag(2:2)) - iachar('0'), id, html)]
    end if
    call add(out, '<'//tag//final_attrs//'>')
    call add(out, html)
    call add(out, '</'//tag//'>')
end subroutine render_heading

!> An id for a heading with text `html`, not used before.
subroutine unique_id(t, html, id)
    type(tree_t), intent(inout) :: t                !! the conversion
    character(len=*), intent(in) :: html            !! the heading
    character(len=:), allocatable, intent(out) :: id !! the id
    type(buffer_t) :: b
    character(len=:), allocatable :: base
    character(len=12) :: number
    logical :: in_tag, last_blank
    integer :: k, n

    in_tag = .false.
    last_blank = .false.
    do k = 1, len(html)
        associate (c => html(k:k))
            if (c == '<') in_tag = .true.
            if (in_tag) then
                if (c == '>') in_tag = .false.
                cycle
            end if
            if (index(WORD_CHARS//'-', c) > 0) then
                if (last_blank .and. b%n > 0) call add(b, '-')
                last_blank = .false.
                call add(b, lower_one(c))
            else if (c == ' ') then
                last_blank = .true.
            end if
        end associate
    end do
    call take(b, base)
    id = base
    n = 0
    do while (contains_string(t%ids, id))
        n = n + 1
        write (number, '(i0)') n
        id = base//'_'//trim(number)
    end do
    call push(t%ids, id)
end subroutine unique_id

!> `c` in lowercase.
elemental function lower_one(c) result(l)
    character, intent(in) :: c  !! the character
    character :: l
    l = c
    if (c >= 'A' .and. c <= 'Z') l = achar(iachar(c) + 32)
end function lower_one

!> Replace the `[TOC]` marker by the table of contents.
subroutine insert_toc(t, html)
    type(tree_t), intent(in) :: t                       !! the conversion
    character(len=:), allocatable, intent(inout) :: html !! the HTML
    type(buffer_t) :: b
    character(len=:), allocatable :: toc
    integer :: at, k, depth, level, lowest

    at = index(html, STX//'toc'//ETX)
    if (at == 0) return
    call add(b, '<div class="toc">'//NL)
    lowest = 7
    do k = 1, size(t%headings)
        lowest = min(lowest, t%headings(k)%level)
    end do
    depth = lowest - 1
    do k = 1, size(t%headings)
        level = t%headings(k)%level
        do while (depth < level)
            call add(b, '<ul>'//NL)
            depth = depth + 1
        end do
        do while (depth > level)
            call add(b, '</ul>'//NL)
            depth = depth - 1
        end do
        call add(b, '<li><a href="#'//t%headings(k)%id//'">'//t%headings(k)%html//'</a></li>'//NL)
    end do
    do while (depth >= lowest)
        call add(b, '</ul>'//NL)
        depth = depth - 1
    end do
    call add(b, '</div>')
    call take(b, toc)
    html = html(:at - 1)//toc//html(at + 5:)
end subroutine insert_toc

!> The HTML of an indented code block, whose first line may name its language.
subroutine render_code(text, html)
    character(len=*), intent(in) :: text                !! the code
    character(len=:), allocatable, intent(out) :: html  !! the HTML
    character(len=:), allocatable :: lang, first
    integer :: at

    at = index(text, NL)
    if (at == 0) at = len(text) + 1
    first = strip(text(:at - 1))
    lang = ''
    if (starts_with(first, ':::')) then
        lang = strip(first(4:))
        call code_block_html(text(min(at + 1, len(text) + 1):), lang, html)
    else if (starts_with(first, '#!') .and. index(first, ' ') == 0 .and. index(first, '/') == 0) then
        lang = first(3:)
        call code_block_html(text(min(at + 1, len(text) + 1):), lang, html)
    else
        call code_block_html(text, '', html)
    end if
end subroutine render_code

!> Write a table.
recursive subroutine render_table(t, block, options, out)
    type(tree_t), intent(inout) :: t                !! the conversion
    character(len=*), intent(in) :: block           !! the chunk
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    type(string_t), allocatable :: lines(:), cells(:), align(:), header(:)
    integer :: k, c, columns

    lines = split_on(block, NL)
    call row_cells(lines(1)%s, header)
    call row_cells(lines(2)%s, cells)
    columns = size(header)
    allocate (align(columns))
    do c = 1, columns
        align(c)%s = ''
        if (c > size(cells)) cycle
        associate (d => cells(c)%s)
            if (len(d) == 0) cycle
            if (d(1:1) == ':' .and. d(len(d):len(d)) == ':') then
                align(c)%s = ' style="text-align: center;"'
            else if (d(1:1) == ':') then
                align(c)%s = ' style="text-align: left;"'
            else if (d(len(d):len(d)) == ':') then
                align(c)%s = ' style="text-align: right;"'
            end if
        end associate
    end do
    call add(out, '<table>'//NL//'<thead>'//NL)
    call table_row(t, header, 'th', align, options, out)
    call add(out, '</thead>'//NL//'<tbody>'//NL)
    do k = 3, size(lines)
        call row_cells(lines(k)%s, cells)
        call table_row(t, cells, 'td', align, options, out)
    end do
    call add(out, '</tbody>'//NL//'</table>')
end subroutine render_table

!> Write a table row with exactly as many cells as `align` has.
recursive subroutine table_row(t, cells, tag, align, options, out)
    type(tree_t), intent(inout) :: t                !! the conversion
    type(string_t), intent(in) :: cells(:)          !! the cells
    character(len=*), intent(in) :: tag             !! `th` or `td`
    type(string_t), intent(in) :: align(:)          !! the attributes of each column
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    integer :: c

    call add(out, '<tr>'//NL)
    do c = 1, size(align)
        call add(out, '<'//tag//align(c)%s//'>')
        if (c <= size(cells)) call inline(t, cells(c)%s, options, out, 0)
        call add(out, '</'//tag//'>'//NL)
    end do
    call add(out, '</tr>'//NL)
end subroutine table_row

!> The cells of a table row, split at `|` outside code spans.
subroutine row_cells(line, cells)
    character(len=*), intent(in) :: line                    !! the row
    type(string_t), allocatable, intent(out) :: cells(:)    !! the cells
    character(len=:), allocatable :: row
    logical :: in_code
    integer :: k, start

    row = strip(line)
    if (starts_with(row, '|')) row = row(2:)
    if (ends_with(row, '|') .and. .not. ends_with(row, '\|')) row = row(:len(row) - 1)
    allocate (cells(0))
    in_code = .false.
    start = 1
    k = 1
    do while (k <= len(row))
        select case (row(k:k))
        case ('`')
            in_code = .not. in_code
        case ('\')
            k = k + 1
        case ('|')
            if (.not. in_code) then
                call push(cells, strip(row(start:k - 1)))
                start = k + 1
            end if
        end select
        k = k + 1
    end do
    call push(cells, strip(row(start:)))
end subroutine row_cells

!> Write the footnotes that were referred to.
recursive subroutine render_footnotes(t, options, out)
    type(tree_t), intent(inout) :: t                !! the conversion
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    character(len=:), allocatable :: html, back, id
    integer :: k, at

    if (.not. any(t%notes%used)) return
    call add(out, NL//'<div class="footnote">'//NL//'<hr>'//NL//'<ol>'//NL)
    do k = 1, size(t%notes)
        if (.not. t%notes(k)%used) cycle
        id = t%notes(k)%id
        call markdown_to_html(t%notes(k)%text, options, html)
        back = '&#160;<a class="footnote-backref" href="#fnref:'//id//'" title="Jump back to footnote '// &
               trim(number_text(k))//' in the text">&#8617;</a>'
        at = index(html, '</p>', back=.true.)
        if (at > 0) then
            html = html(:at - 1)//back//html(at:)
        else
            html = html//back
        end if
        call add(out, '<li id="fn:'//id//'">'//NL)
        call add(out, html)
        call add(out, NL//'</li>'//NL)
    end do
    call add(out, '</ol>'//NL//'</div>')
end subroutine render_footnotes

!> `k` as text, in a fixed width.
pure function number_text(k) result(text)
    integer, intent(in) :: k    !! the number
    character(len=12) :: text
    write (text, '(i0)') k
end function number_text

!> Write inline Markdown `text` as HTML.
recursive subroutine inline(t, text, options, out, depth)
    type(tree_t), intent(inout) :: t                !! the conversion
    character(len=*), intent(in) :: text            !! the text
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    integer, intent(in) :: depth                    !! how deeply this is nested
    integer :: i, n, used

    n = len(text)
    i = 1
    do while (i <= n)
        used = 0
        select case (text(i:i))
        case (STX)
            used = index(text(i:), ETX)
            if (used > 0) call add(out, text(i:i + used - 1))
        case ('\')
            call inline_backslash(t, text, i, out, used)
        case ('`')
            call inline_code(text, i, out, used)
        case ('[')
            call inline_bracket(t, text, i, options, out, depth, used)
        case ('!')
            if (i < n) then
                if (text(i + 1:i + 1) == '[') call inline_image(t, text, i, out, used)
            end if
        case ('<')
            call inline_angle(text, i, out, used)
            if (used == 0) then
                call add(out, '&lt;')
                used = 1
            end if
        case ('>')
            call add(out, '&gt;')
            used = 1
        case ('&')
            call inline_entity(text, i, out, used)
        case ('$')
            call inline_dollar(text, i, out, used)
        case ('*', '_')
            if (depth < MAX_DEPTH) call inline_emphasis(t, text, i, options, out, depth, used)
        case (' ')
            if (i + 2 <= n) then
                if (text(i:i + 2) == '  '//NL) then
                    call add(out, '<br>'//NL)
                    used = 3
                end if
            end if
        end select
        if (used > 0) then
            i = i + used
            cycle
        end if
        if (size(t%abbreviations) > 0) call inline_abbreviation(t, text, i, out, used)
        if (used > 0) then
            i = i + used
            cycle
        end if
        if (options%smarty) call inline_smart(text, i, out, used)
        if (used > 0) then
            i = i + used
            cycle
        end if
        call add(out, text(i:i))
        i = i + 1
    end do
end subroutine inline

!> Handle a backslash: math, or an escaped character.
subroutine inline_backslash(t, text, i, out, used)
    type(tree_t), intent(in) :: t           !! the conversion
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it is
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(out) :: used            !! how much was used
    integer :: close, k

    used = 0
    if (i == len(text)) return
    associate (c => text(i + 1:i + 1))
        if (c == '(' .or. c == '[') then
            close = index(text(i + 2:), '\'//merge(')', ']', c == '('))
            if (close > 0) then
                call math(text(i + 2:i + close), c == '[', out)
                used = close + 3
                return
            end if
        end if
        if (i + 6 <= len(text)) then
            if (text(i:i + 6) == '\begin{') then
                close = index(text(i:), '}')
                k = index(text(i:), '\end'//text(i + 6:i + close - 1))
                if (close > 0 .and. k > 0) then
                    used = k + 4 + close - 7 + 1
                    call math(text(i:i + used - 1), .true., out)
                    return
                end if
            end if
        end if
        if (index(ESCAPED, c) > 0) then
            call html_escape(c, out, .false.)
            used = 2
        end if
    end associate
end subroutine inline_backslash

!> Write math for MathJax.
subroutine math(tex, display, out)
    character(len=*), intent(in) :: tex     !! the TeX
    logical, intent(in) :: display          !! true for display math
    type(buffer_t), intent(inout) :: out    !! the HTML

    if (display) then
        call add(out, NL//'<script type="math/tex; mode=display">')
    else
        call add(out, '<script type="math/tex">')
    end if
    call add(out, tex)
    call add(out, '</script>')
    if (display) call add(out, NL)
end subroutine math

!> Handle a code span.
subroutine inline_code(text, i, out, used)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it starts
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(out) :: used            !! how much was used
    integer :: run, j, m

    run = verify(text(i:)//' ', '`') - 1
    j = i + run
    do while (j <= len(text))
        if (text(j:j) /= '`') then
            j = j + 1
            cycle
        end if
        m = verify(text(j:)//' ', '`') - 1
        if (m == run) then
            call add(out, '<code>')
            call html_escape(strip(text(i + run:j - 1)), out, .false.)
            call add(out, '</code>')
            used = j + run - i
            return
        end if
        j = j + m
    end do
    call add(out, text(i:i + run - 1))
    used = run
end subroutine inline_code

!> Handle `<`: an automatic link or inline HTML.
subroutine inline_angle(text, i, out, used)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it is
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(out) :: used            !! how much was used
    character(len=:), allocatable :: inner
    integer :: close, k

    used = 0
    close = index(text(i:), '>')
    if (close < 3) return
    inner = text(i + 1:i + close - 2)
    if (index(inner, '<') > 0) return
    if (starts_with(lowercase(inner), 'http://') .or. starts_with(lowercase(inner), 'https://') .or. &
        starts_with(lowercase(inner), 'ftp://') .or. starts_with(lowercase(inner), 'ftps://')) then
        call add(out, '<a href="')
        call html_escape(inner, out, .true.)
        call add(out, '">')
        call html_escape(inner, out, .false.)
        call add(out, '</a>')
        used = close
        return
    end if
    k = index(inner, '@')
    if (k > 1 .and. k < len(inner) .and. index(inner, ' ') == 0 .and. index(inner, '!') == 0) then
        call add(out, '<a href="')
        call encoded('mailto:'//inner, out)
        call add(out, '">')
        call encoded(inner, out)
        call add(out, '</a>')
        used = close
        return
    end if
    if (starts_with(inner, '!--') .or. scan(inner(1:1), 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/') == 1) then
        if (index(first_word(inner), '@') > 0) return
        call add(out, text(i:i + close - 1))
        used = close
    end if
end subroutine inline_angle

!> The part of `text` before its first blank.
pure function first_word(text) result(word)
    character(len=*), intent(in) :: text    !! the text
    character(len=merge(len(text), index(text, ' ') - 1, index(text, ' ') == 0)) :: word
    word = text
end function first_word

!> Write `text` as numeric character references.
subroutine encoded(text, out)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer :: k

    do k = 1, len(text)
        call add(out, '&#'//trim(number_text(iachar(text(k:k))))//';')
    end do
end subroutine encoded

!> Handle `&`: an entity stays as it is, anything else is escaped.
subroutine inline_entity(text, i, out, used)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it is
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(out) :: used            !! how much was used
    integer :: close

    close = index(text(i:), ';')
    used = 1
    if (close > 2) then
        if (verify(text(i + 1:i + close - 2), WORD_CHARS(:62)//'#') == 0) then
            call add(out, text(i:i + close - 1))
            used = close
            return
        end if
    end if
    call add(out, '&amp;')
end subroutine inline_entity

!> Handle `$`: display math or an environment variable.
subroutine inline_dollar(text, i, out, used)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it is
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(out) :: used            !! how much was used
    character(len=:), allocatable :: value
    integer :: close, n, stat

    used = 0
    if (i == len(text)) return
    if (text(i + 1:i + 1) == '$') then
        close = index(text(i + 2:), '$$')
        if (close > 1) then
            call math(text(i + 2:i + close), .true., out)
            used = close + 3
        end if
    else if (text(i + 1:i + 1) == '{') then
        close = index(text(i + 2:), '}')
        if (close > 1) then
            if (verify(text(i + 2:i + close), WORD_CHARS) /= 0) return
            call get_environment_variable(text(i + 2:i + close), length=n, status=stat)
            if (stat == 0 .and. n > 0) then
                allocate (character(len=n) :: value)
                call get_environment_variable(text(i + 2:i + close), value)
                call add(out, value)
            end if
            used = close + 2
        end if
    end if
end subroutine inline_dollar

!> The end of the `[...]` that opens at `i`, or 0.
pure integer function bracket_end(text, i)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it opens
    integer :: k, depth

    bracket_end = 0
    depth = 0
    k = i
    do while (k <= len(text))
        select case (text(k:k))
        case ('\')
            k = k + 1
        case ('[')
            depth = depth + 1
        case (']')
            depth = depth - 1
            if (depth == 0) then
                bracket_end = k
                return
            end if
        end select
        k = k + 1
    end do
end function bracket_end

!> Read the `(address "title")` at `open`.
subroutine link_target(text, open, url, title, close)
    character(len=*), intent(in) :: text                !! the text
    integer, intent(in) :: open                         !! where `(` is
    character(len=:), allocatable, intent(out) :: url   !! the address
    character(len=:), allocatable, intent(out) :: title !! the title, or `''`
    integer, intent(out) :: close                       !! where `)` is, or 0
    character(len=:), allocatable :: inner
    integer :: k, depth, q

    url = ''
    title = ''
    close = 0
    depth = 0
    q = 0
    do k = open, len(text)
        if (text(k:k) == '(') depth = depth + 1
        if (text(k:k) == ')') depth = depth - 1
        if (depth == 0) then
            close = k
            exit
        end if
    end do
    if (close == 0) return
    inner = strip(text(open + 1:close - 1))
    if (starts_with(inner, '<')) then
        k = index(inner, '>')
        if (k > 0) then
            url = inner(2:k - 1)
            inner = strip(inner(k + 1:))
            if (len(inner) >= 2) title = inner(2:len(inner) - 1)
            return
        end if
    end if
    if (len(inner) >= 2) then
        if (scan(inner(len(inner):len(inner)), '"''') == 1) then
            q = index(inner, ' '//inner(len(inner):len(inner)))
            if (q > 0) then
                title = inner(q + 2:len(inner) - 1)
                inner = strip(inner(:q - 1))
            end if
        end if
    end if
    url = inner
end subroutine link_target

!> Find link reference `id`, returning its position or 0.
integer function find_reference(t, id)
    type(tree_t), intent(in) :: t           !! the conversion
    character(len=*), intent(in) :: id      !! the name
    character(len=:), allocatable :: normal
    integer :: k

    find_reference = 0
    if (size(t%refs) == 0) return
    call normal_id(id, normal)
    do k = 1, size(t%refs)
        if (t%refs(k)%id == normal) find_reference = k
    end do
end function find_reference

!> Handle `[`: a FORD link, a footnote reference or a link.
recursive subroutine inline_bracket(t, text, i, options, out, depth, used)
    type(tree_t), intent(inout) :: t                !! the conversion
    character(len=*), intent(in) :: text            !! the text
    integer, intent(in) :: i                        !! where it is
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    integer, intent(in) :: depth                    !! how deeply this is nested
    integer, intent(out) :: used                    !! how much was used
    character(len=:), allocatable :: url, title, id
    integer :: close, after, k, target, next

    used = 0
    if (i < len(text)) then
        if (text(i + 1:i + 1) == '[') then
            call ford_link(text, i, options, out, used)
            if (used > 0) return
        end if
        if (text(i + 1:i + 1) == '^') then
            close = index(text(i:), ']')
            if (close > 2) then
                do k = 1, size(t%notes)
                    if (t%notes(k)%id == text(i + 2:i + close - 2)) then
                        t%notes(k)%used = .true.
                        call add(out, '<sup id="fnref:'//t%notes(k)%id//'"><a class="footnote-ref" href="#fn:'// &
                                 t%notes(k)%id//'">'//trim(number_text(k))//'</a></sup>')
                        used = close
                        return
                    end if
                end do
            end if
        end if
    end if

    close = bracket_end(text, i)
    if (close == 0) return
    after = close + 1
    if (after <= len(text)) then
        if (text(after:after) == '(') then
            call link_target(text, after, url, title, k)
            if (k > 0) then
                call write_link(t, text(i + 1:close - 1), url, title, options, out, depth)
                used = k - i + 1
                return
            end if
        end if
    end if

    ! a reference: `[text][id]`, `[text] [id]`, `[id][]` or `[id]`
    next = after
    if (next <= len(text)) then
        if (text(next:next) == ' ') next = next + 1
    end if
    if (next <= len(text)) then
        if (text(next:next) == '[') then
            k = bracket_end(text, next)
            if (k > 0) then
                id = text(next + 1:k - 1)
                if (len(id) == 0) id = text(i + 1:close - 1)
                target = find_reference(t, id)
                if (target > 0) then
                    call write_link(t, text(i + 1:close - 1), t%refs(target)%url, t%refs(target)%title, options, out, depth)
                    used = k - i + 1
                    return
                end if
            end if
        end if
    end if
    target = find_reference(t, text(i + 1:close - 1))
    if (target > 0) then
        call write_link(t, text(i + 1:close - 1), t%refs(target)%url, t%refs(target)%title, options, out, depth)
        used = close - i + 1
    end if
end subroutine inline_bracket

!> Write a link.
recursive subroutine write_link(t, label, url, title, options, out, depth)
    type(tree_t), intent(inout) :: t                !! the conversion
    character(len=*), intent(in) :: label           !! its text
    character(len=*), intent(in) :: url             !! the address
    character(len=*), intent(in) :: title           !! the title, or `''`
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    integer, intent(in) :: depth                    !! how deeply this is nested

    call add(out, '<a href="')
    call html_escape(url, out, .true.)
    call add(out, '"')
    if (len(title) > 0) then
        call add(out, ' title="')
        call html_escape(title, out, .true.)
        call add(out, '"')
    end if
    call add(out, '>')
    if (depth < MAX_DEPTH) call inline(t, label, options, out, depth + 1)
    call add(out, '</a>')
end subroutine write_link

!> Handle `![`: an image.
subroutine inline_image(t, text, i, out, used)
    type(tree_t), intent(in) :: t           !! the conversion
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it is
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(out) :: used            !! how much was used
    character(len=:), allocatable :: url, title
    integer :: close, k, target

    used = 0
    close = bracket_end(text, i + 1)
    if (close == 0) return
    k = 0
    url = ''
    title = ''
    if (close < len(text)) then
        if (text(close + 1:close + 1) == '(') then
            call link_target(text, close + 1, url, title, k)
        else if (text(close + 1:close + 1) == '[') then
            k = bracket_end(text, close + 1)
            if (k > 0) then
                target = find_reference(t, text(close + 2:k - 1))
                if (target == 0) return
                url = t%refs(target)%url
                title = t%refs(target)%title
            end if
        end if
    end if
    if (k == 0) return
    call add(out, '<img alt="')
    call html_escape(text(i + 2:close - 1), out, .true.)
    call add(out, '" src="')
    call html_escape(url, out, .true.)
    call add(out, '"')
    if (len(title) > 0) then
        call add(out, ' title="')
        call html_escape(title, out, .true.)
        call add(out, '"')
    end if
    call add(out, '>')
    used = k - i + 1
end subroutine inline_image

!> Handle `[[name(type):child(type)]]`, a link to an entity.
subroutine ford_link(text, i, options, out, used)
    character(len=*), intent(in) :: text            !! the text
    integer, intent(in) :: i                        !! where it is
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    integer, intent(out) :: used                    !! how much was used
    character(len=:), allocatable :: inner, name, entity, child, child_entity, url, label
    integer :: close, colon
    logical :: found

    used = 0
    if (.not. associated(options%resolver)) return
    close = index(text(i:), ']]')
    if (close < 4) return
    inner = remove_blanks(text(i + 2:i + close - 2))
    if (verify(inner, WORD_CHARS//'.():') /= 0) return
    colon = index(inner, ':')
    child = ''
    child_entity = ''
    if (colon > 0) then
        call name_and_entity(inner(colon + 1:), child, child_entity)
        inner = inner(:colon - 1)
    end if
    call name_and_entity(inner, name, entity)
    call options%resolver(options%resolver_data, name, entity, child, child_entity, url, label, found)
    used = close + 1
    if (.not. found) then
        call warn('Could not substitute link '//text(i:i + close)//", '"//name//"' not found")
        call add(out, '<a>'//name//'</a>')
        return
    end if
    call add(out, '<a href="')
    call html_escape(url, out, .true.)
    call add(out, '">')
    call html_escape(label, out, .false.)
    call add(out, '</a>')
end subroutine ford_link

!> Split `name(entity)`.
subroutine name_and_entity(text, name, entity)
    character(len=*), intent(in) :: text                    !! the text
    character(len=:), allocatable, intent(out) :: name      !! the name
    character(len=:), allocatable, intent(out) :: entity    !! the entity type, or `''`
    integer :: open

    open = index(text, '(')
    if (open > 0) then
        name = text(:open - 1)
        entity = text(open + 1:len(text) - 1)
    else
        name = text
        entity = ''
    end if
end subroutine name_and_entity

!> Handle `*` and `_`.
recursive subroutine inline_emphasis(t, text, i, options, out, depth, used)
    type(tree_t), intent(inout) :: t                !! the conversion
    character(len=*), intent(in) :: text            !! the text
    integer, intent(in) :: i                        !! where it is
    type(markdown_options_t), intent(in) :: options !! what rendering depends on
    type(buffer_t), intent(inout) :: out            !! the HTML
    integer, intent(in) :: depth                    !! how deeply this is nested
    integer, intent(out) :: used                    !! how much was used
    character :: c
    integer :: run, close, width
    logical :: before_blank, after_blank

    used = 0
    c = text(i:i)
    run = verify(text(i:)//' ', c) - 1
    before_blank = i == 1
    if (.not. before_blank) before_blank = scan(text(i - 1:i - 1), ' '//NL) == 1
    after_blank = i + run > len(text)
    if (.not. after_blank) after_blank = scan(text(i + run:i + run), ' '//NL) == 1
    if (run <= 3 .and. before_blank .and. after_blank) then
        call add(out, text(i:i + run - 1))
        used = run
        return
    end if

    if (c == '_') then
        if (i > 1) then
            if (index(WORD_CHARS, text(i - 1:i - 1)) > 0) then
                call add(out, text(i:i + run - 1))
                used = run
                return
            end if
        end if
    end if

    do width = min(run, 3), 1, -1
        if (width == 1 .and. run > 1) exit
        call closing_mark(text, i + width, c, width, close)
        if (close == 0) cycle
        select case (width)
        case (3)
            call add(out, '<strong><em>')
            call inline(t, text(i + 3:close - 1), options, out, depth + 1)
            call add(out, '</em></strong>')
        case (2)
            call add(out, '<strong>')
            call inline(t, text(i + 2:close - 1), options, out, depth + 1)
            call add(out, '</strong>')
        case default
            call add(out, '<em>')
            call inline(t, text(i + 1:close - 1), options, out, depth + 1)
            call add(out, '</em>')
        end select
        used = close + width - i
        return
    end do

    ! `**` with nothing to close it: the second `*` may still open emphasis
    if (run > 1) then
        call add(out, c)
        used = 1
    end if
end subroutine inline_emphasis

!> Find where emphasis of `width` marks `c` opened before `start` closes.
pure subroutine closing_mark(text, start, c, width, close)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: start            !! where its content starts
    character, intent(in) :: c              !! `*` or `_`
    integer, intent(in) :: width            !! how many marks
    integer, intent(out) :: close           !! where the closing marks start, or 0
    integer :: k, run

    close = 0
    k = start
    do while (k <= len(text) - width + 1)
        if (text(k:k) == '\') then
            k = k + 2
            cycle
        end if
        if (text(k:k) == '`') then
            run = index(text(k + 1:), '`')
            if (run > 0) k = k + run
        end if
        if (text(k:k) /= c .or. k == start) then
            k = k + 1
            cycle
        end if
        run = verify(text(k:)//' ', c) - 1
        ! marks with blanks on both sides are ordinary text
        if (run <= 3 .and. scan(text(k - 1:k - 1), ' '//NL) == 1 .and. &
            (k + run > len(text) .or. scan(text(min(k + run, len(text)):min(k + run, len(text))), ' '//NL) == 1)) then
            k = k + run
            cycle
        end if
        if (run >= width) then
            if (c == '*') then
                close = merge(k, k + run - width, width == 1)
                return
            end if
            ! `_` must not be followed by a word character
            if (k + run > len(text)) then
                close = k + run - width
                return
            end if
            if (index(WORD_CHARS, text(k + run:k + run)) == 0) then
                close = k + run - width
                return
            end if
        end if
        k = k + run
    end do
end subroutine closing_mark

!> Handle an abbreviation at `i`, if there is a whole word there.
subroutine inline_abbreviation(t, text, i, out, used)
    type(tree_t), intent(in) :: t           !! the conversion
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it is
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(out) :: used            !! how much was used
    integer :: k, n

    used = 0
    if (i > 1) then
        if (index(WORD_CHARS, text(i - 1:i - 1)) > 0) return
    end if
    do k = 1, size(t%abbreviations)
        n = len(t%abbreviations(k)%key)
        if (i + n - 1 > len(text)) cycle
        if (text(i:i + n - 1) /= t%abbreviations(k)%key) cycle
        if (i + n <= len(text)) then
            if (index(WORD_CHARS, text(i + n:i + n)) > 0) cycle
        end if
        call add(out, '<abbr title="')
        call html_escape(t%abbreviations(k)%value, out, .true.)
        call add(out, '">'//t%abbreviations(k)%key//'</abbr>')
        used = n
        return
    end do
end subroutine inline_abbreviation

!> Handle the punctuation that the `smarty` extension changes.
pure subroutine inline_smart(text, i, out, used)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: i                !! where it is
    type(buffer_t), intent(inout) :: out    !! the HTML
    integer, intent(out) :: used            !! how much was used
    logical :: opening

    used = 0
    opening = i == 1
    if (.not. opening) opening = scan(text(i - 1:i - 1), ' '//NL//'([{-') == 1
    select case (text(i:i))
    case ('-')
        if (i + 2 <= len(text)) then
            if (text(i:i + 2) == '---') then
                call add(out, '&mdash;')
                used = 3
                return
            end if
        end if
        if (i + 1 <= len(text)) then
            if (text(i:i + 1) == '--') then
                call add(out, '&ndash;')
                used = 2
            end if
        end if
    case ('.')
        if (i + 2 <= len(text)) then
            if (text(i:i + 2) == '...') then
                call add(out, '&hellip;')
                used = 3
            end if
        end if
    case ('"')
        call add(out, merge('&ldquo;', '&rdquo;', opening))
        used = 1
    case ("'")
        call add(out, merge('&lsquo;', '&rsquo;', opening))
        used = 1
    end select
end subroutine inline_smart

end module fdoc_markdown
