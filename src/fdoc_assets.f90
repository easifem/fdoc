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
        //'ents td.type { width: auto; }'//NL//'td.attributes { font-family: var(--mono); font-size: .84em; }'//NL//'td.d' &
        //'efault { font-family: var(--mono); font-size: .84em; overflow-wrap: break-word; }'//NL//'@media (min-wi' &
        //'dth: 1100px) {'//NL//'  .arguments td.name, .arguments td.type, .arguments td.attributes { white-space:' &
        //' nowrap; }'//NL//'  .arguments td:last-child { min-width: 14rem; }'//NL//'  .inner:has(.arguments) { max-width' &
        //': 72rem; }'//NL//'  .inner:has(.arguments) > .doc, .inner:has(.arguments) > .sig { max-width: 54rem; }'//NL//'' &
        //'  main { overflow-x: auto; }'//NL//'}'//NL//'.attr { --h: 220; --s: 12%; display: inline-block; margin: 0 .25r' &
        //'em .15rem 0; padding: 0 .4rem; border-radius: 4px;'//NL//'  font: 600 .74rem/1.55 var(--mono); color: h' &
        //'sl(var(--h), var(--s), var(--attr-l));'//NL//'  background: hsla(var(--h), var(--s), var(--attr-l), .12' &
        //'); border: 1px solid hsla(var(--h), var(--s), var(--attr-l), .35); }'//NL//'.attr-in, .attr-out, .attr-' &
        //'inout, .attr-optional, .attr-pointer, .attr-allocatable, .attr-value, .attr-target,'//NL//'.attr-dimens' &
        //'ion, .attr-contiguous, .attr-volatile, .attr-asynchronous, .attr-save, .attr-parameter,'//NL//'.attr-pr' &
        //'otected, .attr-codimension, .attr-private { --s: 62%; }'//NL//'.attr-in { --h: 210; } .attr-out { --h: ' &
        //'25; } .attr-inout { --h: 275; }'//NL//'.attr-optional { --h: 180; } .attr-pointer { --h: 0; } .attr-all' &
        //'ocatable { --h: 125; } .attr-value { --h: 45; }'//NL//'.attr-target { --h: 325; } .attr-dimension { --h' &
        //': 85; } .attr-contiguous { --h: 150; } .attr-volatile { --h: 345; }'//NL//'.attr-asynchronous { --h: 30' &
        //'0; } .attr-save { --h: 60; } .attr-parameter { --h: 195; } .attr-protected { --h: 240; }'//NL//'.attr-c' &
        //'odimension { --h: 105; }'//NL//'.graph text { stroke: none; }'//NL//'.attr-private { --h: 15; --s: 40%; }'//NL//'')
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
        //''//NL//'  }'//NL//''//NL//'  // edit distance with transpositions, giving up once it exceeds `most`'//NL//'  function distan' &
        //'ce(a, b, most) {'//NL//'    if (Math.abs(a.length - b.length) > most) return most + 1;'//NL//'    var before =' &
        //' null, last = [], row = [], i, j;'//NL//'    for (j = 0; j <= b.length; j++) last[j] = j;'//NL//'    for (i = ' &
        //'1; i <= a.length; i++) {'//NL//'      row = [i];'//NL//'      var best = i;'//NL//'      for (j = 1; j <= b.length; j' &
        //'++) {'//NL//'        var cost = a[i - 1] === b[j - 1] ? 0 : 1;'//NL//'        row[j] = Math.min(last[j] + 1, r' &
        //'ow[j - 1] + 1, last[j - 1] + cost);'//NL//'        if (before && i > 1 && j > 1 && a[i - 1] === b[j - 2' &
        //'] && a[i - 2] === b[j - 1]) {'//NL//'          row[j] = Math.min(row[j], before[j - 2] + 1);'//NL//'        }'//NL//'' &
        //'        best = Math.min(best, row[j]);'//NL//'      }'//NL//'      if (best > most) return most + 1;'//NL//'      bef' &
        //'ore = last;'//NL//'      last = row;'//NL//'    }'//NL//'    return last[b.length];'//NL//'  }'//NL//''//NL//'  function parts(text) { ret' &
        //'urn text.split(/[^a-z0-9]+/).filter(Boolean); }'//NL//''//NL//'  // a typo: the word is close to some run of p' &
        //'arts of the name, or to how such a run starts'//NL//'  function typo(tokens, word) {'//NL//'    if (word.lengt' &
        //'h < 3) return 0;'//NL//'    var size = parts(word).length, plain = parts(word).join("_"), most = word.l' &
        //'ength < 8 ? 1 : 2;'//NL//'    var result = 0;'//NL//'    for (var i = 0; i + size <= tokens.length; i++) {'//NL//'   ' &
        //'   var run = tokens.slice(i, i + size).join("_");'//NL//'      var d = distance(plain, run, most);'//NL//'    ' &
        //'  if (d > most) d = distance(plain, run.slice(0, plain.length), most);'//NL//'      if (d <= most) resu' &
        //'lt = Math.max(result, 3 - d);'//NL//'    }'//NL//'    return result;'//NL//'  }'//NL//''//NL//'  // the word is in the initials of ' &
        //'the parts of the name, as `jvcs` for json_value_create_string'//NL//'  function initials(tokens, word) ' &
        //'{'//NL//'    if (word.length < 2) return 0;'//NL//'    return subsequence(tokens.map(function (t) { return t[0' &
        //']; }).join(""), word) ? 2.5 : 0;'//NL//'  }'//NL//''//NL//'  function subsequence(text, word) {'//NL//'    var at = -1;'//NL//'    ' &
        //'for (var i = 0; i < word.length; i++) {'//NL//'      at = text.indexOf(word[i], at + 1);'//NL//'      if (at <' &
        //' 0) return false;'//NL//'    }'//NL//'    return true;'//NL//'  }'//NL//''//NL//'  // the letters of the word are in order and clos' &
        //'e together'//NL//'  function letters(low, word) {'//NL//'    if (word.length < 3) return 0;'//NL//'    var best = 0;'//NL//'' &
        //'    for (var start = low.indexOf(word[0]); start >= 0; start = low.indexOf(word[0], start + 1)) ' &
        //'{'//NL//'      var at = start;'//NL//'      for (var i = 1; i < word.length && at >= 0; i++) at = low.indexOf(' &
        //'word[i], at + 1);'//NL//'      if (at < 0) break;'//NL//'      var span = at - start + 1;'//NL//'      if (span <= wo' &
        //'rd.length * 2) best = Math.max(best, word.length / span);'//NL//'    }'//NL//'    return best;'//NL//'  }'//NL//''//NL//'  function' &
        //' fuzzy(entry, words) {'//NL//'    if (!entry.tokens) entry.tokens = parts(entry.low);'//NL//'    var total = 0' &
        //';'//NL//'    for (var i = 0; i < words.length; i++) {'//NL//'      var w = words[i];'//NL//'      var s = entry.low.i' &
        //'ndexOf(w) >= 0 ? 3 : Math.max(typo(entry.tokens, w), initials(entry.tokens, w), letters(entry.lo' &
        //'w, w));'//NL//'      if (s <= 0) return 0;'//NL//'      total += s;'//NL//'    }'//NL//'    return total - entry.low.length ' &
        //'/ 1000;'//NL//'  }'//NL//''//NL//'  function search(query, limit) {'//NL//'    var words = query.toLowerCase().split(/\s+/).' &
        //'filter(Boolean);'//NL//'    if (!words.length) return [];'//NL//'    var found = [], rest = [];'//NL//'    entries.fo' &
        //'rEach(function (e) {'//NL//'      var s = score(e, words);'//NL//'      if (s > 0) found.push([s, e]); else re' &
        //'st.push(e);'//NL//'    });'//NL//'    found.sort(function (a, b) { return b[0] - a[0]; });'//NL//'    if (found.lengt' &
        //'h < limit) {'//NL//'      // fuzzy matches only fill in below exact ones'//NL//'      var near = [];'//NL//'      res' &
        //'t.forEach(function (e) { var s = fuzzy(e, words); if (s > 0) near.push([s, e]); });'//NL//'      near.s' &
        //'ort(function (a, b) { return b[0] - a[0]; });'//NL//'      found = found.concat(near);'//NL//'    }'//NL//'    return' &
        //' found.slice(0, limit).map(function (f) { return f[1]; });'//NL//'  }'//NL//''//NL//'  function row(entry) {'//NL//'    var ' &
        //'a = document.createElement("a");'//NL//'    a.href = root + entry.u;'//NL//'    var title = document.createEle' &
        //'ment("b");'//NL//'    title.textContent = entry.t;'//NL//'    var kind = document.createElement("span");'//NL//'    k' &
        //'ind.className = "badge";'//NL//'    kind.textContent = entry.k;'//NL//'    a.appendChild(title);'//NL//'    a.appendC' &
        //'hild(kind);'//NL//'    if (entry.s) {'//NL//'      var text = document.createElement("small");'//NL//'      text.text' &
        //'Content = entry.s;'//NL//'      a.appendChild(text);'//NL//'    }'//NL//'    return a;'//NL//'  }'//NL//''//NL//'  function fill(box, resu' &
        //'lts) {'//NL//'    box.textContent = "";'//NL//'    results.forEach(function (e) { box.appendChild(row(e)); });' &
        //''//NL//'  }'//NL//''//NL//'  document.addEventListener("DOMContentLoaded", function () {'//NL//'    var input = document.que' &
        //'rySelector(".search input");'//NL//'    if (!input) return;'//NL//'    var box = document.querySelector(".sear' &
        //'ch .results");'//NL//'    var selected = -1;'//NL//'    function mark() {'//NL//'      var rows = box.children;'//NL//'     ' &
        //' for (var i = 0; i < rows.length; i++) rows[i].className = i === selected ? "on" : "";'//NL//'    }'//NL//'   ' &
        //' input.addEventListener("input", function () {'//NL//'      load(function () {'//NL//'        fill(box, input.' &
        //'value ? search(input.value, 12) : []);'//NL//'        selected = -1;'//NL//'        box.style.display = box.ch' &
        //'ildren.length ? "block" : "none";'//NL//'      });'//NL//'    });'//NL//'    input.addEventListener("keydown", functi' &
        //'on (event) {'//NL//'      var n = box.children.length;'//NL//'      if (event.key === "ArrowDown" && n) { sele' &
        //'cted = (selected + 1) % n; mark(); event.preventDefault(); }'//NL//'      else if (event.key === "Arrow' &
        //'Up" && n) { selected = (selected + n - 1) % n; mark(); event.preventDefault(); }'//NL//'      else if (' &
        //'event.key === "Escape") { box.style.display = "none"; input.blur(); }'//NL//'      else if (event.key =' &
        //'== "Enter") {'//NL//'        if (selected >= 0) box.children[selected].click();'//NL//'        else location.h' &
        //'ref = root + "search.html?q=" + encodeURIComponent(input.value);'//NL//'      }'//NL//'    });'//NL//'    document.ad' &
        //'dEventListener("click", function (event) {'//NL//'      if (!event.target.closest(".search")) box.style' &
        //'.display = "none";'//NL//'    });'//NL//'    document.addEventListener("keydown", function (event) {'//NL//'      if ' &
        //'(event.key === "/" && document.activeElement !== input) { input.focus(); event.preventDefault();' &
        //' }'//NL//'    });'//NL//'    var page = document.querySelector(".search-page");'//NL//'    if (page) {'//NL//'      var quer' &
        //'y = new URLSearchParams(location.search).get("q") || "";'//NL//'      input.value = query;'//NL//'      load(f' &
        //'unction () {'//NL//'        var results = search(query, 200);'//NL//'        fill(page, results);'//NL//'        docu' &
        //'ment.querySelector(".search-count").textContent = results.length + " results for “" + query + "”' &
        //'";'//NL//'      });'//NL//'    }'//NL//'  });'//NL//'})();'//NL//'(function () {'//NL//'  document.addEventListener("DOMContentLoaded", fu' &
        //'nction () {'//NL//'    document.querySelectorAll(".graph").forEach(function (box) {'//NL//'      var svg = box' &
        //'.querySelector("svg");'//NL//'      if (!svg) return;'//NL//'      var width = svg.width.baseVal.value, height' &
        //' = svg.height.baseVal.value, scale = 1;'//NL//'      function set(value) {'//NL//'        scale = Math.max(0.2' &
        //'5, Math.min(6, value));'//NL//'        box.classList.add("zoomed");'//NL//'        svg.style.width = width * s' &
        //'cale + "px";'//NL//'        svg.style.height = height * scale + "px";'//NL//'      }'//NL//'      var zoom = document' &
        //'.createElement("div");'//NL//'      zoom.className = "zoom";'//NL//'      [["+", 1.3], ["\u2212", 1 / 1.3]].fo' &
        //'rEach(function (b) {'//NL//'        var button = document.createElement("button");'//NL//'        button.textC' &
        //'ontent = b[0];'//NL//'        button.setAttribute("aria-label", b[1] > 1 ? "Zoom in" : "Zoom out");'//NL//'   ' &
        //'     button.addEventListener("click", function () { set(scale * b[1]); });'//NL//'        zoom.appendCh' &
        //'ild(button);'//NL//'      });'//NL//'      box.insertBefore(zoom, svg);'//NL//'      var start = null;'//NL//'      box.addE' &
        //'ventListener("mousedown", function (event) {'//NL//'        if (event.target.closest("a, button")) retu')
    call add(b, &
        'rn;'//NL//'        start = [event.clientX, event.clientY, box.scrollLeft, box.scrollTop];'//NL//'        box.c' &
        //'lassList.add("dragging");'//NL//'      });'//NL//'      window.addEventListener("mousemove", function (event) ' &
        //'{'//NL//'        if (!start) return;'//NL//'        box.scrollLeft = start[2] - (event.clientX - start[0]);'//NL//'  ' &
        //'      box.scrollTop = start[3] - (event.clientY - start[1]);'//NL//'      });'//NL//'      window.addEventList' &
        //'ener("mouseup", function () { start = null; box.classList.remove("dragging"); });'//NL//'    });'//NL//'  });'//NL//'' &
        //'})();'//NL//'')
end subroutine asset_fdoc_js

end module fdoc_assets
