module fdoc_graphs
!! Dependency graphs: which modules use which, what procedures call, how types extend each other and
!! how files depend on each other. Graphs are written in Graphviz's language and laid out by `dot`, in
!! batches of files, so that a process does not have to start for each graph.
use iso_c_binding, only: c_int
use iso_fortran_env, only: int64, real64
use ffmt_io, only: read_file, write_file
use fdoc_util
use fdoc_buffer
use fdoc_model
use fdoc_settings, only: settings_t
use fdoc_project, only: project_t
use fdoc_urls, only: entity_url
use fdoc_progress, only: progress_start, progress_tick, progress_finish, warn
use fdoc_shell, only: make_directory, remove_directory, program_exists
implicit none
private

public :: graph_t, graph_set_t, build_graphs

integer, parameter, public :: REL_USES = 1       !! modules used
integer, parameter, public :: REL_CALLS = 2      !! procedures called
integer, parameter, public :: REL_INHERITS = 3   !! types extended
integer, parameter, public :: REL_FILES = 4      !! files depended on
integer, parameter :: NUM_RELATIONS = 4

integer, parameter :: BATCH = 25             !! graphs for one `dot` process
integer(c_int), parameter :: POLL_MICROSECONDS = 2000   !! how often to look for finished batches

character(len=*), parameter :: FONT_SIZE = '13'         !! points, of the names in a graph
character(len=*), parameter :: LABEL_FONT_SIZE = '11'   !! points, of the labels of edges
character(len=*), parameter :: EDGE_COLOUR = '#8a93a5'
character(len=*), parameter :: EDGE_COLOURS(*) = [character(len=7) :: '#3657c9', '#1d7a55', '#a15c00', '#b3261e', &
                                                  '#6a4fb3', '#0b7285', '#a61e69', '#5c6f2d']

interface
    !> Sleep for a while.
    function c_usleep(microseconds) bind(c, name='usleep') result(status)
        import :: c_int
        integer(c_int), value :: microseconds   !! how long to sleep
        integer(c_int) :: status
    end function c_usleep
end interface

type :: int_list_t
    !! A list of entities.
    integer, allocatable :: ids(:)              !! the entities
end type int_list_t

type :: label_list_t
    !! Labels of edges.
    type(string_t), allocatable :: text(:)      !! the label of each edge, `''` for a solid edge
end type label_list_t

type :: adjacency_t
    !! Each direction of one relation, for each entity.
    type(int_list_t), allocatable :: out(:)     !! what each entity points to
    type(int_list_t), allocatable :: in(:)      !! what points to each entity
    type(label_list_t), allocatable :: labels(:)    !! the labels of `out`
end type adjacency_t

type :: graph_t
    !! A graph of a page.
    character(len=:), allocatable :: title      !! its heading
    character(len=:), allocatable :: svg        !! its drawing
    integer :: owner = 0                        !! the entity whose page shows it, or 0
    integer :: list_page = 0                    !! the list page that shows it, or 0
end type graph_t

type :: graph_set_t
    !! The graphs of a project.
    type(graph_t), allocatable :: graphs(:)     !! the graphs
end type graph_set_t

type :: dot_file_t
    !! A graph waiting for layout.
    character(len=:), allocatable :: text       !! its description for `dot`
    character(len=:), allocatable :: title      !! its heading
    integer :: owner = 0                        !! the entity whose page shows it, or 0
    integer :: list_page = 0                    !! the list page that shows it, or 0
end type dot_file_t

contains

!> Build the relations between entities.
subroutine build_relations(p, relations)
    type(project_t), intent(in) :: p                        !! the project
    type(adjacency_t), intent(out) :: relations(NUM_RELATIONS)  !! the relations
    integer, allocatable :: seen(:)
    logical, allocatable :: done(:)
    logical :: changed
    integer :: r, k, j, target, seen_stamp

    allocate (seen(p%list%n))
    seen = 0
    seen_stamp = 0
    do r = 1, NUM_RELATIONS
        allocate (relations(r)%out(p%list%n), relations(r)%in(p%list%n), relations(r)%labels(p%list%n))
    end do
    do k = 1, p%list%n
        associate (e => p%list%box(k)%e)
            if (e%kind == E_NONE) cycle
            if (allocated(e%more%uses)) then
                do j = 1, size(e%more%uses)
                    if (e%more%uses(j)%target > 0) call connect(relations(REL_USES), k, e%more%uses(j)%target)
                end do
            end if
            if (e%kind == E_SUBMODULE) then
                if (e%parent_submodule_id > 0) then
                    call connect(relations(REL_USES), k, e%parent_submodule_id)
                else if (e%ancestor_id > 0) then
                    call connect(relations(REL_USES), k, e%ancestor_id)
                end if
            end if
            if (e%visible .and. e%kind /= E_BOUNDPROC) then
                seen_stamp = seen_stamp + 1
                call visible_calls(p, k, k, seen, seen_stamp, relations(REL_CALLS))
            end if
            if (allocated(e%more%modproc_ids)) then
                do j = 1, size(e%more%modproc_ids)
                    if (e%more%modproc_ids(j) == 0) cycle
                    if (p%list%box(e%more%modproc_ids(j))%e%visible) call connect(relations(REL_CALLS), k, e%more%modproc_ids(j))
                end do
            end if
            if (e%kind == E_INTERFACE) then
                do j = 1, size(e%children)
                    if (p%list%box(e%children(j))%e%visible) call connect(relations(REL_CALLS), k, e%children(j))
                end do
            end if
            if (e%extends_id > 0) call connect(relations(REL_INHERITS), k, e%extends_id)
            if (e%kind == E_TYPE .and. e%visible) then
                do j = 1, size(e%children)
                    associate (c => p%list%box(e%children(j))%e)
                        if (c%kind /= E_VARIABLE .or. c%proto_id == 0) cycle
                        if (p%list%box(c%proto_id)%e%kind == E_TYPE) then
                            call connect(relations(REL_INHERITS), k, c%proto_id, c%name)
                        end if
                    end associate
                end do
            end if
            if (e%file > 0 .and. allocated(e%more%uses)) then
                do j = 1, size(e%more%uses)
                    target = e%more%uses(j)%target
                    if (target == 0) cycle
                    target = p%list%box(target)%e%file
                    if (target > 0 .and. target /= e%file) call connect(relations(REL_FILES), e%file, target)
                end do
            end if
        end associate
    end do

    ! a generic binding is a node only once something refers to it
    allocate (done(p%list%n))
    done = .false.
    changed = .true.
    do while (changed)
        changed = .false.
        do k = 1, p%list%n
            if (done(k) .or. p%list%box(k)%e%kind /= E_BOUNDPROC) cycle
            if (.not. allocated(relations(REL_CALLS)%in(k)%ids)) cycle
            done(k) = .true.
            changed = .true.
            seen_stamp = seen_stamp + 1
            call visible_calls(p, k, k, seen, seen_stamp, relations(REL_CALLS))
        end do
    end do
