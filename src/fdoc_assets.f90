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
        ':root {'//NL//'  --bg: #ffffff; --bg-soft: #f6f7f9; --bg-code: #f6f7f9; --line: #e3e6eb; --text: #1f243' &
        //'0; --muted: #646d7e;'//NL//'  --accent: #3657c9; --accent-soft: #e9eefb; --ok: #1d7a55; --warn: #a15c00' &
        //'; --bad: #b3261e; --hist: #6a4fb3;'//NL//'  --attr-l: 34%;'//NL//'  --k: #7b30b5; --s: #1b7f3b; --c: #7a8290; ' &
        //'--d: #2f7a8c; --n: #b4530a; --p: #a15c00;'//NL//'  --mono: ui-monospace, SFMono-Regular, Menlo, Consola' &
        //'s, monospace;'//NL//'  --sans: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, s' &
        //'ans-serif;'//NL//'}'//NL//':root[data-theme="dark"] {'//NL//'  --bg: #14171d; --bg-soft: #1b1f27; --bg-code: #1b1f27;' &
        //' --line: #2c323d; --text: #e4e7ec; --muted: #9aa3b2;'//NL//'  --accent: #8ba7ff; --accent-soft: #232c45' &
        //'; --ok: #5fcf9f; --warn: #e3ab5c; --bad: #f28b82; --hist: #b9a4f2;'//NL//'  --attr-l: 72%;'//NL//'  --k: #c792' &
        //'ea; --s: #8fd18f; --c: #7f8796; --d: #7fc4d4; --n: #f0a868; --p: #e3ab5c;'//NL//'}'//NL//'@media (prefers-colo' &
        //'r-scheme: dark) {'//NL//'  :root:not([data-theme="light"]) {'//NL//'    --bg: #14171d; --bg-soft: #1b1f27; --b' &
        //'g-code: #1b1f27; --line: #2c323d; --text: #e4e7ec; --muted: #9aa3b2;'//NL//'    --accent: #8ba7ff; --ac' &
        //'cent-soft: #232c45; --ok: #5fcf9f; --warn: #e3ab5c; --bad: #f28b82; --hist: #b9a4f2;'//NL//'    --attr-' &
        //'l: 72%;'//NL//'    --k: #c792ea; --s: #8fd18f; --c: #7f8796; --d: #7fc4d4; --n: #f0a868; --p: #e3ab5c;'//NL//'' &
        //'  }'//NL//'}'//NL//'* { box-sizing: border-box; }'//NL//'html { scroll-padding-top: 4.5rem; }'//NL//'body { margin: 0; backg' &
        //'round: var(--bg); color: var(--text); font: 16px/1.6 var(--sans); }'//NL//'a { color: var(--accent); te' &
        //'xt-decoration: none; }'//NL//'a:hover { text-decoration: underline; }'//NL//'header.top {'//NL//'  position: sticky; ' &
        //'top: 0; z-index: 10; display: flex; align-items: center; gap: 1.25rem; height: 3.5rem;'//NL//'  padding' &
        //': 0 1.25rem; background: var(--bg); border-bottom: 1px solid var(--line);'//NL//'}'//NL//'header.top .brand { ' &
        //'font-weight: 650; color: var(--text); white-space: nowrap; }'//NL//'header.top .brand small { color: va' &
        //'r(--muted); font-weight: 400; margin-left: .35rem; }'//NL//'header.top nav { display: flex; gap: 1rem; ' &
        //'overflow-x: auto; flex: 1; }'//NL//'header.top nav a { color: var(--muted); white-space: nowrap; font-s' &
        //'ize: .92rem; }'//NL//'header.top nav a:hover, header.top nav a.here { color: var(--text); text-decorati' &
        //'on: none; }'//NL//'.theme { background: none; border: 1px solid var(--line); border-radius: 6px; color:' &
        //' var(--muted); cursor: pointer;'//NL//'  width: 2rem; height: 2rem; font-size: 1rem; line-height: 1; }'//NL//'' &
        //'.layout { display: grid; grid-template-columns: 17rem minmax(0, 1fr); max-width: 90rem; margin: ' &
        //'0 auto; }'//NL//'aside.side { position: sticky; top: 3.5rem; align-self: start; height: calc(100vh - 3.' &
        //'5rem); overflow-y: auto;'//NL//'  padding: 1.25rem 1rem 2rem 1.25rem; border-right: 1px solid var(--lin' &
        //'e); font-size: .9rem; }'//NL//'aside.side h4 { margin: 1.1rem 0 .3rem; color: var(--muted); font-size: ' &
        //'.72rem; letter-spacing: .06em;'//NL//'  text-transform: uppercase; font-weight: 650; }'//NL//'aside.side h4:fi' &
        //'rst-child { margin-top: 0; }'//NL//'aside.side ul { list-style: none; margin: 0; padding: 0; }'//NL//'aside.si' &
        //'de li a { display: block; padding: .12rem .5rem; margin-left: -.5rem; border-radius: 5px; color:' &
        //' var(--text);'//NL//'  overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }'//NL//'aside.side li ' &
        //'a:hover { background: var(--bg-soft); text-decoration: none; }'//NL//'aside.side li a.more { color: var' &
        //'(--muted); }'//NL//'main { padding: 2rem 2.5rem 4rem; min-width: 0; }'//NL//'main > .inner { max-width: 54rem;' &
        //' }'//NL//'h1, h2, h3, h4 { line-height: 1.25; font-weight: 650; }'//NL//'h1 { font-size: 1.9rem; margin: 0 0 .' &
        //'4rem; }'//NL//'h2 { font-size: 1.3rem; margin: 2.4rem 0 .8rem; padding-bottom: .3rem; border-bottom: 1p' &
        //'x solid var(--line); }'//NL//'.doc h1 { font-size: 1.5rem; margin-top: 1.6rem; }'//NL//'.doc h2 { font-size: 1' &
        //'.25rem; }'//NL//'.doc h3 { font-size: 1.05rem; margin-top: 1.4rem; }'//NL//'.crumbs { color: var(--muted); fon' &
        //'t-size: .88rem; margin-bottom: .3rem; }'//NL//'.kind { color: var(--muted); font-weight: 400; font-size' &
        //': .62em; margin-right: .35rem; }'//NL//'.meta { display: flex; flex-wrap: wrap; gap: .3rem 1rem; color:' &
        //' var(--muted); font-size: .88rem; margin: .4rem 0 1.1rem; }'//NL//'.lead { font-size: 1.1rem; color: va' &
        //'r(--muted); margin: .2rem 0 1.4rem; }'//NL//'.lead p { margin: 0; }'//NL//'code, pre, .sig { font-family: var(' &
        //'--mono); font-size: .875em; }'//NL//':not(pre) > code { background: var(--bg-code); padding: .1em .3em;' &
        //' border-radius: 4px; }'//NL//'pre, .sig { background: var(--bg-code); border: 1px solid var(--line); bo' &
        //'rder-radius: 8px; padding: .7rem .9rem;'//NL//'  overflow-x: auto; line-height: 1.5; }'//NL//'.codehilite { po' &
        //'sition: relative; margin: 1rem 0; }'//NL//'.codehilite pre { margin: 0; }'//NL//'.copy { position: absolute; t' &
        //'op: .4rem; right: .4rem; opacity: 0; background: var(--bg); color: var(--muted);'//NL//'  border: 1px s' &
        //'olid var(--line); border-radius: 5px; font-size: .72rem; padding: .1rem .4rem; cursor: pointer; ' &
        //'}'//NL//'.codehilite:hover .copy { opacity: 1; }'//NL//'.sig { margin: .4rem 0 .7rem; white-space: pre-wrap; o' &
        //'verflow-wrap: anywhere; }'//NL//'.k { color: var(--k); } .s { color: var(--s); } .c { color: var(--c); ' &
        //'font-style: italic; }'//NL//'.d { color: var(--d); } .n { color: var(--n); } .p { color: var(--p); }'//NL//'.i' &
        //'tem { padding: .9rem 0 1rem; border-top: 1px solid var(--line); }'//NL//'h2 + .item { border-top: 0; pa' &
        //'dding-top: 0; }'//NL//'.item > h3 { margin: 0 0 .2rem; font-size: 1rem; font-family: var(--mono); overf' &
        //'low-wrap: anywhere; }'//NL//'.badge { display: inline-block; font: 600 .68rem/1.5 var(--sans); padding:' &
        //' 0 .4rem; margin-left: .4rem; border-radius: 4px;'//NL//'  background: var(--bg-soft); color: var(--mut' &
        //'ed); border: 1px solid var(--line); vertical-align: middle; }'//NL//'.badge.private { color: var(--warn' &
        //'); } .badge.deprecated { color: var(--bad); }'//NL//'table { border-collapse: collapse; width: 100%; fo' &
        //'nt-size: .92rem; margin: .7rem 0 1rem; }'//NL//'th { text-align: left; font-weight: 600; color: var(--m' &
        //'uted); }'//NL//'th, td { padding: .35rem .7rem .35rem 0; border-bottom: 1px solid var(--line); vertical' &
        //'-align: top; }'//NL//'td p { margin: 0; } td.type { font-family: var(--mono); font-size: .84em; width: ' &
        //'30%; overflow-wrap: break-word; }'//NL//'td.name { font-family: var(--mono); font-size: .88em; width: 2' &
        //'4%; overflow-wrap: break-word; }'//NL//'.doc table { display: block; overflow-x: auto; }'//NL//'.alert { borde' &
        //'r-left: 3px solid var(--accent); background: var(--bg-soft); border-radius: 0 6px 6px 0;'//NL//'  paddi' &
        //'ng: .55rem .9rem; margin: 1rem 0; }'//NL//'.alert p { margin: .3rem 0; } .alert-title { font-weight: 65' &
        //'0; font-size: .9rem; }'//NL//'.alert-warning { border-color: var(--warn); } .alert-success { border-col' &
        //'or: var(--ok); }'//NL//'.alert-danger { border-color: var(--bad); } .alert-history { border-color: var(' &
        //'--hist); }'//NL//'blockquote { margin: 1rem 0; padding: 0 1rem; color: var(--muted); border-left: 3px s' &
        //'olid var(--line); }'//NL//'img { max-width: 100%; }'//NL//'details.source { margin: 1rem 0; } details.source s' &
        //'ummary { cursor: pointer; color: var(--muted); font-size: .9rem; }'//NL//'.chips { display: flex; flex-' &
        //'wrap: wrap; gap: .35rem; padding: 0; list-style: none; margin: .5rem 0 1rem; }'//NL//'.chips li { font-' &
        //'family: var(--mono); font-size: .82rem; background: var(--bg-soft); border: 1px solid var(--line' &
        //');'//NL//'  border-radius: 5px; padding: 0 .45rem; }'//NL//'.listing td:first-child { font-family: var(--mono)' &
        //'; font-size: .9em; white-space: nowrap; }'//NL//'.listing td p { margin: 0; }'//NL//'.grid { display: grid; gr' &
        //'id-template-columns: repeat(auto-fill, minmax(15rem, 1fr)); gap: .9rem; margin: 1.2rem 0; }'//NL//'.car' &
        //'d { border: 1px solid var(--line); border-radius: 8px; padding: .7rem .9rem; color: var(--text);' &
        //' }'//NL//'.card:hover { border-color: var(--accent); text-decoration: none; }'//NL//'.card b { display: block;' &
        //' font-size: 1.4rem; } .card span { color: var(--muted); font-size: .88rem; }'//NL//'pre.source { paddin' &
        //'g-left: 0; counter-reset: line; line-height: 1.45; }'//NL//'.ln { display: inline-block; width: 3.6em; ' &
        //'margin-right: 1em; text-align: right; color: var(--muted); opacity: .6; user-select: none; }'//NL//'.ln' &
        //'::before { counter-increment: line; content: counter(line); }'//NL//'.ln:target { color: var(--accent);' &
        //' opacity: 1; font-weight: 700; }'//NL//'footer { margin-top: 3rem; padding-top: 1rem; border-top: 1px s' &
        //'olid var(--line); color: var(--muted); font-size: .84rem; }'//NL//'@media (max-width: 860px) {'//NL//'  .layou' &
        //'t { grid-template-columns: minmax(0, 1fr); }'//NL//'  aside.side { position: static; height: auto; bord' &
        //'er-right: 0; border-bottom: 1px solid var(--line); max-height: 40vh; }'//NL//'  main { padding: 1.25rem' &
        //' 1rem 3rem; }'//NL//'}'//NL//'@media print { header.top, aside.side, .theme, .copy { display: none; } .layout ' &
        //'{ display: block; } }'//NL//'.search { position: relative; flex: 0 1 15rem; }'//NL//'.search input { width: 10' &
        //'0%; height: 2rem; padding: 0 .6rem; color: var(--text); background: var(--bg-soft);'//NL//'  border: 1p' &
        //'x solid var(--line); border-radius: 6px; font: inherit; font-size: .88rem; }'//NL//'.search input:focus' &
        //' { outline: 2px solid var(--accent); outline-offset: -1px; }'//NL//'.search .results { display: none; p' &
        //'osition: absolute; top: 2.4rem; right: 0; width: min(30rem, 90vw); max-height: 70vh;'//NL//'  overflow-' &
        //'y: auto; background: var(--bg); border: 1px solid var(--line); border-radius: 8px;'//NL//'  box-shadow:' &
        //' 0 8px 24px rgba(0, 0, 0, .18); }'//NL//'.results a, .search-page a { display: block; padding: .45rem .' &
        //'7rem; color: var(--text); border-bottom: 1px solid var(--line); }'//NL//'.results a:hover, .results a.o' &
        //'n, .search-page a:hover { background: var(--accent-soft); text-decoration: none; }'//NL//'.results b, .' &
        //'search-page b { font-family: var(--mono); font-size: .88rem; font-weight: 600; }'//NL//'.results small,' &
        //' .search-page small { display: block; color: var(--muted); }'//NL//'aside.tree ul ul { margin-left: .8r' &
        //'em; }'//NL//'.graph { position: relative; overflow: auto; max-height: 34rem; margin: .4rem 0 1rem; padd' &
        //'ing: .5rem;'//NL//'  border: 1px solid var(--line); border-radius: 8px; background: var(--bg-soft); cur' &
        //'sor: grab; }'//NL//'.graph.dragging { cursor: grabbing; user-select: none; }'//NL//'.graph svg { display: bloc' &
        //'k; max-width: 100%; height: auto; margin: 0 auto; }'//NL//'.graph.zoomed svg { max-width: none; }'//NL//'.grap')
    call add(b, &
        'h .zoom { position: sticky; top: 0; left: 0; float: right; z-index: 2; }'//NL//'.graph .zoom button { b' &
        //'ackground: var(--bg); color: var(--muted); border: 1px solid var(--line); border-radius: 5px;'//NL//'  ' &
        //'width: 1.6rem; height: 1.6rem; cursor: pointer; margin-left: .2rem; }'//NL//'.arguments td.name, .argum' &
        //'ents td.type { width: auto; }'//NL//'td.attributes { font-family: var(--mono); font-size: .84em; }'//NL//'@med' &
        //'ia (min-width: 1100px) {'//NL//'  .arguments td.name, .arguments td.type, .arguments td.attributes { wh' &
        //'ite-space: nowrap; }'//NL//'  .arguments td:last-child { min-width: 14rem; }'//NL//'  .inner:has(.arguments) {' &
        //' max-width: 72rem; }'//NL//'  .inner:has(.arguments) > .doc, .inner:has(.arguments) > .sig { max-width:' &
        //' 54rem; }'//NL//'  main { overflow-x: auto; }'//NL//'}'//NL//'.attr { --h: 220; --s: 12%; display: inline-block; marg' &
        //'in: 0 .25rem .15rem 0; padding: 0 .4rem; border-radius: 4px;'//NL//'  font: 600 .74rem/1.55 var(--mono)' &
        //'; color: hsl(var(--h), var(--s), var(--attr-l));'//NL//'  background: hsla(var(--h), var(--s), var(--at' &
        //'tr-l), .12); border: 1px solid hsla(var(--h), var(--s), var(--attr-l), .35); }'//NL//'.attr-in, .attr-o' &
        //'ut, .attr-inout, .attr-optional, .attr-pointer, .attr-allocatable, .attr-value, .attr-target,'//NL//'.a' &
        //'ttr-dimension, .attr-contiguous, .attr-volatile, .attr-asynchronous, .attr-save, .attr-parameter' &
        //','//NL//'.attr-protected, .attr-codimension { --s: 62%; }'//NL//'.attr-in { --h: 210; } .attr-out { --h: 25; }' &
        //' .attr-inout { --h: 275; }'//NL//'.attr-optional { --h: 180; } .attr-pointer { --h: 0; } .attr-allocata' &
        //'ble { --h: 125; } .attr-value { --h: 45; }'//NL//'.attr-target { --h: 325; } .attr-dimension { --h: 85;' &
        //' } .attr-contiguous { --h: 150; } .attr-volatile { --h: 345; }'//NL//'.attr-asynchronous { --h: 300; } ' &
        //'.attr-save { --h: 60; } .attr-parameter { --h: 195; } .attr-protected { --h: 240; }'//NL//'.attr-codime' &
        //'nsion { --h: 105; }'//NL//'')
end subroutine asset_fdoc_css

!> The contents of `assets/fdoc.js`.
subroutine asset_fdoc_js(b)
    type(buffer_t), intent(inout) :: b  !! where they go
    call add(b, &
        '(function () {'//NL//'  var root = document.documentElement;'//NL//'  var saved = null;'//NL//'  try { saved = localS' &
        //'torage.getItem("fdoc-theme"); } catch (e) {}'//NL//'  if (saved) root.setAttribute("data-theme", saved)' &
        //';'//NL//'  document.addEventListener("DOMContentLoaded", function () {'//NL//'    var button = document.queryS' &
        //'elector(".theme");'//NL//'    if (button) button.addEventListener("click", function () {'//NL//'      var dark' &
        //' = root.getAttribute("data-theme") ? root.getAttribute("data-theme") === "dark"'//NL//'        : window' &
        //'.matchMedia("(prefers-color-scheme: dark)").matches;'//NL//'      var next = dark ? "light" : "dark";'//NL//' ' &
        //'     root.setAttribute("data-theme", next);'//NL//'      try { localStorage.setItem("fdoc-theme", next)' &
        //'; } catch (e) {}'//NL//'    });'//NL//'    document.querySelectorAll(".codehilite").forEach(function (block) {' &
        //''//NL//'      if (!navigator.clipboard) return;'//NL//'      var copy = document.createElement("button");'//NL//'    ' &
        //'  copy.className = "copy";'//NL//'      copy.textContent = "Copy";'//NL//'      copy.addEventListener("click",' &
        //' function () {'//NL//'        navigator.clipboard.writeText(block.querySelector("pre").innerText).then(' &
        //'function () {'//NL//'          copy.textContent = "Copied";'//NL//'          setTimeout(function () { copy.tex' &
        //'tContent = "Copy"; }, 1200);'//NL//'        });'//NL//'      });'//NL//'      block.appendChild(copy);'//NL//'    });'//NL//'  });'//NL//'' &
        //'})();'//NL//'(function () {'//NL//'  var script = document.currentScript;'//NL//'  var root = script ? script.src.rep' &
        //'lace(/js\/fdoc\.js.*$/, "") : "";'//NL//'  var loaded = false, entries = null, waiting = [];'//NL//''//NL//'  functio' &
        //'n load(then) {'//NL//'    if (entries) { then(); return; }'//NL//'    waiting.push(then);'//NL//'    if (loaded) retu' &
        //'rn;'//NL//'    loaded = true;'//NL//'    var tag = document.createElement("script");'//NL//'    tag.src = root + "sea' &
        //'rch/index.js";'//NL//'    tag.onload = function () {'//NL//'      entries = window.FDOC_INDEX || [];'//NL//'      ent' &
        //'ries.forEach(function (e) { e.low = e.t.toLowerCase(); e.text = (e.s || "").toLowerCase(); });'//NL//' ' &
        //'     waiting.forEach(function (f) { f(); });'//NL//'    };'//NL//'    document.head.appendChild(tag);'//NL//'  }'//NL//''//NL//'  f' &
        //'unction score(entry, words) {'//NL//'    var total = 0;'//NL//'    for (var i = 0; i < words.length; i++) {'//NL//'  ' &
        //'    var w = words[i], at = entry.low.indexOf(w);'//NL//'      if (entry.low === w) total += 100;'//NL//'      ' &
        //'else if (at === 0) total += 50;'//NL//'      else if (at > 0) total += 25;'//NL//'      else if (entry.text.in' &
        //'dexOf(w) >= 0) total += 5;'//NL//'      else return 0;'//NL//'    }'//NL//'    return total - entry.low.length / 100;' &
        //''//NL//'  }'//NL//''//NL//'  function search(query, limit) {'//NL//'    var words = query.toLowerCase().split(/\s+/).filter(' &
        //'Boolean);'//NL//'    if (!words.length) return [];'//NL//'    var found = [];'//NL//'    entries.forEach(function (e)' &
        //' { var s = score(e, words); if (s > 0) found.push([s, e]); });'//NL//'    found.sort(function (a, b) { ' &
        //'return b[0] - a[0]; });'//NL//'    return found.slice(0, limit).map(function (f) { return f[1]; });'//NL//'  }' &
        //''//NL//''//NL//'  function row(entry) {'//NL//'    var a = document.createElement("a");'//NL//'    a.href = root + entry.u;'//NL//'' &
        //'    var title = document.createElement("b");'//NL//'    title.textContent = entry.t;'//NL//'    var kind = doc' &
        //'ument.createElement("span");'//NL//'    kind.className = "badge";'//NL//'    kind.textContent = entry.k;'//NL//'    a' &
        //'.appendChild(title);'//NL//'    a.appendChild(kind);'//NL//'    if (entry.s) {'//NL//'      var text = document.creat' &
        //'eElement("small");'//NL//'      text.textContent = entry.s;'//NL//'      a.appendChild(text);'//NL//'    }'//NL//'    return' &
        //' a;'//NL//'  }'//NL//''//NL//'  function fill(box, results) {'//NL//'    box.textContent = "";'//NL//'    results.forEach(function ' &
        //'(e) { box.appendChild(row(e)); });'//NL//'  }'//NL//''//NL//'  document.addEventListener("DOMContentLoaded", function' &
        //' () {'//NL//'    var input = document.querySelector(".search input");'//NL//'    if (!input) return;'//NL//'    var b' &
        //'ox = document.querySelector(".search .results");'//NL//'    var selected = -1;'//NL//'    function mark() {'//NL//'  ' &
        //'    var rows = box.children;'//NL//'      for (var i = 0; i < rows.length; i++) rows[i].className = i =' &
        //'== selected ? "on" : "";'//NL//'    }'//NL//'    input.addEventListener("input", function () {'//NL//'      load(func' &
        //'tion () {'//NL//'        fill(box, input.value ? search(input.value, 12) : []);'//NL//'        selected = -1;'//NL//'' &
        //'        box.style.display = box.children.length ? "block" : "none";'//NL//'      });'//NL//'    });'//NL//'    input.' &
        //'addEventListener("keydown", function (event) {'//NL//'      var n = box.children.length;'//NL//'      if (even' &
        //'t.key === "ArrowDown" && n) { selected = (selected + 1) % n; mark(); event.preventDefault(); }'//NL//' ' &
        //'     else if (event.key === "ArrowUp" && n) { selected = (selected + n - 1) % n; mark(); event.p' &
        //'reventDefault(); }'//NL//'      else if (event.key === "Escape") { box.style.display = "none"; input.bl' &
        //'ur(); }'//NL//'      else if (event.key === "Enter") {'//NL//'        if (selected >= 0) box.children[selected' &
        //'].click();'//NL//'        else location.href = root + "search.html?q=" + encodeURIComponent(input.value' &
        //');'//NL//'      }'//NL//'    });'//NL//'    document.addEventListener("click", function (event) {'//NL//'      if (!event.ta' &
        //'rget.closest(".search")) box.style.display = "none";'//NL//'    });'//NL//'    document.addEventListener("keyd' &
        //'own", function (event) {'//NL//'      if (event.key === "/" && document.activeElement !== input) { inpu' &
        //'t.focus(); event.preventDefault(); }'//NL//'    });'//NL//'    var page = document.querySelector(".search-page' &
        //'");'//NL//'    if (page) {'//NL//'      var query = new URLSearchParams(location.search).get("q") || "";'//NL//'     ' &
        //' input.value = query;'//NL//'      load(function () {'//NL//'        var results = search(query, 200);'//NL//'       ' &
        //' fill(page, results);'//NL//'        document.querySelector(".search-count").textContent = results.leng' &
        //'th + " results for “" + query + "”";'//NL//'      });'//NL//'    }'//NL//'  });'//NL//'})();'//NL//'(function () {'//NL//'  document.addEv' &
        //'entListener("DOMContentLoaded", function () {'//NL//'    document.querySelectorAll(".graph").forEach(fu' &
        //'nction (box) {'//NL//'      var svg = box.querySelector("svg");'//NL//'      if (!svg) return;'//NL//'      var width' &
        //' = svg.width.baseVal.value, height = svg.height.baseVal.value, scale = 1;'//NL//'      function set(val' &
        //'ue) {'//NL//'        scale = Math.max(0.25, Math.min(6, value));'//NL//'        box.classList.add("zoomed");'//NL//' ' &
        //'       svg.style.width = width * scale + "px";'//NL//'        svg.style.height = height * scale + "px";' &
        //''//NL//'      }'//NL//'      var zoom = document.createElement("div");'//NL//'      zoom.className = "zoom";'//NL//'      [[' &
        //'"+", 1.3], ["\u2212", 1 / 1.3]].forEach(function (b) {'//NL//'        var button = document.createEleme' &
        //'nt("button");'//NL//'        button.textContent = b[0];'//NL//'        button.setAttribute("aria-label", b[1] ' &
        //'> 1 ? "Zoom in" : "Zoom out");'//NL//'        button.addEventListener("click", function () { set(scale ' &
        //'* b[1]); });'//NL//'        zoom.appendChild(button);'//NL//'      });'//NL//'      box.insertBefore(zoom, svg);'//NL//'    ' &
        //'  var start = null;'//NL//'      box.addEventListener("mousedown", function (event) {'//NL//'        if (event' &
        //'.target.closest("a, button")) return;'//NL//'        start = [event.clientX, event.clientY, box.scrollL' &
        //'eft, box.scrollTop];'//NL//'        box.classList.add("dragging");'//NL//'      });'//NL//'      window.addEventListe' &
        //'ner("mousemove", function (event) {'//NL//'        if (!start) return;'//NL//'        box.scrollLeft = start[2' &
        //'] - (event.clientX - start[0]);'//NL//'        box.scrollTop = start[3] - (event.clientY - start[1]);'//NL//' ' &
        //'     });'//NL//'      window.addEventListener("mouseup", function () { start = null; box.classList.remo' &
        //'ve("dragging"); });'//NL//'    });'//NL//'  });'//NL//'})();'//NL//'')
end subroutine asset_fdoc_js

end module fdoc_assets
