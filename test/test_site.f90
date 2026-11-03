module test_site
!! The pages of a small project on real files, through the whole program.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc, only: run
use fdoc_util, only: string_t, read_whole_file, write_whole_file
use fdoc_shell, only: make_directory, remove_directory
use fdoc_stats, only: file_stats_t, count_source
implicit none
private

public :: collect_site

! each test has its own directory, as tests run in parallel
character(len=*), parameter :: WITH_LOGO = 'build/test site logo'
character(len=*), parameter :: NO_LOGO = 'build/test site no logo'
character(len=*), parameter :: NL = new_line('a')

contains

!> The tests of this module.
subroutine collect_site(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests

    testsuite = [new_unittest("logo", test_logo), new_unittest("logo that is missing", test_missing_logo), &
                 new_unittest("lines of a source file", test_lines), new_unittest("list of source files", test_file_list), &
                 new_unittest("external project", test_external), &
                 new_unittest("where a type is used", test_type_uses), &
                 new_unittest("index and tree of types", test_index_tree)]
end subroutine collect_site

!> Write a project with the setting `logo: small.svg` in `root`, and run fdoc on it.
subroutine make_site(root, error)
    character(len=*), intent(in) :: root                    !! the directory
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: errmsg
    integer :: stat

    call remove_directory(root)
    call make_directory(root//'/src', stat)
    call write_whole_file(root//'/ford.md', 'project: logos'//NL//'src_dir: ./src'//NL//'output_dir: ./doc'//NL// &
                          'logo: small.svg'//NL//NL//'The project.'//NL, stat, errmsg)
    call check(error, stat, 0, 'the project file')
    if (allocated(error)) return
    call write_whole_file(root//'/src/a.f90', 'module m'//NL//'end module m'//NL, stat, errmsg)
    call check(error, stat, 0, 'the source')
end subroutine make_site

!> Run fdoc on the project in `root`.
subroutine run_site(root, error)
    character(len=*), intent(in) :: root                    !! the directory
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    type(string_t) :: args(2)

    args(1)%s = '-q'
    args(2)%s = root//'/ford.md'
    call check(error, run(args), 0, 'the run')
end subroutine run_site

!> Checks: the logo goes in the site, and on the main page.
subroutine test_logo(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: text, errmsg
    logical :: copied
    integer :: stat

    call make_site(WITH_LOGO, error)
    if (allocated(error)) return
    call write_whole_file(WITH_LOGO//'/small.svg', '<svg xmlns="http://www.w3.org/2000/svg"/>', stat, errmsg)
    call run_site(WITH_LOGO, error)
    if (allocated(error)) return
    inquire (file=WITH_LOGO//'/doc/logo.svg', exist=copied)
    call check(error, copied, 'it is copied, keeping its extension')
    if (allocated(error)) return
    call read_whole_file(WITH_LOGO//'/doc/index.html', text, stat, errmsg)
    call check(error, stat, 0, 'the main page')
    if (allocated(error)) return
    call check(error, index(text, 'class="hero with-logo"') > 0, 'the box makes room for it')
    if (allocated(error)) return
    call check(error, index(text, '<img class="hero-logo" src="logo.svg"') > 0, 'it is on the page')
    call remove_directory(WITH_LOGO)
end subroutine test_logo

!> Checks: a logo that is not there does not stop the run, or leave a broken image.
subroutine test_missing_logo(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=:), allocatable :: text, errmsg
    integer :: stat

    call make_site(NO_LOGO, error)
    if (allocated(error)) return
    call run_site(NO_LOGO, error)
    if (allocated(error)) return
    call read_whole_file(NO_LOGO//'/doc/index.html', text, stat, errmsg)
    call check(error, stat, 0, 'the main page')
    if (allocated(error)) return
    call check(error, index(text, '<img class="hero-logo"') == 0, 'there is no image')
    call remove_directory(NO_LOGO)
end subroutine test_missing_logo

!> Checks: lines are told apart, with a `!` in a string, a comment after code, spaces and CRLF.
subroutine test_lines(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    type(file_stats_t) :: stats

    call count_source('! one'//NL//'x = "!" ! two'//NL//NL//'   '//NL//'  !! three'//achar(13)//NL//'y = 1', stats)
    call check(error, stats%lines, 6, 'all lines, with the last having no line ending')
    if (allocated(error)) return
    call check(error, stats%code, 2, 'a comment after code is code')
    if (allocated(error)) return
    call check(error, stats%comments, 2, 'comments alone on a line')
    if (allocated(error)) return
    call check(error, stats%blank, 2, 'empty lines and lines of spaces')
    if (allocated(error)) return
    call check(error, int(stats%bytes), 42, 'bytes')
end subroutine test_lines

!> Checks: the list of files shows the counts of a file and the total.
subroutine test_file_list(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=*), parameter :: ROOT = 'build/test site files'
    character(len=:), allocatable :: text, sidebar, errmsg
    integer :: stat

    call make_site(ROOT, error)
    if (allocated(error)) return
    call write_whole_file(ROOT//'/src/b.f90', 'module b'//NL//'contains'//NL//'! here'//NL//'subroutine s'//NL// &
                          'end subroutine s'//NL//'end module b'//NL, stat, errmsg)
    call run_site(ROOT, error)
    if (allocated(error)) return
    call read_whole_file(ROOT//'/doc/lists/files.html', text, stat, errmsg)
    call check(error, stat, 0, 'the list')
    if (allocated(error)) return
    call check(error, index(text, 'class="listing sortable"') > 0, 'it can be sorted')
    if (allocated(error)) return
    call read_whole_file(ROOT//'/doc/js/sidebar.js', sidebar, stat, errmsg)
    call check(error, stat, 0, 'the entries of the sidebar')
    if (allocated(error)) return
    call check(error, index(sidebar, 'window.FDOC_SIDEBAR={') == 1, 'they are a script')
    if (allocated(error)) return
    if (allocated(error)) return
    call check(error, index(text, '<td class="num" data-sort="6">6</td><td class="num" data-sort="5">5</td>') > 0, 'lines of b')
    if (allocated(error)) return
    call check(error, index(text, '<tfoot><tr><td>Total</td><td class="num" data-sort="8">8</td>') > 0, 'the total')
    call remove_directory(ROOT)
end subroutine test_file_list

!> Checks: a `use` of a module of an external project links to it, with several variables in the module.
subroutine test_external(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=*), parameter :: ROOT = 'build/test site external'
    character(len=:), allocatable :: text, errmsg
    type(string_t) :: args(2)
    integer :: stat

    call remove_directory(ROOT)
    call make_directory(ROOT//'/src', stat)
    call make_directory(ROOT//'/other', stat)
    call write_whole_file(ROOT//'/ford.md', 'project: uses'//NL//'src_dir: ./src'//NL//'output_dir: ./doc'//NL// &
                          'external: other=./other'//NL//NL//'The project.'//NL, stat, errmsg)
    call check(error, stat, 0, 'the project file')
    if (allocated(error)) return
    call write_whole_file(ROOT//'/src/a.f90', 'module m'//NL//'use lib'//NL//'end module m'//NL, stat, errmsg)
    call write_whole_file(ROOT//'/other/modules.json', '{"modules": [{"name": "lib", "obj": "module", '// &
                          '"external_url": "./module/lib.html", "pub_vars": [{"name": "a", "obj": "variable"}, '// &
                          '{"name": "b", "obj": "variable"}]}]}', stat, errmsg)
    call check(error, stat, 0, 'the external project')
    if (allocated(error)) return
    args(1)%s = '-q'
    args(2)%s = ROOT//'/ford.md'
    call check(error, run(args), 0, 'the run')
    if (allocated(error)) return
    call read_whole_file(ROOT//'/doc/module/m.html', text, stat, errmsg)
    call check(error, stat, 0, 'the page of the module')
    if (allocated(error)) return
    call check(error, index(text, 'module/lib.html">lib</a>') > 0, 'it links to the external module')
    call remove_directory(ROOT)
end subroutine test_external

!> Checks: the uses of a type, without its own methods, its own components or local variables, and with
!> a private specific procedure shown as its generic.
subroutine test_type_uses(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=*), parameter :: ROOT = 'build/test site uses'
    character(len=:), allocatable :: text, errmsg
    type(string_t) :: args(2)
    integer :: stat

    call remove_directory(ROOT)
    call make_directory(ROOT//'/src', stat)
    call write_whole_file(ROOT//'/ford.md', 'project: uses'//NL//'src_dir: ./src'//NL//'output_dir: ./doc'//NL// &
                          NL//'The project.'//NL, stat, errmsg)
    call write_whole_file(ROOT//'/src/a.f90', &
                          'module m'//NL//'private'//NL//'public :: thing, holder, shared, takes, gives, plain, generic'//NL// &
                          'type :: thing'//NL//'type(thing), pointer :: next => null()'//NL//'contains'//NL// &
                          'procedure :: method'//NL//'end type thing'//NL// &
                          'type :: holder'//NL//'type(thing) :: part'//NL//'end type holder'//NL// &
                          'type(thing) :: shared'//NL// &
                          'interface generic'//NL//'module procedure hidden'//NL//'end interface generic'//NL// &
                          'contains'//NL// &
                          'subroutine method(self)'//NL//'class(thing) :: self'//NL//'end subroutine method'//NL// &
                          'subroutine takes(x)'//NL//'type(thing) :: x'//NL//'end subroutine takes'//NL// &
                          'function gives() result(r)'//NL//'type(thing) :: r'//NL//'end function gives'//NL// &
                          'subroutine plain()'//NL//'type(thing) :: local'//NL//'end subroutine plain'//NL// &
                          'subroutine hidden(y)'//NL//'type(thing) :: y'//NL//'end subroutine hidden'//NL// &
                          'end module m'//NL, stat, errmsg)
    call check(error, stat, 0, 'the source')
    if (allocated(error)) return
    args(1)%s = '-q'
    args(2)%s = ROOT//'/ford.md'
    call check(error, run(args), 0, 'the run')
    if (allocated(error)) return
    call read_whole_file(ROOT//'/doc/type/thing.html', text, stat, errmsg)
    call check(error, stat, 0, 'the page of the type')
    if (allocated(error)) return
    text = text(index(text, 'id="uses-of-type"'):)
    text = text(:index(text, '<h2 id="source"') + merge(len(text), 0, index(text, '<h2 id="source"') == 0))
    call check(error, index(text, '<h3>Argument of (2)</h3>') > 0, 'a procedure, and a generic in place of a specific')
    if (allocated(error)) return
    call check(error, index(text, '>takes</a>') > 0, 'an argument')
    if (allocated(error)) return
    call check(error, index(text, '>generic</a>') > 0, 'the generic of a private procedure')
    if (allocated(error)) return
    call check(error, index(text, '>gives</a>') > 0, 'a result')
    if (allocated(error)) return
    call check(error, index(text, '>holder</a>') > 0, 'a component')
    if (allocated(error)) return
    call check(error, index(text, '>shared</a>') > 0, 'a module variable')
    if (allocated(error)) return
    call check(error, index(text, 'method') == 0, 'not its own method')
    if (allocated(error)) return
    call check(error, index(text, '>plain<') == 0, 'not a local variable')
    if (allocated(error)) return
    call check(error, index(text, '>thing<') == 0, 'not a component of itself')
    call remove_directory(ROOT)
end subroutine test_type_uses

!> Checks: the index of all names, in order under their letters, and the tree of types by what they extend.
subroutine test_index_tree(error)
    type(error_type), allocatable, intent(out) :: error     !! the failure, if any
    character(len=*), parameter :: ROOT = 'build/test site index'
    character(len=:), allocatable :: text, errmsg
    type(string_t) :: args(2)
    integer :: stat

    call remove_directory(ROOT)
    call make_directory(ROOT//'/src', stat)
    call write_whole_file(ROOT//'/ford.md', 'project: index'//NL//'src_dir: ./src'//NL//'output_dir: ./doc'//NL// &
                          NL//'The project.'//NL, stat, errmsg)
    call write_whole_file(ROOT//'/src/a.f90', &
                          'module zeta'//NL//'type :: base'//NL//'end type base'//NL// &
                          'type, extends(base) :: child'//NL//'end type child'//NL// &
                          'type, extends(child) :: grandchild'//NL//'end type grandchild'//NL// &
                          'type :: alone'//NL//'end type alone'//NL//'contains'//NL// &
                          'subroutine apply()'//NL//'end subroutine apply'//NL//'end module zeta'//NL, stat, errmsg)
    args(1)%s = '-q'
    args(2)%s = ROOT//'/ford.md'
    call check(error, run(args), 0, 'the run')
    if (allocated(error)) return

    call read_whole_file(ROOT//'/doc/lists/names.html', text, stat, errmsg)
    call check(error, stat, 0, 'the index')
    if (allocated(error)) return
    call check(error, index(text, 'class="here" href="../lists/names.html"') > 0, 'its tab')
    if (allocated(error)) return
    ! the sidebar has names too, in another order
    text = text(index(text, '<main'):)
    call check(error, index(text, '<a href="#letter-a">A</a>') > 0, 'a link to each letter')
    if (allocated(error)) return
    call check(error, index(text, '>alone</a>') < index(text, '>apply</a>'), 'names in order')
    if (allocated(error)) return
    ! the module's own entry, as its name is also where the types are
    call check(error, index(text, '<h2 id="letter-z">Z</h2>') < index(text, '>M</span>zeta</a>'), 'under their letter')
    if (allocated(error)) return

    call read_whole_file(ROOT//'/doc/lists/types.html', text, stat, errmsg)
    call check(error, stat, 0, 'the list of types')
    if (allocated(error)) return
    call check(error, index(text, '<h2 id="hierarchy">Hierarchy</h2>') > 0, 'a tree')
    if (allocated(error)) return
    call check(error, index(text, '>base</a></summary><ul><li><details open><summary>') > 0, 'base holds child')
    if (allocated(error)) return
    call check(error, index(text, '>child</a></summary><ul><li>') > 0, 'child holds grandchild')
    call remove_directory(ROOT)
end subroutine test_index_tree

end module test_site
