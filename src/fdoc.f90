module fdoc
!! The `fdoc` program: documentation for modern Fortran, from FORD project files.
use iso_fortran_env, only: error_unit, output_unit
use ffmt_fs, only: parent_directory
use fdoc_util, only: string_t
use fdoc_cli, only: args_t, parse_args, apply_args, usage, VERSION, ACTION_HELP, ACTION_VERSION, ACTION_DUMP, &
                    ACTION_DUMP_LINKS, ACTION_MARKDOWN
use fdoc_settings, only: settings_t, check_settings, finish_settings, dump_settings, map_entry_t
use fdoc_project_file, only: load_project, apply_toml_string
use fdoc_project, only: project_t, load_project_sources, correlate, prune
use fdoc_output, only: write_modules
use fdoc_links, only: link_project, dump_links
use fdoc_markdown, only: markdown_to_html, markdown_options_t
use fdoc_docs, only: base_options, render_documentation, render_text, collect_abbreviations
use fdoc_site, only: assign_pages, write_site
use fdoc_urls, only: index_entity_names
use fdoc_pages, only: load_pages, page_t
use fdoc_progress, only: progress_enable, progress_start, progress_finish, progress_summary, warn
use json_module, only: json_core, json_value
implicit none
private

public :: run

contains

!> Run with command line `args`, returning the exit status.
integer function run(args) result(status)
    type(string_t), intent(in) :: args(:)   !! the arguments, in order
    type(args_t) :: parsed
    type(settings_t), target :: s
    type(project_t), target :: p
    type(markdown_options_t) :: options, front_options
    type(page_t), allocatable :: static(:)
    character(len=:), allocatable :: errmsg, body, directory, front
    character(len=16) :: count_text
    integer :: stat, pages

    status = 0
    call parse_args(args, parsed, stat, errmsg)
    if (stat /= 0) then
        write (error_unit, '(a)') 'fdoc: '//errmsg
        write (error_unit, '(a)') 'Try "fdoc --help".'
        status = 2
        return
    end if
    if (parsed%action == ACTION_HELP) then
        write (output_unit, '(a)', advance='no') usage()
        return
    end if
    if (parsed%action == ACTION_VERSION) then
        write (output_unit, '(a)') 'fdoc version '//VERSION
        return
    end if

    if (parsed%action == ACTION_MARKDOWN) then
        call markdown_list(parsed%project_file)
        return
    end if

    directory = '.'
    if (len(parsed%project_file) > 0) directory = parent_directory(parsed%project_file)
    call load_project(parsed%project_file, directory, s, body, stat, errmsg)
    if (stat == 0) call check_settings(s, stat, errmsg)
    if (stat == 0 .and. allocated(parsed%config)) call apply_toml_string(parsed%config, s, stat, errmsg)
    if (stat == 0) call apply_args(parsed, s, stat, errmsg)
    if (stat == 0) call finish_settings(s, directory, stat, errmsg)
    if (stat /= 0) then
        write (error_unit, '(a)') 'fdoc: '//errmsg
        status = 1
        return
    end if

    if (parsed%action == ACTION_DUMP) then
        write (output_unit, '(a)', advance='no') dump_settings(s)
        return
    end if

    if (parsed%action /= ACTION_DUMP_LINKS .and. .not. s%quiet) call progress_enable()
    call warn_unsupported(s)
    call load_project_sources(s, p, stat, errmsg)
    if (stat /= 0) then
        write (error_unit, '(a)') 'fdoc: '//errmsg
        status = 1
        return
    end if
    call progress_start('Connecting entities', p%list%n)
    call correlate(p, s)
    call link_project(p)
    call prune(p, s)
    call progress_finish()
    if (parsed%action == ACTION_DUMP_LINKS) then
        call write_text(dump_links(p))
        return
    end if
    call assign_pages(p)
    call base_options(s, '..', options)
    call collect_abbreviations(p, options)
    call index_entity_names(p%list)
    call render_documentation(p, s, options)
    call base_options(s, '.', front_options)
    if (allocated(options%abbreviations)) front_options%abbreviations = options%abbreviations
    call render_text(p, front_options, 0, '', body, front)
    call load_pages(p, s, options, static)
    call write_site(p, s, front, static, pages, stat, errmsg)
    if (stat == 0 .and. s%externalize) call write_modules(p, s, stat, errmsg)
    if (stat /= 0) then
        write (error_unit, '(a)') 'fdoc: '//errmsg
        status = 1
        return
    end if
    write (count_text, '(i0)') pages
    call progress_summary(trim(count_text)//' pages written to '//s%output_dir)
end function run

!> Warn about settings that are read but have no effect.
subroutine warn_unsupported(s)
    type(settings_t), intent(in) :: s   !! the settings
    integer :: k

    if (size(s%html_template_dir) > 0) call warn('html_template_dir has no effect: fdoc does not use templates')
    do k = 1, size(s%md_extensions)
        select case (s%md_extensions(k)%s)
        case ('markdown.extensions.toc', 'toc', 'markdown.extensions.smarty', 'smarty')
            continue
        case default
            call warn('md_extensions: '//s%md_extensions(k)%s//' is not available, only toc and smarty')
        end select
    end do
end subroutine warn_unsupported

!> Convert the Markdown texts in JSON array file `path`, and print the results as a JSON array.
subroutine markdown_list(path)
    character(len=*), intent(in) :: path    !! the file
    type(json_core) :: json
    type(json_value), pointer :: root, item, results
    type(markdown_options_t) :: options
    character(len=:), allocatable :: source, html, text
    logical :: found
    integer :: k, n

    options%base_path = '.'
    options%aliases = [map_entry_t('url', 'URL'), map_entry_t('media', 'MEDIA'), map_entry_t('page', 'PAGE')]
    call json%initialize()
    call json%load(path, root)
    call json%info(root, n_children=n)
    call json%create_array(results, '')
    do k = 1, n
        call json%get_child(root, k, item, found)
        call json%get(item, source)
        call markdown_to_html(source, options, html)
        call json%add(results, '', html)
    end do
    call json%serialize(results, text)
    call write_text(text)
    call json%destroy(root)
    call json%destroy(results)
end subroutine markdown_list

!> Write `text` to standard output.
subroutine write_text(text)
    character(len=*), intent(in) :: text    !! the text
    write (output_unit, '(a)', advance='no') text
end subroutine write_text

end module fdoc
