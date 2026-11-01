module fdoc_assets
!! The style sheet and script of the site. Generated from `assets/` by `tools/gen_assets.py`.
use fdoc_buffer, only: buffer_t, add
implicit none
private

public :: asset_fdoc_css, asset_fdoc_js

character, parameter :: NL = achar(10)

contains

!> The contents of `assets/fdoc.css`.
subroutine asset_fdoc_css(b)
    type(buffer_t), intent(inout) :: b  !! where they go
    call add(b, &
        ':root {'//NL//'  --bg: #ffffff; --bg-soft: #f6f7f9; --bg-code: #f6f7f9; --line: #e3e6eb; --text: #1f2430; --m' &
        //'uted: #646d7e;'//NL//'  --accent: #3657c9; --accent-soft: #e9eefb; --ok: #1d7a55; --warn: #a15c00; --bad: #b3' &
        //'261e; --hist: #6a4fb3;'//NL//'  --attr-l: 34%;'//NL//'  --k: #7b30b5; --s: #1b7f3b; --c: #7a8290; --d: #2f7a8' &
        //'c; --n: #b4530a; --p: #a15c00;'//NL//'  --mono: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;'//NL &
        //'  --sans: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;'//NL//'}'//NL//':' &
        //'root[data-theme="dark"] {'//NL//'  --bg: #14171d; --bg-soft: #1b1f27; --bg-code: #1b1f27; --line: #2c323d; --' &
        //'text: #e4e7ec; --muted: #9aa3b2;'//NL//'  --accent: #8ba7ff; --accent-soft: #232c45; --ok: #5fcf9f; --warn: #' &
        //'e3ab5c; --bad: #f28b82; --hist: #b9a4f2;'//NL//'  --attr-l: 72%;'//NL//'  --k: #c792ea; --s: #8fd18f; --c: #7' &
        //'f8796; --d: #7fc4d4; --n: #f0a868; --p: #e3ab5c;'//NL//'}'//NL//'@media (prefers-color-scheme: dark) {'//NL//' ' &
        //' :root:not([data-theme="light"]) {'//NL//'    --bg: #14171d; --bg-soft: #1b1f27; --bg-code: #1b1f27; --line: ' &
        //'#2c323d; --text: #e4e7ec; --muted: #9aa3b2;'//NL//'    --accent: #8ba7ff; --accent-soft: #232c45; --ok: #5fcf' &
        //'9f; --warn: #e3ab5c; --bad: #f28b82; --hist: #b9a4f2;'//NL//'    --attr-l: 72%;'//NL//'    --k: #c792ea; --s:' &
        //' #8fd18f; --c: #7f8796; --d: #7fc4d4; --n: #f0a868; --p: #e3ab5c;'//NL//'  }'//NL//'}'//NL//'* { box-sizing: ' &
        //'border-box; }'//NL//'html { scroll-padding-top: 4.5rem; }'//NL//'body { margin: 0; background: var(--bg); col' &
        //'or: var(--text); font: 16px/1.6 var(--sans); }'//NL//'a { color: var(--accent); text-decoration: none; }'//NL &
        //'a:hover { text-decoration: underline; }'//NL//'header.top {'//NL//'  position: sticky; top: 0; z-index: 10; d' &
        //'isplay: flex; align-items: center; gap: 1.25rem; height: 3.5rem;'//NL//'  padding: 0 1.25rem; background: var' &
        //'(--bg); border-bottom: 1px solid var(--line);'//NL//'}'//NL//'header.top .brand { font-weight: 650; color: va' &
        //'r(--text); white-space: nowrap; }'//NL//'header.top .brand small { color: var(--muted); font-weight: 400; mar' &
        //'gin-left: .35rem; }'//NL//'header.top nav { display: flex; gap: 1rem; overflow-x: auto; flex: 1; }'//NL//'hea' &
        //'der.top nav a { color: var(--muted); white-space: nowrap; font-size: .92rem; }'//NL//'header.top nav a:hover,' &
        //' header.top nav a.here { color: var(--text); text-decoration: none; }'//NL//'.theme { background: none; borde' &
        //'r: 1px solid var(--line); border-radius: 6px; color: var(--muted); cursor: pointer;'//NL//'  width: 2rem; hei' &
        //'ght: 2rem; font-size: 1rem; line-height: 1; }'//NL//'.layout { display: grid; grid-template-columns: 17rem mi' &
        //'nmax(0, 1fr); max-width: 90rem; margin: 0 auto; }'//NL//'aside.side { position: sticky; top: 3.5rem; align-se' &
        //'lf: start; height: calc(100vh - 3.5rem); overflow-y: auto;'//NL//'  padding: 1.25rem 1rem 2rem 1.25rem; borde' &
        //'r-right: 1px solid var(--line); font-size: .9rem; }'//NL//'aside.side h4 { margin: 1.1rem 0 .3rem; color: var' &
        //'(--muted); font-size: .72rem; letter-spacing: .06em;'//NL//'  text-transform: uppercase; font-weight: 650; }'//NL &
        //'aside.side h4:first-child { margin-top: 0; }'//NL//'aside.side ul { list-style: none; margin: 0; padding: 0; ' &
        //'}'//NL//'aside.side li a { display: block; padding: .12rem .5rem; margin-left: -.5rem; border-radius: 5px; co' &
        //'lor: var(--text);'//NL//'  overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }'//NL//'aside.sid' &
        //'e li a:hover { background: var(--bg-soft); text-decoration: none; }'//NL//'aside.side li a.more { color: var(' &
        //'--muted); }'//NL//'main { padding: 2rem 2.5rem 4rem; min-width: 0; }'//NL//'main > .inner { max-width: 54rem;' &
        //' }'//NL//'h1, h2, h3, h4 { line-height: 1.25; font-weight: 650; }'//NL//'h1 { font-size: 1.9rem; margin: 0 0 ' &
        //'.4rem; }'//NL//'h2 { font-size: 1.3rem; margin: 2.4rem 0 .8rem; padding-bottom: .3rem; border-bottom: 1px sol' &
        //'id var(--line); }'//NL//'.doc h1 { font-size: 1.5rem; margin-top: 1.6rem; }'//NL//'.doc h2 { font-size: 1.25r' &
        //'em; }'//NL//'.doc h3 { font-size: 1.05rem; margin-top: 1.4rem; }'//NL//'.crumbs { color: var(--muted); font-s' &
        //'ize: .88rem; margin-bottom: .3rem; }'//NL//'.crumbs .sep { margin: 0 .15rem; }'//NL//'.kind { color: var(--mu' &
        //'ted); font-weight: 400; font-size: .62em; margin-right: .35rem; }'//NL//'.meta { display: flex; flex-wrap: wr' &
        //'ap; gap: .3rem 1rem; color: var(--muted); font-size: .88rem; margin: .4rem 0 1.1rem; }'//NL//'.lead { font-si' &
        //'ze: 1.05rem; color: var(--muted); margin: .1rem 0 .4rem; }'//NL//'.lead p { margin: 0; }'//NL//'code, pre, .s' &
        //'ig { font-family: var(--mono); font-size: .875em; }'//NL//':not(pre) > code { background: var(--bg-code); pad' &
        //'ding: .1em .3em; border-radius: 4px; }'//NL//'pre, .sig { background: var(--bg-code); border: 1px solid var(-' &
        //'-line); border-radius: 8px; padding: .7rem .9rem;'//NL//'  overflow-x: auto; line-height: 1.5; }'//NL//'.code' &
        //'hilite { position: relative; margin: 1rem 0; }'//NL//'.codehilite pre { margin: 0; }'//NL//'.copy { position:' &
        //' absolute; top: .4rem; right: .4rem; opacity: 0; background: var(--bg); color: var(--muted);'//NL//'  border:' &
        //' 1px solid var(--line); border-radius: 5px; font-size: .72rem; padding: .1rem .4rem; cursor: pointer; }'//NL//'.' &
        //'codehilite:hover .copy { opacity: 1; }'//NL//'.sig { margin: .4rem 0 .7rem; white-space: pre-wrap; overflow-w' &
        //'rap: anywhere; }'//NL//'.k { color: var(--k); } .s { color: var(--s); } .c { color: var(--c); font-style: ita' &
        //'lic; }'//NL//'.d { color: var(--d); } .n { color: var(--n); } .p { color: var(--p); }'//NL//'.item { padding:' &
        //' .9rem 0 1rem; border-top: 1px solid var(--line); }'//NL//'h2 + .item { border-top: 0; padding-top: 0; }'//NL &
        //'.item > h3 { margin: 0 0 .2rem; font-size: 1rem; font-family: var(--mono); overflow-wrap: anywhere; }'//NL//'.' &
        //'badge { display: inline-block; font: 600 .68rem/1.5 var(--sans); padding: 0 .4rem; margin-left: .4rem; border' &
        //'-radius: 4px;'//NL//'  background: var(--bg-soft); color: var(--muted); border: 1px solid var(--line); vertic' &
        //'al-align: middle; }'//NL//'table { border-collapse: collapse; width: 100%; font-size: .92rem; margin: .7rem 0' &
        //' 1rem; }'//NL//'th { text-align: left; font-weight: 600; color: var(--muted); }'//NL//'th, td { padding: .35r' &
        //'em .7rem .35rem 0; border-bottom: 1px solid var(--line); vertical-align: top; }'//NL//'td p { margin: 0; } td' &
        //'.type { font-family: var(--mono); font-size: .84em; width: 30%; overflow-wrap: break-word; }'//NL//'td.name {' &
        //' font-family: var(--mono); font-size: .88em; width: 24%; overflow-wrap: break-word; }'//NL//'.doc table { dis' &
        //'play: block; overflow-x: auto; }'//NL//'.alert { border-left: 3px solid var(--accent); background: var(--bg-s' &
        //'oft); border-radius: 0 6px 6px 0;'//NL//'  padding: .55rem .9rem; margin: 1rem 0; }'//NL//'.alert p { margin:' &
        //' .3rem 0; } .alert-title { font-weight: 650; font-size: .9rem; }'//NL//'.alert-warning { border-color: var(--' &
        //'warn); } .alert-success { border-color: var(--ok); }'//NL//'.alert-danger { border-color: var(--bad); } .aler' &
        //'t-history { border-color: var(--hist); }'//NL//'blockquote { margin: 1rem 0; padding: 0 1rem; color: var(--mu' &
        //'ted); border-left: 3px solid var(--line); }'//NL//'img { max-width: 100%; }'//NL//'details.specifics { margin' &
        //': .5rem 0 1rem; } details.specifics summary { cursor: pointer; color: var(--muted); font-size: .9rem; }'//NL//'d' &
        //'etails.specifics .item:first-of-type { border-top: 0; }'//NL//'.form { margin: 1rem 0 1.6rem; } .form .sig { ' &
        //'margin-bottom: .4rem; }'//NL//'table.forms { width: auto; margin: .4rem 0 .5rem; } table.forms td.type, table' &
        //'.forms td.name { width: auto; white-space: nowrap; }'//NL//'table.forms td.rank, table.forms th.rank { text-a' &
        //'lign: center; padding-right: 1rem; white-space: nowrap; }'//NL//'table.forms td.rank a { text-decoration: non' &
        //'e; }'//NL//'.fixed { color: var(--muted); font-size: .88rem; margin: .2rem 0 0; }'//NL//'details.source { mar' &
        //'gin: 1rem 0; } details.source summary { cursor: pointer; color: var(--muted); font-size: .9rem; }'//NL//'.chi' &
        //'ps { display: flex; flex-wrap: wrap; gap: .35rem; padding: 0; list-style: none; margin: .5rem 0 1rem; }'//NL//'.' &
        //'chips li { font-family: var(--mono); font-size: .82rem; background: var(--bg-soft); border: 1px solid var(--l' &
        //'ine);'//NL//'  border-radius: 5px; padding: 0 .45rem; }'//NL//'.listing td:first-child { font-family: var(--m' &
        //'ono); font-size: .9em; white-space: nowrap; }'//NL//'.listing td p { margin: 0; }'//NL//'.listing .num { text' &
        //'-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; padding-left: 0; padding-right: .55re' &
        //'m; }'//NL//'.listing tfoot td { font-weight: 600; border-bottom: 0; border-top: 2px solid var(--line); }'//NL &
        //'.layout:has(table.sortable), .inner:has(table.sortable) { max-width: none; }'//NL//'.sortable th { cursor: po' &
        //'inter; user-select: none; }'//NL//'@media (max-width: 1099px) { .sortable { display: block; overflow-x: auto;' &
        //' } }'//NL//'.sortable th[aria-sort="ascending"]::after { content: " \25B2"; font-size: .7em; }'//NL//'.sortab' &
        //'le th[aria-sort="descending"]::after { content: " \25BC"; font-size: .7em; }'//NL//'.hero { background: var(-' &
        //'-bg-soft); border: 1px solid var(--line); border-radius: 10px; padding: .9rem 1.2rem 1rem;'//NL//'  margin-bo' &
        //'ttom: 1.4rem; }'//NL//'.hero { position: relative; }'//NL//'.hero h1 { margin-right: 10rem; }'//NL//'.hero .m' &
        //'eta { margin-bottom: .4rem; align-items: center; }'//NL//'.hero.with-logo { padding-left: 7rem; min-height: 6' &
        //'.2rem; }'//NL//'.hero-logo { position: absolute; left: 1.2rem; top: .9rem; width: 4.8rem; height: 4.8rem; obj' &
        //'ect-fit: contain; }'//NL//'.project-links { position: absolute; top: 1.1rem; right: 1.2rem; display: flex; ga' &
        //'p: .55rem; }'//NL//'.author-links { display: inline-flex; gap: .45rem; align-items: center; }'//NL//'.author-' &
        //'links:empty, .project-links:empty { display: none; }'//NL//'.icon-link { display: inline-block; width: 1.1rem' &
        //'; height: 1.1rem; background: var(--muted);'//NL//'  -webkit-mask: var(--i) center / contain no-repeat; mask:' &
        //' var(--i) center / contain no-repeat; }'//NL//'.project-links .icon-link { width: 1.35rem; height: 1.35rem; }' &
        //NL//'.icon-link:hover { background: var(--accent); }'//NL//'.grid { display: flex; flex-wrap: wrap; gap: .4rem' &
        //'; margin: .5rem 0 0; }'//NL//'.card { background: var(--bg); }'//NL//'.card { border: 1px solid var(--line); ' &
        //'border-radius: 999px; padding: .05rem .65rem; color: var(--text); font-size: .84rem; white-space: nowrap; }'//NL &
        //'.card:hover { border-color: var(--accent); text-decoration: none; }'//NL//'.card b { margin-right: .3rem; fon' &
        //'t-weight: 650; } .card span { color: var(--muted); }'//NL//'pre.source { padding-left: 0; counter-reset: line' &
        //'; line-height: 1.45; }'//NL//'.ln { display: inline-block; width: 3.6em; margin-right: 1em; text-align: right' &
        //'; color: var(--muted); opacity: .6; user-select: none; }'//NL//'.ln::before { counter-increment: line; conten' &
        //'t: counter(line); }'//NL//'.ln:target { color: var(--accent); opacity: 1; font-weight: 700; }'//NL//'footer {' &
        //' margin-top: 3rem; padding-top: 1rem; border-top: 1px solid var(--line); color: var(--muted); font-size: .84r')
    call add(b, &
        'em; }'//NL//'@media (max-width: 860px) {'//NL//'  .layout { grid-template-columns: minmax(0, 1fr); }'//NL//' ' &
        //' aside.side { position: static; height: auto; border-right: 0; border-bottom: 1px solid var(--line); max-heig' &
        //'ht: 40vh; }'//NL//'  main { padding: 1.25rem 1rem 3rem; }'//NL//'}'//NL//'@media print { header.top, aside.si' &
        //'de, .theme, .copy { display: none; } .layout { display: block; } }'//NL//'.search { position: relative; flex:' &
        //' 0 1 15rem; }'//NL//'.search input { width: 100%; height: 2rem; padding: 0 .6rem; color: var(--text); backgro' &
        //'und: var(--bg-soft);'//NL//'  border: 1px solid var(--line); border-radius: 6px; font: inherit; font-size: .8' &
        //'8rem; }'//NL//'.search input:focus { outline: 2px solid var(--accent); outline-offset: -1px; }'//NL//'.search' &
        //' .results { display: none; position: absolute; top: 2.4rem; right: 0; width: min(30rem, 90vw); max-height: 70' &
        //'vh;'//NL//'  overflow-y: auto; background: var(--bg); border: 1px solid var(--line); border-radius: 8px;'//NL &
        //'  box-shadow: 0 8px 24px rgba(0, 0, 0, .18); }'//NL//'.results a, .search-page a { display: block; padding: .' &
        //'45rem .7rem; color: var(--text); border-bottom: 1px solid var(--line); }'//NL//'.results a:hover, .results a.' &
        //'on, .search-page a:hover { background: var(--accent-soft); text-decoration: none; }'//NL//'.results b, .searc' &
        //'h-page b { font-family: var(--mono); font-size: .88rem; font-weight: 600; }'//NL//'.results small, .search-pa' &
        //'ge small { display: block; color: var(--muted); }'//NL//'aside.tree ul ul { margin-left: .8rem; }'//NL//'.gra' &
        //'ph { position: relative; overflow: auto; max-height: 34rem; margin: .4rem 0 1rem; padding: .5rem;'//NL//'  bo' &
        //'rder: 1px solid var(--line); border-radius: 8px; background: var(--bg-soft); cursor: grab; }'//NL//'.graph.dr' &
        //'agging { cursor: grabbing; user-select: none; }'//NL//'.graph svg { display: block; max-width: 100%; height: ' &
        //'auto; margin: 0 auto; }'//NL//'.graph.zoomed svg { max-width: none; }'//NL//'.graph .zoom { position: sticky;' &
        //' top: 0; left: 0; float: right; z-index: 2; }'//NL//'.graph .zoom button { background: var(--bg); color: var(' &
        //'--muted); border: 1px solid var(--line); border-radius: 5px;'//NL//'  width: 1.6rem; height: 1.6rem; cursor: ' &
        //'pointer; margin-left: .2rem; }'//NL//'.arguments td.name, .arguments td.type { width: auto; }'//NL//'td.attri' &
        //'butes { font-family: var(--mono); font-size: .84em; }'//NL//'td.default { font-family: var(--mono); font-size' &
        //': .84em; min-width: 11rem; max-width: 15rem; overflow-wrap: anywhere; }'//NL//'@media (min-width: 1400px) {'//NL &
        //'  .arguments td.type { white-space: nowrap; }'//NL//'}'//NL//'@media (min-width: 1100px) {'//NL//'  .argument' &
        //'s td.name, .arguments td.attributes { white-space: nowrap; }'//NL//'  .arguments td:last-child { min-width: 1' &
        //'2rem; }'//NL//'  .inner:has(.arguments) { max-width: 72rem; }'//NL//'  .inner:has(.arguments) > .doc, .inner:' &
        //'has(.arguments) > .sig { max-width: 54rem; }'//NL//'  main { overflow-x: auto; }'//NL//'}'//NL//'.attr { --h:' &
        //' 220; --s: 12%; display: inline-block; margin: 0 .25rem .15rem 0; padding: 0 .4rem; border-radius: 4px;'//NL//' ' &
        //' font: 600 .74rem/1.55 var(--mono); color: hsl(var(--h), var(--s), var(--attr-l));'//NL//'  background: hsla(' &
        //'var(--h), var(--s), var(--attr-l), .12); border: 1px solid hsla(var(--h), var(--s), var(--attr-l), .35); }'//NL &
        //'.attr-in, .attr-out, .attr-inout, .attr-optional, .attr-pointer, .attr-allocatable, .attr-value, .attr-target' &
        //','//NL//'.attr-dimension, .attr-contiguous, .attr-volatile, .attr-asynchronous, .attr-save, .attr-parameter,'//NL &
        //'.attr-protected, .attr-codimension, .attr-private, .attr-generic, .attr-deferred, .attr-nopass, .attr-pass,'//NL &
        //'.attr-non, .attr-deprecated, .attr-subroutine, .attr-function, .attr-interface { --s: 62%; }'//NL//'.attr-in ' &
        //'{ --h: 210; } .attr-out { --h: 25; } .attr-inout { --h: 275; }'//NL//'.attr-optional { --h: 180; } .attr-poin' &
        //'ter { --h: 0; } .attr-allocatable { --h: 125; } .attr-value { --h: 45; }'//NL//'.attr-target { --h: 325; } .a' &
        //'ttr-dimension { --h: 85; } .attr-contiguous { --h: 150; } .attr-volatile { --h: 345; }'//NL//'.attr-asynchron' &
        //'ous { --h: 300; } .attr-save { --h: 60; } .attr-parameter { --h: 195; } .attr-protected { --h: 240; }'//NL//'.' &
        //'attr-codimension { --h: 105; }'//NL//'.graph text { stroke: none; }'//NL//'.attr-private { --h: 15; --s: 40%;' &
        //' }'//NL//'.attr-generic { --h: 265; } .attr-deferred { --h: 35; } .attr-nopass { --h: 200; } .attr-pass { --h' &
        //': 160; }'//NL//'.attr-non { --h: 55; } .attr-deprecated { --h: 355; } .attr-subroutine { --h: 155; } .attr-fu' &
        //'nction { --h: 188; }'//NL//'.attr-interface { --h: 258; }'//NL//'.attr-pure, .attr-impure, .attr-elemental, .' &
        //'attr-recursive, .attr-bind, .attr-saved, .attr-common { --s: 62%; }'//NL//'.attr-pure { --h: 140; } .attr-imp' &
        //'ure { --h: 20; } .attr-elemental { --h: 170; } .attr-recursive { --h: 290; }'//NL//'.attr-bind { --h: 230; } ' &
        //'.attr-saved { --h: 40; } .attr-common { --h: 5; }'//NL//'.intent { color: hsl(var(--h), var(--s), var(--attr-' &
        //'l)); }'//NL//'td.binds { font-family: var(--mono); font-size: .84em; overflow-wrap: break-word; max-width: 20' &
        //'rem; }'//NL//'.listing th { white-space: nowrap; }'//NL//'.listing td.link { font-family: var(--mono); font-s' &
        //'ize: .84em; overflow-wrap: break-word; }'//NL//'.item h3 .attr, h1 .attr { margin-left: .5rem; vertical-align' &
        //': middle; }'//NL//'.ico { display: inline-block; width: 1.05rem; height: 1.05rem; margin-right: .4rem; border' &
        //'-radius: 3px; color: #fff;'//NL//'  background: #646d7e; font: 700 .68rem/1.05rem var(--sans); text-align: ce' &
        //'nter; vertical-align: .05rem; }'//NL//'.ico-m { background: #3657c9; } .ico-p { background: #a61e69; } .ico-s' &
        //' { background: #1d7a55; }'//NL//'.ico-f { background: #0b7285; } .ico-i { background: #6a4fb3; } .ico-a { bac' &
        //'kground: #8a4fb3; }'//NL//'.ico-t { background: #a15c00; } .ico-b { background: #7a6a2d; } .ico-v { backgroun' &
        //'d: #646d7e; }'//NL//'.ico-n { background: #5c6f2d; } .ico-d { background: #8a5a44; } .ico-_ { background: #5c' &
        //'6f2d; }'//NL//'.icon-github { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=' &
        //'''0 0 16 16''><path fill-rule=''evenodd'' d=''M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.5' &
        //'5-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.0' &
        //'1 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2' &
        //'.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2' &
        //'-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1' &
        //'.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z''/></svg>"); }'//NL//'.icon-gitlab { --' &
        //'i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''' &
        //'evenodd'' d=''M8 15 .9 9.8a.7.7 0 0 1-.3-.8L2.3 2c.1-.4.6-.4.7 0l1.9 4.4h6.2L13 2c.1-.4.6-.4.7 0L15.4 9a.7.7 ' &
        //'0 0 1-.3.8z''/></svg>"); }'//NL//'.icon-bitbucket { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.o' &
        //'rg/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd'' d=''M1.2 1.5a.5.5 0 0 0-.5.6l2 12.2a.7.7 0 0 ' &
        //'0 .7.6h9.4a.5.5 0 0 0 .5-.4l2-12.4a.5.5 0 0 0-.5-.6zm8.7 9H6.2l-.9-4.7h5.4z''/></svg>"); }'//NL//'.icon-sourc' &
        //'eforge { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path f' &
        //'ill-rule=''evenodd'' d=''M8 .6.6 8 8 15.4 15.4 8zm0 2.9L12.5 8 8 12.5 3.5 8z''/><path d=''M8.7 4.6c.1 1.5 1.5' &
        //' 2 1.5 3.6 0 1.2-1 2.2-2.2 2.2S5.8 9.5 5.8 8.4c0-.8.5-1.2.7-1.9.4.4.6.7.7 1.1.5-.8 1-1.8 1.5-3z''/></svg>"); ' &
        //'}'//NL//'.icon-website { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0' &
        //' 16 16''><g fill=''none'' stroke=''black'' stroke-width=''1.4''><circle cx=''8'' cy=''8'' r=''6.8''/><ellipse' &
        //' cx=''8'' cy=''8'' rx=''3'' ry=''6.8''/><path d=''M1.2 8h13.6M2.2 4.6h11.6M2.2 11.4h11.6''/></g></svg>"); }'//NL &
        //'.icon-download { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''' &
        //'><path fill-rule=''evenodd'' d=''M7.1 1h1.8v7l2.5-2.5 1.3 1.3L8 11.5 3.3 6.8l1.3-1.3L7.1 8zM2 13.2h12V15H2z''' &
        //'/></svg>"); }'//NL//'.icon-email { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' vie' &
        //'wBox=''0 0 16 16''><g fill=''none'' stroke=''black'' stroke-width=''1.4''><rect x=''1'' y=''3'' width=''14'' ' &
        //'height=''10'' rx=''1.4''/><path d=''m1.5 4 6.5 5 6.5-5''/></g></svg>"); }'//NL//'.icon-linkedin { --i: url("d' &
        //'ata:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd''' &
        //' d=''M2.2 1h11.6c.7 0 1.2.5 1.2 1.2v11.6c0 .7-.5 1.2-1.2 1.2H2.2c-.7 0-1.2-.5-1.2-1.2V2.2C1 1.5 1.5 1 2.2 1zM' &
        //'3.9 6.5v6.1h2V6.5zm1-3.1a1.1 1.1 0 1 0 0 2.3 1.1 1.1 0 0 0 0-2.3zm2.3 3.1v6.1h2V9.3c0-1 .5-1.5 1.2-1.5s1 .5 1' &
        //' 1.5v3.3h2V8.9c0-1.7-1-2.6-2.4-2.6-.9 0-1.5.4-1.8 1V6.5z''/></svg>"); }'//NL//'.icon-twitter { --i: url("data' &
        //':image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd'' d=' &
        //'''M12.1 1.5h2.3L9.3 7.3l6 7.2h-4.7L6.9 10l-4.2 4.5H.4L5.8 8.3.1 1.5h4.8l3.3 4.1z''/></svg>"); }'//NL//'.icon-' &
        //'facebook { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path' &
        //' fill-rule=''evenodd'' d=''M8 .6a7.4 7.4 0 0 0-1.2 14.7V10.1H5V8h1.8V6.4c0-1.8 1.1-2.8 2.7-2.8.8 0 1.6.1 1.6.' &
        //'1v1.8h-.9c-.9 0-1.2.6-1.2 1.1V8h2l-.3 2.1H9v5.2A7.4 7.4 0 0 0 8 .6z''/></svg>"); }'//NL//'@media (max-width: ' &
        //'860px) { .project-links { position: static; margin: .3rem 0; } .hero h1 { margin-right: 0; }'//NL//'  .hero.w' &
        //'ith-logo { padding-left: 4.6rem; } .hero-logo { left: .9rem; width: 2.8rem; height: 2.8rem; } }'//NL)
end subroutine asset_fdoc_css

!> The contents of `assets/fdoc.js`.
subroutine asset_fdoc_js(b)
    type(buffer_t), intent(inout) :: b  !! where they go
    call add(b, &
        '(function () {'//NL//'  var root = document.documentElement;'//NL//'  var saved = null;'//NL//'  try { saved ' &
        //'= localStorage.getItem("fdoc-theme"); } catch (e) {}'//NL//'  if (saved) root.setAttribute("data-theme", save' &
        //'d);'//NL//'  document.addEventListener("DOMContentLoaded", function () {'//NL//'    var button = document.que' &
        //'rySelector(".theme");'//NL//'    if (button) button.addEventListener("click", function () {'//NL//'      var ' &
        //'dark = root.getAttribute("data-theme") ? root.getAttribute("data-theme") === "dark"'//NL//'        : window.m' &
        //'atchMedia("(prefers-color-scheme: dark)").matches;'//NL//'      var next = dark ? "light" : "dark";'//NL//'  ' &
        //'    root.setAttribute("data-theme", next);'//NL//'      try { localStorage.setItem("fdoc-theme", next); } cat' &
        //'ch (e) {}'//NL//'    });'//NL//'    document.querySelectorAll(".codehilite").forEach(function (block) {'//NL//' ' &
        //'     if (!navigator.clipboard) return;'//NL//'      var copy = document.createElement("button");'//NL//'     ' &
        //' copy.className = "copy";'//NL//'      copy.textContent = "Copy";'//NL//'      copy.addEventListener("click",' &
        //' function () {'//NL//'        navigator.clipboard.writeText(block.querySelector("pre").innerText).then(functi' &
        //'on () {'//NL//'          copy.textContent = "Copied";'//NL//'          setTimeout(function () { copy.textCont' &
        //'ent = "Copy"; }, 1200);'//NL//'        });'//NL//'      });'//NL//'      block.appendChild(copy);'//NL//'    ' &
        //'});'//NL//'  });'//NL//'})();'//NL//'(function () {'//NL//'  var script = document.currentScript;'//NL//'  va' &
        //'r root = script ? script.src.replace(/js\/fdoc\.js.*$/, "") : "";'//NL//'  var loaded = false, entries = null' &
        //', waiting = [];'//NL//NL//'  function load(then) {'//NL//'    if (entries) { then(); return; }'//NL//'    wai' &
        //'ting.push(then);'//NL//'    if (loaded) return;'//NL//'    loaded = true;'//NL//'    var tag = document.creat' &
        //'eElement("script");'//NL//'    tag.src = root + "search/index.js";'//NL//'    tag.onload = function () {'//NL &
        //'      entries = window.FDOC_INDEX || [];'//NL//'      entries.forEach(function (e) { e.low = e.t.toLowerCase(' &
        //'); e.text = (e.s || "").toLowerCase(); });'//NL//'      waiting.forEach(function (f) { f(); });'//NL//'    };' &
        //NL//'    document.head.appendChild(tag);'//NL//'  }'//NL//NL//'  function score(entry, words) {'//NL//'    var' &
        //' total = 0;'//NL//'    for (var i = 0; i < words.length; i++) {'//NL//'      var w = words[i], at = entry.low' &
        //'.indexOf(w);'//NL//'      if (entry.low === w) total += 100;'//NL//'      else if (at === 0) total += 50;'//NL &
        //'      else if (at > 0) total += 25;'//NL//'      else if (entry.text.indexOf(w) >= 0) total += 5;'//NL//'    ' &
        //'  else return 0;'//NL//'    }'//NL//'    return total - entry.low.length / 100;'//NL//'  }'//NL//NL//'  // ed' &
        //'it distance with transpositions, giving up once it exceeds `most`'//NL//'  function distance(a, b, most) {'//NL &
        //'    if (Math.abs(a.length - b.length) > most) return most + 1;'//NL//'    var before = null, last = [], row =' &
        //' [], i, j;'//NL//'    for (j = 0; j <= b.length; j++) last[j] = j;'//NL//'    for (i = 1; i <= a.length; i++)' &
        //' {'//NL//'      row = [i];'//NL//'      var best = i;'//NL//'      for (j = 1; j <= b.length; j++) {'//NL//' ' &
        //'       var cost = a[i - 1] === b[j - 1] ? 0 : 1;'//NL//'        row[j] = Math.min(last[j] + 1, row[j - 1] + 1' &
        //', last[j - 1] + cost);'//NL//'        if (before && i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b' &
        //'[j - 1]) {'//NL//'          row[j] = Math.min(row[j], before[j - 2] + 1);'//NL//'        }'//NL//'        bes' &
        //'t = Math.min(best, row[j]);'//NL//'      }'//NL//'      if (best > most) return most + 1;'//NL//'      before' &
        //' = last;'//NL//'      last = row;'//NL//'    }'//NL//'    return last[b.length];'//NL//'  }'//NL//NL//'  func' &
        //'tion parts(text) { return text.split(/[^a-z0-9]+/).filter(Boolean); }'//NL//NL//'  // a typo: the word is clo' &
        //'se to some run of parts of the name, or to how such a run starts'//NL//'  function typo(tokens, word) {'//NL//' ' &
        //'   if (word.length < 3) return 0;'//NL//'    var size = parts(word).length, plain = parts(word).join("_"), mo' &
        //'st = word.length < 8 ? 1 : 2;'//NL//'    var result = 0;'//NL//'    for (var i = 0; i + size <= tokens.length' &
        //'; i++) {'//NL//'      var run = tokens.slice(i, i + size).join("_");'//NL//'      var d = distance(plain, run' &
        //', most);'//NL//'      if (d > most) d = distance(plain, run.slice(0, plain.length), most);'//NL//'      if (d' &
        //' <= most) result = Math.max(result, 3 - d);'//NL//'    }'//NL//'    return result;'//NL//'  }'//NL//NL//'  //' &
        //' the word is in the initials of the parts of the name, as `jvcs` for json_value_create_string'//NL//'  functi' &
        //'on initials(tokens, word) {'//NL//'    if (word.length < 2) return 0;'//NL//'    return subsequence(tokens.ma' &
        //'p(function (t) { return t[0]; }).join(""), word) ? 2.5 : 0;'//NL//'  }'//NL//NL//'  function subsequence(text' &
        //', word) {'//NL//'    var at = -1;'//NL//'    for (var i = 0; i < word.length; i++) {'//NL//'      at = text.i' &
        //'ndexOf(word[i], at + 1);'//NL//'      if (at < 0) return false;'//NL//'    }'//NL//'    return true;'//NL//' ' &
        //' }'//NL//NL//'  // the letters of the word are in order and close together'//NL//'  function letters(low, wor' &
        //'d) {'//NL//'    if (word.length < 3) return 0;'//NL//'    var best = 0;'//NL//'    for (var start = low.index' &
        //'Of(word[0]); start >= 0; start = low.indexOf(word[0], start + 1)) {'//NL//'      var at = start;'//NL//'     ' &
        //' for (var i = 1; i < word.length && at >= 0; i++) at = low.indexOf(word[i], at + 1);'//NL//'      if (at < 0)' &
        //' break;'//NL//'      var span = at - start + 1;'//NL//'      if (span <= word.length * 2) best = Math.max(bes' &
        //'t, word.length / span);'//NL//'    }'//NL//'    return best;'//NL//'  }'//NL//NL//'  function fuzzy(entry, wo' &
        //'rds) {'//NL//'    if (!entry.tokens) entry.tokens = parts(entry.low);'//NL//'    var total = 0;'//NL//'    fo' &
        //'r (var i = 0; i < words.length; i++) {'//NL//'      var w = words[i];'//NL//'      var s = entry.low.indexOf(' &
        //'w) >= 0 ? 3 : Math.max(typo(entry.tokens, w), initials(entry.tokens, w), letters(entry.low, w));'//NL//'     ' &
        //' if (s <= 0) return 0;'//NL//'      total += s;'//NL//'    }'//NL//'    return total - entry.low.length / 100' &
        //'0;'//NL//'  }'//NL//NL//'  function search(query, limit) {'//NL//'    var words = query.toLowerCase().split(/' &
        //'\s+/).filter(Boolean);'//NL//'    if (!words.length) return [];'//NL//'    var found = [], rest = [];'//NL//' ' &
        //'   entries.forEach(function (e) {'//NL//'      var s = score(e, words);'//NL//'      if (s > 0) found.push([s' &
        //', e]); else rest.push(e);'//NL//'    });'//NL//'    found.sort(function (a, b) { return b[0] - a[0]; });'//NL &
        //'    if (found.length < limit) {'//NL//'      // fuzzy matches only fill in below exact ones'//NL//'      var ' &
        //'near = [];'//NL//'      rest.forEach(function (e) { var s = fuzzy(e, words); if (s > 0) near.push([s, e]); })' &
        //';'//NL//'      near.sort(function (a, b) { return b[0] - a[0]; });'//NL//'      found = found.concat(near);'//NL &
        //'    }'//NL//'    return found.slice(0, limit).map(function (f) { return f[1]; });'//NL//'  }'//NL//NL//'  fun' &
        //'ction row(entry) {'//NL//'    var a = document.createElement("a");'//NL//'    a.href = root + entry.u;'//NL//' ' &
        //'   var title = document.createElement("b");'//NL//'    title.textContent = entry.t;'//NL//'    var kind = doc' &
        //'ument.createElement("span");'//NL//'    kind.className = "badge";'//NL//'    kind.textContent = entry.k;'//NL &
        //'    a.appendChild(title);'//NL//'    a.appendChild(kind);'//NL//'    if (entry.s) {'//NL//'      var text = d' &
        //'ocument.createElement("small");'//NL//'      text.textContent = entry.s;'//NL//'      a.appendChild(text);'//NL &
        //'    }'//NL//'    return a;'//NL//'  }'//NL//NL//'  function fill(box, results) {'//NL//'    box.textContent =' &
        //' "";'//NL//'    results.forEach(function (e) { box.appendChild(row(e)); });'//NL//'  }'//NL//NL//'  document.' &
        //'addEventListener("DOMContentLoaded", function () {'//NL//'    var input = document.querySelector(".search inp' &
        //'ut");'//NL//'    if (!input) return;'//NL//'    var box = document.querySelector(".search .results");'//NL//' ' &
        //'   var selected = -1;'//NL//'    function mark() {'//NL//'      var rows = box.children;'//NL//'      for (va' &
        //'r i = 0; i < rows.length; i++) rows[i].className = i === selected ? "on" : "";'//NL//'    }'//NL//'    input.' &
        //'addEventListener("input", function () {'//NL//'      load(function () {'//NL//'        fill(box, input.value ' &
        //'? search(input.value, 12) : []);'//NL//'        selected = -1;'//NL//'        box.style.display = box.childre' &
        //'n.length ? "block" : "none";'//NL//'      });'//NL//'    });'//NL//'    input.addEventListener("keydown", fun' &
        //'ction (event) {'//NL//'      var n = box.children.length;'//NL//'      if (event.key === "ArrowDown" && n) { ' &
        //'selected = (selected + 1) % n; mark(); event.preventDefault(); }'//NL//'      else if (event.key === "ArrowUp' &
        //'" && n) { selected = (selected + n - 1) % n; mark(); event.preventDefault(); }'//NL//'      else if (event.ke' &
        //'y === "Escape") { box.style.display = "none"; input.blur(); }'//NL//'      else if (event.key === "Enter") {'//NL &
        //'        if (selected >= 0) box.children[selected].click();'//NL//'        else location.href = root + "search' &
        //'.html?q=" + encodeURIComponent(input.value);'//NL//'      }'//NL//'    });'//NL//'    document.addEventListen' &
        //'er("click", function (event) {'//NL//'      if (!event.target.closest(".search")) box.style.display = "none";' &
        //NL//'    });'//NL//'    document.addEventListener("keydown", function (event) {'//NL//'      if (event.key ===' &
        //' "/" && document.activeElement !== input) { input.focus(); event.preventDefault(); }'//NL//'    });'//NL//'  ' &
        //'  var page = document.querySelector(".search-page");'//NL//'    if (page) {'//NL//'      var query = new URLS' &
        //'earchParams(location.search).get("q") || "";'//NL//'      input.value = query;'//NL//'      load(function () ' &
        //'{'//NL//'        var results = search(query, 200);'//NL//'        fill(page, results);'//NL//'        documen' &
        //'t.querySelector(".search-count").textContent = results.length + " results for “" + query + "”";'//NL//'  ' &
        //'    });'//NL//'    }'//NL//'  });'//NL//'})();'//NL//'(function () {'//NL//'  document.addEventListener("DOMC' &
        //'ontentLoaded", function () {'//NL//'    document.querySelectorAll(".graph").forEach(function (box) {'//NL//' ' &
        //'     var svg = box.querySelector("svg");'//NL//'      if (!svg) return;'//NL//'      var width = svg.width.ba' &
        //'seVal.value, height = svg.height.baseVal.value, scale = 1;'//NL//'      function set(value) {'//NL//'        ' &
        //'scale = Math.max(0.25, Math.min(6, value));'//NL//'        box.classList.add("zoomed");'//NL//'        svg.st' &
        //'yle.width = width * scale + "px";'//NL//'        svg.style.height = height * scale + "px";'//NL//'      }'//NL &
        //'      var zoom = document.createElement("div");'//NL//'      zoom.className = "zoom";'//NL//'      [["+", 1.3' &
        //'], ["\u2212", 1 / 1.3]].forEach(function (b) {'//NL//'        var button = document.createElement("button");'//NL &
        //'        button.textContent = b[0];'//NL//'        button.setAttribute("aria-label", b[1] > 1 ? "Zoom in" : "Z')
    call add(b, &
        'oom out");'//NL//'        button.addEventListener("click", function () { set(scale * b[1]); });'//NL//'      ' &
        //'  zoom.appendChild(button);'//NL//'      });'//NL//'      box.insertBefore(zoom, svg);'//NL//'      var fit =' &
        //' box.clientWidth / width;'//NL//'      if (fit > 0 && fit < 0.75) set(0.75);'//NL//'      var start = null;'//NL &
        //'      box.addEventListener("mousedown", function (event) {'//NL//'        if (event.target.closest("a, button' &
        //'")) return;'//NL//'        start = [event.clientX, event.clientY, box.scrollLeft, box.scrollTop];'//NL//'    ' &
        //'    box.classList.add("dragging");'//NL//'      });'//NL//'      window.addEventListener("mousemove", functio' &
        //'n (event) {'//NL//'        if (!start) return;'//NL//'        box.scrollLeft = start[2] - (event.clientX - st' &
        //'art[0]);'//NL//'        box.scrollTop = start[3] - (event.clientY - start[1]);'//NL//'      });'//NL//'      ' &
        //'window.addEventListener("mouseup", function () { start = null; box.classList.remove("dragging"); });'//NL//' ' &
        //'   });'//NL//'  });'//NL//'})();'//NL//NL//'// a link to something inside a closed section opens the section'//NL &
        //'function openTarget() {'//NL//'  var id = decodeURIComponent(location.hash.slice(1));'//NL//'  var target = i' &
        //'d && document.getElementById(id);'//NL//'  var section = target && target.closest(''details'');'//NL//'  if (' &
        //'section) { section.open = true; target.scrollIntoView(); }'//NL//'}'//NL//'window.addEventListener(''hashchan' &
        //'ge'', openTarget);'//NL//'window.addEventListener(''DOMContentLoaded'', openTarget);'//NL//NL//'// clicking a' &
        //' heading of a sortable table sorts it by that column'//NL//'window.addEventListener(''DOMContentLoaded'', fun' &
        //'ction () {'//NL//'  document.querySelectorAll(''table.sortable'').forEach(function (table) {'//NL//'    var h' &
        //'eadings = table.querySelectorAll(''thead th'');'//NL//'    headings.forEach(function (th, column) {'//NL//'  ' &
        //'    th.addEventListener(''click'', function () {'//NL//'        var body = table.tBodies[0];'//NL//'        v' &
        //'ar numeric = th.classList.contains(''num'');'//NL//'        var up = th.hasAttribute(''aria-sort'') ? th.getA' &
        //'ttribute(''aria-sort'') === ''descending'' : !numeric;'//NL//'        var key = function (row) {'//NL//'     ' &
        //'     var cell = row.cells[column];'//NL//'          return numeric ? Number(cell.dataset.sort) : cell.textCon' &
        //'tent.toLowerCase();'//NL//'        };'//NL//'        var rows = Array.prototype.slice.call(body.rows);'//NL//' ' &
        //'       rows.sort(function (a, b) {'//NL//'          var x = key(a), y = key(b);'//NL//'          return (x < ' &
        //'y ? -1 : x > y ? 1 : 0) * (up ? 1 : -1);'//NL//'        });'//NL//'        rows.forEach(function (row) { body' &
        //'.appendChild(row); });'//NL//'        headings.forEach(function (other) { other.removeAttribute(''aria-sort''' &
        //'); });'//NL//'        th.setAttribute(''aria-sort'', up ? ''ascending'' : ''descending'');'//NL//'      });'//NL &
        //'    });'//NL//'  });'//NL//'});'//NL)
end subroutine asset_fdoc_js

end module fdoc_assets
