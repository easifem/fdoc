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
        //'740e; --c: #928374; --d: #427b58; --n: #8f3f71; --p: #af3a03;'//NL//'  --kind-module: #076678; --kind-submodu' &
        //'le: #458588; --kind-program: #9d0006; --kind-subroutine: #79740e;'//NL//'  --kind-function: #427b58; --kind-i' &
        //'nterface: #8f3f71; --kind-absint: #b16286; --kind-type: #af3a03;'//NL//'  --kind-binding: #b57614; --kind-fil' &
        //'e: #665c54; --kind-blockdata: #d65d0e; --kind-other: #7c6f64;'//NL//'  --kind-undoc: #a89984; --kind-red: #cc' &
        //'241d; --kind-here: #d79921; --kind-ink: #fbf1c7;'//NL//'}'//NL//':root[data-theme="gruvbox-dark"] {'//NL//'  ' &
        //'--bg: #282828; --bg-soft: #32302f; --bg-code: #1d2021; --line: #504945; --text: #ebdbb2; --muted: #a89984;'//NL &
        //'  --accent: #83a598; --accent-soft: #3c3836; --ok: #b8bb26; --warn: #fabd2f; --bad: #fb4934; --hist: #d3869b;' &
        //NL//'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #fb4934; --s: #b8bb26; --c: #928374; --d: #8ec07c; --n' &
        //': #d3869b; --p: #fe8019;'//NL//'  --kind-module: #83a598; --kind-submodule: #6f9a8f; --kind-program: #fb4934;' &
        //' --kind-subroutine: #b8bb26;'//NL//'  --kind-function: #8ec07c; --kind-interface: #d3869b; --kind-absint: #b1' &
        //'6286; --kind-type: #fe8019;'//NL//'  --kind-binding: #fabd2f; --kind-file: #a89984; --kind-blockdata: #d65d0e' &
        //'; --kind-other: #bdae93;'//NL//'  --kind-undoc: #928374; --kind-red: #fb4934; --kind-here: #fabd2f; --kind-in' &
        //'k: #282828;'//NL//'}'//NL//'@media (prefers-color-scheme: dark) {'//NL//'  :root:not([data-theme]) {'//NL//' ' &
        //'   --bg: #282828; --bg-soft: #32302f; --bg-code: #1d2021; --line: #504945; --text: #ebdbb2; --muted: #a89984;' &
        //NL//'    --accent: #83a598; --accent-soft: #3c3836; --ok: #b8bb26; --warn: #fabd2f; --bad: #fb4934; --hist: #d' &
        //'3869b;'//NL//'    --attr-l: 72%; color-scheme: dark;'//NL//'    --k: #fb4934; --s: #b8bb26; --c: #928374; --d' &
        //': #8ec07c; --n: #d3869b; --p: #fe8019;'//NL//'    --kind-module: #83a598; --kind-submodule: #6f9a8f; --kind-p' &
        //'rogram: #fb4934; --kind-subroutine: #b8bb26;'//NL//'    --kind-function: #8ec07c; --kind-interface: #d3869b; ' &
        //'--kind-absint: #b16286; --kind-type: #fe8019;'//NL//'    --kind-binding: #fabd2f; --kind-file: #a89984; --kin' &
        //'d-blockdata: #d65d0e; --kind-other: #bdae93;'//NL//'    --kind-undoc: #928374; --kind-red: #fb4934; --kind-he' &
        //'re: #fabd2f; --kind-ink: #282828;'//NL//'  }'//NL//'}'//NL//':root[data-theme="tokyo-night"] {'//NL//'  --bg:' &
        //' #1a1b26; --bg-soft: #1f2335; --bg-code: #16161e; --line: #292e42; --text: #c0caf5; --muted: #9aa5ce;'//NL//' ' &
        //' --accent: #7aa2f7; --accent-soft: #283457; --ok: #9ece6a; --warn: #e0af68; --bad: #f7768e; --hist: #bb9af7;'//NL &
        //'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #bb9af7; --s: #9ece6a; --c: #565f89; --d: #7dcfff; --n: #f' &
        //'f9e64; --p: #e0af68;'//NL//'  --kind-module: #7aa2f7; --kind-submodule: #2ac3de; --kind-program: #f7768e; --k' &
        //'ind-subroutine: #9ece6a;'//NL//'  --kind-function: #7dcfff; --kind-interface: #bb9af7; --kind-absint: #9d7cd8' &
        //'; --kind-type: #ff9e64;'//NL//'  --kind-binding: #e0af68; --kind-file: #73daca; --kind-blockdata: #db4b4b; --' &
        //'kind-other: #a9b1d6;'//NL//'  --kind-undoc: #737aa2; --kind-red: #f7768e; --kind-here: #e0af68; --kind-ink: #' &
        //'1a1b26;'//NL//'}'//NL//':root[data-theme="catppuccin-mocha"] {'//NL//'  --bg: #1e1e2e; --bg-soft: #181825; --' &
        //'bg-code: #181825; --line: #313244; --text: #cdd6f4; --muted: #a6adc8;'//NL//'  --accent: #89b4fa; --accent-so' &
        //'ft: #313244; --ok: #a6e3a1; --warn: #f9e2af; --bad: #f38ba8; --hist: #cba6f7;'//NL//'  --attr-l: 72%; color-s' &
        //'cheme: dark;'//NL//'  --k: #cba6f7; --s: #a6e3a1; --c: #6c7086; --d: #94e2d5; --n: #fab387; --p: #f9e2af;'//NL &
        //'  --kind-module: #89b4fa; --kind-submodule: #74c7ec; --kind-program: #f38ba8; --kind-subroutine: #a6e3a1;'//NL &
        //'  --kind-function: #94e2d5; --kind-interface: #cba6f7; --kind-absint: #b4befe; --kind-type: #fab387;'//NL//' ' &
        //' --kind-binding: #f9e2af; --kind-file: #f5c2e7; --kind-blockdata: #eba0ac; --kind-other: #9399b2;'//NL//'  --' &
        //'kind-undoc: #7f849c; --kind-red: #f38ba8; --kind-here: #f9e2af; --kind-ink: #1e1e2e;'//NL//'}'//NL//':root[da' &
        //'ta-theme="catppuccin-frappe"] {'//NL//'  --bg: #303446; --bg-soft: #292c3c; --bg-code: #292c3c; --line: #4145' &
        //'59; --text: #c6d0f5; --muted: #a5adce;'//NL//'  --accent: #8caaee; --accent-soft: #414559; --ok: #a6d189; --w' &
        //'arn: #e5c890; --bad: #e78284; --hist: #ca9ee6;'//NL//'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #ca9' &
        //'ee6; --s: #a6d189; --c: #737994; --d: #81c8be; --n: #ef9f76; --p: #e5c890;'//NL//'  --kind-module: #8caaee; -' &
        //'-kind-submodule: #85c1dc; --kind-program: #e78284; --kind-subroutine: #a6d189;'//NL//'  --kind-function: #81c' &
        //'8be; --kind-interface: #ca9ee6; --kind-absint: #babbf1; --kind-type: #ef9f76;'//NL//'  --kind-binding: #e5c89' &
        //'0; --kind-file: #f4b8e4; --kind-blockdata: #ea999c; --kind-other: #949cbb;'//NL//'  --kind-undoc: #838ba7; --' &
        //'kind-red: #e78284; --kind-here: #e5c890; --kind-ink: #303446;'//NL//'}'//NL//':root[data-theme="rose-pine"] {' &
        //NL//'  --bg: #191724; --bg-soft: #1f1d2e; --bg-code: #1f1d2e; --line: #403d52; --text: #e0def4; --muted: #908c' &
        //'aa;'//NL//'  --accent: #c4a7e7; --accent-soft: #26233a; --ok: #9ccfd8; --warn: #f6c177; --bad: #eb6f92; --his' &
        //'t: #ebbcba;'//NL//'  --attr-l: 72%; color-scheme: dark;'//NL//'  --k: #c4a7e7; --s: #f6c177; --c: #6e6a86; --' &
        //'d: #9ccfd8; --n: #ebbcba; --p: #eb6f92;'//NL//'  --kind-module: #9ccfd8; --kind-submodule: #c4e1e6; --kind-pr' &
        //'ogram: #eb6f92; --kind-subroutine: #ebbcba;'//NL//'  --kind-function: #a3d4c8; --kind-interface: #c4a7e7; --k' &
        //'ind-absint: #a48ec7; --kind-type: #f6c177;'//NL//'  --kind-binding: #e8b06a; --kind-file: #908caa; --kind-blo' &
        //'ckdata: #d7827e; --kind-other: #a8a5bd;'//NL//'  --kind-undoc: #817c9c; --kind-red: #eb6f92; --kind-here: #f6' &
        //'c177; --kind-ink: #191724;'//NL//'}'//NL//':root[data-theme="rose-pine-dawn"] {'//NL//'  --bg: #faf4ed; --bg-' &
        //'soft: #f2e9e1; --bg-code: #fffaf3; --line: #dfdad9; --text: #575279; --muted: #797593;'//NL//'  --accent: #28' &
        //'6983; --accent-soft: #f2e9e1; --ok: #56949f; --warn: #ea9d34; --bad: #b4637a; --hist: #907aa9;'//NL//'  --att' &
        //'r-l: 34%; color-scheme: light;'//NL//'  --k: #286983; --s: #ea9d34; --c: #9893a5; --d: #56949f; --n: #d7827e;' &
        //' --p: #b4637a;'//NL//'  --kind-module: #286983; --kind-submodule: #56949f; --kind-program: #b4637a; --kind-su' &
        //'broutine: #d7827e;'//NL//'  --kind-function: #4f8a7a; --kind-interface: #907aa9; --kind-absint: #7d6a99; --ki' &
        //'nd-type: #b8791f;'//NL//'  --kind-binding: #a07d3a; --kind-file: #797593; --kind-blockdata: #c26d68; --kind-o' &
        //'ther: #797593;'//NL//'  --kind-undoc: #9893a5; --kind-red: #b4637a; --kind-here: #ea9d34; --kind-ink: #faf4ed' &
        //';'//NL//'}'//NL//'* { box-sizing: border-box; }'//NL//'html { scroll-padding-top: 4.5rem; }'//NL//'body { mar' &
        //'gin: 0; background: var(--bg); color: var(--text); font: 16px/1.6 var(--sans); }'//NL//'a { color: var(--acce' &
        //'nt); text-decoration: none; }'//NL//'a:hover { text-decoration: underline; }'//NL//'header.top {'//NL//'  pos' &
        //'ition: sticky; top: 0; z-index: 10; display: flex; align-items: center; gap: 1.25rem; height: 3.5rem;'//NL//' ' &
        //' padding: 0 1.25rem; background: var(--bg); border-bottom: 1px solid var(--line);'//NL//'}'//NL//'header.top ' &
        //'.brand { font-weight: 650; color: var(--text); white-space: nowrap; }'//NL//'header.top .brand small { color:' &
        //' var(--muted); font-weight: 400; margin-left: .35rem; }'//NL//'header.top nav { display: flex; align-self: st' &
        //'retch; gap: .15rem; overflow-x: auto; flex: 1 1 auto; scrollbar-width: none; }'//NL//'header.top nav a { disp' &
        //'lay: flex; align-items: center; padding: 0 .65rem; color: var(--muted); white-space: nowrap;'//NL//'  font-si' &
        //'ze: .92rem; border-bottom: 2px solid transparent; }'//NL//'header.top nav a:hover { color: var(--text); backg' &
        //'round: var(--bg-soft); text-decoration: none; }'//NL//'header.top nav a.here { color: var(--accent); backgrou' &
        //'nd: var(--bg-soft); border-bottom-color: var(--accent);'//NL//'  font-weight: 600; }'//NL//'.theme { backgrou' &
        //'nd: var(--bg); border: 1px solid var(--line); border-radius: 6px; color: var(--muted); cursor: pointer;'//NL//' ' &
        //' height: 2rem; padding: 0 .4rem; font: inherit; font-size: .85rem; }'//NL//'.theme:hover, .theme:focus { colo' &
        //'r: var(--text); border-color: var(--accent); }'//NL//'/* --side-w is the width of the left sidebar, which can' &
        //' be dragged; fdoc.js sets it */'//NL//'.layout { display: grid; grid-template-columns: var(--side-w, 17rem) m' &
        //'inmax(0, 1fr); max-width: 90rem; margin: 0 auto; }'//NL//'.side-hidden .layout { grid-template-columns: minma' &
        //'x(0, 1fr); }'//NL//'.side-hidden aside.side { display: none; }'//NL//'aside.side { position: sticky; top: 3.5' &
        //'rem; align-self: start; height: calc(100vh - 3.5rem); overflow-y: auto;'//NL//'  padding: 0 1rem 1.5rem 1.25r' &
        //'em; border-right: 1px solid var(--line); font-size: .9rem;'//NL//'  scrollbar-width: thin; scrollbar-color: v' &
        //'ar(--line) transparent; }'//NL//'aside.side h4 { display: flex; align-items: center; gap: .25rem; margin: 1re' &
        //'m 0 .3rem; color: var(--muted);'//NL//'  font-size: .72rem; letter-spacing: .06em; text-transform: uppercase;' &
        //' font-weight: 650; }'//NL//'aside.side h4 a { flex: 1 1 auto; }'//NL//'aside.side ul { list-style: none; marg' &
        //'in: 0; padding: 0; }'//NL//'aside.side li a { display: block; padding: .12rem .5rem; margin-left: -.5rem; bor' &
        //'der-radius: 5px; color: var(--text);'//NL//'  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;' &
        //' }'//NL//'aside.side li a:hover { background: var(--bg-soft); text-decoration: none; }'//NL//'aside.side li a' &
        //'.more { color: var(--muted); }'//NL//'aside.side li a.current { background: var(--bg-soft); color: var(--acce' &
        //'nt); font-weight: 600; }'//NL//'/* folding: a section heading or a module group hides the list after it */'//NL &
        //'.fold { flex: none; width: 1.3rem; height: 1.3rem; padding: 0; border: 0; background: none; color: var(--mute' &
        //'d);'//NL//'  cursor: pointer; border-radius: 4px; font-size: .7rem; line-height: 1; transition: transform .12' &
        //'s; }'//NL//'.fold:hover { background: var(--bg-soft); color: var(--text); }'//NL//'.folded > .fold, h4.folded' &
        //' .fold { transform: rotate(-90deg); }'//NL//'h4.folded + ul { display: none; }'//NL//'li.group > ul { display' &
        //': none; padding-left: .7rem; border-left: 1px solid var(--line); margin: .1rem 0 .3rem .55rem; }'//NL//'li.gr' &
        //'oup.open > ul { display: block; }'//NL//'li.group > .group-name { display: flex; align-items: center; gap: .2' &
        //'rem; width: 100%; margin-left: -.5rem;'//NL//'  padding: .12rem .5rem .12rem .2rem; border: 0; border-radius:')
    call add(b, &
        ' 5px; background: none; color: var(--text);'//NL//'  font: inherit; text-align: left; cursor: pointer; }'//NL &
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
        //'-left: 1px solid var(--line); }'//NL//'nav.toc li a { display: block; padding: .15rem 0 .15rem .8rem; margin-' &
        //'left: -1px; border-left: 2px solid transparent;'//NL//'  color: var(--muted); overflow: hidden; text-overflow' &
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
        //' { margin: 0; }'//NL//'code, pre, .sig { font-family: var(--mono); font-size: .875em; }'//NL//'pre code { fon' &
        //'t-size: inherit; }'//NL//':not(pre) > code { background: var(--bg-code); padding: .1em .3em; border-radius: 4' &
        //'px; }'//NL//'pre, .sig { background: var(--bg-code); border: 1px solid var(--line); border-radius: 8px; paddi' &
        //'ng: .7rem .9rem;'//NL//'  overflow-x: auto; line-height: 1.5; }'//NL//'.codehilite { position: relative; marg' &
        //'in: 1rem 0; }'//NL//'.codehilite pre { margin: 0; }'//NL//'.copy { position: absolute; top: .4rem; right: .4r' &
        //'em; opacity: 0; background: var(--bg); color: var(--muted);'//NL//'  border: 1px solid var(--line); border-ra' &
        //'dius: 5px; font-size: .72rem; padding: .1rem .4rem; cursor: pointer; }'//NL//'.codehilite:hover .copy { opaci' &
        //'ty: 1; }'//NL//'.sig { margin: .4rem 0 .7rem; white-space: pre-wrap; overflow-wrap: anywhere; }'//NL//'.k { c' &
        //'olor: var(--k); } .s { color: var(--s); } .c { color: var(--c); font-style: italic; }'//NL//'.d { color: var(' &
        //'--d); } .n { color: var(--n); } .p { color: var(--p); }'//NL//'.item { padding: .9rem 0 1rem; border-top: 1px' &
        //' solid var(--line); }'//NL//'h2 + .item { border-top: 0; padding-top: 0; }'//NL//'.item > h3 { margin: 0 0 .2' &
        //'rem; font-size: 1rem; font-family: var(--mono); overflow-wrap: anywhere; }'//NL//'.badge { display: inline-bl' &
        //'ock; font: 600 .68rem/1.5 var(--sans); padding: 0 .4rem; margin-left: .4rem; border-radius: 4px;'//NL//'  bac' &
        //'kground: var(--bg-soft); color: var(--muted); border: 1px solid var(--line); vertical-align: middle; }'//NL//'t' &
        //'able { border-collapse: collapse; width: 100%; font-size: .92rem; margin: .7rem 0 1rem; }'//NL//'th { text-al' &
        //'ign: left; font-weight: 600; color: var(--muted); }'//NL//'/* headings stay under the bar at the top; a stick' &
        //'y cell loses a collapsed border, so a shadow draws it */'//NL//'thead th { position: sticky; top: 3.5rem; z-i' &
        //'ndex: 1; background: var(--bg); box-shadow: inset 0 -1px 0 var(--line); }'//NL//'tr[id] { scroll-margin-top: ' &
        //'2.5rem; }'//NL//'.listing td:last-child, .arguments td { overflow-wrap: anywhere; }'//NL//'th, td { padding: ' &
        //'.35rem .7rem .35rem 0; border-bottom: 1px solid var(--line); vertical-align: top; }'//NL//'td p { margin: 0; ' &
        //'} td.type { font-family: var(--mono); font-size: .84em; width: 30%; overflow-wrap: break-word; }'//NL//'td.na' &
        //'me { font-family: var(--mono); font-size: .88em; width: 24%; overflow-wrap: break-word; }'//NL//'.doc table {' &
        //' display: block; overflow-x: auto; }'//NL//'.alert { border-left: 3px solid var(--accent); background: var(--' &
        //'bg-soft); border-radius: 0 6px 6px 0;'//NL//'  padding: .55rem .9rem; margin: 1rem 0; }'//NL//'.alert p { mar' &
        //'gin: .3rem 0; } .alert-title { font-weight: 650; font-size: .9rem; }'//NL//'.alert-warning { border-color: va' &
        //'r(--warn); } .alert-success { border-color: var(--ok); }'//NL//'.alert-danger { border-color: var(--bad); } .' &
        //'alert-history { border-color: var(--hist); }'//NL//'blockquote { margin: 1rem 0; padding: 0 1rem; color: var(' &
        //'--muted); border-left: 3px solid var(--line); }'//NL//'img { max-width: 100%; }'//NL//'details.specifics { ma' &
        //'rgin: .5rem 0 1rem; } details.specifics summary { cursor: pointer; color: var(--muted); font-size: .9rem; }'//NL &
        //'details.specifics .item:first-of-type { border-top: 0; }'//NL//'.form { margin: 1rem 0 1.6rem; } .form .sig {' &
        //' margin-bottom: .4rem; }'//NL//'table.forms { width: auto; margin: .4rem 0 .5rem; } table.forms td.type, tabl' &
        //'e.forms td.name { width: auto; min-width: 5.5rem; overflow-wrap: anywhere; }'//NL//'table.forms td.rank, tabl' &
        //'e.forms th.rank { text-align: center; padding-right: 1rem; white-space: nowrap; }'//NL//'table.forms td.rank ' &
        //'a { text-decoration: none; }'//NL//'.fixed { color: var(--muted); font-size: .88rem; margin: .2rem 0 0; }'//NL &
        //'pre.mermaid { background: none; border: 0; padding: 0; margin: 1rem 0; text-align: center; }'//NL//'details.s' &
        //'ource { margin: 1rem 0; } details.source summary { cursor: pointer; color: var(--muted); font-size: .9rem; }'//NL &
        //'.chips { display: flex; flex-wrap: wrap; gap: .35rem; padding: 0; list-style: none; margin: .5rem 0 1rem; }'//NL &
        //'.chips li { font-family: var(--mono); font-size: .82rem; background: var(--bg-soft); border: 1px solid var(--' &
        //'line);'//NL//'  border-radius: 5px; padding: 0 .45rem; }'//NL//'.listing td:first-child { font-family: var(--' &
        //'mono); font-size: .9em; white-space: nowrap; }'//NL//'.listing td p { margin: 0; }'//NL//'.listing .num { tex' &
        //'t-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; padding-left: 0; padding-right: .55r' &
        //'em; }'//NL//'.listing tfoot td { font-weight: 600; border-bottom: 0; border-top: 2px solid var(--line); }'//NL &
        //'.layout:has(table.sortable), .inner:has(table.sortable) { max-width: none; }'//NL//'.sortable th { cursor: po' &
        //'inter; user-select: none; }'//NL//'/* a table that scrolls by itself cannot stick to the window, and would mo' &
        //'ve its headings down instead */'//NL//'.doc thead th { position: static; }'//NL//'@media (max-width: 1099px) ' &
        //'{ .sortable { display: block; overflow-x: auto; } .sortable thead th { position: static; } }'//NL//'.sortable' &
        //' th[aria-sort="ascending"]::after { content: " \25B2"; font-size: .7em; }'//NL//'.sortable th[aria-sort="desc' &
        //'ending"]::after { content: " \25BC"; font-size: .7em; }'//NL//'.hero { background: var(--bg-soft); border: 1p' &
        //'x solid var(--line); border-radius: 10px; padding: .9rem 1.2rem 1rem;'//NL//'  margin-bottom: 1.4rem; }'//NL//'.' &
        //'hero { position: relative; }'//NL//'.hero h1 { margin-right: 10rem; }'//NL//'.hero .meta { margin-bottom: .4r' &
        //'em; align-items: center; }'//NL//'.hero.with-logo { padding-left: 7rem; min-height: 6.2rem; }'//NL//'.hero-lo' &
        //'go { position: absolute; left: 1.2rem; top: .9rem; width: 4.8rem; height: 4.8rem; object-fit: contain; }'//NL &
        //'.project-links { position: absolute; top: 1.1rem; right: 1.2rem; display: flex; gap: .55rem; }'//NL//'.author' &
        //'-links { display: inline-flex; gap: .45rem; align-items: center; }'//NL//'.author-links:empty, .project-links' &
        //':empty { display: none; }'//NL//'.icon-link { display: inline-block; width: 1.1rem; height: 1.1rem; backgroun' &
        //'d: var(--muted);'//NL//'  -webkit-mask: var(--i) center / contain no-repeat; mask: var(--i) center / contain ' &
        //'no-repeat; }'//NL//'.project-links .icon-link { width: 1.35rem; height: 1.35rem; }'//NL//'.icon-link:hover { ')
    call add(b, &
        'background: var(--accent); }'//NL//'.grid { display: flex; flex-wrap: wrap; gap: .4rem; margin: .5rem 0 0; }'//NL &
        //'.card { background: var(--bg); }'//NL//'.card { border: 1px solid var(--line); border-radius: 999px; padding:' &
        //' .05rem .65rem; color: var(--text); font-size: .84rem; white-space: nowrap; }'//NL//'.card:hover { border-col' &
        //'or: var(--accent); text-decoration: none; }'//NL//'.card b { margin-right: .3rem; font-weight: 650; } .card s' &
        //'pan { color: var(--muted); }'//NL//'pre.source { padding-left: 0; counter-reset: line; line-height: 1.45; }'//NL &
        //'.ln { display: inline-block; width: 3.6em; margin-right: 1em; text-align: right; color: var(--muted); opacity' &
        //': .6; user-select: none; }'//NL//'.ln::before { counter-increment: line; content: counter(line); }'//NL//'.ln' &
        //':target { color: var(--accent); opacity: 1; font-weight: 700; }'//NL//'footer { margin-top: 3rem; padding-top' &
        //': 1rem; border-top: 1px solid var(--line); color: var(--muted); font-size: .84rem; }'//NL//'@media (max-width' &
        //': 860px) {'//NL//'  /* on a phone the sidebar is a drawer, opened from the button at the left of the header *' &
        //'/'//NL//'  .layout, .side-hidden .layout { grid-template-columns: minmax(0, 1fr); }'//NL//'  aside.side, .sid' &
        //'e-hidden aside.side { display: block; position: fixed; top: 3.5rem; bottom: 0; left: 0; z-index: 20;'//NL//' ' &
        //'   width: min(85vw, 20rem); height: calc(100vh - 3.5rem); align-self: auto; background: var(--bg);'//NL//'   ' &
        //' transform: translateX(-102%);'//NL//'    transition: transform .2s ease; box-shadow: 0 0 24px rgba(0, 0, 0, ' &
        //'.25); }'//NL//'  .side-open aside.side { transform: none; }'//NL//'  .side-open .side-backdrop { display: blo' &
        //'ck; position: fixed; inset: 3.5rem 0 0 0; z-index: 19;'//NL//'    background: rgba(0, 0, 0, .35); }'//NL//'  ' &
        //'.side-resize { display: none; }'//NL//'  header.top { gap: .6rem; padding: 0 .75rem; }'//NL//'  .search { fle' &
        //'x: 0 1 9rem; min-width: 6rem; }'//NL//'  .theme { max-width: 6.5rem; }'//NL//'  main { padding: 1.25rem 1rem ' &
        //'3rem; }'//NL//'}'//NL//'@media print { header.top, aside.side, nav.toc, .side-resize, .theme, .copy { display' &
        //': none; } .layout { display: block; } }'//NL//'.search { position: relative; flex: 0 1 15rem; }'//NL//'.searc' &
        //'h input { width: 100%; height: 2rem; padding: 0 .6rem; color: var(--text); background: var(--bg-soft);'//NL//' ' &
        //' border: 1px solid var(--line); border-radius: 6px; font: inherit; font-size: .88rem; }'//NL//'.search input:' &
        //'focus { outline: 2px solid var(--accent); outline-offset: -1px; }'//NL//'.search .results { display: none; po' &
        //'sition: absolute; top: 2.4rem; right: 0; width: min(30rem, 90vw); max-height: 70vh;'//NL//'  overflow-y: auto' &
        //'; background: var(--bg); border: 1px solid var(--line); border-radius: 8px;'//NL//'  box-shadow: 0 8px 24px r' &
        //'gba(0, 0, 0, .18); }'//NL//'.results a, .search-page a { display: block; padding: .45rem .7rem; color: var(--' &
        //'text); border-bottom: 1px solid var(--line); }'//NL//'.results a:hover, .results a.on, .search-page a:hover {' &
        //' background: var(--accent-soft); text-decoration: none; }'//NL//'.results b, .search-page b { font-family: va' &
        //'r(--mono); font-size: .88rem; font-weight: 600; }'//NL//'.results small, .search-page small { display: block;' &
        //' color: var(--muted); }'//NL//'aside.side.tree { padding-top: 1.25rem; padding-bottom: 2rem; }'//NL//'aside.t' &
        //'ree ul ul { margin-left: .8rem; }'//NL//'.graph { position: relative; overflow: auto; max-height: 34rem; marg' &
        //'in: .4rem 0 1rem; padding: .5rem;'//NL//'  border: 1px solid var(--line); border-radius: 8px; background: var' &
        //'(--bg-soft); cursor: grab; }'//NL//'.graph.dragging { cursor: grabbing; user-select: none; }'//NL//'.graph sv' &
        //'g { display: block; max-width: 100%; height: auto; margin: 0 auto; }'//NL//'.graph.zoomed svg { max-width: no' &
        //'ne; }'//NL//'.graph .zoom { position: sticky; top: 0; left: 0; float: right; z-index: 2; }'//NL//'.graph .zoo' &
        //'m button { background: var(--bg); color: var(--muted); border: 1px solid var(--line); border-radius: 5px;'//NL &
        //'  width: 1.6rem; height: 1.6rem; cursor: pointer; margin-left: .2rem; }'//NL//'.arguments td.name, .arguments' &
        //' td.type { width: auto; }'//NL//'td.attributes { font-family: var(--mono); font-size: .84em; }'//NL//'td.defa' &
        //'ult { font-family: var(--mono); font-size: .84em; min-width: 11rem; max-width: 15rem; overflow-wrap: anywhere' &
        //'; }'//NL//'@media (min-width: 1100px) {'//NL//'  .arguments td.name { white-space: nowrap; }'//NL//'  .argume' &
        //'nts td:last-child { min-width: 12rem; }'//NL//'  .inner:has(.arguments) { max-width: 72rem; }'//NL//'  .inner' &
        //':has(.arguments) > .doc, .inner:has(.arguments) > .sig { max-width: 54rem; }'//NL//'}'//NL//'.attr { --h: 220' &
        //'; --s: 12%; display: inline-block; margin: 0 .25rem .15rem 0; padding: 0 .4rem; border-radius: 4px;'//NL//'  ' &
        //'font: 600 .74rem/1.55 var(--mono); color: hsl(var(--h), var(--s), var(--attr-l));'//NL//'  background: hsla(v' &
        //'ar(--h), var(--s), var(--attr-l), .12); border: 1px solid hsla(var(--h), var(--s), var(--attr-l), .35); }'//NL &
        //'.attr-in, .attr-out, .attr-inout, .attr-optional, .attr-pointer, .attr-allocatable, .attr-value, .attr-target' &
        //','//NL//'.attr-dimension, .attr-contiguous, .attr-volatile, .attr-asynchronous, .attr-save, .attr-parameter,'//NL &
        //'.attr-protected, .attr-codimension, .attr-private, .attr-generic, .attr-deferred, .attr-nopass, .attr-pass,'//NL &
        //'.attr-non, .attr-deprecated, .attr-subroutine, .attr-function, .attr-interface { --s: 62%; }'//NL//'.attr-in ' &
        //'{ --h: 210; } .attr-out { --h: 25; } .attr-inout { --h: 275; }'//NL//'.attr-optional { --h: 180; } .attr-poin' &
        //'ter { --h: 0; } .attr-allocatable { --h: 125; } .attr-value { --h: 45; }'//NL//'.attr-target { --h: 325; } .a' &
        //'ttr-dimension { --h: 85; } .attr-contiguous { --h: 150; } .attr-volatile { --h: 345; }'//NL//'.attr-asynchron' &
        //'ous { --h: 300; } .attr-save { --h: 60; } .attr-parameter { --h: 195; } .attr-protected { --h: 240; }'//NL//'.' &
        //'attr-codimension { --h: 105; }'//NL//'.graph text { stroke: none; }'//NL//'/* the graphs are drawn with fixed' &
        //' colours, the ones of fdoc_graphs.f90: these give each the colour of the theme */'//NL//'.graph [fill="#3657c' &
        //'9"] { fill: var(--kind-module); } .graph [stroke="#3657c9"] { stroke: var(--kind-module); }'//NL//'.graph [fi' &
        //'ll="#5a78de"] { fill: var(--kind-submodule); } .graph [stroke="#5a78de"] { stroke: var(--kind-submodule); }'//NL &
        //'.graph [fill="#a61e69"] { fill: var(--kind-program); } .graph [stroke="#a61e69"] { stroke: var(--kind-program' &
        //'); }'//NL//'.graph [fill="#1d7a55"] { fill: var(--kind-subroutine); } .graph [stroke="#1d7a55"] { stroke: var' &
        //'(--kind-subroutine); }'//NL//'.graph [fill="#0b7285"] { fill: var(--kind-function); } .graph [stroke="#0b7285' &
        //'"] { stroke: var(--kind-function); }'//NL//'.graph [fill="#6a4fb3"] { fill: var(--kind-interface); } .graph [' &
        //'stroke="#6a4fb3"] { stroke: var(--kind-interface); }'//NL//'.graph [fill="#a15c00"] { fill: var(--kind-type);' &
        //' } .graph [stroke="#a15c00"] { stroke: var(--kind-type); }'//NL//'.graph [fill="#7a6a2d"] { fill: var(--kind-' &
        //'binding); } .graph [stroke="#7a6a2d"] { stroke: var(--kind-binding); }'//NL//'.graph [fill="#5c6f2d"] { fill:' &
        //' var(--kind-file); } .graph [stroke="#5c6f2d"] { stroke: var(--kind-file); }'//NL//'.graph [fill="#646d7e"] {' &
        //' fill: var(--kind-other); } .graph [stroke="#646d7e"] { stroke: var(--kind-other); }'//NL//'.graph [fill="#8a' &
        //'93a5"] { fill: var(--kind-undoc); } .graph [stroke="#8a93a5"] { stroke: var(--kind-undoc); }'//NL//'.graph [f' &
        //'ill="#b3261e"] { fill: var(--kind-red); } .graph [stroke="#b3261e"] { stroke: var(--kind-red); }'//NL//'.grap' &
        //'h [fill="#f0a868"] { fill: var(--kind-here); } .graph [stroke="#f0a868"] { stroke: var(--kind-here); }'//NL//'.' &
        //'graph a[fill="white"] { fill: var(--kind-ink); }'//NL//'.graph-key { display: flex; flex-wrap: wrap; gap: .25' &
        //'rem 1rem; margin: -.6rem 0 1rem; padding: .4rem .6rem;'//NL//'  color: var(--muted); font-size: .84rem; }'//NL &
        //'.graph-key[hidden] { display: none; }'//NL//'.graph-key-item { display: inline-flex; align-items: center; gap' &
        //': .4rem; }'//NL//'.graph-key-mark { display: inline-block; width: 1.1rem; height: .8rem; border-radius: 3px; ' &
        //'}'//NL//'.attr-private { --h: 15; --s: 40%; }'//NL//'.attr-generic { --h: 265; } .attr-deferred { --h: 35; } ' &
        //'.attr-nopass { --h: 200; } .attr-pass { --h: 160; }'//NL//'.attr-non { --h: 55; } .attr-deprecated { --h: 355' &
        //'; } .attr-subroutine { --h: 155; } .attr-function { --h: 188; }'//NL//'.attr-interface { --h: 258; }'//NL//'.' &
        //'attr-pure, .attr-impure, .attr-elemental, .attr-recursive, .attr-bind, .attr-saved, .attr-common { --s: 62%; ' &
        //'}'//NL//'.attr-pure { --h: 140; } .attr-impure { --h: 20; } .attr-elemental { --h: 170; } .attr-recursive { -' &
        //'-h: 290; }'//NL//'.attr-bind { --h: 230; } .attr-saved { --h: 40; } .attr-common { --h: 5; }'//NL//'.intent {' &
        //' color: hsl(var(--h), var(--s), var(--attr-l)); }'//NL//'td.binds { font-family: var(--mono); font-size: .84e' &
        //'m; overflow-wrap: break-word; max-width: 20rem; }'//NL//'.listing th { white-space: nowrap; }'//NL//'.listing' &
        //' td.link { font-family: var(--mono); font-size: .84em; overflow-wrap: break-word; }'//NL//'.item h3 .attr, h1' &
        //' .attr { margin-left: .5rem; vertical-align: middle; }'//NL//'.chips.kinds li { display: inline-flex; align-i' &
        //'tems: center; padding-left: .2rem; border-color: var(--kind);'//NL//'  background: color-mix(in srgb, var(--k' &
        //'ind) 14%, transparent); }'//NL//'.chips.kinds .ico { margin-right: .3rem; }'//NL//'.ico { --kind: var(--kind-' &
        //'other); background: var(--kind); display: inline-block; width: 1.05rem; height: 1.05rem; margin-right: .4rem;' &
        //' border-radius: 3px; color: var(--kind-ink);'//NL//'  font: 700 .68rem/1.05rem var(--sans); text-align: cente' &
        //'r; vertical-align: .05rem; }'//NL//'.ico-m { --kind: var(--kind-module); } .ico-p { --kind: var(--kind-progra' &
        //'m); } .ico-s { --kind: var(--kind-subroutine); }'//NL//'.ico-f { --kind: var(--kind-function); } .ico-i { --k' &
        //'ind: var(--kind-interface); } .ico-a { --kind: var(--kind-absint); }'//NL//'.ico-t { --kind: var(--kind-type)' &
        //'; } .ico-b { --kind: var(--kind-binding); } .ico-v { --kind: var(--kind-other); }'//NL//'.ico-n { --kind: var' &
        //'(--kind-file); } .ico-d { --kind: var(--kind-blockdata); } .ico-_ { --kind: var(--kind-file); }'//NL//'.icon-' &
        //'github { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path f' &
        //'ill-rule=''evenodd'' d=''M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.' &
        //'01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 ' &
        //'1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.0' &
        //'8-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.0' &
        //'8 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.' &
        //'46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z''/></svg>"); }'//NL//'.icon-gitlab { --i: url("data:image/sv' &
        //'g+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd'' d=''M8 15 .')
    call add(b, &
        '9 9.8a.7.7 0 0 1-.3-.8L2.3 2c.1-.4.6-.4.7 0l1.9 4.4h6.2L13 2c.1-.4.6-.4.7 0L15.4 9a.7.7 0 0 1-.3.8z''/></svg>' &
        //'"); }'//NL//'.icon-bitbucket { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox' &
        //'=''0 0 16 16''><path fill-rule=''evenodd'' d=''M1.2 1.5a.5.5 0 0 0-.5.6l2 12.2a.7.7 0 0 0 .7.6h9.4a.5.5 0 0 0' &
        //' .5-.4l2-12.4a.5.5 0 0 0-.5-.6zm8.7 9H6.2l-.9-4.7h5.4z''/></svg>"); }'//NL//'.icon-sourceforge { --i: url("da' &
        //'ta:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd'' ' &
        //'d=''M8 .6.6 8 8 15.4 15.4 8zm0 2.9L12.5 8 8 12.5 3.5 8z''/><path d=''M8.7 4.6c.1 1.5 1.5 2 1.5 3.6 0 1.2-1 2.' &
        //'2-2.2 2.2S5.8 9.5 5.8 8.4c0-.8.5-1.2.7-1.9.4.4.6.7.7 1.1.5-.8 1-1.8 1.5-3z''/></svg>"); }'//NL//'.icon-websit' &
        //'e { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><g fill=''no' &
        //'ne'' stroke=''black'' stroke-width=''1.4''><circle cx=''8'' cy=''8'' r=''6.8''/><ellipse cx=''8'' cy=''8'' rx' &
        //'=''3'' ry=''6.8''/><path d=''M1.2 8h13.6M2.2 4.6h11.6M2.2 11.4h11.6''/></g></svg>"); }'//NL//'.icon-download ' &
        //'{ --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rul' &
        //'e=''evenodd'' d=''M7.1 1h1.8v7l2.5-2.5 1.3 1.3L8 11.5 3.3 6.8l1.3-1.3L7.1 8zM2 13.2h12V15H2z''/></svg>"); }'//NL &
        //'.icon-email { --i: url("data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><g' &
        //' fill=''none'' stroke=''black'' stroke-width=''1.4''><rect x=''1'' y=''3'' width=''14'' height=''10'' rx=''1.' &
        //'4''/><path d=''m1.5 4 6.5 5 6.5-5''/></g></svg>"); }'//NL//'.icon-linkedin { --i: url("data:image/svg+xml,<sv' &
        //'g xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd'' d=''M2.2 1h11.6c.7 0' &
        //' 1.2.5 1.2 1.2v11.6c0 .7-.5 1.2-1.2 1.2H2.2c-.7 0-1.2-.5-1.2-1.2V2.2C1 1.5 1.5 1 2.2 1zM3.9 6.5v6.1h2V6.5zm1-' &
        //'3.1a1.1 1.1 0 1 0 0 2.3 1.1 1.1 0 0 0 0-2.3zm2.3 3.1v6.1h2V9.3c0-1 .5-1.5 1.2-1.5s1 .5 1 1.5v3.3h2V8.9c0-1.7-' &
        //'1-2.6-2.4-2.6-.9 0-1.5.4-1.8 1V6.5z''/></svg>"); }'//NL//'.icon-twitter { --i: url("data:image/svg+xml,<svg x' &
        //'mlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd'' d=''M12.1 1.5h2.3L9.3 7' &
        //'.3l6 7.2h-4.7L6.9 10l-4.2 4.5H.4L5.8 8.3.1 1.5h4.8l3.3 4.1z''/></svg>"); }'//NL//'.icon-facebook { --i: url("' &
        //'data:image/svg+xml,<svg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16''><path fill-rule=''evenodd''' &
        //' d=''M8 .6a7.4 7.4 0 0 0-1.2 14.7V10.1H5V8h1.8V6.4c0-1.8 1.1-2.8 2.7-2.8.8 0 1.6.1 1.6.1v1.8h-.9c-.9 0-1.2.6-' &
        //'1.2 1.1V8h2l-.3 2.1H9v5.2A7.4 7.4 0 0 0 8 .6z''/></svg>"); }'//NL//'@media (max-width: 860px) { .project-link' &
        //'s { position: static; margin: .3rem 0; } .hero h1 { margin-right: 0; }'//NL//'  .hero.with-logo { padding-lef' &
        //'t: 4.6rem; } .hero-logo { left: .9rem; width: 2.8rem; height: 2.8rem; } }'//NL//'.anchor { margin-left: .4rem' &
        //'; color: var(--muted); font-weight: 400; text-decoration: none; opacity: 0; }'//NL//'h2:hover .anchor, h3:hov' &
        //'er .anchor, .anchor:focus { opacity: 1; }'//NL//'@media (hover: none) { .anchor { opacity: .5; } }'//NL//'nav' &
        //'.letters { display: flex; flex-wrap: wrap; gap: .25rem; margin: .4rem 0 1rem; }'//NL//'nav.letters a { min-wi' &
        //'dth: 1.7rem; padding: .1rem .35rem; text-align: center; border: 1px solid var(--line);'//NL//'  border-radius' &
        //': 5px; font-weight: 600; }'//NL//'ul.names { list-style: none; padding: 0; columns: 22rem; column-gap: 2rem; ' &
        //'margin: 0; }'//NL//'ul.names li { break-inside: avoid; padding: .12rem 0; }'//NL//'.where { color: var(--mute' &
        //'d); font-size: .84rem; }'//NL//'ul.tree { list-style: none; padding-left: 0; margin: .4rem 0 1rem; }'//NL//'u' &
        //'l.tree ul { list-style: none; padding-left: 1.4rem; margin: 0; border-left: 1px solid var(--line); }'//NL//'u' &
        //'l.tree li { padding: .12rem 0; }'//NL//'ul.tree details > summary { cursor: pointer; }'//NL//'ul.tree details' &
        //' > summary::marker { color: var(--muted); }'//NL//'ul.tree li:not(:has(details)) { padding-left: 1.05rem; }'//NL)
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
        //': keep the two the same'//NL//'    // the CSS gives each the colour of the theme, from the variable named thi' &
        //'rd'//NL//'    var COLOURS = [["#3657c9", "Module", "module"], ["#5a78de", "Submodule", "submodule"],'//NL//' ' &
        //'     ["#a61e69", "Program", "program"], ["#1d7a55", "Subroutine", "subroutine"], ["#0b7285", "Function", "fun' &
        //'ction"],'//NL//'      ["#6a4fb3", "Interface", "interface"], ["#a15c00", "Derived type", "type"],'//NL//'    ')
    call add(b, &
        '  ["#7a6a2d", "Type-bound procedure", "binding"], ["#5c6f2d", "Source file", "file"],'//NL//'      ["#646d7e"' &
        //', "External, or other", "other"], ["#8a93a5", "Not documented", "undoc"]];'//NL//NL//'    // a button that sh' &
        //'ows what is in this drawing, under it, as a short drawing can''t hold a popup'//NL//'    function addKey(box,' &
        //' svg, zoom) {'//NL//'      var key = document.createElement("div");'//NL//'      key.className = "graph-key";' &
        //NL//'      key.hidden = true;'//NL//'      function entry(mark, text) {'//NL//'        var item = document.cre' &
        //'ateElement("span");'//NL//'        item.className = "graph-key-item";'//NL//'        item.appendChild(mark);'//NL &
        //'        item.appendChild(document.createTextNode(text));'//NL//'        key.appendChild(item);'//NL//'      }' &
        //NL//'      function swatch(style) {'//NL//'        var mark = document.createElement("span");'//NL//'        m' &
        //'ark.className = "graph-key-mark";'//NL//'        Object.keys(style).forEach(function (name) { mark.style[name' &
        //'] = style[name]; });'//NL//'        return mark;'//NL//'      }'//NL//'      COLOURS.forEach(function (c) {'//NL &
        //'        if (svg.querySelector(''rect[fill="'' + c[0] + ''"], path[fill="'' + c[0] + ''"]'')) entry(swatch({ b' &
        //'ackground: "var(--kind-" + c[2] + ")" }), c[1]);'//NL//'      });'//NL//'      if (svg.querySelector(''rect[s' &
        //'troke="#f0a868"]'')) entry(swatch({ border: "2px solid var(--kind-here)" }), "This page");'//NL//'      if (s' &
        //'vg.querySelector("path[stroke-dasharray]")) {'//NL//'        entry(swatch({ height: "0", borderRadius: "0", b' &
        //'orderTop: "2px dashed var(--kind-undoc)" }), "Component of a type");'//NL//'      }'//NL//'      var button =' &
        //' document.createElement("button");'//NL//'      button.textContent = "?";'//NL//'      button.title = "Key to' &
        //' the colours";'//NL//'      button.setAttribute("aria-label", "Key to the colours");'//NL//'      button.setA' &
        //'ttribute("aria-expanded", "false");'//NL//'      button.addEventListener("click", function () {'//NL//'      ' &
        //'  key.hidden = !key.hidden;'//NL//'        button.setAttribute("aria-expanded", String(!key.hidden));'//NL//' ' &
        //'     });'//NL//'      zoom.appendChild(button);'//NL//'      box.parentNode.insertBefore(key, box.nextSibling' &
        //');'//NL//'    }'//NL//NL//'    document.querySelectorAll(".graph").forEach(function (box) {'//NL//'      var ' &
        //'svg = box.querySelector("svg");'//NL//'      if (!svg) return;'//NL//'      var width = svg.width.baseVal.val' &
        //'ue, height = svg.height.baseVal.value, scale = 1;'//NL//'      function set(value) {'//NL//'        scale = M' &
        //'ath.max(0.25, Math.min(6, value));'//NL//'        box.classList.add("zoomed");'//NL//'        svg.style.width' &
        //' = width * scale + "px";'//NL//'        svg.style.height = height * scale + "px";'//NL//'      }'//NL//'     ' &
        //' var zoom = document.createElement("div");'//NL//'      zoom.className = "zoom";'//NL//'      [["+", 1.3], ["' &
        //'\u2212", 1 / 1.3]].forEach(function (b) {'//NL//'        var button = document.createElement("button");'//NL//' ' &
        //'       button.textContent = b[0];'//NL//'        button.setAttribute("aria-label", b[1] > 1 ? "Zoom in" : "Zo' &
        //'om out");'//NL//'        button.addEventListener("click", function () { set(scale * b[1]); });'//NL//'       ' &
        //' zoom.appendChild(button);'//NL//'      });'//NL//'      box.insertBefore(zoom, svg);'//NL//'      addKey(box' &
        //', svg, zoom);'//NL//'      var fit = box.clientWidth / width;'//NL//'      if (fit > 0 && fit < 0.75) set(0.7' &
        //'5);'//NL//'      var start = null;'//NL//'      box.addEventListener("mousedown", function (event) {'//NL//' ' &
        //'       if (event.target.closest("a, button")) return;'//NL//'        start = [event.clientX, event.clientY, b' &
        //'ox.scrollLeft, box.scrollTop];'//NL//'        box.classList.add("dragging");'//NL//'      });'//NL//'      wi' &
        //'ndow.addEventListener("mousemove", function (event) {'//NL//'        if (!start) return;'//NL//'        box.s' &
        //'crollLeft = start[2] - (event.clientX - start[0]);'//NL//'        box.scrollTop = start[3] - (event.clientY -' &
        //' start[1]);'//NL//'      });'//NL//'      window.addEventListener("mouseup", function () { start = null; box.' &
        //'classList.remove("dragging"); });'//NL//'    });'//NL//'  });'//NL//'})();'//NL//NL//'// a link to something ' &
        //'inside a closed section opens the section'//NL//'function openTarget() {'//NL//'  var id = decodeURIComponent' &
        //'(location.hash.slice(1));'//NL//'  var target = id && document.getElementById(id);'//NL//'  var section = tar' &
        //'get && target.closest(''details'');'//NL//'  if (section) { section.open = true; target.scrollIntoView(); }'//NL &
        //'}'//NL//'window.addEventListener(''hashchange'', openTarget);'//NL//'window.addEventListener(''DOMContentLoad' &
        //'ed'', openTarget);'//NL//NL//'// clicking a heading of a sortable table sorts it by that column'//NL//'window' &
        //'.addEventListener(''DOMContentLoaded'', function () {'//NL//'  document.querySelectorAll(''table.sortable'').' &
        //'forEach(function (table) {'//NL//'    var headings = table.querySelectorAll(''thead th'');'//NL//'    heading' &
        //'s.forEach(function (th, column) {'//NL//'      th.addEventListener(''click'', function () {'//NL//'        va' &
        //'r body = table.tBodies[0];'//NL//'        var numeric = th.classList.contains(''num'');'//NL//'        var up' &
        //' = th.hasAttribute(''aria-sort'') ? th.getAttribute(''aria-sort'') === ''descending'' : !numeric;'//NL//'    ' &
        //'    var key = function (row) {'//NL//'          var cell = row.cells[column];'//NL//'          return numeric' &
        //' ? Number(cell.dataset.sort) : cell.textContent.toLowerCase();'//NL//'        };'//NL//'        var rows = Ar' &
        //'ray.prototype.slice.call(body.rows);'//NL//'        rows.sort(function (a, b) {'//NL//'          var x = key(' &
        //'a), y = key(b);'//NL//'          return (x < y ? -1 : x > y ? 1 : 0) * (up ? 1 : -1);'//NL//'        });'//NL &
        //'        rows.forEach(function (row) { body.appendChild(row); });'//NL//'        headings.forEach(function (ot' &
        //'her) { other.removeAttribute(''aria-sort''); });'//NL//'        th.setAttribute(''aria-sort'', up ? ''ascendi' &
        //'ng'' : ''descending'');'//NL//'      });'//NL//'    });'//NL//'  });'//NL//'});'//NL//NL//'// the left sideba' &
        //'r: the list of this page grouped by module, a filter, folding, resizing, hiding, a'//NL//'// drawer on phones' &
        //', and its scroll position kept from page to page'//NL//'(function () {'//NL//'  var script = document.current' &
        //'Script;'//NL//'  var root = script ? script.src.replace(/js\/fdoc\.js.*$/, "") : "";'//NL//'  var html = docu' &
        //'ment.documentElement;'//NL//'  var MIN = 180, MAX = 640;'//NL//NL//'  function load(key) { try { return local' &
        //'Storage.getItem(key); } catch (e) { return null; } }'//NL//'  function store(key, value) {'//NL//'    try { i' &
        //'f (value === null) localStorage.removeItem(key); else localStorage.setItem(key, value); } catch (e) {}'//NL//' ' &
        //' }'//NL//'  function loadSet(key) { try { return JSON.parse(load(key) || "[]"); } catch (e) { return []; } }'//NL &
        //'  function storeSet(key, set) { store(key, set.length ? JSON.stringify(set) : null); }'//NL//'  function togg' &
        //'leIn(set, item, on) {'//NL//'    var k = set.indexOf(item);'//NL//'    if (on && k < 0) set.push(item);'//NL//' ' &
        //'   if (!on && k >= 0) set.splice(k, 1);'//NL//'  }'//NL//NL//'  // before the page is drawn, so that it doesn' &
        //'''t jump'//NL//'  var width = parseInt(load("fdoc-side-w"), 10);'//NL//'  if (width >= MIN && width <= MAX) h' &
        //'tml.style.setProperty("--side-w", width + "px");'//NL//'  if (load("fdoc-side-hidden") === "1") html.classLis' &
        //'t.add("side-hidden");'//NL//NL//'  function phone() { return window.matchMedia("(max-width: 860px)").matches;' &
        //' }'//NL//NL//'  // the arrow of a fold: a button on a heading, or a plain mark inside the button of a group'//NL &
        //'  function foldButton(mark) {'//NL//'    var b = document.createElement(mark ? "span" : "button");'//NL//'   ' &
        //' b.className = "fold";'//NL//'    if (!mark) b.type = "button";'//NL//'    b.innerHTML = "&#9662;";'//NL//'  ' &
        //'  return b;'//NL//'  }'//NL//NL//'  // put the entries of `list` under a group for each module, sorted by nam' &
        //'e'//NL//'  function group(list, key) {'//NL//'    var items = Array.prototype.slice.call(list.children), grou' &
        //'ps = {}, names = [];'//NL//'    items.forEach(function (li) {'//NL//'      var a = li.querySelector("a"), m =' &
        //' a ? a.getAttribute("data-m") : null;'//NL//'      if (m === null) return;'//NL//'      if (!groups[m]) { gro' &
        //'ups[m] = []; names.push(m); }'//NL//'      groups[m].push(li);'//NL//'    });'//NL//'    if (names.length < 2' &
        //') return;'//NL//'    names.sort(function (x, y) { return x.toLowerCase() < y.toLowerCase() ? -1 : x.toLowerCa' &
        //'se() > y.toLowerCase() ? 1 : 0; });'//NL//'    var open = loadSet("fdoc-open-groups");'//NL//'    list.textCo' &
        //'ntent = "";'//NL//'    names.forEach(function (m) {'//NL//'      var li = document.createElement("li"), head ' &
        //'= document.createElement("button"), ul = document.createElement("ul");'//NL//'      li.className = "group";'//NL &
        //'      li.dataset.group = key + ":" + m;'//NL//'      head.className = "group-name";'//NL//'      head.type = ' &
        //'"button";'//NL//'      head.appendChild(foldButton(true));'//NL//'      var label = document.createElement("s' &
        //'pan");'//NL//'      label.className = "label";'//NL//'      label.textContent = m || "(no module)";'//NL//'  ' &
        //'    head.title = label.textContent;'//NL//'      head.appendChild(label);'//NL//'      var n = document.creat' &
        //'eElement("span");'//NL//'      n.className = "n";'//NL//'      n.textContent = groups[m].length;'//NL//'     ' &
        //' head.appendChild(n);'//NL//'      groups[m].forEach(function (item) { ul.appendChild(item); });'//NL//'     ' &
        //' li.appendChild(head);'//NL//'      li.appendChild(ul);'//NL//'      if (open.indexOf(li.dataset.group) >= 0)' &
        //' li.classList.add("open");'//NL//'      head.addEventListener("click", function () {'//NL//'        var on = ' &
        //'li.classList.toggle("open");'//NL//'        var set = loadSet("fdoc-open-groups");'//NL//'        toggleIn(se' &
        //'t, li.dataset.group, on);'//NL//'        storeSet("fdoc-open-groups", set);'//NL//'      });'//NL//'      lis' &
        //'t.appendChild(li);'//NL//'    });'//NL//'  }'//NL//NL//'  // a fold button on each heading with a list after ' &
        //'it; the folded ones are remembered'//NL//'  function folding(side) {'//NL//'    var folded = loadSet("fdoc-fo' &
        //'lded");'//NL//'    side.querySelectorAll("h4").forEach(function (h) {'//NL//'      var ul = h.nextElementSibl' &
        //'ing;'//NL//'      if (!ul || ul.tagName !== "UL" || !ul.children.length) return;'//NL//'      var name = h.te' &
        //'xtContent.trim(), b = foldButton(false);'//NL//'      b.title = "Fold or unfold " + name;'//NL//'      h.inse' &
        //'rtBefore(b, h.firstChild);'//NL//'      if (folded.indexOf(name) >= 0) h.classList.add("folded");'//NL//'    ' &
        //'  b.addEventListener("click", function () {'//NL//'        var on = h.classList.toggle("folded"), set = loadS' &
        //'et("fdoc-folded");'//NL//'        toggleIn(set, name, on);'//NL//'        storeSet("fdoc-folded", set);'//NL//' ' &
        //'     });'//NL//'    });'//NL//'  }'//NL//NL//'  // the filter box at the top of the sidebar: it shows the ent' &
        //'ries whose names contain what is typed'//NL//'  function filter(side) {'//NL//'    var links = side.querySele')
    call add(b, &
        'ctorAll("li > a");'//NL//'    if (links.length < 8) return;'//NL//'    var box = document.createElement("div"' &
        //'), input = document.createElement("input");'//NL//'    var empty = document.createElement("div");'//NL//'    ' &
        //'box.className = "side-filter";'//NL//'    input.type = "search";'//NL//'    input.placeholder = "Filter…";'//NL &
        //'    input.setAttribute("aria-label", "Filter the sidebar");'//NL//'    empty.className = "side-empty";'//NL//' ' &
        //'   empty.textContent = "Nothing matches";'//NL//'    empty.hidden = true;'//NL//'    box.appendChild(input);'//NL &
        //'    side.insertBefore(box, side.firstChild);'//NL//'    side.appendChild(empty);'//NL//'    var names = Array' &
        //'.prototype.map.call(links, function (a) { return (a.dataset.name || a.textContent).toLowerCase(); });'//NL//NL &
        //'    function run() {'//NL//'      var q = input.value.trim().toLowerCase(), any = false;'//NL//'      side.cl' &
        //'assList.toggle("filtering", q.length > 0);'//NL//'      links.forEach(function (a, k) {'//NL//'        var sh' &
        //'ow = !q || names[k].indexOf(q) >= 0;'//NL//'        a.parentElement.hidden = !show;'//NL//'        any = any ' &
        //'|| show;'//NL//'      });'//NL//'      side.querySelectorAll("li.group").forEach(function (g) {'//NL//'      ' &
        //'  g.hidden = q && !g.querySelector("li:not([hidden])");'//NL//'        g.classList.toggle("found", !!q && !g.' &
        //'hidden);'//NL//'      });'//NL//'      side.querySelectorAll("h4").forEach(function (h) {'//NL//'        var ' &
        //'ul = h.nextElementSibling;'//NL//'        h.hidden = q && !(ul && ul.tagName === "UL" && ul.querySelector("li' &
        //':not([hidden])"));'//NL//'        if (ul && ul.tagName === "UL") ul.hidden = h.hidden;'//NL//'      });'//NL//' ' &
        //'     empty.hidden = !q || any;'//NL//'      if (q) side.scrollTop = 0;'//NL//'    }'//NL//'    input.addEvent' &
        //'Listener("input", run);'//NL//'    input.addEventListener("keydown", function (event) {'//NL//'      if (even' &
        //'t.key === "Escape") { input.value = ""; run(); input.blur(); }'//NL//'    });'//NL//'  }'//NL//NL//'  // drag' &
        //' the edge of the sidebar to resize it; a double click goes back to the default width'//NL//'  function resizi' &
        //'ng(side) {'//NL//'    var handle = document.createElement("div");'//NL//'    handle.className = "side-resize"' &
        //';'//NL//'    handle.title = "Drag to resize, double-click to reset";'//NL//'    document.body.appendChild(han' &
        //'dle);'//NL//'    function place() { handle.style.left = side.getBoundingClientRect().right + "px"; }'//NL//' ' &
        //'   place();'//NL//'    window.addEventListener("resize", place);'//NL//'    handle.addEventListener("pointerd' &
        //'own", function (event) {'//NL//'      event.preventDefault();'//NL//'      handle.setPointerCapture(event.poi' &
        //'nterId);'//NL//'      handle.classList.add("dragging");'//NL//'      var left = side.getBoundingClientRect().' &
        //'left;'//NL//'      function move(e) {'//NL//'        var w = Math.max(MIN, Math.min(MAX, Math.round(e.clientX' &
        //' - left)));'//NL//'        html.style.setProperty("--side-w", w + "px");'//NL//'        place();'//NL//'     ' &
        //' }'//NL//'      function up() {'//NL//'        handle.classList.remove("dragging");'//NL//'        handle.rem' &
        //'oveEventListener("pointermove", move);'//NL//'        handle.removeEventListener("pointerup", up);'//NL//'   ' &
        //'     store("fdoc-side-w", String(Math.round(side.getBoundingClientRect().width)));'//NL//'      }'//NL//'    ' &
        //'  handle.addEventListener("pointermove", move);'//NL//'      handle.addEventListener("pointerup", up);'//NL//' ' &
        //'   });'//NL//'    handle.addEventListener("dblclick", function () {'//NL//'      html.style.removeProperty("-' &
        //'-side-w");'//NL//'      store("fdoc-side-w", null);'//NL//'      place();'//NL//'    });'//NL//'    return pl' &
        //'ace;'//NL//'  }'//NL//NL//'  document.addEventListener("DOMContentLoaded", function () {'//NL//'    var side ' &
        //'= document.querySelector("aside.side"), toggle = document.querySelector(".side-toggle");'//NL//'    if (!side' &
        //') {'//NL//'      if (toggle) toggle.hidden = true;'//NL//'      return;'//NL//'    }'//NL//'    var list = si' &
        //'de.querySelector("ul[data-list]"), key = list ? list.dataset.list : "";'//NL//'    if (list && window.FDOC_SI' &
        //'DEBAR) {'//NL//'      list.innerHTML = (window.FDOC_SIDEBAR[key] || "").replace(/href="@/g, ''href="'' + root' &
        //');'//NL//'    }'//NL//'    // the full name, and the module, as the tooltip of each entry'//NL//'    side.que' &
        //'rySelectorAll("li > a").forEach(function (a) {'//NL//'      var name = a.textContent.trim(), m = a.getAttribu' &
        //'te("data-m");'//NL//'      a.dataset.name = name;'//NL//'      a.title = m ? name + " — " + m : name;'//NL//' ' &
        //'   });'//NL//'    if (list) group(list, key);'//NL//NL//'    var here = location.href.split("#")[0], current ' &
        //'= null;'//NL//'    side.querySelectorAll("li > a").forEach(function (a) {'//NL//'      if (current || a.href ' &
        //'!== here) return;'//NL//'      current = a;'//NL//'      a.classList.add("current");'//NL//'      a.setAttrib' &
        //'ute("aria-current", "page");'//NL//'      var g = a.closest("li.group");'//NL//'      if (g) g.classList.add(' &
        //'"open", "here");'//NL//'    });'//NL//'    folding(side);'//NL//'    filter(side);'//NL//'    var place = res' &
        //'izing(side);'//NL//NL//'    // the sidebar opens where it was left when one of its links was followed'//NL//' ' &
        //'   var saved = null;'//NL//'    try { saved = JSON.parse(sessionStorage.getItem("fdoc-side-scroll") || "null"' &
        //'); } catch (e) {}'//NL//'    try { sessionStorage.removeItem("fdoc-side-scroll"); } catch (e) {}'//NL//'    i' &
        //'f (saved && saved.list === key) side.scrollTop = saved.top;'//NL//'    else if (current) side.scrollTop = cur' &
        //'rent.offsetTop - side.clientHeight / 2;'//NL//'    side.addEventListener("click", function (event) {'//NL//' ' &
        //'     if (!event.target.closest("a")) return;'//NL//'      try { sessionStorage.setItem("fdoc-side-scroll", JS' &
        //'ON.stringify({ list: key, top: side.scrollTop })); } catch (e) {}'//NL//'      html.classList.remove("side-op' &
        //'en");'//NL//'    });'//NL//NL//'    // the button at the left of the header hides the sidebar, or on a phone ' &
        //'opens it as a drawer'//NL//'    var backdrop = document.createElement("div");'//NL//'    backdrop.className =' &
        //' "side-backdrop";'//NL//'    document.body.appendChild(backdrop);'//NL//'    backdrop.addEventListener("click' &
        //'", function () { html.classList.remove("side-open"); });'//NL//'    document.addEventListener("keydown", func' &
        //'tion (event) {'//NL//'      if (event.key === "Escape") html.classList.remove("side-open");'//NL//'    });'//NL &
        //'    if (toggle) toggle.addEventListener("click", function () {'//NL//'      if (phone()) {'//NL//'        htm' &
        //'l.classList.toggle("side-open");'//NL//'        return;'//NL//'      }'//NL//'      var hidden = html.classLi' &
        //'st.toggle("side-hidden");'//NL//'      store("fdoc-side-hidden", hidden ? "1" : null);'//NL//'      place();'//NL &
        //'    });'//NL//'  });'//NL//'})();'//NL//NL//'// the contents of the page, at the right on wide screens, with ' &
        //'the section being read marked'//NL//'document.addEventListener("DOMContentLoaded", function () {'//NL//'  var' &
        //' main = document.querySelector("main"), layout = document.querySelector(".layout");'//NL//'  if (!main || !la' &
        //'yout) return;'//NL//'  var heads = Array.prototype.filter.call(main.querySelectorAll("h2[id], .doc h1[id], .d' &
        //'oc h3[id]"), function (h) {'//NL//'    return !h.closest(".item");'//NL//'  });'//NL//'  if (heads.length < 2' &
        //') return;'//NL//'  var nav = document.createElement("nav"), ul = document.createElement("ul"), links = [];'//NL &
        //'  nav.className = "toc";'//NL//'  nav.setAttribute("aria-label", "On this page");'//NL//'  nav.innerHTML = "<' &
        //'h4>On this page</h4>";'//NL//'  heads.forEach(function (h) {'//NL//'    var copy = h.cloneNode(true);'//NL//' ' &
        //'   copy.querySelectorAll(".anchor").forEach(function (a) { a.remove(); });'//NL//'    var li = document.creat' &
        //'eElement("li"), a = document.createElement("a");'//NL//'    if (h.tagName === "H3") li.className = "sub";'//NL &
        //'    a.href = "#" + h.id;'//NL//'    a.textContent = copy.textContent.trim();'//NL//'    a.title = a.textConte' &
        //'nt;'//NL//'    li.appendChild(a);'//NL//'    ul.appendChild(li);'//NL//'    links.push(a);'//NL//'  });'//NL//' ' &
        //' nav.appendChild(ul);'//NL//'  layout.appendChild(nav);'//NL//'  layout.classList.add("has-toc");'//NL//NL//' ' &
        //' var ticking = false;'//NL//'  function mark() {'//NL//'    ticking = false;'//NL//'    var on = 0;'//NL//'  ' &
        //'  heads.forEach(function (h, k) { if (h.getBoundingClientRect().top < 110) on = k; });'//NL//'    links.forEa' &
        //'ch(function (a, k) { a.classList.toggle("on", k === on); });'//NL//'  }'//NL//'  window.addEventListener("scr' &
        //'oll", function () {'//NL//'    if (!ticking) { ticking = true; window.requestAnimationFrame(mark); }'//NL//' ' &
        //' }, { passive: true });'//NL//'  mark();'//NL//'});'//NL//NL//'// Mermaid diagrams are drawn in the browser, ' &
        //'and Mermaid is only loaded for pages that have one'//NL//'(function () {'//NL//'  var URL = "https://cdn.jsde' &
        //'livr.net/npm/mermaid@11/dist/mermaid.min.js";'//NL//NL//'  function dark() {'//NL//'    var theme = document.' &
        //'documentElement.getAttribute("data-theme");'//NL//'    if (!theme) return window.matchMedia("(prefers-color-s' &
        //'cheme: dark)").matches;'//NL//'    return ["gruvbox-light", "rose-pine-dawn"].indexOf(theme) < 0;'//NL//'  }'//NL &
        //NL//'  document.addEventListener("DOMContentLoaded", function () {'//NL//'    var blocks = document.querySelec' &
        //'torAll("pre.mermaid");'//NL//'    if (!blocks.length) return;'//NL//'    blocks.forEach(function (block) { bl' &
        //'ock.dataset.source = block.textContent; });'//NL//NL//'    function draw() {'//NL//'      blocks.forEach(func' &
        //'tion (block) {'//NL//'        block.textContent = block.dataset.source;'//NL//'        block.removeAttribute(' &
        //'"data-processed");'//NL//'      });'//NL//'      window.mermaid.initialize({ startOnLoad: false, theme: dark(' &
        //') ? "dark" : "default" });'//NL//'      window.mermaid.run({ nodes: blocks });'//NL//'    }'//NL//NL//'    va' &
        //'r tag = document.createElement("script");'//NL//'    tag.src = URL;'//NL//'    tag.onload = function () {'//NL &
        //'      draw();'//NL//'      var select = document.querySelector("select.theme");'//NL//'      if (select) sele' &
        //'ct.addEventListener("change", draw);'//NL//'    };'//NL//'    document.head.appendChild(tag);'//NL//'  });'//NL &
        //'})();'//NL//NL//'// each heading with an id, and each entry of a list, gets a link to itself'//NL//'document.' &
        //'addEventListener("DOMContentLoaded", function () {'//NL//'  document.querySelectorAll("main h2[id], main h3[i' &
        //'d], main .item[id] > h3").forEach(function (heading) {'//NL//'    var id = heading.id || heading.parentElemen' &
        //'t.id;'//NL//'    var link = document.createElement("a");'//NL//'    link.className = "anchor";'//NL//'    lin' &
        //'k.href = "#" + id;'//NL//'    link.textContent = "#";'//NL//'    link.setAttribute("aria-label", "Link to thi' &
        //'s section");'//NL//'    heading.appendChild(link);'//NL//'  });'//NL//'});'//NL)
end subroutine asset_fdoc_js

end module fdoc_assets
