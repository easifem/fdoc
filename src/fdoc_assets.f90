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
        ':root {'//NL//'  --mono: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;'//NL//'  --sans: system-ui' &
        //', -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;'//NL//'}'//NL//'/* The themes. With' &
        //' none chosen, the page follows the system: gruvbox-light or gruvbox-dark. */'//NL//':root, :root[data-theme="' &
        //'gruvbox-light"] {'//NL//'  --bg: #fbf1c7; --bg-soft: #f2e5bc; --bg-code: #f2e5bc; --line: #d5c4a1; --text: #3' &
        //'c3836; --muted: #7c6f64;'//NL//'  --accent: #076678; --accent-soft: #ebdbb2; --ok: #79740e; --warn: #b57614; ' &
        //'--bad: #9d0006; --hist: #8f3f71;'//NL//'  --attr-l: 34%; color-scheme: light;'//NL//'  --k: #9d0006; --s: #79' &
        //'740e; --c: #928374; --d: #427b58; --n: #8f3f71; --p: #af3a03;'//NL//'}'//NL//':root[data-theme="gruvbox-dark"' &
        //'] {'//NL//'  --bg: #282828; --bg-soft: #32302f; --bg-code: #1d2021; --line: #504945; --text: #ebdbb2; --muted' &
        //': #a89984;'//NL//'  --accent: #83a598; --accent-soft: #3c3836; --ok: #b8bb26; --warn: #fabd2f; --bad: #fb4934' &
        //'; --hist: #d3869b;'//NL//'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #fb4934; --s: #b8bb26; --c: #928' &
        //'374; --d: #8ec07c; --n: #d3869b; --p: #fe8019;'//NL//'}'//NL//'@media (prefers-color-scheme: dark) {'//NL//' ' &
        //' :root:not([data-theme]) {'//NL//'    --bg: #282828; --bg-soft: #32302f; --bg-code: #1d2021; --line: #504945;' &
        //' --text: #ebdbb2; --muted: #a89984;'//NL//'    --accent: #83a598; --accent-soft: #3c3836; --ok: #b8bb26; --wa' &
        //'rn: #fabd2f; --bad: #fb4934; --hist: #d3869b;'//NL//'    --attr-l: 72%; color-scheme: dark;'//NL//'    --k: #' &
        //'fb4934; --s: #b8bb26; --c: #928374; --d: #8ec07c; --n: #d3869b; --p: #fe8019;'//NL//'  }'//NL//'}'//NL//':roo' &
        //'t[data-theme="tokyo-night"] {'//NL//'  --bg: #1a1b26; --bg-soft: #1f2335; --bg-code: #16161e; --line: #292e42' &
        //'; --text: #c0caf5; --muted: #9aa5ce;'//NL//'  --accent: #7aa2f7; --accent-soft: #283457; --ok: #9ece6a; --war' &
        //'n: #e0af68; --bad: #f7768e; --hist: #bb9af7;'//NL//'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #bb9af' &
        //'7; --s: #9ece6a; --c: #565f89; --d: #7dcfff; --n: #ff9e64; --p: #e0af68;'//NL//'}'//NL//':root[data-theme="ca' &
        //'tppuccin-mocha"] {'//NL//'  --bg: #1e1e2e; --bg-soft: #181825; --bg-code: #181825; --line: #313244; --text: #' &
        //'cdd6f4; --muted: #a6adc8;'//NL//'  --accent: #89b4fa; --accent-soft: #313244; --ok: #a6e3a1; --warn: #f9e2af;' &
        //' --bad: #f38ba8; --hist: #cba6f7;'//NL//'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #cba6f7; --s: #a6' &
        //'e3a1; --c: #6c7086; --d: #94e2d5; --n: #fab387; --p: #f9e2af;'//NL//'}'//NL//':root[data-theme="catppuccin-fr' &
        //'appe"] {'//NL//'  --bg: #303446; --bg-soft: #292c3c; --bg-code: #292c3c; --line: #414559; --text: #c6d0f5; --' &
        //'muted: #a5adce;'//NL//'  --accent: #8caaee; --accent-soft: #414559; --ok: #a6d189; --warn: #e5c890; --bad: #e' &
        //'78284; --hist: #ca9ee6;'//NL//'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #ca9ee6; --s: #a6d189; --c:' &
        //' #737994; --d: #81c8be; --n: #ef9f76; --p: #e5c890;'//NL//'}'//NL//':root[data-theme="rose-pine"] {'//NL//'  ' &
        //'--bg: #191724; --bg-soft: #1f1d2e; --bg-code: #1f1d2e; --line: #403d52; --text: #e0def4; --muted: #908caa;'//NL &
        //'  --accent: #c4a7e7; --accent-soft: #26233a; --ok: #9ccfd8; --warn: #f6c177; --bad: #eb6f92; --hist: #ebbcba;' &
        //NL//'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #c4a7e7; --s: #f6c177; --c: #6e6a86; --d: #9ccfd8; --n' &
        //': #ebbcba; --p: #eb6f92;'//NL//'}'//NL//':root[data-theme="rose-pine-dawn"] {'//NL//'  --bg: #faf4ed; --bg-so' &
        //'ft: #f2e9e1; --bg-code: #fffaf3; --line: #dfdad9; --text: #575279; --muted: #797593;'//NL//'  --accent: #2869' &
        //'83; --accent-soft: #f2e9e1; --ok: #56949f; --warn: #ea9d34; --bad: #b4637a; --hist: #907aa9;'//NL//'  --attr-' &
        //'l: 34%; color-scheme: light;'//NL//'  --k: #286983; --s: #ea9d34; --c: #9893a5; --d: #56949f; --n: #d7827e; -' &
        //'-p: #b4637a;'//NL//'}'//NL//'* { box-sizing: border-box; }'//NL//'html { scroll-padding-top: 4.5rem; }'//NL//'b' &
        //'ody { margin: 0; background: var(--bg); color: var(--text); font: 16px/1.6 var(--sans); }'//NL//'a { color: v' &
        //'ar(--accent); text-decoration: none; }'//NL//'a:hover { text-decoration: underline; }'//NL//'header.top {'//NL &
        //'  position: sticky; top: 0; z-index: 10; display: flex; align-items: center; gap: 1.25rem; height: 3.5rem;'//NL &
        //'  padding: 0 1.25rem; background: var(--bg); border-bottom: 1px solid var(--line);'//NL//'}'//NL//'header.top' &
        //' .brand { font-weight: 650; color: var(--text); white-space: nowrap; }'//NL//'header.top .brand small { color' &
        //': var(--muted); font-weight: 400; margin-left: .35rem; }'//NL//'header.top nav { display: flex; align-self: s' &
        //'tretch; gap: .15rem; overflow-x: auto; flex: 1 1 auto; scrollbar-width: none; }'//NL//'header.top nav a { dis' &
        //'play: flex; align-items: center; padding: 0 .65rem; color: var(--muted); white-space: nowrap;'//NL//'  font-s' &
        //'ize: .92rem; border-bottom: 2px solid transparent; }'//NL//'header.top nav a:hover { color: var(--text); back' &
        //'ground: var(--bg-soft); text-decoration: none; }'//NL//'header.top nav a.here { color: var(--accent); backgro' &
        //'und: var(--bg-soft); border-bottom-color: var(--accent);'//NL//'  font-weight: 600; }'//NL//'.theme { backgro' &
        //'und: var(--bg); border: 1px solid var(--line); border-radius: 6px; color: var(--muted); cursor: pointer;'//NL &
        //'  height: 2rem; padding: 0 .4rem; font: inherit; font-size: .85rem; }'//NL//'.theme:hover, .theme:focus { col' &
        //'or: var(--text); border-color: var(--accent); }'//NL//'/* --side-w is the width of the left sidebar, which ca' &
        //'n be dragged; fdoc.js sets it */'//NL//'.layout { display: grid; grid-template-columns: var(--side-w, 17rem) ' &
        //'minmax(0, 1fr); max-width: 90rem; margin: 0 auto; }'//NL//'.side-hidden .layout { grid-template-columns: minm' &
        //'ax(0, 1fr); }'//NL//'.side-hidden aside.side { display: none; }'//NL//'aside.side { position: sticky; top: 3.' &
        //'5rem; align-self: start; height: calc(100vh - 3.5rem); overflow-y: auto;'//NL//'  padding: 0 1rem 1.5rem 1.25' &
        //'rem; border-right: 1px solid var(--line); font-size: .9rem;'//NL//'  scrollbar-width: thin; scrollbar-color: ' &
        //'var(--line) transparent; }'//NL//'aside.side h4 { display: flex; align-items: center; gap: .25rem; margin: 1r' &
        //'em 0 .3rem; color: var(--muted);'//NL//'  font-size: .72rem; letter-spacing: .06em; text-transform: uppercase' &
        //'; font-weight: 650; }'//NL//'aside.side h4 a { flex: 1 1 auto; }'//NL//'aside.side ul { list-style: none; mar' &
        //'gin: 0; padding: 0; }'//NL//'aside.side li a { display: block; padding: .12rem .5rem; margin-left: -.5rem; bo' &
        //'rder-radius: 5px; color: var(--text);'//NL//'  overflow: hidden; text-overflow: ellipsis; white-space: nowrap' &
        //'; }'//NL//'aside.side li a:hover { background: var(--bg-soft); text-decoration: none; }'//NL//'aside.side li ' &
        //'a.more { color: var(--muted); }'//NL//'aside.side li a.current { background: var(--bg-soft); color: var(--acc' &
        //'ent); font-weight: 600; }'//NL//'/* folding: a section heading or a module group hides the list after it */'//NL &
        //'.fold { flex: none; width: 1.3rem; height: 1.3rem; padding: 0; border: 0; background: none; color: var(--mute' &
        //'d);'//NL//'  cursor: pointer; border-radius: 4px; font-size: .7rem; line-height: 1; transition: transform .12' &
        //'s; }'//NL//'.fold:hover { background: var(--bg-soft); color: var(--text); }'//NL//'.folded > .fold, h4.folded' &
        //' .fold { transform: rotate(-90deg); }'//NL//'h4.folded + ul { display: none; }'//NL//'li.group > ul { display' &
        //': none; padding-left: .7rem; border-left: 1px solid var(--line); margin: .1rem 0 .3rem .55rem; }'//NL//'li.gr' &
        //'oup.open > ul { display: block; }'//NL//'li.group > .group-name { display: flex; align-items: center; gap: .2' &
        //'rem; width: 100%; margin-left: -.5rem;'//NL//'  padding: .12rem .5rem .12rem .2rem; border: 0; border-radius:' &
        //' 5px; background: none; color: var(--text);'//NL//'  font: inherit; text-align: left; cursor: pointer; }'//NL &
        //'li.group > .group-name:hover { background: var(--bg-soft); }'//NL//'li.group > .group-name .label { flex: 1 1' &
        //' auto; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }'//NL//'li.group > .gro' &
        //'up-name span.n { flex: none; margin-left: .3rem; color: var(--muted); font-size: .78rem; }'//NL//'li.group > ' &
        //'.group-name .fold { display: inline-flex; align-items: center; justify-content: center;'//NL//'  pointer-even' &
        //'ts: none; transform: rotate(-90deg); }'//NL//'li.group.open > .group-name .fold { transform: none; }'//NL//'l' &
        //'i.group.here > .group-name { color: var(--accent); font-weight: 600; }'//NL//'/* while filtering, every group' &
        //' and section with a match is open */'//NL//'.filtering li.group > ul, .filtering h4.folded + ul { display: bl' &
        //'ock; }'//NL//'.filtering li.group > .group-name .fold { transform: none; }'//NL//'aside.side [hidden] { displ' &
        //'ay: none !important; }'//NL//'aside.side li a small { margin-left: .4rem; color: var(--muted); font-size: .78' &
        //'rem; }'//NL//'/* the filter box stays at the top of the sidebar */'//NL//'.side-filter { position: sticky; to' &
        //'p: 0; z-index: 2; margin: 0 -1rem 0 -1.25rem; padding: .9rem 1rem .5rem 1.25rem;'//NL//'  background: var(--b' &
        //'g); }'//NL//'.side-filter input { width: 100%; height: 1.9rem; padding: 0 .55rem; color: var(--text); backgro' &
        //'und: var(--bg-soft);'//NL//'  border: 1px solid var(--line); border-radius: 6px; font: inherit; font-size: .8' &
        //'5rem; }'//NL//'.side-filter input:focus { outline: 2px solid var(--accent); outline-offset: -1px; }'//NL//'.s' &
        //'ide-empty { color: var(--muted); font-size: .85rem; padding: .3rem 0; }'//NL//'/* the edge of the sidebar can' &
        //' be dragged to resize it */'//NL//'.side-resize { position: fixed; top: 3.5rem; bottom: 0; width: 7px; margin' &
        //'-left: -4px; cursor: col-resize; z-index: 5; }'//NL//'.side-resize:hover, .side-resize.dragging { background:' &
        //' var(--accent); opacity: .35; }'//NL//'.side-hidden .side-resize { display: none; }'//NL//'.side-toggle { fle' &
        //'x: none; width: 2rem; height: 2rem; margin-left: -.4rem; padding: 0; border: 1px solid transparent;'//NL//'  ' &
        //'border-radius: 6px; background: none; color: var(--muted); font-size: 1.05rem; line-height: 1; cursor: pointe' &
        //'r; }'//NL//'.side-toggle:hover { color: var(--text); border-color: var(--line); }'//NL//'.side-backdrop { dis' &
        //'play: none; }'//NL//'/* the contents of the page, at the right on wide screens */'//NL//'nav.toc { display: n' &
        //'one; }'//NL//'@media (min-width: 1280px) {'//NL//'  .layout.has-toc { grid-template-columns: var(--side-w, 17' &
        //'rem) minmax(0, 1fr) 15rem; max-width: 104rem; }'//NL//'  .side-hidden .layout.has-toc { grid-template-columns' &
        //': minmax(0, 1fr) 15rem; }'//NL//'  .layout.has-toc nav.toc { display: block; position: sticky; top: 3.5rem; a' &
        //'lign-self: start;'//NL//'    max-height: calc(100vh - 3.5rem); overflow-y: auto; padding: 2rem 1rem 2rem .5re' &
        //'m; font-size: .85rem;'//NL//'    scrollbar-width: thin; scrollbar-color: var(--line) transparent; }'//NL//'}'//NL &
        //'nav.toc h4 { margin: 0 0 .5rem; color: var(--muted); font-size: .72rem; letter-spacing: .06em; text-transform' &
        //': uppercase;'//NL//'  font-weight: 650; }'//NL//'nav.toc ul { list-style: none; margin: 0; padding: 0; border' &
        //'-left: 1px solid var(--line); }'//NL//'nav.toc li a { display: block; padding: .15rem 0 .15rem .8rem; margin-')
    call add(b, &
        'left: -1px; border-left: 2px solid transparent;'//NL//'  color: var(--muted); overflow: hidden; text-overflow' &
        //': ellipsis; white-space: nowrap; }'//NL//'nav.toc li.sub a { padding-left: 1.6rem; font-size: .8rem; }'//NL//'n' &
        //'av.toc li a:hover { color: var(--text); text-decoration: none; }'//NL//'nav.toc li a.on { color: var(--accent' &
        //'); border-left-color: var(--accent); font-weight: 600; }'//NL//'main { padding: 2rem 2.5rem 4rem; min-width: ' &
        //'0; }'//NL//'main > .inner { max-width: 54rem; }'//NL//'h1, h2, h3, h4 { line-height: 1.25; font-weight: 650; ' &
        //'}'//NL//'h1 { font-size: 1.9rem; margin: 0 0 .4rem; }'//NL//'h2 { font-size: 1.3rem; margin: 2.4rem 0 .8rem; ' &
        //'padding-bottom: .3rem; border-bottom: 1px solid var(--line); }'//NL//'.doc h1 { font-size: 1.5rem; margin-top' &
        //': 1.6rem; }'//NL//'.doc h2 { font-size: 1.25rem; }'//NL//'.doc h3 { font-size: 1.05rem; margin-top: 1.4rem; }' &
        //NL//'.crumbs { color: var(--muted); font-size: .88rem; margin-bottom: .3rem; }'//NL//'.crumbs .sep { margin: 0' &
        //' .15rem; }'//NL//'.kind { color: var(--muted); font-weight: 400; font-size: .62em; margin-right: .35rem; }'//NL &
        //'.meta { display: flex; flex-wrap: wrap; gap: .3rem 1rem; color: var(--muted); font-size: .88rem; margin: .4re' &
        //'m 0 1.1rem; }'//NL//'.lead { font-size: 1.05rem; color: var(--muted); margin: .1rem 0 .4rem; }'//NL//'.lead p' &
        //' { margin: 0; }'//NL//'code, pre, .sig { font-family: var(--mono); font-size: .875em; }'//NL//':not(pre) > co' &
        //'de { background: var(--bg-code); padding: .1em .3em; border-radius: 4px; }'//NL//'pre, .sig { background: var' &
        //'(--bg-code); border: 1px solid var(--line); border-radius: 8px; padding: .7rem .9rem;'//NL//'  overflow-x: au' &
        //'to; line-height: 1.5; }'//NL//'.codehilite { position: relative; margin: 1rem 0; }'//NL//'.codehilite pre { m' &
        //'argin: 0; }'//NL//'.copy { position: absolute; top: .4rem; right: .4rem; opacity: 0; background: var(--bg); c' &
        //'olor: var(--muted);'//NL//'  border: 1px solid var(--line); border-radius: 5px; font-size: .72rem; padding: .' &
        //'1rem .4rem; cursor: pointer; }'//NL//'.codehilite:hover .copy { opacity: 1; }'//NL//'.sig { margin: .4rem 0 .' &
        //'7rem; white-space: pre-wrap; overflow-wrap: anywhere; }'//NL//'.k { color: var(--k); } .s { color: var(--s); ' &
        //'} .c { color: var(--c); font-style: italic; }'//NL//'.d { color: var(--d); } .n { color: var(--n); } .p { col' &
        //'or: var(--p); }'//NL//'.item { padding: .9rem 0 1rem; border-top: 1px solid var(--line); }'//NL//'h2 + .item ' &
        //'{ border-top: 0; padding-top: 0; }'//NL//'.item > h3 { margin: 0 0 .2rem; font-size: 1rem; font-family: var(-' &
        //'-mono); overflow-wrap: anywhere; }'//NL//'.badge { display: inline-block; font: 600 .68rem/1.5 var(--sans); p' &
        //'adding: 0 .4rem; margin-left: .4rem; border-radius: 4px;'//NL//'  background: var(--bg-soft); color: var(--mu' &
        //'ted); border: 1px solid var(--line); vertical-align: middle; }'//NL//'table { border-collapse: collapse; widt' &
        //'h: 100%; font-size: .92rem; margin: .7rem 0 1rem; }'//NL//'th { text-align: left; font-weight: 600; color: va' &
        //'r(--muted); }'//NL//'/* headings stay under the bar at the top; a sticky cell loses a collapsed border, so a ' &
        //'shadow draws it */'//NL//'thead th { position: sticky; top: 3.5rem; z-index: 1; background: var(--bg); box-sh' &
        //'adow: inset 0 -1px 0 var(--line); }'//NL//'tr[id] { scroll-margin-top: 2.5rem; }'//NL//'.listing td:last-chil' &
        //'d, .arguments td { overflow-wrap: anywhere; }'//NL//'th, td { padding: .35rem .7rem .35rem 0; border-bottom: ' &
        //'1px solid var(--line); vertical-align: top; }'//NL//'td p { margin: 0; } td.type { font-family: var(--mono); ' &
        //'font-size: .84em; width: 30%; overflow-wrap: break-word; }'//NL//'td.name { font-family: var(--mono); font-si' &
        //'ze: .88em; width: 24%; overflow-wrap: break-word; }'//NL//'.doc table { display: block; overflow-x: auto; }'//NL &
        //'.alert { border-left: 3px solid var(--accent); background: var(--bg-soft); border-radius: 0 6px 6px 0;'//NL//' ' &
        //' padding: .55rem .9rem; margin: 1rem 0; }'//NL//'.alert p { margin: .3rem 0; } .alert-title { font-weight: 65' &
        //'0; font-size: .9rem; }'//NL//'.alert-warning { border-color: var(--warn); } .alert-success { border-color: va' &
        //'r(--ok); }'//NL//'.alert-danger { border-color: var(--bad); } .alert-history { border-color: var(--hist); }'//NL &
        //'blockquote { margin: 1rem 0; padding: 0 1rem; color: var(--muted); border-left: 3px solid var(--line); }'//NL &
        //'img { max-width: 100%; }'//NL//'details.specifics { margin: .5rem 0 1rem; } details.specifics summary { curso' &
        //'r: pointer; color: var(--muted); font-size: .9rem; }'//NL//'details.specifics .item:first-of-type { border-to' &
        //'p: 0; }'//NL//'.form { margin: 1rem 0 1.6rem; } .form .sig { margin-bottom: .4rem; }'//NL//'table.forms { wid' &
        //'th: auto; margin: .4rem 0 .5rem; } table.forms td.type, table.forms td.name { width: auto; min-width: 5.5rem;' &
        //' overflow-wrap: anywhere; }'//NL//'table.forms td.rank, table.forms th.rank { text-align: center; padding-rig' &
        //'ht: 1rem; white-space: nowrap; }'//NL//'table.forms td.rank a { text-decoration: none; }'//NL//'.fixed { colo' &
        //'r: var(--muted); font-size: .88rem; margin: .2rem 0 0; }'//NL//'pre.mermaid { background: none; border: 0; pa' &
        //'dding: 0; margin: 1rem 0; text-align: center; }'//NL//'details.source { margin: 1rem 0; } details.source summ' &
        //'ary { cursor: pointer; color: var(--muted); font-size: .9rem; }'//NL//'.chips { display: flex; flex-wrap: wra' &
        //'p; gap: .35rem; padding: 0; list-style: none; margin: .5rem 0 1rem; }'//NL//'.chips li { font-family: var(--m' &
        //'ono); font-size: .82rem; background: var(--bg-soft); border: 1px solid var(--line);'//NL//'  border-radius: 5' &
        //'px; padding: 0 .45rem; }'//NL//'.listing td:first-child { font-family: var(--mono); font-size: .9em; white-sp' &
        //'ace: nowrap; }'//NL//'.listing td p { margin: 0; }'//NL//'.listing .num { text-align: right; white-space: now' &
        //'rap; font-variant-numeric: tabular-nums; padding-left: 0; padding-right: .55rem; }'//NL//'.listing tfoot td {' &
        //' font-weight: 600; border-bottom: 0; border-top: 2px solid var(--line); }'//NL//'.layout:has(table.sortable),' &
        //' .inner:has(table.sortable) { max-width: none; }'//NL//'.sortable th { cursor: pointer; user-select: none; }'//NL &
        //'/* a table that scrolls by itself cannot stick to the window, and would move its headings down instead */'//NL &
        //'.doc thead th { position: static; }'//NL//'@media (max-width: 1099px) { .sortable { display: block; overflow-' &
        //'x: auto; } .sortable thead th { position: static; } }'//NL//'.sortable th[aria-sort="ascending"]::after { con' &
        //'tent: " \25B2"; font-size: .7em; }'//NL//'.sortable th[aria-sort="descending"]::after { content: " \25BC"; fo' &
        //'nt-size: .7em; }'//NL//'.hero { background: var(--bg-soft); border: 1px solid var(--line); border-radius: 10p' &
        //'x; padding: .9rem 1.2rem 1rem;'//NL//'  margin-bottom: 1.4rem; }'//NL//'.hero { position: relative; }'//NL//'.' &
        //'hero h1 { margin-right: 10rem; }'//NL//'.hero .meta { margin-bottom: .4rem; align-items: center; }'//NL//'.he' &
        //'ro.with-logo { padding-left: 7rem; min-height: 6.2rem; }'//NL//'.hero-logo { position: absolute; left: 1.2rem' &
        //'; top: .9rem; width: 4.8rem; height: 4.8rem; object-fit: contain; }'//NL//'.project-links { position: absolut' &
        //'e; top: 1.1rem; right: 1.2rem; display: flex; gap: .55rem; }'//NL//'.author-links { display: inline-flex; gap' &
        //': .45rem; align-items: center; }'//NL//'.author-links:empty, .project-links:empty { display: none; }'//NL//'.' &
        //'icon-link { display: inline-block; width: 1.1rem; height: 1.1rem; background: var(--muted);'//NL//'  -webkit-' &
        //'mask: var(--i) center / contain no-repeat; mask: var(--i) center / contain no-repeat; }'//NL//'.project-links' &
        //' .icon-link { width: 1.35rem; height: 1.35rem; }'//NL//'.icon-link:hover { background: var(--accent); }'//NL//'.' &
        //'grid { display: flex; flex-wrap: wrap; gap: .4rem; margin: .5rem 0 0; }'//NL//'.card { background: var(--bg);' &
        //' }'//NL//'.card { border: 1px solid var(--line); border-radius: 999px; padding: .05rem .65rem; color: var(--t' &
        //'ext); font-size: .84rem; white-space: nowrap; }'//NL//'.card:hover { border-color: var(--accent); text-decora' &
        //'tion: none; }'//NL//'.card b { margin-right: .3rem; font-weight: 650; } .card span { color: var(--muted); }'//NL &
        //'pre.source { padding-left: 0; counter-reset: line; line-height: 1.45; }'//NL//'.ln { display: inline-block; w' &
        //'idth: 3.6em; margin-right: 1em; text-align: right; color: var(--muted); opacity: .6; user-select: none; }'//NL &
        //'.ln::before { counter-increment: line; content: counter(line); }'//NL//'.ln:target { color: var(--accent); op' &
        //'acity: 1; font-weight: 700; }'//NL//'footer { margin-top: 3rem; padding-top: 1rem; border-top: 1px solid var(' &
        //'--line); color: var(--muted); font-size: .84rem; }'//NL//'@media (max-width: 860px) {'//NL//'  /* on a phone ' &
        //'the sidebar is a drawer, opened from the button at the left of the header */'//NL//'  .layout, .side-hidden .' &
        //'layout { grid-template-columns: minmax(0, 1fr); }'//NL//'  aside.side, .side-hidden aside.side { display: blo' &
        //'ck; position: fixed; top: 3.5rem; bottom: 0; left: 0; z-index: 20;'//NL//'    width: min(85vw, 20rem); height' &
        //': calc(100vh - 3.5rem); align-self: auto; background: var(--bg);'//NL//'    transform: translateX(-102%);'//NL &
        //'    transition: transform .2s ease; box-shadow: 0 0 24px rgba(0, 0, 0, .25); }'//NL//'  .side-open aside.side' &
        //' { transform: none; }'//NL//'  .side-open .side-backdrop { display: block; position: fixed; inset: 3.5rem 0 0' &
        //' 0; z-index: 19;'//NL//'    background: rgba(0, 0, 0, .35); }'//NL//'  .side-resize { display: none; }'//NL//' ' &
        //' header.top { gap: .6rem; padding: 0 .75rem; }'//NL//'  .search { flex: 0 1 9rem; min-width: 6rem; }'//NL//' ' &
        //' .theme { max-width: 6.5rem; }'//NL//'  main { padding: 1.25rem 1rem 3rem; }'//NL//'}'//NL//'@media print { h' &
        //'eader.top, aside.side, nav.toc, .side-resize, .theme, .copy { display: none; } .layout { display: block; } }'//NL &
        //'.search { position: relative; flex: 0 1 15rem; }'//NL//'.search input { width: 100%; height: 2rem; padding: 0' &
        //' .6rem; color: var(--text); background: var(--bg-soft);'//NL//'  border: 1px solid var(--line); border-radius' &
        //': 6px; font: inherit; font-size: .88rem; }'//NL//'.search input:focus { outline: 2px solid var(--accent); out' &
        //'line-offset: -1px; }'//NL//'.search .results { display: none; position: absolute; top: 2.4rem; right: 0; widt' &
        //'h: min(30rem, 90vw); max-height: 70vh;'//NL//'  overflow-y: auto; background: var(--bg); border: 1px solid va' &
        //'r(--line); border-radius: 8px;'//NL//'  box-shadow: 0 8px 24px rgba(0, 0, 0, .18); }'//NL//'.results a, .sear' &
        //'ch-page a { display: block; padding: .45rem .7rem; color: var(--text); border-bottom: 1px solid var(--line); ' &
        //'}'//NL//'.results a:hover, .results a.on, .search-page a:hover { background: var(--accent-soft); text-decorat' &
        //'ion: none; }'//NL//'.results b, .search-page b { font-family: var(--mono); font-size: .88rem; font-weight: 60' &
        //'0; }'//NL//'.results small, .search-page small { display: block; color: var(--muted); }'//NL//'aside.side.tre' &
        //'e { padding-top: 1.25rem; padding-bottom: 2rem; }'//NL//'aside.tree ul ul { margin-left: .8rem; }'//NL//'.gra' &
        //'ph { position: relative; overflow: auto; max-height: 34rem; margin: .4rem 0 1rem; padding: .5rem;'//NL//'  bo')
    call add(b, &
        'rder: 1px solid var(--line); border-radius: 8px; background: var(--bg-soft); cursor: grab; }'//NL//'.graph.dr' &
        //'agging { cursor: grabbing; user-select: none; }'//NL//'.graph svg { display: block; max-width: 100%; height: ' &
        //'auto; margin: 0 auto; }'//NL//'.graph.zoomed svg { max-width: none; }'//NL//'.graph .zoom { position: sticky;' &
        //' top: 0; left: 0; float: right; z-index: 2; }'//NL//'.graph .zoom button { background: var(--bg); color: var(' &
        //'--muted); border: 1px solid var(--line); border-radius: 5px;'//NL//'  width: 1.6rem; height: 1.6rem; cursor: ' &
        //'pointer; margin-left: .2rem; }'//NL//'.arguments td.name, .arguments td.type { width: auto; }'//NL//'td.attri' &
        //'butes { font-family: var(--mono); font-size: .84em; }'//NL//'td.default { font-family: var(--mono); font-size' &
        //': .84em; min-width: 11rem; max-width: 15rem; overflow-wrap: anywhere; }'//NL//'@media (min-width: 1100px) {'//NL &
        //'  .arguments td.name { white-space: nowrap; }'//NL//'  .arguments td:last-child { min-width: 12rem; }'//NL//' ' &
        //' .inner:has(.arguments) { max-width: 72rem; }'//NL//'  .inner:has(.arguments) > .doc, .inner:has(.arguments) ' &
        //'> .sig { max-width: 54rem; }'//NL//'}'//NL//'.attr { --h: 220; --s: 12%; display: inline-block; margin: 0 .25' &
        //'rem .15rem 0; padding: 0 .4rem; border-radius: 4px;'//NL//'  font: 600 .74rem/1.55 var(--mono); color: hsl(va' &
        //'r(--h), var(--s), var(--attr-l));'//NL//'  background: hsla(var(--h), var(--s), var(--attr-l), .12); border: ' &
        //'1px solid hsla(var(--h), var(--s), var(--attr-l), .35); }'//NL//'.attr-in, .attr-out, .attr-inout, .attr-opti' &
        //'onal, .attr-pointer, .attr-allocatable, .attr-value, .attr-target,'//NL//'.attr-dimension, .attr-contiguous, ' &
        //'.attr-volatile, .attr-asynchronous, .attr-save, .attr-parameter,'//NL//'.attr-protected, .attr-codimension, .' &
        //'attr-private, .attr-generic, .attr-deferred, .attr-nopass, .attr-pass,'//NL//'.attr-non, .attr-deprecated, .a' &
        //'ttr-subroutine, .attr-function, .attr-interface { --s: 62%; }'//NL//'.attr-in { --h: 210; } .attr-out { --h: ' &
        //'25; } .attr-inout { --h: 275; }'//NL//'.attr-optional { --h: 180; } .attr-pointer { --h: 0; } .attr-allocatab' &
        //'le { --h: 125; } .attr-value { --h: 45; }'//NL//'.attr-target { --h: 325; } .attr-dimension { --h: 85; } .att' &
        //'r-contiguous { --h: 150; } .attr-volatile { --h: 345; }'//NL//'.attr-asynchronous { --h: 300; } .attr-save { ' &
        //'--h: 60; } .attr-parameter { --h: 195; } .attr-protected { --h: 240; }'//NL//'.attr-codimension { --h: 105; }' &
        //NL//'.graph text { stroke: none; }'//NL//'.graph-key { display: flex; flex-wrap: wrap; gap: .25rem 1rem; margi' &
        //'n: -.6rem 0 1rem; padding: .4rem .6rem;'//NL//'  color: var(--muted); font-size: .84rem; }'//NL//'.graph-key[' &
        //'hidden] { display: none; }'//NL//'.graph-key-item { display: inline-flex; align-items: center; gap: .4rem; }'//NL &
        //'.graph-key-mark { display: inline-block; width: 1.1rem; height: .8rem; border-radius: 3px; }'//NL//'.attr-pri' &
        //'vate { --h: 15; --s: 40%; }'//NL//'.attr-generic { --h: 265; } .attr-deferred { --h: 35; } .attr-nopass { --h' &
        //': 200; } .attr-pass { --h: 160; }'//NL//'.attr-non { --h: 55; } .attr-deprecated { --h: 355; } .attr-subrouti' &
        //'ne { --h: 155; } .attr-function { --h: 188; }'//NL//'.attr-interface { --h: 258; }'//NL//'.attr-pure, .attr-i' &
        //'mpure, .attr-elemental, .attr-recursive, .attr-bind, .attr-saved, .attr-common { --s: 62%; }'//NL//'.attr-pur' &
        //'e { --h: 140; } .attr-impure { --h: 20; } .attr-elemental { --h: 170; } .attr-recursive { --h: 290; }'//NL//'.' &
        //'attr-bind { --h: 230; } .attr-saved { --h: 40; } .attr-common { --h: 5; }'//NL//'.intent { color: hsl(var(--h' &
        //'), var(--s), var(--attr-l)); }'//NL//'td.binds { font-family: var(--mono); font-size: .84em; overflow-wrap: b' &
        //'reak-word; max-width: 20rem; }'//NL//'.listing th { white-space: nowrap; }'//NL//'.listing td.link { font-fam' &
        //'ily: var(--mono); font-size: .84em; overflow-wrap: break-word; }'//NL//'.item h3 .attr, h1 .attr { margin-lef' &
        //'t: .5rem; vertical-align: middle; }'//NL//'.chips.kinds li { display: inline-flex; align-items: center; paddi' &
        //'ng-left: .2rem; border-color: var(--kind);'//NL//'  background: color-mix(in srgb, var(--kind) 14%, transpare' &
        //'nt); }'//NL//'.chips.kinds .ico { margin-right: .3rem; }'//NL//'.ico { --kind: #646d7e; background: var(--kin' &
        //'d); display: inline-block; width: 1.05rem; height: 1.05rem; margin-right: .4rem; border-radius: 3px; color: #' &
        //'fff;'//NL//'  font: 700 .68rem/1.05rem var(--sans); text-align: center; vertical-align: .05rem; }'//NL//'.ico' &
        //'-m { --kind: #3657c9; } .ico-p { --kind: #a61e69; } .ico-s { --kind: #1d7a55; }'//NL//'.ico-f { --kind: #0b72' &
        //'85; } .ico-i { --kind: #6a4fb3; } .ico-a { --kind: #8a4fb3; }'//NL//'.ico-t { --kind: #a15c00; } .ico-b { --k' &
        //'ind: #7a6a2d; } .ico-v { --kind: #646d7e; }'//NL//'.ico-n { --kind: #5c6f2d; } .ico-d { --kind: #8a5a44; } .i' &
        //'co-_ { --kind: #5c6f2d; }'//NL//'.icon-github { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2' &
        //'000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd'' d=''M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 ' &
        //'7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68' &
        //'-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 ' &
        //'0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.5' &
        //'3-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54' &
        //' 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z''/></svg>"); }'//NL//'.' &
        //'icon-gitlab { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><p' &
        //'ath fill-rule=''evenodd'' d=''M8 15 .9 9.8a.7.7 0 0 1-.3-.8L2.3 2c.1-.4.6-.4.7 0l1.9 4.4h6.2L13 2c.1-.4.6-.4.' &
        //'7 0L15.4 9a.7.7 0 0 1-.3.8z''/></svg>"); }'//NL//'.icon-bitbucket { --i: url("data:image/svg+xml,<svg xmlns=''' &
        //'http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd'' d=''M1.2 1.5a.5.5 0 0 0-.5.6l2' &
        //' 12.2a.7.7 0 0 0 .7.6h9.4a.5.5 0 0 0 .5-.4l2-12.4a.5.5 0 0 0-.5-.6zm8.7 9H6.2l-.9-4.7h5.4z''/></svg>"); }'//NL &
        //'.icon-sourceforge { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 1' &
        //'6''><path fill-rule=''evenodd'' d=''M8 .6.6 8 8 15.4 15.4 8zm0 2.9L12.5 8 8 12.5 3.5 8z''/><path d=''M8.7 4.6' &
        //'c.1 1.5 1.5 2 1.5 3.6 0 1.2-1 2.2-2.2 2.2S5.8 9.5 5.8 8.4c0-.8.5-1.2.7-1.9.4.4.6.7.7 1.1.5-.8 1-1.8 1.5-3z''/' &
        //'></svg>"); }'//NL//'.icon-website { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' vi' &
        //'ewBox=''0 0 16 16''><g fill=''none'' stroke=''black'' stroke-width=''1.4''><circle cx=''8'' cy=''8'' r=''6.8''' &
        //'/><ellipse cx=''8'' cy=''8'' rx=''3'' ry=''6.8''/><path d=''M1.2 8h13.6M2.2 4.6h11.6M2.2 11.4h11.6''/></g></s' &
        //'vg>"); }'//NL//'.icon-download { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewB' &
        //'ox=''0 0 16 16''><path fill-rule=''evenodd'' d=''M7.1 1h1.8v7l2.5-2.5 1.3 1.3L8 11.5 3.3 6.8l1.3-1.3L7.1 8zM2' &
        //' 13.2h12V15H2z''/></svg>"); }'//NL//'.icon-email { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.or' &
        //'g/2000/svg'' viewBox=''0 0 16 16''><g fill=''none'' stroke=''black'' stroke-width=''1.4''><rect x=''1'' y=''3' &
        //''' width=''14'' height=''10'' rx=''1.4''/><path d=''m1.5 4 6.5 5 6.5-5''/></g></svg>"); }'//NL//'.icon-linked' &
        //'in { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-' &
        //'rule=''evenodd'' d=''M2.2 1h11.6c.7 0 1.2.5 1.2 1.2v11.6c0 .7-.5 1.2-1.2 1.2H2.2c-.7 0-1.2-.5-1.2-1.2V2.2C1 1' &
        //'.5 1.5 1 2.2 1zM3.9 6.5v6.1h2V6.5zm1-3.1a1.1 1.1 0 1 0 0 2.3 1.1 1.1 0 0 0 0-2.3zm2.3 3.1v6.1h2V9.3c0-1 .5-1.' &
        //'5 1.2-1.5s1 .5 1 1.5v3.3h2V8.9c0-1.7-1-2.6-2.4-2.6-.9 0-1.5.4-1.8 1V6.5z''/></svg>"); }'//NL//'.icon-twitter ' &
        //'{ --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rul' &
        //'e=''evenodd'' d=''M12.1 1.5h2.3L9.3 7.3l6 7.2h-4.7L6.9 10l-4.2 4.5H.4L5.8 8.3.1 1.5h4.8l3.3 4.1z''/></svg>");' &
        //' }'//NL//'.icon-facebook { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0' &
        //' 0 16 16''><path fill-rule=''evenodd'' d=''M8 .6a7.4 7.4 0 0 0-1.2 14.7V10.1H5V8h1.8V6.4c0-1.8 1.1-2.8 2.7-2.' &
        //'8.8 0 1.6.1 1.6.1v1.8h-.9c-.9 0-1.2.6-1.2 1.1V8h2l-.3 2.1H9v5.2A7.4 7.4 0 0 0 8 .6z''/></svg>"); }'//NL//'@me' &
        //'dia (max-width: 860px) { .project-links { position: static; margin: .3rem 0; } .hero h1 { margin-right: 0; }'//NL &
        //'  .hero.with-logo { padding-left: 4.6rem; } .hero-logo { left: .9rem; width: 2.8rem; height: 2.8rem; } }'//NL &
        //'.anchor { margin-left: .4rem; color: var(--muted); font-weight: 400; text-decoration: none; opacity: 0; }'//NL &
        //'h2:hover .anchor, h3:hover .anchor, .anchor:focus { opacity: 1; }'//NL//'@media (hover: none) { .anchor { opa' &
        //'city: .5; } }'//NL//'nav.letters { display: flex; flex-wrap: wrap; gap: .25rem; margin: .4rem 0 1rem; }'//NL//'n' &
        //'av.letters a { min-width: 1.7rem; padding: .1rem .35rem; text-align: center; border: 1px solid var(--line);'//NL &
        //'  border-radius: 5px; font-weight: 600; }'//NL//'ul.names { list-style: none; padding: 0; columns: 22rem; col' &
        //'umn-gap: 2rem; margin: 0; }'//NL//'ul.names li { break-inside: avoid; padding: .12rem 0; }'//NL//'.where { co' &
        //'lor: var(--muted); font-size: .84rem; }'//NL//'ul.tree { list-style: none; padding-left: 0; margin: .4rem 0 1' &
        //'rem; }'//NL//'ul.tree ul { list-style: none; padding-left: 1.4rem; margin: 0; border-left: 1px solid var(--li' &
        //'ne); }'//NL//'ul.tree li { padding: .12rem 0; }'//NL//'ul.tree details > summary { cursor: pointer; }'//NL//'u' &
        //'l.tree details > summary::marker { color: var(--muted); }'//NL//'ul.tree li:not(:has(details)) { padding-left' &
        //': 1.05rem; }'//NL)
end subroutine asset_fdoc_css

!> The contents of `assets/fdoc.js`.
subroutine asset_fdoc_js(b)
    type(buffer_t), intent(inout) :: b  !! where they go
    call add(b, &
        '(function () {'//NL//'  var root = document.documentElement;'//NL//'  var saved = null;'//NL//'  try { saved ' &
        //'= localStorage.getItem("fdoc-theme"); } catch (e) {}'//NL//'  // the themes the selector offers; with none ch' &
        //'osen (Auto) the CSS follows the system'//NL//'  var THEMES = ["gruvbox-light", "gruvbox-dark", "tokyo-night",' &
        //' "catppuccin-mocha", "catppuccin-frappe",'//NL//'    "rose-pine", "rose-pine-dawn"];'//NL//'  if (saved && TH' &
        //'EMES.indexOf(saved) >= 0) root.setAttribute("data-theme", saved);'//NL//'  document.addEventListener("DOMCont' &
        //'entLoaded", function () {'//NL//'    var select = document.querySelector("select.theme");'//NL//'    if (sele' &
        //'ct) {'//NL//'      select.value = root.getAttribute("data-theme") || "";'//NL//'      select.addEventListener' &
        //'("change", function () {'//NL//'        if (select.value) root.setAttribute("data-theme", select.value);'//NL &
        //'        else root.removeAttribute("data-theme");'//NL//'        try {'//NL//'          if (select.value) loca' &
        //'lStorage.setItem("fdoc-theme", select.value);'//NL//'          else localStorage.removeItem("fdoc-theme");'//NL &
        //'        } catch (e) {}'//NL//'      });'//NL//'    }'//NL//'    document.querySelectorAll(".codehilite").forE' &
        //'ach(function (block) {'//NL//'      if (!navigator.clipboard) return;'//NL//'      var copy = document.create' &
        //'Element("button");'//NL//'      copy.className = "copy";'//NL//'      copy.textContent = "Copy";'//NL//'     ' &
        //' copy.addEventListener("click", function () {'//NL//'        navigator.clipboard.writeText(block.querySelecto' &
        //'r("pre").innerText).then(function () {'//NL//'          copy.textContent = "Copied";'//NL//'          setTime' &
        //'out(function () { copy.textContent = "Copy"; }, 1200);'//NL//'        });'//NL//'      });'//NL//'      block' &
        //'.appendChild(copy);'//NL//'    });'//NL//'  });'//NL//'})();'//NL//'(function () {'//NL//'  var script = docu' &
        //'ment.currentScript;'//NL//'  var root = script ? script.src.replace(/js\/fdoc\.js.*$/, "") : "";'//NL//'  var' &
        //' loaded = false, entries = null, waiting = [];'//NL//NL//'  function load(then) {'//NL//'    if (entries) { t' &
        //'hen(); return; }'//NL//'    waiting.push(then);'//NL//'    if (loaded) return;'//NL//'    loaded = true;'//NL &
        //'    var tag = document.createElement("script");'//NL//'    tag.src = root + "search/index.js";'//NL//'    tag' &
        //'.onload = function () {'//NL//'      entries = window.FDOC_INDEX || [];'//NL//'      entries.forEach(function' &
        //' (e) { e.low = e.t.toLowerCase(); e.text = (e.s || "").toLowerCase(); });'//NL//'      waiting.forEach(functi' &
        //'on (f) { f(); });'//NL//'    };'//NL//'    document.head.appendChild(tag);'//NL//'  }'//NL//NL//'  function s' &
        //'core(entry, words) {'//NL//'    var total = 0;'//NL//'    for (var i = 0; i < words.length; i++) {'//NL//'   ' &
        //'   var w = words[i], at = entry.low.indexOf(w);'//NL//'      if (entry.low === w) total += 100;'//NL//'      ' &
        //'else if (at === 0) total += 50;'//NL//'      else if (at > 0) total += 25;'//NL//'      else if (entry.text.i' &
        //'ndexOf(w) >= 0) total += 5;'//NL//'      else return 0;'//NL//'    }'//NL//'    return total - entry.low.leng' &
        //'th / 100;'//NL//'  }'//NL//NL//'  // edit distance with transpositions, giving up once it exceeds `most`'//NL &
        //'  function distance(a, b, most) {'//NL//'    if (Math.abs(a.length - b.length) > most) return most + 1;'//NL//' ' &
        //'   var before = null, last = [], row = [], i, j;'//NL//'    for (j = 0; j <= b.length; j++) last[j] = j;'//NL &
        //'    for (i = 1; i <= a.length; i++) {'//NL//'      row = [i];'//NL//'      var best = i;'//NL//'      for (j ' &
        //'= 1; j <= b.length; j++) {'//NL//'        var cost = a[i - 1] === b[j - 1] ? 0 : 1;'//NL//'        row[j] = M' &
        //'ath.min(last[j] + 1, row[j - 1] + 1, last[j - 1] + cost);'//NL//'        if (before && i > 1 && j > 1 && a[i ' &
        //'- 1] === b[j - 2] && a[i - 2] === b[j - 1]) {'//NL//'          row[j] = Math.min(row[j], before[j - 2] + 1);'//NL &
        //'        }'//NL//'        best = Math.min(best, row[j]);'//NL//'      }'//NL//'      if (best > most) return m' &
        //'ost + 1;'//NL//'      before = last;'//NL//'      last = row;'//NL//'    }'//NL//'    return last[b.length];'//NL &
        //'  }'//NL//NL//'  function parts(text) { return text.split(/[^a-z0-9]+/).filter(Boolean); }'//NL//NL//'  // a ' &
        //'typo: the word is close to some run of parts of the name, or to how such a run starts'//NL//'  function typo(' &
        //'tokens, word) {'//NL//'    if (word.length < 3) return 0;'//NL//'    var size = parts(word).length, plain = p' &
        //'arts(word).join("_"), most = word.length < 8 ? 1 : 2;'//NL//'    var result = 0;'//NL//'    for (var i = 0; i' &
        //' + size <= tokens.length; i++) {'//NL//'      var run = tokens.slice(i, i + size).join("_");'//NL//'      var' &
        //' d = distance(plain, run, most);'//NL//'      if (d > most) d = distance(plain, run.slice(0, plain.length), m' &
        //'ost);'//NL//'      if (d <= most) result = Math.max(result, 3 - d);'//NL//'    }'//NL//'    return result;'//NL &
        //'  }'//NL//NL//'  // the word is in the initials of the parts of the name, as `jvcs` for json_value_create_str' &
        //'ing'//NL//'  function initials(tokens, word) {'//NL//'    if (word.length < 2) return 0;'//NL//'    return su' &
        //'bsequence(tokens.map(function (t) { return t[0]; }).join(""), word) ? 2.5 : 0;'//NL//'  }'//NL//NL//'  functi' &
        //'on subsequence(text, word) {'//NL//'    var at = -1;'//NL//'    for (var i = 0; i < word.length; i++) {'//NL//' ' &
        //'     at = text.indexOf(word[i], at + 1);'//NL//'      if (at < 0) return false;'//NL//'    }'//NL//'    retur' &
        //'n true;'//NL//'  }'//NL//NL//'  // the letters of the word are in order and close together'//NL//'  function ' &
        //'letters(low, word) {'//NL//'    if (word.length < 3) return 0;'//NL//'    var best = 0;'//NL//'    for (var s' &
        //'tart = low.indexOf(word[0]); start >= 0; start = low.indexOf(word[0], start + 1)) {'//NL//'      var at = sta' &
        //'rt;'//NL//'      for (var i = 1; i < word.length && at >= 0; i++) at = low.indexOf(word[i], at + 1);'//NL//' ' &
        //'     if (at < 0) break;'//NL//'      var span = at - start + 1;'//NL//'      if (span <= word.length * 2) bes' &
        //'t = Math.max(best, word.length / span);'//NL//'    }'//NL//'    return best;'//NL//'  }'//NL//NL//'  function' &
        //' fuzzy(entry, words) {'//NL//'    if (!entry.tokens) entry.tokens = parts(entry.low);'//NL//'    var total = ' &
        //'0;'//NL//'    for (var i = 0; i < words.length; i++) {'//NL//'      var w = words[i];'//NL//'      var s = en' &
        //'try.low.indexOf(w) >= 0 ? 3 : Math.max(typo(entry.tokens, w), initials(entry.tokens, w), letters(entry.low, w' &
        //'));'//NL//'      if (s <= 0) return 0;'//NL//'      total += s;'//NL//'    }'//NL//'    return total - entry.' &
        //'low.length / 1000;'//NL//'  }'//NL//NL//'  function search(query, limit) {'//NL//'    var words = query.toLow' &
        //'erCase().split(/\s+/).filter(Boolean);'//NL//'    if (!words.length) return [];'//NL//'    var found = [], re' &
        //'st = [];'//NL//'    entries.forEach(function (e) {'//NL//'      var s = score(e, words);'//NL//'      if (s >' &
        //' 0) found.push([s, e]); else rest.push(e);'//NL//'    });'//NL//'    found.sort(function (a, b) { return b[0]' &
        //' - a[0]; });'//NL//'    if (found.length < limit) {'//NL//'      // fuzzy matches only fill in below exact on' &
        //'es'//NL//'      var near = [];'//NL//'      rest.forEach(function (e) { var s = fuzzy(e, words); if (s > 0) n' &
        //'ear.push([s, e]); });'//NL//'      near.sort(function (a, b) { return b[0] - a[0]; });'//NL//'      found = f' &
        //'ound.concat(near);'//NL//'    }'//NL//'    return found.slice(0, limit).map(function (f) { return f[1]; });'//NL &
        //'  }'//NL//NL//'  function row(entry) {'//NL//'    var a = document.createElement("a");'//NL//'    a.href = ro' &
        //'ot + entry.u;'//NL//'    var title = document.createElement("b");'//NL//'    title.textContent = entry.t;'//NL &
        //'    var kind = document.createElement("span");'//NL//'    kind.className = "badge";'//NL//'    kind.textConte' &
        //'nt = entry.k;'//NL//'    a.appendChild(title);'//NL//'    a.appendChild(kind);'//NL//'    if (entry.s) {'//NL &
        //'      var text = document.createElement("small");'//NL//'      text.textContent = entry.s;'//NL//'      a.app' &
        //'endChild(text);'//NL//'    }'//NL//'    return a;'//NL//'  }'//NL//NL//'  function fill(box, results) {'//NL//' ' &
        //'   box.textContent = "";'//NL//'    results.forEach(function (e) { box.appendChild(row(e)); });'//NL//'  }'//NL &
        //NL//'  document.addEventListener("DOMContentLoaded", function () {'//NL//'    var input = document.querySelect' &
        //'or(".search input");'//NL//'    if (!input) return;'//NL//'    var box = document.querySelector(".search .res' &
        //'ults");'//NL//'    var selected = -1;'//NL//'    function mark() {'//NL//'      var rows = box.children;'//NL &
        //'      for (var i = 0; i < rows.length; i++) rows[i].className = i === selected ? "on" : "";'//NL//'    }'//NL &
        //'    input.addEventListener("input", function () {'//NL//'      load(function () {'//NL//'        fill(box, in' &
        //'put.value ? search(input.value, 12) : []);'//NL//'        selected = -1;'//NL//'        box.style.display = b' &
        //'ox.children.length ? "block" : "none";'//NL//'      });'//NL//'    });'//NL//'    input.addEventListener("key' &
        //'down", function (event) {'//NL//'      var n = box.children.length;'//NL//'      if (event.key === "ArrowDown' &
        //'" && n) { selected = (selected + 1) % n; mark(); event.preventDefault(); }'//NL//'      else if (event.key ==' &
        //'= "ArrowUp" && n) { selected = (selected + n - 1) % n; mark(); event.preventDefault(); }'//NL//'      else if' &
        //' (event.key === "Escape") { box.style.display = "none"; input.blur(); }'//NL//'      else if (event.key === "' &
        //'Enter") {'//NL//'        if (selected >= 0) box.children[selected].click();'//NL//'        else location.href' &
        //' = root + "search.html?q=" + encodeURIComponent(input.value);'//NL//'      }'//NL//'    });'//NL//'    docume' &
        //'nt.addEventListener("click", function (event) {'//NL//'      if (!event.target.closest(".search")) box.style.' &
        //'display = "none";'//NL//'    });'//NL//'    document.addEventListener("keydown", function (event) {'//NL//'  ' &
        //'    if (event.key === "/" && document.activeElement !== input) { input.focus(); event.preventDefault(); }'//NL &
        //'    });'//NL//'    var page = document.querySelector(".search-page");'//NL//'    if (page) {'//NL//'      var' &
        //' query = new URLSearchParams(location.search).get("q") || "";'//NL//'      input.value = query;'//NL//'      ' &
        //'load(function () {'//NL//'        var results = search(query, 200);'//NL//'        fill(page, results);'//NL//' ' &
        //'       document.querySelector(".search-count").textContent = results.length + " results for “" + query + "”' &
        //'";'//NL//'      });'//NL//'    }'//NL//'  });'//NL//'})();'//NL//'(function () {'//NL//'  document.addEventLi' &
        //'stener("DOMContentLoaded", function () {'//NL//'    // what the colours of `add_node` in fdoc_graphs.f90 mean' &
        //': keep the two the same'//NL//'    var COLOURS = [["#3657c9", "Module"], ["#5a78de", "Submodule"], ["#a61e69"' &
        //', "Program"], ["#1d7a55", "Subroutine"],'//NL//'      ["#0b7285", "Function"], ["#6a4fb3", "Interface"], ["#a' &
        //'15c00", "Derived type"], ["#7a6a2d", "Type-bound procedure"],'//NL//'      ["#5c6f2d", "Source file"], ["#646' &
        //'d7e", "External, or other"], ["#8a93a5", "Not documented"]];'//NL//NL//'    // a button that shows what is in')
    call add(b, &
        ' this drawing, under it, as a short drawing can''t hold a popup'//NL//'    function addKey(box, svg, zoom) {'//NL &
        //'      var key = document.createElement("div");'//NL//'      key.className = "graph-key";'//NL//'      key.hid' &
        //'den = true;'//NL//'      function entry(mark, text) {'//NL//'        var item = document.createElement("span"' &
        //');'//NL//'        item.className = "graph-key-item";'//NL//'        item.appendChild(mark);'//NL//'        it' &
        //'em.appendChild(document.createTextNode(text));'//NL//'        key.appendChild(item);'//NL//'      }'//NL//'  ' &
        //'    function swatch(style) {'//NL//'        var mark = document.createElement("span");'//NL//'        mark.cl' &
        //'assName = "graph-key-mark";'//NL//'        Object.keys(style).forEach(function (name) { mark.style[name] = st' &
        //'yle[name]; });'//NL//'        return mark;'//NL//'      }'//NL//'      COLOURS.forEach(function (c) {'//NL//' ' &
        //'       if (svg.querySelector(''rect[fill="'' + c[0] + ''"], path[fill="'' + c[0] + ''"]'')) entry(swatch({ ba' &
        //'ckground: c[0] }), c[1]);'//NL//'      });'//NL//'      if (svg.querySelector(''rect[stroke="#f0a868"]'')) en' &
        //'try(swatch({ border: "2px solid #f0a868" }), "This page");'//NL//'      if (svg.querySelector("path[stroke-da' &
        //'sharray]")) {'//NL//'        entry(swatch({ height: "0", borderRadius: "0", borderTop: "2px dashed #8a93a5" }' &
        //'), "Component of a type");'//NL//'      }'//NL//'      var button = document.createElement("button");'//NL//' ' &
        //'     button.textContent = "?";'//NL//'      button.title = "Key to the colours";'//NL//'      button.setAttri' &
        //'bute("aria-label", "Key to the colours");'//NL//'      button.setAttribute("aria-expanded", "false");'//NL//' ' &
        //'     button.addEventListener("click", function () {'//NL//'        key.hidden = !key.hidden;'//NL//'        b' &
        //'utton.setAttribute("aria-expanded", String(!key.hidden));'//NL//'      });'//NL//'      zoom.appendChild(butt' &
        //'on);'//NL//'      box.parentNode.insertBefore(key, box.nextSibling);'//NL//'    }'//NL//NL//'    document.que' &
        //'rySelectorAll(".graph").forEach(function (box) {'//NL//'      var svg = box.querySelector("svg");'//NL//'    ' &
        //'  if (!svg) return;'//NL//'      var width = svg.width.baseVal.value, height = svg.height.baseVal.value, scal' &
        //'e = 1;'//NL//'      function set(value) {'//NL//'        scale = Math.max(0.25, Math.min(6, value));'//NL//' ' &
        //'       box.classList.add("zoomed");'//NL//'        svg.style.width = width * scale + "px";'//NL//'        svg' &
        //'.style.height = height * scale + "px";'//NL//'      }'//NL//'      var zoom = document.createElement("div");'//NL &
        //'      zoom.className = "zoom";'//NL//'      [["+", 1.3], ["\u2212", 1 / 1.3]].forEach(function (b) {'//NL//' ' &
        //'       var button = document.createElement("button");'//NL//'        button.textContent = b[0];'//NL//'      ' &
        //'  button.setAttribute("aria-label", b[1] > 1 ? "Zoom in" : "Zoom out");'//NL//'        button.addEventListene' &
        //'r("click", function () { set(scale * b[1]); });'//NL//'        zoom.appendChild(button);'//NL//'      });'//NL &
        //'      box.insertBefore(zoom, svg);'//NL//'      addKey(box, svg, zoom);'//NL//'      var fit = box.clientWidt' &
        //'h / width;'//NL//'      if (fit > 0 && fit < 0.75) set(0.75);'//NL//'      var start = null;'//NL//'      box' &
        //'.addEventListener("mousedown", function (event) {'//NL//'        if (event.target.closest("a, button")) retur' &
        //'n;'//NL//'        start = [event.clientX, event.clientY, box.scrollLeft, box.scrollTop];'//NL//'        box.c' &
        //'lassList.add("dragging");'//NL//'      });'//NL//'      window.addEventListener("mousemove", function (event)' &
        //' {'//NL//'        if (!start) return;'//NL//'        box.scrollLeft = start[2] - (event.clientX - start[0]);'//NL &
        //'        box.scrollTop = start[3] - (event.clientY - start[1]);'//NL//'      });'//NL//'      window.addEventL' &
        //'istener("mouseup", function () { start = null; box.classList.remove("dragging"); });'//NL//'    });'//NL//'  ' &
        //'});'//NL//'})();'//NL//NL//'// a link to something inside a closed section opens the section'//NL//'function ' &
        //'openTarget() {'//NL//'  var id = decodeURIComponent(location.hash.slice(1));'//NL//'  var target = id && docu' &
        //'ment.getElementById(id);'//NL//'  var section = target && target.closest(''details'');'//NL//'  if (section) ' &
        //'{ section.open = true; target.scrollIntoView(); }'//NL//'}'//NL//'window.addEventListener(''hashchange'', ope' &
        //'nTarget);'//NL//'window.addEventListener(''DOMContentLoaded'', openTarget);'//NL//NL//'// clicking a heading ' &
        //'of a sortable table sorts it by that column'//NL//'window.addEventListener(''DOMContentLoaded'', function () ' &
        //'{'//NL//'  document.querySelectorAll(''table.sortable'').forEach(function (table) {'//NL//'    var headings =' &
        //' table.querySelectorAll(''thead th'');'//NL//'    headings.forEach(function (th, column) {'//NL//'      th.ad' &
        //'dEventListener(''click'', function () {'//NL//'        var body = table.tBodies[0];'//NL//'        var numeri' &
        //'c = th.classList.contains(''num'');'//NL//'        var up = th.hasAttribute(''aria-sort'') ? th.getAttribute(' &
        //'''aria-sort'') === ''descending'' : !numeric;'//NL//'        var key = function (row) {'//NL//'          var ' &
        //'cell = row.cells[column];'//NL//'          return numeric ? Number(cell.dataset.sort) : cell.textContent.toLo' &
        //'werCase();'//NL//'        };'//NL//'        var rows = Array.prototype.slice.call(body.rows);'//NL//'        ' &
        //'rows.sort(function (a, b) {'//NL//'          var x = key(a), y = key(b);'//NL//'          return (x < y ? -1 ' &
        //': x > y ? 1 : 0) * (up ? 1 : -1);'//NL//'        });'//NL//'        rows.forEach(function (row) { body.append' &
        //'Child(row); });'//NL//'        headings.forEach(function (other) { other.removeAttribute(''aria-sort''); });'//NL &
        //'        th.setAttribute(''aria-sort'', up ? ''ascending'' : ''descending'');'//NL//'      });'//NL//'    });'//NL &
        //'  });'//NL//'});'//NL//NL//'// the left sidebar: the list of this page grouped by module, a filter, folding, ' &
        //'resizing, hiding, a'//NL//'// drawer on phones, and its scroll position kept from page to page'//NL//'(functi' &
        //'on () {'//NL//'  var script = document.currentScript;'//NL//'  var root = script ? script.src.replace(/js\/fd' &
        //'oc\.js.*$/, "") : "";'//NL//'  var html = document.documentElement;'//NL//'  var MIN = 180, MAX = 640;'//NL//NL &
        //'  function load(key) { try { return localStorage.getItem(key); } catch (e) { return null; } }'//NL//'  functi' &
        //'on store(key, value) {'//NL//'    try { if (value === null) localStorage.removeItem(key); else localStorage.s' &
        //'etItem(key, value); } catch (e) {}'//NL//'  }'//NL//'  function loadSet(key) { try { return JSON.parse(load(k' &
        //'ey) || "[]"); } catch (e) { return []; } }'//NL//'  function storeSet(key, set) { store(key, set.length ? JSO' &
        //'N.stringify(set) : null); }'//NL//'  function toggleIn(set, item, on) {'//NL//'    var k = set.indexOf(item);' &
        //NL//'    if (on && k < 0) set.push(item);'//NL//'    if (!on && k >= 0) set.splice(k, 1);'//NL//'  }'//NL//NL//' ' &
        //' // before the page is drawn, so that it doesn''t jump'//NL//'  var width = parseInt(load("fdoc-side-w"), 10)' &
        //';'//NL//'  if (width >= MIN && width <= MAX) html.style.setProperty("--side-w", width + "px");'//NL//'  if (l' &
        //'oad("fdoc-side-hidden") === "1") html.classList.add("side-hidden");'//NL//NL//'  function phone() { return wi' &
        //'ndow.matchMedia("(max-width: 860px)").matches; }'//NL//NL//'  // the arrow of a fold: a button on a heading, ' &
        //'or a plain mark inside the button of a group'//NL//'  function foldButton(mark) {'//NL//'    var b = document' &
        //'.createElement(mark ? "span" : "button");'//NL//'    b.className = "fold";'//NL//'    if (!mark) b.type = "bu' &
        //'tton";'//NL//'    b.innerHTML = "&#9662;";'//NL//'    return b;'//NL//'  }'//NL//NL//'  // put the entries of' &
        //' `list` under a group for each module, sorted by name'//NL//'  function group(list, key) {'//NL//'    var ite' &
        //'ms = Array.prototype.slice.call(list.children), groups = {}, names = [];'//NL//'    items.forEach(function (l' &
        //'i) {'//NL//'      var a = li.querySelector("a"), m = a ? a.getAttribute("data-m") : null;'//NL//'      if (m ' &
        //'=== null) return;'//NL//'      if (!groups[m]) { groups[m] = []; names.push(m); }'//NL//'      groups[m].push' &
        //'(li);'//NL//'    });'//NL//'    if (names.length < 2) return;'//NL//'    names.sort(function (x, y) { return ' &
        //'x.toLowerCase() < y.toLowerCase() ? -1 : x.toLowerCase() > y.toLowerCase() ? 1 : 0; });'//NL//'    var open =' &
        //' loadSet("fdoc-open-groups");'//NL//'    list.textContent = "";'//NL//'    names.forEach(function (m) {'//NL//' ' &
        //'     var li = document.createElement("li"), head = document.createElement("button"), ul = document.createElem' &
        //'ent("ul");'//NL//'      li.className = "group";'//NL//'      li.dataset.group = key + ":" + m;'//NL//'      h' &
        //'ead.className = "group-name";'//NL//'      head.type = "button";'//NL//'      head.appendChild(foldButton(tru' &
        //'e));'//NL//'      var label = document.createElement("span");'//NL//'      label.className = "label";'//NL//' ' &
        //'     label.textContent = m || "(no module)";'//NL//'      head.title = label.textContent;'//NL//'      head.a' &
        //'ppendChild(label);'//NL//'      var n = document.createElement("span");'//NL//'      n.className = "n";'//NL//' ' &
        //'     n.textContent = groups[m].length;'//NL//'      head.appendChild(n);'//NL//'      groups[m].forEach(funct' &
        //'ion (item) { ul.appendChild(item); });'//NL//'      li.appendChild(head);'//NL//'      li.appendChild(ul);'//NL &
        //'      if (open.indexOf(li.dataset.group) >= 0) li.classList.add("open");'//NL//'      head.addEventListener("' &
        //'click", function () {'//NL//'        var on = li.classList.toggle("open");'//NL//'        var set = loadSet("' &
        //'fdoc-open-groups");'//NL//'        toggleIn(set, li.dataset.group, on);'//NL//'        storeSet("fdoc-open-gr' &
        //'oups", set);'//NL//'      });'//NL//'      list.appendChild(li);'//NL//'    });'//NL//'  }'//NL//NL//'  // a ' &
        //'fold button on each heading with a list after it; the folded ones are remembered'//NL//'  function folding(si' &
        //'de) {'//NL//'    var folded = loadSet("fdoc-folded");'//NL//'    side.querySelectorAll("h4").forEach(function' &
        //' (h) {'//NL//'      var ul = h.nextElementSibling;'//NL//'      if (!ul || ul.tagName !== "UL" || !ul.childre' &
        //'n.length) return;'//NL//'      var name = h.textContent.trim(), b = foldButton(false);'//NL//'      b.title =' &
        //' "Fold or unfold " + name;'//NL//'      h.insertBefore(b, h.firstChild);'//NL//'      if (folded.indexOf(name' &
        //') >= 0) h.classList.add("folded");'//NL//'      b.addEventListener("click", function () {'//NL//'        var ' &
        //'on = h.classList.toggle("folded"), set = loadSet("fdoc-folded");'//NL//'        toggleIn(set, name, on);'//NL &
        //'        storeSet("fdoc-folded", set);'//NL//'      });'//NL//'    });'//NL//'  }'//NL//NL//'  // the filter b' &
        //'ox at the top of the sidebar: it shows the entries whose names contain what is typed'//NL//'  function filter' &
        //'(side) {'//NL//'    var links = side.querySelectorAll("li > a");'//NL//'    if (links.length < 8) return;'//NL &
        //'    var box = document.createElement("div"), input = document.createElement("input");'//NL//'    var empty = ' &
        //'document.createElement("div");'//NL//'    box.className = "side-filter";'//NL//'    input.type = "search";'//NL)
    call add(b, &
        '    input.placeholder = "Filter…";'//NL//'    input.setAttribute("aria-label", "Filter the sidebar");'//NL//' ' &
        //'   empty.className = "side-empty";'//NL//'    empty.textContent = "Nothing matches";'//NL//'    empty.hidden ' &
        //'= true;'//NL//'    box.appendChild(input);'//NL//'    side.insertBefore(box, side.firstChild);'//NL//'    sid' &
        //'e.appendChild(empty);'//NL//'    var names = Array.prototype.map.call(links, function (a) { return (a.dataset' &
        //'.name || a.textContent).toLowerCase(); });'//NL//NL//'    function run() {'//NL//'      var q = input.value.t' &
        //'rim().toLowerCase(), any = false;'//NL//'      side.classList.toggle("filtering", q.length > 0);'//NL//'     ' &
        //' links.forEach(function (a, k) {'//NL//'        var show = !q || names[k].indexOf(q) >= 0;'//NL//'        a.p' &
        //'arentElement.hidden = !show;'//NL//'        any = any || show;'//NL//'      });'//NL//'      side.querySelect' &
        //'orAll("li.group").forEach(function (g) {'//NL//'        g.hidden = q && !g.querySelector("li:not([hidden])");' &
        //NL//'        g.classList.toggle("found", !!q && !g.hidden);'//NL//'      });'//NL//'      side.querySelectorAl' &
        //'l("h4").forEach(function (h) {'//NL//'        var ul = h.nextElementSibling;'//NL//'        h.hidden = q && !' &
        //'(ul && ul.tagName === "UL" && ul.querySelector("li:not([hidden])"));'//NL//'        if (ul && ul.tagName === ' &
        //'"UL") ul.hidden = h.hidden;'//NL//'      });'//NL//'      empty.hidden = !q || any;'//NL//'      if (q) side.' &
        //'scrollTop = 0;'//NL//'    }'//NL//'    input.addEventListener("input", run);'//NL//'    input.addEventListene' &
        //'r("keydown", function (event) {'//NL//'      if (event.key === "Escape") { input.value = ""; run(); input.blu' &
        //'r(); }'//NL//'    });'//NL//'  }'//NL//NL//'  // drag the edge of the sidebar to resize it; a double click go' &
        //'es back to the default width'//NL//'  function resizing(side) {'//NL//'    var handle = document.createElemen' &
        //'t("div");'//NL//'    handle.className = "side-resize";'//NL//'    handle.title = "Drag to resize, double-clic' &
        //'k to reset";'//NL//'    document.body.appendChild(handle);'//NL//'    function place() { handle.style.left = ' &
        //'side.getBoundingClientRect().right + "px"; }'//NL//'    place();'//NL//'    window.addEventListener("resize",' &
        //' place);'//NL//'    handle.addEventListener("pointerdown", function (event) {'//NL//'      event.preventDefau' &
        //'lt();'//NL//'      handle.setPointerCapture(event.pointerId);'//NL//'      handle.classList.add("dragging");'//NL &
        //'      var left = side.getBoundingClientRect().left;'//NL//'      function move(e) {'//NL//'        var w = Ma' &
        //'th.max(MIN, Math.min(MAX, Math.round(e.clientX - left)));'//NL//'        html.style.setProperty("--side-w", w' &
        //' + "px");'//NL//'        place();'//NL//'      }'//NL//'      function up() {'//NL//'        handle.classList' &
        //'.remove("dragging");'//NL//'        handle.removeEventListener("pointermove", move);'//NL//'        handle.re' &
        //'moveEventListener("pointerup", up);'//NL//'        store("fdoc-side-w", String(Math.round(side.getBoundingCli' &
        //'entRect().width)));'//NL//'      }'//NL//'      handle.addEventListener("pointermove", move);'//NL//'      ha' &
        //'ndle.addEventListener("pointerup", up);'//NL//'    });'//NL//'    handle.addEventListener("dblclick", functio' &
        //'n () {'//NL//'      html.style.removeProperty("--side-w");'//NL//'      store("fdoc-side-w", null);'//NL//'  ' &
        //'    place();'//NL//'    });'//NL//'    return place;'//NL//'  }'//NL//NL//'  document.addEventListener("DOMCo' &
        //'ntentLoaded", function () {'//NL//'    var side = document.querySelector("aside.side"), toggle = document.que' &
        //'rySelector(".side-toggle");'//NL//'    if (!side) {'//NL//'      if (toggle) toggle.hidden = true;'//NL//'   ' &
        //'   return;'//NL//'    }'//NL//'    var list = side.querySelector("ul[data-list]"), key = list ? list.dataset.' &
        //'list : "";'//NL//'    if (list && window.FDOC_SIDEBAR) {'//NL//'      list.innerHTML = (window.FDOC_SIDEBAR[k' &
        //'ey] || "").replace(/href="@/g, ''href="'' + root);'//NL//'    }'//NL//'    // the full name, and the module, ' &
        //'as the tooltip of each entry'//NL//'    side.querySelectorAll("li > a").forEach(function (a) {'//NL//'      v' &
        //'ar name = a.textContent.trim(), m = a.getAttribute("data-m");'//NL//'      a.dataset.name = name;'//NL//'    ' &
        //'  a.title = m ? name + " — " + m : name;'//NL//'    });'//NL//'    if (list) group(list, key);'//NL//NL//' ' &
        //'   var here = location.href.split("#")[0], current = null;'//NL//'    side.querySelectorAll("li > a").forEach' &
        //'(function (a) {'//NL//'      if (current || a.href !== here) return;'//NL//'      current = a;'//NL//'      a' &
        //'.classList.add("current");'//NL//'      a.setAttribute("aria-current", "page");'//NL//'      var g = a.closes' &
        //'t("li.group");'//NL//'      if (g) g.classList.add("open", "here");'//NL//'    });'//NL//'    folding(side);'//NL &
        //'    filter(side);'//NL//'    var place = resizing(side);'//NL//NL//'    // the sidebar opens where it was lef' &
        //'t when one of its links was followed'//NL//'    var saved = null;'//NL//'    try { saved = JSON.parse(session' &
        //'Storage.getItem("fdoc-side-scroll") || "null"); } catch (e) {}'//NL//'    try { sessionStorage.removeItem("fd' &
        //'oc-side-scroll"); } catch (e) {}'//NL//'    if (saved && saved.list === key) side.scrollTop = saved.top;'//NL &
        //'    else if (current) side.scrollTop = current.offsetTop - side.clientHeight / 2;'//NL//'    side.addEventLis' &
        //'tener("click", function (event) {'//NL//'      if (!event.target.closest("a")) return;'//NL//'      try { ses' &
        //'sionStorage.setItem("fdoc-side-scroll", JSON.stringify({ list: key, top: side.scrollTop })); } catch (e) {}'//NL &
        //'      html.classList.remove("side-open");'//NL//'    });'//NL//NL//'    // the button at the left of the head' &
        //'er hides the sidebar, or on a phone opens it as a drawer'//NL//'    var backdrop = document.createElement("di' &
        //'v");'//NL//'    backdrop.className = "side-backdrop";'//NL//'    document.body.appendChild(backdrop);'//NL//' ' &
        //'   backdrop.addEventListener("click", function () { html.classList.remove("side-open"); });'//NL//'    docume' &
        //'nt.addEventListener("keydown", function (event) {'//NL//'      if (event.key === "Escape") html.classList.rem' &
        //'ove("side-open");'//NL//'    });'//NL//'    if (toggle) toggle.addEventListener("click", function () {'//NL//' ' &
        //'     if (phone()) {'//NL//'        html.classList.toggle("side-open");'//NL//'        return;'//NL//'      }'//NL &
        //'      var hidden = html.classList.toggle("side-hidden");'//NL//'      store("fdoc-side-hidden", hidden ? "1" ' &
        //': null);'//NL//'      place();'//NL//'    });'//NL//'  });'//NL//'})();'//NL//NL//'// the contents of the pag' &
        //'e, at the right on wide screens, with the section being read marked'//NL//'document.addEventListener("DOMCont' &
        //'entLoaded", function () {'//NL//'  var main = document.querySelector("main"), layout = document.querySelector' &
        //'(".layout");'//NL//'  if (!main || !layout) return;'//NL//'  var heads = Array.prototype.filter.call(main.que' &
        //'rySelectorAll("h2[id], .doc h1[id], .doc h3[id]"), function (h) {'//NL//'    return !h.closest(".item");'//NL &
        //'  });'//NL//'  if (heads.length < 2) return;'//NL//'  var nav = document.createElement("nav"), ul = document.' &
        //'createElement("ul"), links = [];'//NL//'  nav.className = "toc";'//NL//'  nav.setAttribute("aria-label", "On ' &
        //'this page");'//NL//'  nav.innerHTML = "<h4>On this page</h4>";'//NL//'  heads.forEach(function (h) {'//NL//' ' &
        //'   var copy = h.cloneNode(true);'//NL//'    copy.querySelectorAll(".anchor").forEach(function (a) { a.remove(' &
        //'); });'//NL//'    var li = document.createElement("li"), a = document.createElement("a");'//NL//'    if (h.ta' &
        //'gName === "H3") li.className = "sub";'//NL//'    a.href = "#" + h.id;'//NL//'    a.textContent = copy.textCon' &
        //'tent.trim();'//NL//'    a.title = a.textContent;'//NL//'    li.appendChild(a);'//NL//'    ul.appendChild(li);' &
        //NL//'    links.push(a);'//NL//'  });'//NL//'  nav.appendChild(ul);'//NL//'  layout.appendChild(nav);'//NL//'  ' &
        //'layout.classList.add("has-toc");'//NL//NL//'  var ticking = false;'//NL//'  function mark() {'//NL//'    tick' &
        //'ing = false;'//NL//'    var on = 0;'//NL//'    heads.forEach(function (h, k) { if (h.getBoundingClientRect().' &
        //'top < 110) on = k; });'//NL//'    links.forEach(function (a, k) { a.classList.toggle("on", k === on); });'//NL &
        //'  }'//NL//'  window.addEventListener("scroll", function () {'//NL//'    if (!ticking) { ticking = true; windo' &
        //'w.requestAnimationFrame(mark); }'//NL//'  }, { passive: true });'//NL//'  mark();'//NL//'});'//NL//NL//'// Me' &
        //'rmaid diagrams are drawn in the browser, and Mermaid is only loaded for pages that have one'//NL//'(function ' &
        //'() {'//NL//'  var URL = "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js";'//NL//NL//'  function ' &
        //'dark() {'//NL//'    var theme = document.documentElement.getAttribute("data-theme");'//NL//'    if (!theme) r' &
        //'eturn window.matchMedia("(prefers-color-scheme: dark)").matches;'//NL//'    return ["gruvbox-light", "rose-pi' &
        //'ne-dawn"].indexOf(theme) < 0;'//NL//'  }'//NL//NL//'  document.addEventListener("DOMContentLoaded", function ' &
        //'() {'//NL//'    var blocks = document.querySelectorAll("pre.mermaid");'//NL//'    if (!blocks.length) return;' &
        //NL//'    blocks.forEach(function (block) { block.dataset.source = block.textContent; });'//NL//NL//'    functi' &
        //'on draw() {'//NL//'      blocks.forEach(function (block) {'//NL//'        block.textContent = block.dataset.s' &
        //'ource;'//NL//'        block.removeAttribute("data-processed");'//NL//'      });'//NL//'      window.mermaid.i' &
        //'nitialize({ startOnLoad: false, theme: dark() ? "dark" : "default" });'//NL//'      window.mermaid.run({ node' &
        //'s: blocks });'//NL//'    }'//NL//NL//'    var tag = document.createElement("script");'//NL//'    tag.src = UR' &
        //'L;'//NL//'    tag.onload = function () {'//NL//'      draw();'//NL//'      var select = document.querySelecto' &
        //'r("select.theme");'//NL//'      if (select) select.addEventListener("change", draw);'//NL//'    };'//NL//'   ' &
        //' document.head.appendChild(tag);'//NL//'  });'//NL//'})();'//NL//NL//'// each heading with an id, and each en' &
        //'try of a list, gets a link to itself'//NL//'document.addEventListener("DOMContentLoaded", function () {'//NL//' ' &
        //' document.querySelectorAll("main h2[id], main h3[id], main .item[id] > h3").forEach(function (heading) {'//NL &
        //'    var id = heading.id || heading.parentElement.id;'//NL//'    var link = document.createElement("a");'//NL//' ' &
        //'   link.className = "anchor";'//NL//'    link.href = "#" + id;'//NL//'    link.textContent = "#";'//NL//'    ' &
        //'link.setAttribute("aria-label", "Link to this section");'//NL//'    heading.appendChild(link);'//NL//'  });'//NL &
        //'});'//NL)
end subroutine asset_fdoc_js

end module fdoc_assets
