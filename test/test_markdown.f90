module test_markdown
!! Markdown. The real check is `pixi run compare markdown`, against FORD; these pin down the cases where
!! fdoc is meant to differ from it, and the features that documentation in the corpus does not use.
use testdrive, only: new_unittest, unittest_type, error_type, check
use fdoc_markdown, only: markdown_to_html, markdown_options_t
use fdoc_settings, only: map_entry_t
implicit none
private

public :: collect_markdown

character, parameter :: NL = achar(10)

contains

!> The tests of this module.
subroutine collect_markdown(testsuite)
    type(unittest_type), allocatable, intent(out) :: testsuite(:)   !! the tests
    testsuite = [ &
                new_unittest("a less-than sign keeps the text after it", test_less_than), &
                new_unittest("lists, tight and loose", test_lists), &
                new_unittest("emphasis", test_emphasis), &
                new_unittest("aliases", test_aliases), &
                new_unittest("admonitions", test_admonitions), &
                new_unittest("fenced code", test_fenced), &
                new_unittest("tables", test_tables), &
                new_unittest("footnotes", test_footnotes), &
                new_unittest("math", test_math), &
                new_unittest("table of contents", test_toc), &
                new_unittest("typographic punctuation", test_smarty) &
                ]
end subroutine collect_markdown

!> Check that `source` converts to `expected`.
subroutine expect(error, source, expected, options)
    type(error_type), allocatable, intent(out) :: error         !! the failure, if any
    character(len=*), intent(in) :: source                      !! the Markdown
    character(len=*), intent(in) :: expected                    !! the HTML
    type(markdown_options_t), intent(in), optional :: options   !! the options
    type(markdown_options_t) :: defaults
    character(len=:), allocatable :: html

    if (present(options)) then
        call markdown_to_html(source, options, html)
    else
        call markdown_to_html(source, defaults, html)
    end if
    call check(error, html, expected)
end subroutine expect