end subroutine build_relations

!> True if a graph shows binding `id` as the procedure it binds: it binds one, which can be shown.
logical function is_simple_binding(p, id)
    type(project_t), intent(in) :: p    !! the project
    integer, intent(in) :: id           !! the entity

    is_simple_binding = .false.
    associate (e => p%list%box(id)%e)
        if (e%kind /= E_BOUNDPROC .or. .not. allocated(e%more%binding_ids)) return
        if (size(e%more%binding_ids) /= 1) return
        if (e%deferred) then
            is_simple_binding = .true.
        else if (e%more%binding_ids(1) > 0) then
            is_simple_binding = p%list%box(e%more%binding_ids(1))%e%kind /= E_BOUNDPROC .and. &
                                p%list%box(e%more%binding_ids(1))%e%visible
        end if
    end associate
end function is_simple_binding

!> Add edges from `from` to what `id` calls. What cannot be shown is replaced by what it calls.
recursive subroutine visible_calls(p, id, from, seen, stamp, relation)
    type(project_t), intent(in) :: p                !! the project
    integer, intent(in) :: id                       !! the entity whose calls to follow
    integer, intent(in) :: from                     !! where the edges start
    integer, intent(inout) :: seen(:)               !! when each entity was last visited
    integer, intent(in) :: stamp                    !! a number new for each `from`
    type(adjacency_t), intent(inout) :: relation    !! the relation
    integer :: j

    associate (e => p%list%box(id)%e)
        if (allocated(e%call_ids)) then
            do j = 1, size(e%call_ids)
                call visit(e%call_ids(j))
            end do
        end if
        if (allocated(e%more%binding_ids)) then
            do j = 1, size(e%more%binding_ids)
                if (e%more%binding_ids(j) > 0) call visit(e%more%binding_ids(j))
            end do
        end if
    end associate

contains

    !> Handle a call to `target`.
    recursive subroutine visit(target)
        integer, intent(in) :: target   !! what is called

        if (seen(target) == stamp) return
        seen(target) = stamp
        if (p%list%box(target)%e%visible .and. .not. is_simple_binding(p, target)) then
            call connect(relation, from, target)
        else
            call visible_calls(p, target, from, seen, stamp, relation)
        end if
    end subroutine visit

end subroutine visible_calls

!> Add an edge, once. With `label`, the edge is dashed and labelled: components of a type have one.
subroutine connect(relation, from, to, label)
    type(adjacency_t), intent(inout) :: relation    !! the relation
    integer, intent(in) :: from                     !! where it starts
    integer, intent(in) :: to                       !! where it ends
    character(len=*), intent(in), optional :: label !! its label
    integer :: k

    if (from == to .and. .not. present(label)) return
    if (allocated(relation%out(from)%ids)) then
        do k = 1, size(relation%out(from)%ids)
            if (relation%out(from)%ids(k) /= to) cycle
            if (present(label)) then
                if (len(relation%labels(from)%text(k)%s) > 0) then
                    relation%labels(from)%text(k)%s = relation%labels(from)%text(k)%s//', '//label
                end if
            end if
            return
        end do
    end if
    call push_int(relation%out(from)%ids, to)
    call push_int(relation%in(to)%ids, from)
    if (present(label)) then
        call push(relation%labels(from)%text, label)
    else
        call push(relation%labels(from)%text, '')
    end if
end subroutine connect

