module fdoc_cli
!! The command line. Options are those of FORD, and override the project file.
use ffmt_fs, only: parent_directory
use fdoc_util
use fdoc_settings, only: settings_t, set_option
implicit none
private

public :: parse_args, apply_args, usage

character(len=*), parameter, public :: VERSION = '0.0.1'

integer, parameter, public :: ACTION_RUN = 0       !! generate the documentation
integer, parameter, public :: ACTION_HELP = 1      !! print the usage
integer, parameter, public :: ACTION_VERSION = 2   !! print the version
integer, parameter, public :: ACTION_DUMP = 3      !! print the settings
integer, parameter, public :: ACTION_DUMP_LINKS = 4 !! print how entities are connected
integer, parameter, public :: ACTION_MARKDOWN = 5  !! convert a JSON list of Markdown texts

type, public :: option_t
    !! An option given on the command line, in the form [[set_option]] takes.
    character(len=:), allocatable :: key
    type(string_t), allocatable :: values(:)
end type option_t

type, public :: args_t
    !! The parsed command line.
    integer :: action = ACTION_RUN
    character(len=:), allocatable :: project_file
    character(len=:), allocatable :: config             !! `--config`, not allocated if not given
    type(option_t), allocatable :: options(:)
end type args_t

contains

!> The help text.
function usage() result(text)
    character(len=:), allocatable :: text
    character, parameter :: NL = achar(10)
    text = 'usage: fdoc [options] [project_file]'//NL//NL// &
           'Document a program or library written in modern Fortran. Command line options override'//NL// &
           'those in the project file. Without one, settings come from an [extra.fdoc] or'//NL// &
           '[extra.ford] table in fpm.toml, or from ford.md.'//NL//NL// &
           '  -d, --src_dir DIR        directory of source files (repeatable; default ./src)'//NL// &
           '  -p, --page_dir DIR       directory of static pages'//NL// &
           '  -o, --output_dir DIR     output directory (default ./doc)'//NL// &
           '  -s, --css FILE           custom style sheet'//NL// &
           '  -r, --revision REV       version or revision of the project'//NL// &
           '      --exclude FILE       file to leave out (repeatable)'//NL// &
           '      --exclude_dir DIR    directory to leave out (repeatable)'//NL// &
           '  -e, --extensions EXT     extension to scan (repeatable)'//NL// &
           '  -m, --macro MACRO        preprocessor macro (repeatable)'//NL// &
           '  -I, --include DIR        directory for include files (repeatable)'//NL// &
           '  -L, --external_links X   external project: name=path-or-url (repeatable)'//NL// &
           '  -w, --warn               warn about undocumented items'//NL// &
           '  -f, --force              continue reading files after fatal errors'//NL// &
           '  -g, --graph              generate graphs'//NL// &
           '      --no-search          do not build the search index'//NL// &
           '      --externalize        write modules.json for other projects (default)'//NL// &
           '      --no-externalize     do not write modules.json'//NL// &
           '  -q, --quiet              suppress normal output'//NL// &
           '      --debug              show details of fatal errors'//NL// &
           '      --config TOML        other options, as TOML with ; between lines'//NL// &
           '      --dump-settings      print the settings as JSON and stop'//NL// &
           '      --dump-links         print how entities are connected as JSON and stop'//NL// &
           '      --markdown-list FILE convert a JSON list of Markdown texts, to compare with FORD'//NL// &
           '  -V, --version            print the version'//NL// &
           '  -h, --help               print this help'//NL
end function usage

