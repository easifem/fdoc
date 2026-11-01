module fdoc_pages
!! Static pages: a tree of Markdown files under `page_dir`, each directory with an `index.md`.
use ffmt_fs, only: list_directory, dir_entry_t, is_directory, ENTRY_DIR
use fdoc_util
use fdoc_settings, only: settings_t
use fdoc_project, only: project_t
use fdoc_project_file, only: parse_metadata, metadata_t
use fdoc_markdown, only: markdown_options_t, dedent
use fdoc_docs, only: base_options, render_text
use fdoc_progress, only: warn
implicit none
private

public :: page_t, load_pages, page_file

type :: page_t
    !! A static page.
    character(len=:), allocatable :: title      !! its title
    character(len=:), allocatable :: path       !! its file, relative to `page/`
    character(len=:), allocatable :: html       !! its text as HTML
    character(len=:), allocatable :: author     !! its author, if any
    character(len=:), allocatable :: date       !! its date, if any
    integer :: parent = 0                       !! the page above it
    integer :: depth = 0                        !! how many directories below `page/` it is
    type(string_t), allocatable :: copies(:)    !! files and directories to copy next to it
end type page_t

contains

!> The length of the part of `name` that names its page.
pure integer function stem_length(name)
    character(len=*), intent(in) :: name    !! the name of a Markdown file
    integer :: at

    stem_length = len(name) - 3
    at = index(name(:stem_length), '.', back=.true.)
    if (at > 1) stem_length = at - 1
end function stem_length

!> Read the pages of the project into `pages`, parents before children.
subroutine load_pages(p, s, abbreviations_from, pages)
    type(project_t), intent(inout), target :: p                 !! the project
    type(settings_t), intent(in) :: s                           !! the settings
    type(markdown_options_t), intent(in) :: abbreviations_from  !! has the abbreviations of the project
    type(page_t), allocatable, intent(out) :: pages(:)          !! the pages

    allocate (pages(0))
    if (.not. allocated(s%page_dir)) return
    call read_tree(p, s, abbreviations_from, s%page_dir, '', 0, 0, pages)
end subroutine load_pages