!> Checks: a less-than sign keeps the text after it.
subroutine test_less_than(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call expect(error, 'ensure f(a)<f(b) holds', '<p>ensure f(a)&lt;f(b) holds</p>')
end subroutine test_less_than

!> Checks: lists, tight and loose.
subroutine test_lists(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call expect(error, '* a'//NL//'* b', '<ul>'//NL//'<li>a</li>'//NL//'<li>b</li>'//NL//'</ul>')
    if (allocated(error)) return
    call expect(error, '1. a'//NL//NL//'2. b', '<ol>'//NL//'<li>'//NL//'<p>a</p>'//NL//'</li>'//NL// &
                '<li>'//NL//'<p>b</p>'//NL//'</li>'//NL//'</ol>')
end subroutine test_lists

!> Checks: emphasis.
subroutine test_emphasis(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call expect(error, '**a** *b* snake_case_name a * b * c D*f = g * h', &
                '<p><strong>a</strong> <em>b</em> snake_case_name a * b * c D*f = g * h</p>')
    if (allocated(error)) return
    call expect(error, '**`x`**', '<p><strong><code>x</code></strong></p>')
end subroutine test_emphasis

!> Checks: aliases.
subroutine test_aliases(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(markdown_options_t) :: options
    options%aliases = [map_entry_t('url', 'U')]
    call expect(error, '|url| \|url| |other|', '<p>U |url| |other|</p>', options)
end subroutine test_aliases

!> Checks: admonitions.
subroutine test_admonitions(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call expect(error, '@warning careful'//NL//'more'//NL//'@endwarning', &
                '<div class="alert alert-warning">'//NL//'<p class="alert-title h4">Warning</p>'//NL// &
                '<p>careful'//NL//'more</p>'//NL//'</div>')
end subroutine test_admonitions

!> Checks: fenced code.
subroutine test_fenced(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call expect(error, '```fortran'//NL//'a < b'//NL//'```', &
                '<div class="codehilite"><pre><code class="language-fortran">a &lt; b'//NL//'</code></pre></div>')
    if (allocated(error)) return
    call expect(error, '```mermaid'//NL//'graph LR'//NL//'a --> b'//NL//'```', &
                '<pre class="mermaid">graph LR'//NL//'a --&gt; b'//NL//'</pre>')
    if (allocated(error)) return
    call expect(error, '```json'//NL//'{"a": "b:c", "n": -1.5e3, "t": true, "z": null}'//NL//'```', &
                '<div class="codehilite"><pre><code class="language-json">{<span class="k">"a"</span>: '// &
                '<span class="s">"b:c"</span>, <span class="k">"n"</span>: '// &
                '<span class="n">-1.5e3</span>, <span class="k">"t"</span>: <span class="n">true</span>, '// &
                '<span class="k">"z"</span>: <span class="n">null</span>}'//NL//'</code></pre></div>')
    if (allocated(error)) return
    call expect(error, '```toml'//NL//'[extra.fdoc] # here'//NL//'graph = true'//NL//'src_dir = ["./src"]'//NL// &
                'a.b = 2024-01-01'//NL//'x = { y = 1 }'//NL//'```', &
                '<div class="codehilite"><pre><code class="language-toml"><span class="p">[extra.fdoc]</span> '// &
                '<span class="c"># here</span>'//NL//'<span class="k">graph</span> = <span class="n">true</span>'//NL// &
                '<span class="k">src_dir</span> = [<span class="s">"./src"</span>]'//NL// &
                '<span class="k">a.b</span> = <span class="n">2024-01-01</span>'//NL// &
                '<span class="k">x</span> = { <span class="k">y</span> = <span class="n">1</span> }'//NL// &
                '</code></pre></div>')
end subroutine test_fenced

!> Checks: tables.
subroutine test_tables(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call expect(error, 'a|b'//NL//':-|-:'//NL//'1|2', &
                '<table>'//NL//'<thead>'//NL//'<tr>'//NL//'<th style="text-align: left;">a</th>'//NL// &
                '<th style="text-align: right;">b</th>'//NL//'</tr>'//NL//'</thead>'//NL//'<tbody>'//NL//'<tr>'//NL// &
                '<td style="text-align: left;">1</td>'//NL//'<td style="text-align: right;">2</td>'//NL//'</tr>'//NL// &
                '</tbody>'//NL//'</table>')
end subroutine test_tables

!> Checks: footnotes.
subroutine test_footnotes(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    character(len=:), allocatable :: html
    type(markdown_options_t) :: options
    call markdown_to_html('x[^n]'//NL//NL//'[^n]: note', options, html)
    call check(error, index(html, 'href="#fn:n"') > 0 .and. index(html, '<li id="fn:n">') > 0)
end subroutine test_footnotes

!> Checks: math.
subroutine test_math(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    call expect(error, 'a \(x_1*y*z\) b', '<p>a <script type="math/tex">x_1*y*z</script> b</p>')
end subroutine test_math

!> Checks: table of contents.
subroutine test_toc(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(markdown_options_t) :: options
    options%toc = .true.
    call expect(error, '[TOC]'//NL//NL//'# One Two', '<div class="toc">'//NL//'<ul>'//NL// &
                '<li><a href="#one-two">One Two</a></li>'//NL//'</ul>'//NL//'</div>'//NL// &
                '<h1 id="one-two">One Two</h1>', options)
    if (allocated(error)) return
    call expect(error, '# `and` - bitwise', '<h1 id="and-bitwise"><code>and</code> - bitwise</h1>', options)
    if (allocated(error)) return
    call expect(error, '# C++ & co!', '<h1 id="c-co">C++ &amp; co!</h1>', options)
    if (allocated(error)) return
    call expect(error, '# a  --  b', '<h1 id="a-b">a  --  b</h1>', options)
    if (allocated(error)) return
    call expect(error, '# x_y - Z', '<h1 id="x_y-z">x_y - Z</h1>', options)
end subroutine test_toc

!> Checks: typographic punctuation.
subroutine test_smarty(error)
    type(error_type), allocatable, intent(out) :: error  !! the failure, if any
    type(markdown_options_t) :: options
    options%smarty = .true.
    call expect(error, 'a -- b --- c...', '<p>a &ndash; b &mdash; c&hellip;</p>', options)
end subroutine test_smarty

end module test_markdown
