module fdoc_graphs
!! Dependency graphs: which modules use which, what procedures call, how types extend each other and
!! how files depend on each other. Graphs are written in Graphviz's language, laid out by [[fdoc_dot]]
!! and made smaller by [[fdoc_svg]].
use iso_fortran_env, only: int64
use fdoc_util
use fdoc_buffer
use fdoc_model
use fdoc_settings, only: settings_t
use fdoc_project, only: project_t
use fdoc_urls, only: entity_url
use fdoc_progress, only: progress_start, progress_tick, progress_finish, warn
use fdoc_shell, only: make_directory, remove_directory, program_exists
use fdoc_svg, only: slim_svg, FONT_SIZE, EDGE_COLOUR
use fdoc_dot, only: run_batches, file_name
implicit none
private

public :: graph_set_t, build_graphs

integer, parameter, public :: REL_USES = 1       !! modules used
integer, parameter, public :: REL_CALLS = 2      !! procedures called
integer, parameter, public :: REL_INHERITS = 3   !! types extended
integer, parameter, public :: REL_FILES = 4      !! files depended on
integer, parameter :: NUM_RELATIONS = 4

character(len=*), parameter :: LABEL_FONT_SIZE = '11'   !! points, of the labels of edges
character(len=*), parameter :: EDGE_COLOURS(*) = [character(len=7) :: '#3657c9', '#1d7a55', '#a15c00', '#b3261e', &
                                                  '#6a4fb3', '#0b7285', '#a61e69', '#5c6f2d']

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
            at = last_separator(name)
            name = name(at + 1:)
        end if
        if (e%kind == E_BOUNDPROC) name = p%list%box(e%parent)%e%name//'%'//name
        if (e%bound_to > 0) name = p%list%box(e%bound_to)%e%name//'%'//name
        url = ''
        if (e%visible .or. allocated(e%external_url)) call entity_url(p%list, id, url)
        if (.not. e%visible .and. .not. allocated(e%external_url)) colour = '#8a93a5'
        if (allocated(e%external_url)) colour = '#646d7e'
        call add(b, 'n'//trim(int_text(id))//' [label="')
        call dot_escaped(name, b)
        call add(b, '", fillcolor="'//colour//'"')
        if (root) call add(b, ', penwidth=2, color="#f0a868"')
        if (len(url) > 0) then
            call add(b, ', URL="')
            if (.not. allocated(e%external_url)) call add(b, '../')
            call dot_escaped(url, b)
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

    call add(b, 'n'//trim(int_text(from))//' -> n'//trim(int_text(to))//' [')
    if (s%coloured_edges) call add(b, 'color="'//EDGE_COLOURS(mod(from, size(EDGE_COLOURS)) + 1)//'", ')
    do k = 1, size(relation%out(from)%ids)
        if (relation%out(from)%ids(k) /= to) cycle
        if (len(relation%labels(from)%text(k)%s) == 0) exit
        call add(b, 'style=dashed, fontname="Helvetica", fontsize='//LABEL_FONT_SIZE//', fontcolor="#8a93a5", label="')
        call dot_escaped(relation%labels(from)%text(k)%s, b)
        call add(b, '"')
        exit
    end do
    call add(b, '];'//achar(10))
end subroutine add_edge

!> Append `text` for use inside a quoted string of `dot`.
pure subroutine dot_escaped(text, b)
    character(len=*), intent(in) :: text    !! the text
    type(buffer_t), intent(inout) :: b      !! the description
    integer :: k

    do k = 1, len(text)
        if (text(k:k) == '"' .or. text(k:k) == '\') call add(b, '\')
        call add(b, text(k:k))
    end do
end subroutine dot_escaped

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
    character(len=:), allocatable :: directory
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
    ! a directory of this run's own, as the names of the files inside are the same in every run
    directory = s%output_dir//'/.graphs-'//trim(tag)
    if (allocated(s%graph_dir)) directory = s%graph_dir//'/'//trim(tag)
    call make_directory(directory, status)
    do k = 1, n
        call write_whole_file(trim(file_name(directory, k, '')), files(k)%text, stat, errmsg)
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
            call warn(title//' left out: it would have more than '//trim(int_text(s%graph_project_maxnodes))// &
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
    call read_whole_file(path, text, status, errmsg)
    found = status == 0
    if (.not. found) return
    at = index(text, '<svg')
    if (at > 0) call slim_svg(text(at:), svg)
end subroutine load_graph

end module fdoc_graphs