!> Read the command line.
subroutine parse_args(args, parsed, stat, errmsg)
    type(string_t), intent(in) :: args(:)               !! the arguments, in order
    type(args_t), intent(out) :: parsed                 !! the result
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    character(len=:), allocatable :: arg, name, value
    integer :: k, at
    logical :: has_value

    stat = 0
    allocate (parsed%options(0))
    k = 1
    do while (k <= size(args))
        arg = args(k)%s
        k = k + 1
        if (len(arg) < 2 .or. arg(1:1) /= '-') then
            if (allocated(parsed%project_file)) then
                call fail('unexpected argument: '//arg)
                return
            end if
            parsed%project_file = arg
            cycle
        end if

        has_value = .false.
        if (starts_with(arg, '--')) then
            at = index(arg, '=')
            if (at > 0) then
                name = arg(:at - 1)
                value = arg(at + 1:)
                has_value = .true.
            else
                name = arg
            end if
        else
            name = arg(1:2)
            if (len(arg) > 2) then
                value = arg(3:)
                has_value = .true.
            end if
        end if

        select case (name)
        case ('-h', '--help'); parsed%action = ACTION_HELP
        case ('-V', '--version'); parsed%action = ACTION_VERSION
        case ('--dump-settings'); parsed%action = ACTION_DUMP
        case ('--dump-links'); parsed%action = ACTION_DUMP_LINKS
        case ('--markdown-list')
            parsed%action = ACTION_MARKDOWN
            call take_value()
            if (stat == 0) parsed%project_file = value
        case ('-w', '--warn'); call flag('warn', 'true')
        case ('-f', '--force'); call flag('force', 'true')
        case ('-g', '--graph'); call flag('graph', 'true')
        case ('-q', '--quiet'); call flag('quiet', 'true')
        case ('--debug'); call flag('dbg', 'true')
        case ('--no-search'); call flag('search', 'false')
        case ('--externalize'); call flag('externalize', 'true')
        case ('--no-externalize'); call flag('externalize', 'false')
        case ('-d', '--src_dir'); call valued('src_dir', .true.)
        case ('-p', '--page_dir'); call valued('page_dir', .false.)
        case ('-o', '--output_dir'); call valued('output_dir', .false.)
        case ('-s', '--css'); call valued('css', .false.)
        case ('-r', '--revision'); call valued('revision', .false.)
        case ('--exclude'); call valued('exclude', .true.)
        case ('--exclude_dir'); call valued('exclude_dir', .true.)
        case ('-e', '--extensions'); call valued('extensions', .true.)
        case ('-m', '--macro'); call valued('macro', .true.)
        case ('-I', '--include'); call valued('include', .true.)
        case ('-L', '--external_links'); call valued('external', .true.)
        case ('--config')
            call take_value()
            if (stat == 0) parsed%config = value
        case default
            call fail('unknown option: '//arg)
        end select
        if (stat /= 0) return
    end do
    if (.not. allocated(parsed%project_file)) parsed%project_file = ''

contains

    !> Record a failure.
    subroutine fail(msg)
        character(len=*), intent(in) :: msg     !! what is wrong
        stat = 2
        errmsg = msg
    end subroutine fail

    !> The value of the current option: joined to it, or the next argument.
    subroutine take_value()
        if (has_value) return
        if (k > size(args)) then
            call fail('option '//name//' needs a value')
            return
        end if
        value = args(k)%s
        k = k + 1
    end subroutine take_value

    !> Handle an option that takes no value.
    subroutine flag(key, text)
        character(len=*), intent(in) :: key     !! the setting it controls
        character(len=*), intent(in) :: text    !! the value of that setting
        if (has_value) then
            call fail('option '//name//' takes no value')
            return
        end if
        call add(key, text, .false.)
    end subroutine flag

    !> Handle an option that takes a value.
    subroutine valued(key, repeatable)
        character(len=*), intent(in) :: key     !! the setting it controls
        logical, intent(in) :: repeatable       !! true if the option may be given more than once
        call take_value()
        if (stat == 0) call add(key, value, repeatable)
    end subroutine valued

    !> Record an option. A later value replaces an earlier one unless the option is repeatable.
    subroutine add(key, text, repeatable)
        character(len=*), intent(in) :: key     !! the setting
        character(len=*), intent(in) :: text    !! its value
        logical, intent(in) :: repeatable       !! true if values accumulate
        type(option_t), allocatable :: grown(:)
        integer :: j

        do j = 1, size(parsed%options)
            if (parsed%options(j)%key /= key) cycle
            if (repeatable) then
                call push(parsed%options(j)%values, text)
            else
                parsed%options(j)%values = [string_t(text)]
            end if
            return
        end do
        allocate (grown(size(parsed%options) + 1))
        grown(:size(parsed%options)) = parsed%options
        grown(size(grown))%key = key
        grown(size(grown))%values = [string_t(text)]
        call move_alloc(grown, parsed%options)
    end subroutine add

end subroutine parse_args

!> Apply command line options to the settings.
subroutine apply_args(parsed, s, stat, errmsg)
    type(args_t), intent(in) :: parsed                  !! the command line
    type(settings_t), intent(inout) :: s                !! the settings
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg  !! what is wrong
    integer :: k

    stat = 0
    do k = 1, size(parsed%options)
        call set_option(s, parsed%options(k)%key, parsed%options(k)%values, stat, errmsg)
        if (stat /= 0) return
    end do
end subroutine apply_args

end module fdoc_cli