!> True if entity `id` is drawn with graphs.
logical function graphs_wanted(p, s, id, depth, nodes)
    type(project_t), intent(in) :: p    !! the project
    type(settings_t), intent(in) :: s   !! the settings
    integer, intent(in) :: id           !! the entity
    integer, intent(out) :: depth       !! its `graph_maxdepth`
    integer, intent(out) :: nodes       !! its `graph_maxnodes`
    logical :: flag, ok
    integer :: k, value

    graphs_wanted = s%graph
    depth = s%graph_maxdepth
    nodes = s%graph_maxnodes
    associate (e => p%list%box(id)%e)
        if (.not. allocated(e%meta)) return
        do k = 1, size(e%meta)
            select case (e%meta(k)%key)
            case ('graph')
                call parse_bool(e%meta(k)%values(1)%s, flag, ok)
                if (ok) graphs_wanted = flag
            case ('graph_maxdepth')
                call parse_int(e%meta(k)%values(1)%s, value, ok)
                if (ok) depth = value
            case ('graph_maxnodes')
                call parse_int(e%meta(k)%values(1)%s, value, ok)
                if (ok) nodes = value
            end select
        end do
    end associate
end function graphs_wanted

!> The description of the graph reached from `roots`, or `''` if it has only one node.
subroutine describe_graph(p, s, relation, forward, roots, marked, stamp, max_depth, max_nodes, direction, text)
    type(project_t), intent(in) :: p                    !! the project
    type(settings_t), intent(in) :: s                   !! the settings
    type(adjacency_t), intent(in) :: relation           !! the relation
    logical, intent(in) :: forward                      !! true to follow edges forward
    integer, intent(in) :: roots(:)                     !! where to start
    integer, intent(inout) :: marked(:)                 !! when each entity was last reached
    integer, intent(inout) :: stamp                     !! a number new for each graph
    integer, intent(in) :: max_depth                    !! how many hops to follow
    integer, intent(in) :: max_nodes                    !! how many nodes to allow
    character(len=*), intent(in) :: direction           !! `rankdir`
    character(len=:), allocatable, intent(out) :: text  !! the description
    integer, allocatable :: queue(:), levels(:), next(:)
    type(buffer_t) :: nodes, edges
    integer :: head, k, id, other, j, tail, edge_count

    stamp = stamp + 1
    allocate (queue(0), levels(0))
    do k = 1, size(roots)
        marked(roots(k)) = stamp
        call push_int(queue, roots(k))
        call push_int(levels, 0)
    end do
    head = 1
    edge_count = 0
    do while (head <= size(queue))
        id = queue(head)
        call add_node(p, id, any(roots == id) .and. size(roots) == 1, nodes)
        if (levels(head) < max_depth) then
            if (forward) then
                if (allocated(relation%out(id)%ids)) then
                    next = relation%out(id)%ids
                else
                    allocate (next(0))
                end if
            else
                if (allocated(relation%in(id)%ids)) then
                    next = relation%in(id)%ids
                else
                    allocate (next(0))
                end if
            end if
            do j = 1, size(next)
                other = next(j)
                if (p%list%box(other)%e%kind == E_NONE) cycle
                if (marked(other) /= stamp) then
                    if (size(queue) >= max_nodes) cycle
                    marked(other) = stamp
                    call push_int(queue, other)
                    call push_int(levels, levels(head) + 1)
                end if
                edge_count = edge_count + 1
                tail = merge(id, other, forward)
                call add_edge(s, relation, tail, merge(other, id, forward), edges)
            end do
            deallocate (next)
        end if
        head = head + 1
    end do
    if (size(queue) <= 1 .or. edge_count == 0) then
        text = ''
        return
    end if
    block
        type(buffer_t) :: b
        character(len=:), allocatable :: body

        call add(b, 'digraph g {'//achar(10)//'rankdir='//direction//'; bgcolor="transparent"; concentrate=true;'//achar(10))
        call add(b, 'node [shape=box, style="rounded,filled", fontname="Helvetica", fontsize='//FONT_SIZE//', fontcolor=white, ')
        call add(b, 'color=transparent, height=0.3, margin="0.1,0.04"];'//achar(10))
        call add(b, 'edge [color="'//EDGE_COLOUR//'", arrowsize=0.7];'//achar(10))
        call take(nodes, body)
        call add(b, body)
        call take(edges, body)
        call add(b, body)
        call add(b, '}'//achar(10))
        call take(b, text)
    end block
end subroutine describe_graph

!> Add node `id` to a description.
subroutine add_node(p, id, root, b)
    type(project_t), intent(in) :: p    !! the project
    integer, intent(in) :: id           !! the entity
    logical, intent(in) :: root         !! true for the entity the graph is about
    type(buffer_t), intent(inout) :: b  !! the description
    character(len=:), allocatable :: url, colour, name
    integer :: at

    associate (e => p%list%box(id)%e)
        select case (e%kind)
        case (E_MODULE); colour = '#3657c9'
        case (E_SUBMODULE); colour = '#5a78de'
        case (E_PROGRAM); colour = '#a61e69'
        case (E_SUBROUTINE); colour = '#1d7a55'
        case (E_FUNCTION); colour = '#0b7285'
        case (E_INTERFACE, E_MODPROC); colour = '#6a4fb3'
        case (E_TYPE); colour = '#a15c00'
        case (E_BOUNDPROC); colour = '#7a6a2d'
        case (E_FILE); colour = '#5c6f2d'
        case default; colour = '#646d7e'
        end select
        name = e%name
        if (e%kind == E_FILE) then
            at = index(name, '/', back=.true.)
            name = name(at + 1:)
        end if
        if (e%kind == E_BOUNDPROC) name = p%list%box(e%parent)%e%name//'%'//name
        if (e%bound_to > 0) name = p%list%box(e%bound_to)%e%name//'%'//name
        url = ''
        if (e%visible .or. allocated(e%external_url)) call entity_url(p%list, id, url)
        if (.not. e%visible .and. .not. allocated(e%external_url)) colour = '#8a93a5'
        if (allocated(e%external_url)) colour = '#646d7e'
        call add(b, 'n'//trim(number(id))//' [label="')
        call quoted(name, b)
        call add(b, '", fillcolor="'//colour//'"')
        if (root) call add(b, ', penwidth=2, color="#f0a868"')
        if (len(url) > 0) then
            call add(b, ', URL="')
            if (.not. allocated(e%external_url)) call add(b, '../')
            call quoted(url, b)
            call add(b, '"')
        end if
        call add(b, '];'//achar(10))
    end associate
end subroutine add_node

!> Add an edge to a description.
subroutine add_edge(s, relation, from, to, b)
    type(settings_t), intent(in) :: s           !! the settings
    type(adjacency_t), intent(in) :: relation   !! the relation
    integer, intent(in) :: from                 !! where it starts
    integer, intent(in) :: to                   !! where it ends
    type(buffer_t), intent(inout) :: b          !! the description
    integer :: k

    call add(b, 'n'//trim(number(from))//' -> n'//trim(number(to))//' [')
    if (s%coloured_edges) call add(b, 'color="'//EDGE_COLOURS(mod(from, size(EDGE_COLOURS)) + 1)//'", ')
    do k = 1, size(relation%out(from)%ids)
        if (relation%out(from)%ids(k) /= to) cycle
        if (len(relation%labels(from)%text(k)%s) == 0) exit
        call add(b, 'style=dashed, fontname="Helvetica", fontsize='//LABEL_FONT_SIZE//', fontcolor="#8a93a5", label="')
        call quoted(relation%labels(from)%text(k)%s, b)
        call add(b, '"')
        exit
    end do
    call add(b, '];'//achar(10))
end subroutine add_edge

!> Append `text` for use inside a quoted string of `dot`.
pure subroutine quoted(text, b)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: b      !! the description
    integer :: k

    do k = 1, len(text)
        if (text(k:k) == '"' .or. text(k:k) == '\') call add(b, '\')
        call add(b, text(k:k))
    end do
end subroutine quoted

!> `k` as text.
pure function number(k) result(text)
    integer, intent(in) :: k    !! the number
    character(len=12) :: text
    text = int_text(k)
end function number

!> Build the graphs of the project: those of `s%graph`, and of entities that ask for them.
subroutine build_graphs(p, s, members, list_codes, set, stat, errmsg)
    type(project_t), intent(in) :: p                    !! the project
    type(settings_t), intent(in) :: s                   !! the settings
    integer, intent(in) :: members(:)                   !! the entities that have pages
    integer, intent(in) :: list_codes(4)                !! the list pages of files, modules, procedures, types
    type(graph_set_t), intent(out) :: set               !! the graphs
    integer, intent(out) :: stat                        !! nonzero on failure
    character(len=:), allocatable, intent(out) :: errmsg !! what is wrong
    type(adjacency_t) :: relations(NUM_RELATIONS)
    type(dot_file_t), allocatable :: files(:)
    integer, allocatable :: marked(:), roots(:)
    character(len=:), allocatable :: directory, text
    character(len=32) :: tag
    logical :: any_wanted
    logical, allocatable :: found(:)
    integer :: k, n, stamp, depth, nodes, status, count_files

    stat = 0
    allocate (set%graphs(0))
    any_wanted = s%graph
    do k = 1, p%list%n
        if (.not. allocated(p%list%box(k)%e%meta)) cycle
        if (any([(p%list%box(k)%e%meta(n)%key == 'graph', n=1, size(p%list%box(k)%e%meta))])) any_wanted = .true.
    end do
    if (.not. any_wanted) return
    if (.not. program_exists('dot')) then
        call warn('graphs need Graphviz, and dot was not found: leaving them out')
        return
    end if

    call progress_start('Finding dependencies', size(members))
    call build_relations(p, relations)
    allocate (marked(p%list%n), files(0))
    count_files = 0
    marked = 0
    stamp = 0
    do k = 1, size(members)
        call progress_tick()
        associate (id => members(k))
            if (.not. graphs_wanted(p, s, id, depth, nodes)) cycle
            select case (p%list%box(id)%e%kind)
            case (E_MODULE, E_SUBMODULE)
                call one(id, REL_USES, .true., 'Uses', 'RL')
                call one(id, REL_USES, .false., 'Used by', 'RL')
            case (E_TYPE)
                call one(id, REL_INHERITS, .true., 'Inherits', 'RL')
                call one(id, REL_INHERITS, .false., 'Inherited by', 'RL')
            case (E_SUBROUTINE, E_FUNCTION, E_MODPROC, E_INTERFACE)
                call one(id, REL_CALLS, .true., 'Calls', 'LR')
                call one(id, REL_CALLS, .false., 'Called by', 'RL')
            case (E_PROGRAM)
                call one(id, REL_CALLS, .true., 'Calls', 'LR')
                call one(id, REL_USES, .true., 'Uses', 'RL')
            case (E_BLOCKDATA)
                call one(id, REL_USES, .true., 'Uses', 'RL')
            case (E_FILE)
                call one(id, REL_FILES, .true., 'Files this one depends on', 'RL')
                call one(id, REL_FILES, .false., 'Files that depend on this one', 'RL')
            end select
        end associate
    end do
    if (s%graph) then
        call project_graph([E_MODULE, E_SUBMODULE], REL_USES, list_codes(2), 'Module graph')
        call project_graph([E_TYPE], REL_INHERITS, list_codes(4), 'Type graph')
        call project_graph([E_SUBROUTINE, E_FUNCTION, E_PROGRAM, E_INTERFACE], REL_CALLS, list_codes(3), 'Call graph')
        call project_graph([E_FILE], REL_FILES, list_codes(1), 'File graph')
    end if
    call progress_finish()

    n = count_files
    if (n == 0) return
    call unique_tag(tag)
    directory = s%output_dir//'/.graphs-'//trim(tag)
    if (allocated(s%graph_dir)) directory = s%graph_dir
    call remove_directory(directory)
    call make_directory(directory, status)
    do k = 1, n
        call write_file(trim(file_name(directory, k, '')), files(k)%text, stat, errmsg)
        if (stat /= 0) return
    end do

    call run_batches(directory, trim(tag), n, max(1, s%parallel))

    deallocate (set%graphs)
    allocate (set%graphs(n))
    allocate (found(n))
    do k = 1, n
        set%graphs(k)%title = files(k)%title
        set%graphs(k)%owner = files(k)%owner
        set%graphs(k)%list_page = files(k)%list_page
    end do
    call load_graphs(directory, set%graphs, found, max(1, s%parallel))
    do k = 1, n
        if (.not. found(k)) call warn('no layout for a graph of '//files(k)%title)
    end do
    if (.not. allocated(s%graph_dir)) call remove_directory(directory)

contains

    !> Add a graph of the page of `id`.
    subroutine one(id, relation, forward, title, direction)
        integer, intent(in) :: id                   !! the entity
        integer, intent(in) :: relation             !! the relation
        logical, intent(in) :: forward              !! true to follow edges forward
        character(len=*), intent(in) :: title       !! the heading
        character(len=*), intent(in) :: direction   !! `rankdir`
        character(len=:), allocatable :: description

        call describe_graph(p, s, relations(relation), forward, [id], marked, stamp, depth, nodes, direction, description)
        if (len(description) == 0) return
        call add_file(description, title, id, 0)
    end subroutine one

    !> Add the graph of a whole relation to a list page.
    subroutine project_graph(kinds, relation, page, title)
        integer, intent(in) :: kinds(:)         !! the kinds of entity
        integer, intent(in) :: relation         !! the relation
        integer, intent(in) :: page             !! the list page
        character(len=*), intent(in) :: title   !! the heading
        character(len=:), allocatable :: description
        integer :: j

        allocate (roots(0))
        do j = 1, size(members)
            if (p%list%box(members(j))%e%iface == IFACE_ABSTRACT) cycle
            if (any(p%list%box(members(j))%e%kind == kinds)) call push_int(roots, members(j))
        end do
        if (size(roots) > s%graph_project_maxnodes) then
            call warn(title//' left out: it would have more than '//trim(number(s%graph_project_maxnodes))// &
                      ' nodes (see graph_project_maxnodes)')
        else if (size(roots) > 1) then
            call describe_graph(p, s, relations(relation), .true., roots, marked, stamp, 1, huge(1), 'RL', description)
            if (len(description) > 0) call add_file(description, title, 0, page)
        end if
        deallocate (roots)
    end subroutine project_graph

    !> Add a graph to the list.
    subroutine add_file(description, title, owner, page)
        character(len=*), intent(in) :: description !! its description
        character(len=*), intent(in) :: title       !! its heading
        integer, intent(in) :: owner                !! the entity whose page shows it, or 0
        integer, intent(in) :: page                 !! the list page that shows it, or 0

        type(dot_file_t), allocatable :: grown(:)
        integer :: j

        if (count_files == size(files)) then
            allocate (grown(max(64, 2*count_files)))
            do j = 1, count_files
                call move_alloc(files(j)%text, grown(j)%text)
                call move_alloc(files(j)%title, grown(j)%title)
                grown(j)%owner = files(j)%owner
                grown(j)%list_page = files(j)%list_page
            end do
            call move_alloc(grown, files)
        end if
        count_files = count_files + 1
        files(count_files)%text = description
        files(count_files)%title = title
        files(count_files)%owner = owner
        files(count_files)%list_page = page
    end subroutine add_file

end subroutine build_graphs

!> The value of attribute `name` in `line`, or `''`.
pure subroutine attribute(line, name, value)
    character(len=*), intent(in) :: line                !! the element
    character(len=*), intent(in) :: name                !! the attribute
    character(len=:), allocatable, intent(out) :: value !! its value
    integer :: at, close

    value = ''
    at = index(line, ' '//name//'="')
    if (at == 0) return
    at = at + len(name) + 3
    close = index(line(at:), '"')
    if (close > 0) value = line(at:at + close - 2)
end subroutine attribute

!> Append `text` with its numbers rounded to one decimal.
pure subroutine rounded(text, b)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: b      !! where it goes
    integer :: i, j, k, start, tenths

    i = 1
    start = 1
    do while (i <= len(text))
        if (.not. is_digit(text(i:i))) then
            i = i + 1
            cycle
        end if
        j = end_of_digits(text, i)
        if (j >= len(text)) then
            i = j
            cycle
        else if (text(j:j) /= '.') then
            i = j
            cycle
        end if
        k = end_of_digits(text, j + 1)
        if (i > start) call add(b, text(start:i - 1))
        call number_value(text(i:j - 1), tenths)
        tenths = tenths*10
        if (k > j + 1) tenths = tenths + iachar(text(j + 1:j + 1)) - iachar('0')
        if (k > j + 2) then
            if (text(j + 2:j + 2) >= '5') tenths = tenths + 1
        end if
        call add_integer(tenths/10, b)
        if (mod(tenths, 10) /= 0) then
            call add(b, '.')
            call add(b, achar(iachar('0') + mod(tenths, 10)))
        end if
        i = k
        start = k
    end do
    if (start <= len(text)) call add(b, text(start:))
end subroutine rounded

!> Whether `c` is a digit.
elemental logical function is_digit(c)
    character, intent(in) :: c  !! the character
    is_digit = c >= '0' .and. c <= '9'
end function is_digit

!> Where the digits of `text` starting at `from` end: the position after the last one.
pure integer function end_of_digits(text, from)
    character(len=*), intent(in) :: text    !! the text
    integer, intent(in) :: from             !! where to start
    integer :: k

    k = from
    do while (k <= len(text))
        if (.not. is_digit(text(k:k))) exit
        k = k + 1
    end do
    end_of_digits = k
end function end_of_digits

!> Append `value`, which is not negative.
pure subroutine add_integer(value, b)
    integer, intent(in) :: value            !! the value
    type(buffer_t), intent(inout) :: b      !! where it goes
    character(len=11) :: digits
    integer :: at, rest

    at = len(digits) + 1
    rest = value
    do
        at = at - 1
        digits(at:at) = achar(iachar('0') + mod(rest, 10))
        rest = rest/10
        if (rest == 0) exit
    end do
    call add(b, digits(at:))
end subroutine add_integer

!> The value of the digits `digits`.
pure subroutine number_value(digits, value)
    character(len=*), intent(in) :: digits  !! the digits
    integer, intent(out) :: value           !! their value
    integer :: k

    value = 0
    do k = 1, len(digits)
        value = 10*value + iachar(digits(k:k)) - iachar('0')
    end do
end subroutine number_value

!> The extent of the points in path data `d`.
subroutine path_box(d, left, top, right, bottom)
    character(len=*), intent(in) :: d   !! the path data
    real, intent(out) :: left           !! the smallest x
    real, intent(out) :: top            !! the smallest y
    real, intent(out) :: right          !! the largest x
    real, intent(out) :: bottom         !! the largest y
    character(len=*), parameter :: DIGITS = '0123456789.-'
    real :: value
    logical :: is_x
    integer :: i, j

    left = huge(left)
    top = huge(top)
    right = -huge(right)
    bottom = -huge(bottom)
    is_x = .true.
    i = 1
    do while (i <= len(d))
        if (scan(d(i:i), DIGITS) == 0) then
            i = i + 1
            cycle
        end if
        j = i
        do while (j < len(d))
            if (scan(d(j + 1:j + 1), DIGITS) == 0) exit
            j = j + 1
        end do
        call parse_real(d(i:j), value)
        if (is_x) then
            left = min(left, value)
            right = max(right, value)
        else
            top = min(top, value)
            bottom = max(bottom, value)
        end if
        is_x = .not. is_x
        i = j + 1
    end do
end subroutine path_box

!> The value of `text`, a decimal number. Internal `read` and `write` statements are avoided here, as
!> they take a lock that threads end up spending most of their time on.
pure subroutine parse_real(text, value)
    character(len=*), intent(in) :: text    !! the number
    real, intent(out) :: value              !! its value
    real(real64) :: digits, scale
    logical :: negative, fraction
    integer :: k

    digits = 0
    scale = 1
    negative = .false.
    fraction = .false.
    do k = 1, len(text)
        select case (text(k:k))
        case ('-')
            negative = .true.
        case ('.')
            fraction = .true.
        case default
            digits = 10*digits + (iachar(text(k:k)) - iachar('0'))
            if (fraction) scale = 10*scale
        end select
    end do
    value = real(digits/scale)
    if (negative) value = -value
end subroutine parse_real

!> Write a real with one decimal, rounded like the format `f0.1`: a tie goes to the even digit.
pure subroutine real_text(value, b)
    real, intent(in) :: value           !! the value
    type(buffer_t), intent(inout) :: b  !! where it goes
    real(real64) :: exact, rest
    integer :: tenths

    exact = 10*abs(real(value, real64))
    tenths = floor(exact)
    rest = exact - tenths
    if (rest > 0.5_real64) then
        tenths = tenths + 1
    else if (rest == 0.5_real64 .and. mod(tenths, 2) == 1) then
        tenths = tenths + 1
    end if
    if (value < 0) call add(b, '-')
    call add_integer(tenths/10, b)
    call add(b, '.')
    call add(b, achar(iachar('0') + mod(tenths, 10)))
end subroutine real_text

!> Rewrite a drawing from `dot` to draw the same thing in fewer bytes: the boxes of nodes become
!> rectangles, what most elements share goes on the group around them, and comments, ids and titles
!> that nothing shows are left out. Coordinates keep one decimal, a tenth of a point.
subroutine slim_svg(svg, out)
    character(len=*), intent(in) :: svg                 !! the drawing
    character(len=:), allocatable, intent(out) :: out   !! the result
    type(string_t), allocatable :: lines(:)
    character(len=:), allocatable :: fill, stroke, width, dash, data, x, y, size, href
    type(buffer_t) :: b
    logical :: dropped(0:16), in_link
    real :: left, top, right, bottom
    integer :: k, depth, at

    allocate (character(len=len(svg)) :: b%s)
    lines = split_lines(svg)
    depth = 0
    dropped = .false.
    in_link = .false.
    do k = 1, size_of(lines)
        associate (line => lines(k)%s)
            if (starts_with(line, '<!--') .or. starts_with(line, '<title>')) then
                cycle
            else if (starts_with(line, '<g id="node') .or. starts_with(line, '<g id="edge')) then
                depth = min(depth + 1, 16)
                dropped(depth) = .true.
            else if (starts_with(line, '<g id="a_')) then
                depth = min(depth + 1, 16)
                dropped(depth) = .true.
                call attribute(line, 'xlink:href', href)
                if (len(href) > 0) then
                    call add(b, '<a href="'//href//'" fill="white" stroke="none">')
                    in_link = .true.
                else
                    call add(b, '<a>')
                end if
            else if (starts_with(line, '<g ')) then
                depth = min(depth + 1, 16)
                dropped(depth) = .false.
                at = index(line, 'transform=')
                call add(b, '<g '//line(at:len(line) - 1)//' fill="none" stroke="'//EDGE_COLOUR// &
                         '" font-family="Helvetica,sans-Serif" font-size="'//FONT_SIZE//'" text-anchor="middle">')
            else if (line == '</g>') then
                if (.not. dropped(depth)) call add(b, line)
                depth = max(depth - 1, 0)
            else if (line == '</a>') then
                in_link = .false.
                call add(b, line)
            else if (starts_with(line, '<path ')) then
                call attribute(line, 'fill', fill)
                call attribute(line, 'stroke', stroke)
                call attribute(line, 'stroke-width', width)
                call attribute(line, 'stroke-dasharray', dash)
                call attribute(line, 'd', data)
                if (fill /= 'none') then
                    call path_box(data, left, top, right, bottom)
                    call add(b, '<rect fill="'//fill//'"')
                    if (stroke /= 'none' .or. .not. in_link) call add(b, ' stroke="'//stroke//'"')
                    if (len(width) > 0) call add(b, ' stroke-width="'//width//'"')
                    call add(b, ' rx="7.2" x="')
                    call real_text(left, b)
                    call add(b, '" y="')
                    call real_text(top, b)
                    call add(b, '" width="')
                    call real_text(right - left, b)
                    call add(b, '" height="')
                    call real_text(bottom - top, b)
                    call add(b, '"/>')
                else
                    call add(b, '<path')
                    if (stroke /= EDGE_COLOUR) call add(b, ' stroke="'//stroke//'"')
                    if (len(width) > 0) call add(b, ' stroke-width="'//width//'"')
                    if (len(dash) > 0) call add(b, ' stroke-dasharray="'//dash//'"')
                    call add(b, ' d="')
                    call rounded(data, b)
                    call add(b, '"/>')
                end if
            else if (starts_with(line, '<polygon ')) then
                call attribute(line, 'fill', fill)
                call attribute(line, 'stroke', stroke)
                if (fill == 'none' .and. stroke == 'none') cycle
                call attribute(line, 'points', data)
                call add(b, '<polygon fill="'//fill//'"')
                if (stroke /= EDGE_COLOUR) call add(b, ' stroke="'//stroke//'"')
                call add(b, ' points="')
                call rounded(data, b)
                call add(b, '"/>')
            else if (starts_with(line, '<text ')) then
                call attribute(line, 'x', x)
                call attribute(line, 'y', y)
                call attribute(line, 'font-size', size)
                call attribute(line, 'fill', fill)
                call add(b, '<text x="')
                call rounded(x, b)
                call add(b, '" y="')
                call rounded(y, b)
                call add(b, '"')
                if (size /= FONT_SIZE//'.00') call add(b, ' font-size="'//size//'"')
                if (fill /= 'white' .or. .not. in_link) call add(b, ' fill="'//fill//'"')
                call add(b, line(index(line, '>'):))
            else
                call add(b, line)
                if (k < 3) call add(b, achar(10))
            end if
        end associate
    end do
    call take(b, out)
end subroutine slim_svg

!> The number of strings in `lines`.
pure integer function size_of(lines)
    type(string_t), intent(in) :: lines(:)  !! the strings
    size_of = size(lines)
end function size_of

!> The file of graph `k`.
pure function file_name(directory, k, suffix) result(path)
    character(len=*), intent(in) :: directory   !! the directory
    integer, intent(in) :: k                    !! the graph
    character(len=*), intent(in) :: suffix      !! what follows `.gv`
    character(len=len(directory) + 18 + len(suffix)) :: path

    path = directory//'/g'//number(k)//'.gv'//suffix
    path = pack_blanks(path)
end function file_name

!> `text` without the blanks after a number, which are all that follow `/g`.
pure function pack_blanks(text) result(out)
    character(len=*), intent(in) :: text    !! the text
    character(len=len(text)) :: out
    integer :: at, stop_at

    at = index(text, '/g', back=.true.)
    stop_at = at + 1 + index(text(at + 2:), ' ')
    out = text(:stop_at - 1)//adjustl(text(stop_at:))
end function pack_blanks

!> Read the drawings of `graphs` from `directory`, and slim them. The directory is an argument with a
!> plain length because a deferred-length string does not work when it is shared with a parallel region.
subroutine load_graphs(directory, graphs, found, threads)
    character(len=*), intent(in) :: directory       !! the directory
    type(graph_t), intent(inout) :: graphs(:)       !! the graphs
    logical, intent(out) :: found(:)                !! whether each one has a drawing
    integer, intent(in) :: threads                  !! how many threads to use
    integer :: k

    call progress_start('Slimming graphs', size(graphs))
    !$omp parallel do schedule(dynamic) num_threads(threads) default(shared) private(k)
    do k = 1, size(graphs)
        call load_graph(trim(file_name(directory, k, '.svg')), graphs(k)%svg, found(k))
        call progress_tick()
    end do
    !$omp end parallel do
    call progress_finish()
end subroutine load_graphs

!> Read and slim the drawing in file `path`.
subroutine load_graph(path, svg, found)
    character(len=*), intent(in) :: path                !! the file
    character(len=:), allocatable, intent(out) :: svg   !! the slimmed drawing
    logical, intent(out) :: found                       !! whether the file could be read
    character(len=:), allocatable :: text, errmsg
    integer :: at, status

    svg = ''
    !$omp critical (file_io)
    call read_file(path, text, status, errmsg)
    !$omp end critical (file_io)
    found = status == 0
    if (.not. found) return
    at = index(text, '<svg')
    if (at > 0) call slim_svg(text(at:), svg)
end subroutine load_graph

!> Lay out `n` graphs, in batches, running up to `threads` processes at once. This uses a single
!> thread, as `execute_command_line` runs only one waiting command at a time on some systems. The
!> commands are started without waiting, and each writes a file in `directory` when it ends. Where
!> commands cannot be started without waiting, as on Windows, they run in turn with the same result.
!> A batch whose first graph has gone counts as ended, as another run has replaced the directory.
subroutine run_batches(directory, tag, n, threads)
    character(len=*), intent(in) :: directory   !! the directory
    character(len=*), intent(in) :: tag         !! what makes the names of this run's files unique
    integer, intent(in) :: n                    !! how many graphs there are
    integer, intent(in) :: threads              !! how many processes to run at once
    integer :: b, batches, started, finished, active
    integer(c_int) :: status
    logical :: ended, present
    logical, allocatable :: running(:)

    batches = (n + BATCH - 1)/BATCH
    allocate (running(batches), source=.false.)
    started = 0
    finished = 0
    active = 0
    call progress_start('Laying out graphs', n)
    do while (finished < batches)
        do while (started < batches .and. active < threads)
            started = started + 1
            running(started) = .true.
            active = active + 1
            call remove_file(trim(batch_file(directory, tag, started, 'done')))
            call start_dot(directory, tag, started, n)
        end do
        do b = 1, started
            if (.not. running(b)) cycle
            inquire (file=trim(batch_file(directory, tag, b, 'done')), exist=ended)
            inquire (file=trim(file_name(directory, (b - 1)*BATCH + 1, '')), exist=present)
            if (present .and. .not. ended) cycle
            running(b) = .false.
            active = active - 1
            finished = finished + 1
            call remove_file(trim(batch_file(directory, tag, b, 'done')))
            call remove_file(trim(batch_file(directory, tag, b, 'err')))
            call progress_tick(min(n, b*BATCH) - (b - 1)*BATCH)
        end do
        status = c_usleep(POLL_MICROSECONDS)
    end do
    call progress_finish()
end subroutine run_batches

!> Start batch `which` of `n` graphs. The command works in both `sh` and `cmd.exe`, and ends by
!> writing its file whether or not `dot` succeeds.
subroutine start_dot(directory, tag, which, n)
    character(len=*), intent(in) :: directory   !! the directory
    character(len=*), intent(in) :: tag         !! what makes the names of this run's files unique
    integer, intent(in) :: which                !! the batch
    integer, intent(in) :: n                    !! how many graphs there are
    type(buffer_t) :: b
    character(len=:), allocatable :: command
    character(len=:), allocatable :: done, errmsg
    integer :: k, status

    done = trim(batch_file(directory, tag, which, 'done'))
    call add(b, 'dot -Tsvg -O')
    do k = (which - 1)*BATCH + 1, min(n, which*BATCH)
        call add(b, ' "'//trim(file_name(directory, k, ''))//'"')
    end do
    call add(b, ' 2> "'//trim(batch_file(directory, tag, which, 'err'))//'" && echo ok> "'//done)
    call add(b, '" || echo failed> "'//done//'"')
    call take(b, command)
    call execute_command_line(command, wait=.false., cmdstat=status)
    if (status > 0) call write_file(done, 'failed', status, errmsg)
end subroutine start_dot

!> The file of batch `which` with extension `suffix`.
pure function batch_file(directory, tag, which, suffix) result(path)
    character(len=*), intent(in) :: directory   !! the directory
    character(len=*), intent(in) :: tag         !! what makes the names of this run's files unique
    integer, intent(in) :: which                !! the batch
    character(len=*), intent(in) :: suffix      !! the extension
    character(len=len(directory) + len(tag) + 16 + len(suffix)) :: path

    path = directory//'/b'//trim(adjustl(number(which)))//'-'//tag//'.'//suffix
end function batch_file

!> Delete a file, if it can be.
subroutine remove_file(path)
    character(len=*), intent(in) :: path    !! the file
    integer :: unit, status

    open (newunit=unit, file=path, status='old', iostat=status)
    if (status == 0) close (unit, status='delete', iostat=status)
end subroutine remove_file

end module fdoc_graphs