!> Read the directory `directory` of pages, `location` below the top.
recursive subroutine read_tree(p, s, base, directory, location, parent, depth, pages)
    type(project_t), intent(inout), target :: p         !! the project
    type(settings_t), intent(in) :: s                   !! the settings
    type(markdown_options_t), intent(in) :: base        !! has the abbreviations of the project
    character(len=*), intent(in) :: directory           !! the directory
    character(len=*), intent(in) :: location            !! its path below the top, ending in `/`, or `''`
    integer, intent(in) :: parent                       !! the page above, or 0
    integer, intent(in) :: depth                        !! how deep it is
    type(page_t), allocatable, intent(inout) :: pages(:)    !! the pages
    type(dir_entry_t), allocatable :: entries(:)
    type(string_t), allocatable :: names(:), ordered(:), skip(:)
    character(len=:), allocatable :: name, path
    logical :: exists
    integer :: k, node, stat, index_page

    path = directory//'/index.md'
    inquire (file=path, exist=exists)
    if (.not. exists) then
        if (.not. is_input_directory(s, directory)) then
            call warn("Skipping creating page for '"//directory//"' because it does not contain 'index.md'")
        end if
        return
    end if
    call read_page(p, s, base, path, location//'index.html', parent, depth, pages, ordered, skip)
    index_page = size(pages)
    if (index_page == 0) return
    if (parent > 0 .and. pages(index_page)%parent /= parent) return
    node = index_page

    call list_directory(directory, entries, stat)
    if (stat /= 0) return
    allocate (names(0))
    do k = 1, size(ordered)
        if (ordered(k)%s /= 'index.md') call push(names, ordered(k)%s)
    end do
    block
        type(string_t), allocatable :: listed(:)
        allocate (listed(0))
        do k = 1, size(entries)
            call push(listed, entries(k)%name)
        end do
        call sort_strings(listed)
        do k = 1, size(listed)
            if (.not. contains_string(names, listed(k)%s) .and. listed(k)%s /= 'index.md') call push(names, listed(k)%s)
        end do
    end block

    do k = 1, size(names)
        name = names(k)%s
        if (name(1:1) == '.' .or. name(len(name):len(name)) == '~') cycle
        path = directory//'/'//name
        if (contains_string(skip, name)) then
            call push(pages(node)%copies, location//name)
        else if (is_directory(path)) then
            call read_tree(p, s, base, path, location//name//'/', node, depth + 1, pages)
        else if (ends_with(name, '.md')) then
            call read_page(p, s, base, path, location//page_file(name), node, depth, pages, ordered, skip)
        else
            call push(pages(node)%copies, location//name)
        end if
    end do
end subroutine read_tree

!> The HTML file for Markdown file `name`. As in FORD one other suffix goes too: `CI.yml.md` becomes
!> `CI.html`.
pure function page_file(name) result(file)
    character(len=*), intent(in) :: name    !! the name of a Markdown file
    character(len=stem_length(name) + 5) :: file

    file = name(:stem_length(name))//'.html'
end function page_file

!> True if `directory` is an input of the project, so that it not being a page is expected.
logical function is_input_directory(s, directory)
    type(settings_t), intent(in) :: s           !! the settings
    character(len=*), intent(in) :: directory   !! the directory

    is_input_directory = contains_string(s%src_dir, directory) .or. contains_string(s%html_template_dir, directory) .or. &
                         directory == s%output_dir
    if (allocated(s%media_dir)) is_input_directory = is_input_directory .or. directory == s%media_dir
    if (allocated(s%graph_dir)) is_input_directory = is_input_directory .or. directory == s%graph_dir
end function is_input_directory

!> Read and render one page, adding it to `pages`.
subroutine read_page(p, s, base, path, target, parent, depth, pages, ordered, skip)
    type(project_t), intent(inout), target :: p         !! the project
    type(settings_t), intent(in) :: s                   !! the settings
    type(markdown_options_t), intent(in) :: base        !! has the abbreviations of the project
    character(len=*), intent(in) :: path                !! the Markdown file
    character(len=*), intent(in) :: target              !! the HTML file, relative to `page/`
    integer, intent(in) :: parent                       !! the page above, or 0
    integer, intent(in) :: depth                        !! how deep it is
    type(page_t), allocatable, intent(inout) :: pages(:)    !! the pages
    type(string_t), allocatable, intent(out) :: ordered(:)  !! its `ordered_subpage`
    type(string_t), allocatable, intent(out) :: skip(:)     !! its `copy_subdir`
    type(metadata_t) :: meta
    type(markdown_options_t) :: options
    type(string_t), allocatable :: lines(:)
    character(len=:), allocatable :: text, msg, root, prefix, title, html, author, date
    type(page_t) :: page
    integer :: k, stat

    allocate (ordered(0))
    skip = s%copy_subdir
    do k = 1, size(skip)
        skip(k)%s = skip(k)%s(last_separator(skip(k)%s) + 1:)
    end do
    call read_whole_file(path, text, stat, msg)
    if (stat /= 0) then
        call warn('could not read '//path//': '//msg)
        return
    end if
    lines = split_lines(text)
    call dedent(lines)
    call parse_metadata(join(lines, achar(10)), meta)
    title = ''
    do k = 1, size(meta%items)
        select case (meta%items(k)%key)
        case ('title'); title = join(meta%items(k)%values, ' ')
        case ('author'); author = join(meta%items(k)%values, ' ')
        case ('date'); date = join(meta%items(k)%values, ' ')
        case ('ordered_subpage'); ordered = meta%items(k)%values
        case ('copy_subdir'); skip = meta%items(k)%values
        end select
    end do
    if (len(title) == 0) then
        call warn("Page '"//path//"' has no title metadata")
        return
    end if

    prefix = repeat('../', depth + 1)
    root = prefix(:len(prefix) - 1)
    call base_options(s, root, options)
    if (allocated(base%abbreviations)) options%abbreviations = base%abbreviations
    call render_text(p, options, 0, prefix, join(meta%body, achar(10)), html)

    page%title = title
    page%path = target
    call move_alloc(html, page%html)
    if (allocated(author)) page%author = author
    if (allocated(date)) page%date = date
    page%parent = parent
    page%depth = depth
    allocate (page%copies(0))
    pages = [pages, page]
end subroutine read_page

end module fdoc_pages
