module fdoc_docs
!! Rendering the documentation of every entity from Markdown to HTML.
use fdoc_util
use fdoc_model
use fdoc_settings, only: settings_t, map_entry_t
use fdoc_project, only: project_t
use fdoc_markdown, only: markdown_to_html, markdown_to_markdown, markdown_options_t, dedent
use fdoc_urls, only: link_context_t, resolve_link
use fdoc_progress, only: progress_start, progress_tick, progress_finish
implicit none
private

public :: base_options, render_documentation, render_text, collect_abbreviations

contains

!> The Markdown options of a project.
subroutine base_options(s, root, options)
    type(settings_t), intent(in) :: s                   !! the settings
    character(len=*), intent(in) :: root                !! from the pages to the root of the site
    type(markdown_options_t), intent(out) :: options    !! the options
    integer :: k
    character(len=:), allocatable :: url

    url = root
    options%aliases = [s%alias, s%external, map_entry_t('url', url), map_entry_t('media', url//'/media'), &
                       map_entry_t('page', url//'/page')]
    options%base_path = s%md_base_dir
    options%keep_markdown = s%output_format == 'markdown'
    options%resolver => resolve_link
    do k = 1, size(s%md_extensions)
        select case (s%md_extensions(k)%s)
        case ('markdown.extensions.toc', 'toc')
            options%toc = .true.
        case ('markdown.extensions.smarty', 'smarty')
            options%smarty = .true.
        end select
    end do
end subroutine base_options

!> Make the abbreviations defined in any documentation apply everywhere, as they do in FORD.
subroutine collect_abbreviations(p, options)
    type(project_t), intent(in) :: p                    !! the project
    type(markdown_options_t), intent(inout) :: options  !! the options
    type(map_entry_t), allocatable :: found(:)
    integer :: k, j, at

    allocate (found(0))
    do k = 1, p%list%n
        if (.not. allocated(p%list%box(k)%e%doc)) cycle
        associate (doc => p%list%box(k)%e%doc)
            do j = 1, size(doc)
                if (.not. starts_with(strip(doc(j)%s), '*[')) cycle
                at = index(doc(j)%s, ']:')
                if (at == 0) cycle
                found = [found, map_entry_t(doc(j)%s(index(doc(j)%s, '*[') + 2:at - 1), strip(doc(j)%s(at + 2:)))]
            end do
        end associate
    end do
    if (size(found) > 0) options%abbreviations = found
end subroutine collect_abbreviations

!> Render `text`, as if it belonged to entity `context`, for a page `prefix` away from the root. The
!> result is Markdown for Markdown output.
subroutine render_text(p, base, context, prefix, text, html)
    type(project_t), intent(inout), target :: p         !! the project
    type(markdown_options_t), intent(in) :: base        !! the Markdown options
    integer, intent(in) :: context                      !! the entity, or 0
    character(len=*), intent(in) :: prefix              !! from the page to the root of the site
    character(len=*), intent(in) :: text                !! the Markdown
    character(len=:), allocatable, intent(out) :: html  !! the result
    type(markdown_options_t) :: options
    type(link_context_t), target :: link

    options = base
    link%list => p%list
    link%entity = context
    link%prefix = prefix
    link%markdown = base%keep_markdown
    options%resolver_data => link
    if (base%keep_markdown) then
        call markdown_to_markdown(text, options, html)
    else
        call markdown_to_html(text, options, html)
    end if
end subroutine render_text

!> The first paragraph of `html`, or `''`.
pure subroutine first_paragraph(html, out)
    character(len=*), intent(in) :: html                !! the HTML
    character(len=:), allocatable, intent(out) :: out   !! the paragraph
    integer :: a, b

    out = ''
    a = index(html, '<p>')
    if (a == 0) a = index(html, '<p ')
    if (a == 0) return
    b = index(html(a:), '</p>')
    if (b > 0) out = html(a:a + b + 2)
end subroutine first_paragraph

!> The first paragraph of Markdown `text`, on one line, or `''`. As in the HTML, this is the first block
!> of plain text, so headings, lists, tables, quotes, raw HTML and code are passed over.
pure subroutine first_markdown_paragraph(text, out)
    character(len=*), intent(in) :: text                !! the Markdown
    character(len=:), allocatable, intent(out) :: out   !! the paragraph
    character, parameter :: NL = achar(10)
    character(len=3) :: fence
    integer :: at, stop_at, next, first
    logical :: taking

    out = ''
    fence = ''
    taking = .false.
    at = 1
    do while (at <= len(text))
        next = index(text(at:), NL)
        stop_at = merge(at + next - 2, len(text), next > 0)
        first = verify(text(at:stop_at), ' ')
        if (len_trim(fence) > 0) then
            if (first > 0) then
                if (starts_with(text(at + first - 1:stop_at), fence)) fence = ''
            end if
        else if (first == 0) then
            if (taking) return
        else if (taking) then
            out = out//' '//text(at + first - 1:stop_at)
        else if (starts_with(text(at + first - 1:stop_at), '```') .or. starts_with(text(at + first - 1:stop_at), '~~~')) then
            fence = text(at + first - 1:at + first + 1)
        else if (.not. other_block(text(at + first - 1:stop_at))) then
            out = text(at + first - 1:stop_at)
            taking = .true.
        else
            ! the rest of this block is not a paragraph either
            do while (next > 0 .and. at + next <= len(text))
                at = at + next
                next = index(text(at:), NL)
                stop_at = merge(at + next - 2, len(text), next > 0)
                if (verify(text(at:stop_at), ' ') == 0) exit
            end do
        end if
        if (next == 0) return
        at = at + next
    end do
end subroutine first_markdown_paragraph

!> True if `line`, with no blanks before it, starts something other than a paragraph.
pure logical function other_block(line)
    character(len=*), intent(in) :: line    !! the line

    other_block = index('#|<>', line(1:1)) > 0 .or. starts_with(line, '- ') .or. starts_with(line, '* ') .or. &
                  starts_with(line, '+ ') .or. starts_with(line, '$$')
end function other_block

!> Render the documentation and summary of each entity.
subroutine render_documentation(p, s, options)
    type(project_t), intent(inout), target :: p         !! the project
    type(settings_t), intent(in) :: s                   !! the settings
    type(markdown_options_t), intent(in) :: options     !! the Markdown options
    integer :: k

    call progress_start('Converting Markdown', p%list%n)
    !$omp parallel do schedule(dynamic, 16) num_threads(max(1, s%parallel)) default(shared)
    do k = 1, p%list%n
        call render_entity(p, options, k)
        call progress_tick()
    end do
    !$omp end parallel do
    call progress_finish()
end subroutine render_documentation

!> Render the documentation and summary of entity `id`.
subroutine render_entity(p, options, id)
    type(project_t), intent(inout), target :: p         !! the project
    type(markdown_options_t), intent(in) :: options     !! the Markdown options
    integer, intent(in) :: id                           !! the entity
    type(string_t), allocatable :: lines(:)
    integer :: k

    if (.not. allocated(p%list%box(id)%e%doc)) return
    if (p%list%box(id)%e%kind == E_NONE) return
    associate (e => p%list%box(id)%e)
        lines = e%doc
        call dedent(lines)
        call render_text(p, options, id, '../', join(lines, achar(10)), e%html)
        do k = 1, size(e%meta)
            if (e%meta(k)%key /= 'summary') cycle
            call render_text(p, options, id, '../', join(split_words(join(e%meta(k)%values, ' ')), ' '), e%summary)
        end do
        if (.not. allocated(e%summary)) then
            if (options%keep_markdown) then
                call first_markdown_paragraph(e%html, e%summary)
            else
                call first_paragraph(e%html, e%summary)
            end if
        end if
    end associate
end subroutine render_entity

end module fdoc_docs
