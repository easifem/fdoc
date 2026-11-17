(function () {
  var root = document.documentElement;
  var saved = null;
  try { saved = localStorage.getItem("fdoc-theme"); } catch (e) {}
  // the themes the selector offers; with none chosen (Auto) the CSS follows the system
  var THEMES = ["gruvbox-light", "gruvbox-dark", "tokyo-night", "catppuccin-mocha", "catppuccin-latte",
    "rose-pine", "rose-pine-dawn"];
  if (saved && THEMES.indexOf(saved) >= 0) root.setAttribute("data-theme", saved);
  document.addEventListener("DOMContentLoaded", function () {
    var select = document.querySelector("select.theme");
    if (select) {
      select.value = root.getAttribute("data-theme") || "";
      select.addEventListener("change", function () {
        if (select.value) root.setAttribute("data-theme", select.value);
        else root.removeAttribute("data-theme");
        try {
          if (select.value) localStorage.setItem("fdoc-theme", select.value);
          else localStorage.removeItem("fdoc-theme");
        } catch (e) {}
      });
    }
    document.querySelectorAll(".codehilite").forEach(function (block) {
      if (!navigator.clipboard) return;
      var copy = document.createElement("button");
      copy.className = "copy";
      copy.textContent = "Copy";
      copy.addEventListener("click", function () {
        navigator.clipboard.writeText(block.querySelector("pre").innerText).then(function () {
          copy.textContent = "Copied";
          setTimeout(function () { copy.textContent = "Copy"; }, 1200);
        });
      });
      block.appendChild(copy);
    });
  });
})();
(function () {
  var script = document.currentScript;
  var root = script ? script.src.replace(/js\/fdoc\.js.*$/, "") : "";
  var loaded = false, entries = null, waiting = [];

  function load(then) {
    if (entries) { then(); return; }
    waiting.push(then);
    if (loaded) return;
    loaded = true;
    var tag = document.createElement("script");
    tag.src = root + "search/index.js";
    tag.onload = function () {
      entries = window.FDOC_INDEX || [];
      entries.forEach(function (e) { e.low = e.t.toLowerCase(); e.text = (e.s || "").toLowerCase(); });
      waiting.forEach(function (f) { f(); });
    };
    document.head.appendChild(tag);
  }

  function score(entry, words) {
    var total = 0;
    for (var i = 0; i < words.length; i++) {
      var w = words[i], at = entry.low.indexOf(w);
      if (entry.low === w) total += 100;
      else if (at === 0) total += 50;
      else if (at > 0) total += 25;
      else if (entry.text.indexOf(w) >= 0) total += 5;
      else return 0;
    }
    return total - entry.low.length / 100;
  }

  // edit distance with transpositions, giving up once it exceeds `most`
  function distance(a, b, most) {
    if (Math.abs(a.length - b.length) > most) return most + 1;
    var before = null, last = [], row = [], i, j;
    for (j = 0; j <= b.length; j++) last[j] = j;
    for (i = 1; i <= a.length; i++) {
      row = [i];
      var best = i;
      for (j = 1; j <= b.length; j++) {
        var cost = a[i - 1] === b[j - 1] ? 0 : 1;
        row[j] = Math.min(last[j] + 1, row[j - 1] + 1, last[j - 1] + cost);
        if (before && i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) {
          row[j] = Math.min(row[j], before[j - 2] + 1);
        }
        best = Math.min(best, row[j]);
      }
      if (best > most) return most + 1;
      before = last;
      last = row;
    }
    return last[b.length];
  }

  function parts(text) { return text.split(/[^a-z0-9]+/).filter(Boolean); }

  // a typo: the word is close to some run of parts of the name, or to how such a run starts
  function typo(tokens, word) {
    if (word.length < 3) return 0;
    var size = parts(word).length, plain = parts(word).join("_"), most = word.length < 8 ? 1 : 2;
    var result = 0;
    for (var i = 0; i + size <= tokens.length; i++) {
      var run = tokens.slice(i, i + size).join("_");
      var d = distance(plain, run, most);
      if (d > most) d = distance(plain, run.slice(0, plain.length), most);
      if (d <= most) result = Math.max(result, 3 - d);
    }
    return result;
  }

  // the word is in the initials of the parts of the name, as `jvcs` for json_value_create_string
  function initials(tokens, word) {
    if (word.length < 2) return 0;
    return subsequence(tokens.map(function (t) { return t[0]; }).join(""), word) ? 2.5 : 0;
  }

  function subsequence(text, word) {
    var at = -1;
    for (var i = 0; i < word.length; i++) {
      at = text.indexOf(word[i], at + 1);
      if (at < 0) return false;
    }
    return true;
  }

  // the letters of the word are in order and close together
  function letters(low, word) {
    if (word.length < 3) return 0;
    var best = 0;
    for (var start = low.indexOf(word[0]); start >= 0; start = low.indexOf(word[0], start + 1)) {
      var at = start;
      for (var i = 1; i < word.length && at >= 0; i++) at = low.indexOf(word[i], at + 1);
      if (at < 0) break;
      var span = at - start + 1;
      if (span <= word.length * 2) best = Math.max(best, word.length / span);
    }
    return best;
  }

  function fuzzy(entry, words) {
    if (!entry.tokens) entry.tokens = parts(entry.low);
    var total = 0;
    for (var i = 0; i < words.length; i++) {
      var w = words[i];
      var s = entry.low.indexOf(w) >= 0 ? 3 : Math.max(typo(entry.tokens, w), initials(entry.tokens, w), letters(entry.low, w));
      if (s <= 0) return 0;
      total += s;
    }
    return total - entry.low.length / 1000;
  }

  function search(query, limit) {
    var words = query.toLowerCase().split(/\s+/).filter(Boolean);
    if (!words.length) return [];
    var found = [], rest = [];
    entries.forEach(function (e) {
      var s = score(e, words);
      if (s > 0) found.push([s, e]); else rest.push(e);
    });
    found.sort(function (a, b) { return b[0] - a[0]; });
    if (found.length < limit) {
      // fuzzy matches only fill in below exact ones
      var near = [];
      rest.forEach(function (e) { var s = fuzzy(e, words); if (s > 0) near.push([s, e]); });
      near.sort(function (a, b) { return b[0] - a[0]; });
      found = found.concat(near);
    }
    return found.slice(0, limit).map(function (f) { return f[1]; });
  }

  function row(entry) {
    var a = document.createElement("a");
    a.href = root + entry.u;
    var title = document.createElement("b");
    title.textContent = entry.t;
    var kind = document.createElement("span");
    kind.className = "badge";
    kind.textContent = entry.k;
    a.appendChild(title);
    a.appendChild(kind);
    if (entry.s) {
      var text = document.createElement("small");
      text.textContent = entry.s;
      a.appendChild(text);
    }
    return a;
  }

  function fill(box, results) {
    box.textContent = "";
    results.forEach(function (e) { box.appendChild(row(e)); });
  }

  document.addEventListener("DOMContentLoaded", function () {
    var input = document.querySelector(".search input");
    if (!input) return;
    var box = document.querySelector(".search .results");
    var selected = -1;
    function mark() {
      var rows = box.children;
      for (var i = 0; i < rows.length; i++) rows[i].className = i === selected ? "on" : "";
    }
    input.addEventListener("input", function () {
      load(function () {
        fill(box, input.value ? search(input.value, 12) : []);
        selected = -1;
        box.style.display = box.children.length ? "block" : "none";
      });
    });
    input.addEventListener("keydown", function (event) {
      var n = box.children.length;
      if (event.key === "ArrowDown" && n) { selected = (selected + 1) % n; mark(); event.preventDefault(); }
      else if (event.key === "ArrowUp" && n) { selected = (selected + n - 1) % n; mark(); event.preventDefault(); }
      else if (event.key === "Escape") { box.style.display = "none"; input.blur(); }
      else if (event.key === "Enter") {
        if (selected >= 0) box.children[selected].click();
        else location.href = root + "search.html?q=" + encodeURIComponent(input.value);
      }
    });
    document.addEventListener("click", function (event) {
      if (!event.target.closest(".search")) box.style.display = "none";
    });
    document.addEventListener("keydown", function (event) {
      if (event.key === "/" && document.activeElement !== input) { input.focus(); event.preventDefault(); }
    });
    var page = document.querySelector(".search-page");
    if (page) {
      var query = new URLSearchParams(location.search).get("q") || "";
      input.value = query;
      load(function () {
        var results = search(query, 200);
        fill(page, results);
        document.querySelector(".search-count").textContent = results.length + " results for “" + query + "”";
      });
    }
  });
})();
(function () {
  document.addEventListener("DOMContentLoaded", function () {
    // what the colours of `add_node` in fdoc_graphs.f90 mean: keep the two the same
    // the CSS gives each the colour of the theme, from the variable named third
    var COLOURS = [["#3657c9", "Module", "module"], ["#5a78de", "Submodule", "submodule"],
      ["#a61e69", "Program", "program"], ["#1d7a55", "Subroutine", "subroutine"], ["#0b7285", "Function", "function"],
      ["#6a4fb3", "Interface", "interface"], ["#a15c00", "Derived type", "type"],
      ["#7a6a2d", "Type-bound procedure", "binding"], ["#5c6f2d", "Source file", "file"],
      ["#646d7e", "External, or other", "other"], ["#8a93a5", "Not documented", "undoc"]];

    // a button that shows what is in this drawing, under it, as a short drawing can't hold a popup
    function addKey(box, svg, zoom) {
      var key = document.createElement("div");
      key.className = "graph-key";
      key.hidden = true;
      function entry(mark, text) {
        var item = document.createElement("span");
        item.className = "graph-key-item";
        item.appendChild(mark);
        item.appendChild(document.createTextNode(text));
        key.appendChild(item);
      }
      function swatch(style) {
        var mark = document.createElement("span");
        mark.className = "graph-key-mark";
        Object.keys(style).forEach(function (name) { mark.style[name] = style[name]; });
        return mark;
      }
      COLOURS.forEach(function (c) {
        if (svg.querySelector('rect[fill="' + c[0] + '"], path[fill="' + c[0] + '"]')) entry(swatch({ background: "var(--kind-" + c[2] + ")" }), c[1]);
      });
      if (svg.querySelector('rect[stroke="#f0a868"]')) entry(swatch({ border: "2px solid var(--kind-here)" }), "This page");
      if (svg.querySelector("path[stroke-dasharray]")) {
        entry(swatch({ height: "0", borderRadius: "0", borderTop: "2px dashed var(--kind-undoc)" }), "Component of a type");
      }
      var button = document.createElement("button");
      button.textContent = "?";
      button.title = "Key to the colours";
      button.setAttribute("aria-label", "Key to the colours");
      button.setAttribute("aria-expanded", "false");
      button.addEventListener("click", function () {
        key.hidden = !key.hidden;
        button.setAttribute("aria-expanded", String(!key.hidden));
      });
      zoom.appendChild(button);
      box.parentNode.insertBefore(key, box.nextSibling);
    }

    document.querySelectorAll(".graph").forEach(function (box) {
      var svg = box.querySelector("svg");
      if (!svg) return;
      var width = svg.width.baseVal.value, height = svg.height.baseVal.value, scale = 1;
      function set(value) {
        scale = Math.max(0.25, Math.min(6, value));
        box.classList.add("zoomed");
        svg.style.width = width * scale + "px";
        svg.style.height = height * scale + "px";
      }
      var zoom = document.createElement("div");
      zoom.className = "zoom";
      [["+", 1.3], ["\u2212", 1 / 1.3]].forEach(function (b) {
        var button = document.createElement("button");
        button.textContent = b[0];
        button.setAttribute("aria-label", b[1] > 1 ? "Zoom in" : "Zoom out");
        button.addEventListener("click", function () { set(scale * b[1]); });
        zoom.appendChild(button);
      });
      box.insertBefore(zoom, svg);
      addKey(box, svg, zoom);
      var fit = box.clientWidth / width;
      if (fit > 0 && fit < 0.75) set(0.75);
      var start = null;
      box.addEventListener("mousedown", function (event) {
        if (event.target.closest("a, button")) return;
        start = [event.clientX, event.clientY, box.scrollLeft, box.scrollTop];
        box.classList.add("dragging");
      });
      window.addEventListener("mousemove", function (event) {
        if (!start) return;
        box.scrollLeft = start[2] - (event.clientX - start[0]);
        box.scrollTop = start[3] - (event.clientY - start[1]);
      });
      window.addEventListener("mouseup", function () { start = null; box.classList.remove("dragging"); });
    });
  });
})();

// a link to something inside a closed section opens the section
function openTarget() {
  var id = decodeURIComponent(location.hash.slice(1));
  var target = id && document.getElementById(id);
  var section = target && target.closest('details');
  if (section) { section.open = true; target.scrollIntoView(); }
}
window.addEventListener('hashchange', openTarget);
window.addEventListener('DOMContentLoaded', openTarget);

// clicking a heading of a sortable table sorts it by that column
window.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('table.sortable').forEach(function (table) {
    var headings = table.querySelectorAll('thead th');
    headings.forEach(function (th, column) {
      th.addEventListener('click', function () {
        var body = table.tBodies[0];
        var numeric = th.classList.contains('num');
        var up = th.hasAttribute('aria-sort') ? th.getAttribute('aria-sort') === 'descending' : !numeric;
        var key = function (row) {
          var cell = row.cells[column];
          return numeric ? Number(cell.dataset.sort) : cell.textContent.toLowerCase();
        };
        var rows = Array.prototype.slice.call(body.rows);
        rows.sort(function (a, b) {
          var x = key(a), y = key(b);
          return (x < y ? -1 : x > y ? 1 : 0) * (up ? 1 : -1);
        });
        rows.forEach(function (row) { body.appendChild(row); });
        headings.forEach(function (other) { other.removeAttribute('aria-sort'); });
        th.setAttribute('aria-sort', up ? 'ascending' : 'descending');
      });
    });
  });
});

// the left sidebar: the list of this page grouped by module, a filter, folding, resizing, hiding, a
// drawer on phones, and its scroll position kept from page to page
(function () {
  var script = document.currentScript;
  var root = script ? script.src.replace(/js\/fdoc\.js.*$/, "") : "";
  var html = document.documentElement;
  var MIN = 180, MAX = 640;

  function load(key) { try { return localStorage.getItem(key); } catch (e) { return null; } }
  function store(key, value) {
    try { if (value === null) localStorage.removeItem(key); else localStorage.setItem(key, value); } catch (e) {}
  }
  function loadSet(key) { try { return JSON.parse(load(key) || "[]"); } catch (e) { return []; } }
  function storeSet(key, set) { store(key, set.length ? JSON.stringify(set) : null); }
  function toggleIn(set, item, on) {
    var k = set.indexOf(item);
    if (on && k < 0) set.push(item);
    if (!on && k >= 0) set.splice(k, 1);
  }

  // before the page is drawn, so that it doesn't jump
  var width = parseInt(load("fdoc-side-w"), 10);
  if (width >= MIN && width <= MAX) html.style.setProperty("--side-w", width + "px");
  if (load("fdoc-side-hidden") === "1") html.classList.add("side-hidden");

  function phone() { return window.matchMedia("(max-width: 860px)").matches; }

  // the arrow of a fold: a button on a heading, or a plain mark inside the button of a group
  function foldButton(mark) {
    var b = document.createElement(mark ? "span" : "button");
    b.className = "fold";
    if (!mark) b.type = "button";
    b.innerHTML = "&#9662;";
    return b;
  }

  // put the entries of `list` under a group for each module, sorted by name
  function group(list, key) {
    var items = Array.prototype.slice.call(list.children), groups = {}, names = [];
    items.forEach(function (li) {
      var a = li.querySelector("a"), m = a ? a.getAttribute("data-m") : null;
      if (m === null) return;
      if (!groups[m]) { groups[m] = []; names.push(m); }
      groups[m].push(li);
    });
    if (names.length < 2) return;
    names.sort(function (x, y) { return x.toLowerCase() < y.toLowerCase() ? -1 : x.toLowerCase() > y.toLowerCase() ? 1 : 0; });
    var open = loadSet("fdoc-open-groups");
    list.textContent = "";
    names.forEach(function (m) {
      var li = document.createElement("li"), head = document.createElement("button"), ul = document.createElement("ul");
      li.className = "group";
      li.dataset.group = key + ":" + m;
      head.className = "group-name";
      head.type = "button";
      head.appendChild(foldButton(true));
      var label = document.createElement("span");
      label.className = "label";
      label.textContent = m || "(no module)";
      head.title = label.textContent;
      head.appendChild(label);
      var n = document.createElement("span");
      n.className = "n";
      n.textContent = groups[m].length;
      head.appendChild(n);
      groups[m].forEach(function (item) { ul.appendChild(item); });
      li.appendChild(head);
      li.appendChild(ul);
      if (open.indexOf(li.dataset.group) >= 0) li.classList.add("open");
      head.addEventListener("click", function () {
        var on = li.classList.toggle("open");
        var set = loadSet("fdoc-open-groups");
        toggleIn(set, li.dataset.group, on);
        storeSet("fdoc-open-groups", set);
      });
      list.appendChild(li);
    });
  }

  // a fold button on each heading with a list after it; the folded ones are remembered
  function folding(side) {
    var folded = loadSet("fdoc-folded");
    side.querySelectorAll("h4").forEach(function (h) {
      var ul = h.nextElementSibling;
      if (!ul || ul.tagName !== "UL" || !ul.children.length) return;
      var name = h.textContent.trim(), b = foldButton(false);
      b.title = "Fold or unfold " + name;
      h.insertBefore(b, h.firstChild);
      if (folded.indexOf(name) >= 0) h.classList.add("folded");
      b.addEventListener("click", function () {
        var on = h.classList.toggle("folded"), set = loadSet("fdoc-folded");
        toggleIn(set, name, on);
        storeSet("fdoc-folded", set);
      });
    });
  }

  // the filter box at the top of the sidebar: it shows the entries whose names contain what is typed
  function filter(side) {
    var links = side.querySelectorAll("li > a");
    if (links.length < 8) return;
    var box = document.createElement("div"), input = document.createElement("input");
    var empty = document.createElement("div");
    box.className = "side-filter";
    input.type = "search";
    input.placeholder = "Filter…";
    input.setAttribute("aria-label", "Filter the sidebar");
    empty.className = "side-empty";
    empty.textContent = "Nothing matches";
    empty.hidden = true;
    box.appendChild(input);
    side.insertBefore(box, side.firstChild);
    side.appendChild(empty);
    var names = Array.prototype.map.call(links, function (a) { return (a.dataset.name || a.textContent).toLowerCase(); });

    function run() {
      var q = input.value.trim().toLowerCase(), any = false;
      side.classList.toggle("filtering", q.length > 0);
      links.forEach(function (a, k) {
        var show = !q || names[k].indexOf(q) >= 0;
        a.parentElement.hidden = !show;
        any = any || show;
      });
      side.querySelectorAll("li.group").forEach(function (g) {
        g.hidden = q && !g.querySelector("li:not([hidden])");
        g.classList.toggle("found", !!q && !g.hidden);
      });
      side.querySelectorAll("h4").forEach(function (h) {
        var ul = h.nextElementSibling;
        h.hidden = q && !(ul && ul.tagName === "UL" && ul.querySelector("li:not([hidden])"));
        if (ul && ul.tagName === "UL") ul.hidden = h.hidden;
      });
      empty.hidden = !q || any;
      if (q) side.scrollTop = 0;
    }
    input.addEventListener("input", run);
    input.addEventListener("keydown", function (event) {
      if (event.key === "Escape") { input.value = ""; run(); input.blur(); }
    });
  }

  // drag the edge of the sidebar to resize it; a double click goes back to the default width
  function resizing(side) {
    var handle = document.createElement("div");
    handle.className = "side-resize";
    handle.title = "Drag to resize, double-click to reset";
    document.body.appendChild(handle);
    function place() { handle.style.left = side.getBoundingClientRect().right + "px"; }
    place();
    window.addEventListener("resize", place);
    handle.addEventListener("pointerdown", function (event) {
      event.preventDefault();
      handle.setPointerCapture(event.pointerId);
      handle.classList.add("dragging");
      var left = side.getBoundingClientRect().left;
      function move(e) {
        var w = Math.max(MIN, Math.min(MAX, Math.round(e.clientX - left)));
        html.style.setProperty("--side-w", w + "px");
        place();
      }
      function up() {
        handle.classList.remove("dragging");
        handle.removeEventListener("pointermove", move);
        handle.removeEventListener("pointerup", up);
        store("fdoc-side-w", String(Math.round(side.getBoundingClientRect().width)));
      }
      handle.addEventListener("pointermove", move);
      handle.addEventListener("pointerup", up);
    });
    handle.addEventListener("dblclick", function () {
      html.style.removeProperty("--side-w");
      store("fdoc-side-w", null);
      place();
    });
    return place;
  }

  document.addEventListener("DOMContentLoaded", function () {
    var side = document.querySelector("aside.side"), toggle = document.querySelector(".side-toggle");
    if (!side) {
      if (toggle) toggle.hidden = true;
      return;
    }
    var list = side.querySelector("ul[data-list]"), key = list ? list.dataset.list : "";
    if (list && window.FDOC_SIDEBAR) {
      list.innerHTML = (window.FDOC_SIDEBAR[key] || "").replace(/href="@/g, 'href="' + root);
    }
    // the full name, and the module, as the tooltip of each entry
    side.querySelectorAll("li > a").forEach(function (a) {
      var name = a.textContent.trim(), m = a.getAttribute("data-m");
      a.dataset.name = name;
      a.title = m ? name + " — " + m : name;
    });
    if (list) group(list, key);

    var here = location.href.split("#")[0], current = null;
    side.querySelectorAll("li > a").forEach(function (a) {
      if (current || a.href !== here) return;
      current = a;
      a.classList.add("current");
      a.setAttribute("aria-current", "page");
      var g = a.closest("li.group");
      if (g) g.classList.add("open", "here");
    });
    folding(side);
    filter(side);
    var place = resizing(side);

    // the sidebar opens where it was left when one of its links was followed
    var saved = null;
    try { saved = JSON.parse(sessionStorage.getItem("fdoc-side-scroll") || "null"); } catch (e) {}
    try { sessionStorage.removeItem("fdoc-side-scroll"); } catch (e) {}
    if (saved && saved.list === key) side.scrollTop = saved.top;
    else if (current) side.scrollTop = current.offsetTop - side.clientHeight / 2;
    side.addEventListener("click", function (event) {
      if (!event.target.closest("a")) return;
      try { sessionStorage.setItem("fdoc-side-scroll", JSON.stringify({ list: key, top: side.scrollTop })); } catch (e) {}
      html.classList.remove("side-open");
    });

    // the button at the left of the header hides the sidebar, or on a phone opens it as a drawer
    var backdrop = document.createElement("div");
    backdrop.className = "side-backdrop";
    document.body.appendChild(backdrop);
    backdrop.addEventListener("click", function () { html.classList.remove("side-open"); });
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") html.classList.remove("side-open");
    });
    if (toggle) toggle.addEventListener("click", function () {
      if (phone()) {
        html.classList.toggle("side-open");
        return;
      }
      var hidden = html.classList.toggle("side-hidden");
      store("fdoc-side-hidden", hidden ? "1" : null);
      place();
    });
  });
})();

// the contents of the page, at the right on wide screens, with the section being read marked
document.addEventListener("DOMContentLoaded", function () {
  var main = document.querySelector("main"), layout = document.querySelector(".layout");
  if (!main || !layout) return;
  var heads = Array.prototype.filter.call(main.querySelectorAll("h2[id], .doc h1[id], .doc h3[id]"), function (h) {
    return !h.closest(".item");
  });
  if (heads.length < 2) return;
  var nav = document.createElement("nav"), ul = document.createElement("ul"), links = [];
  nav.className = "toc";
  nav.setAttribute("aria-label", "On this page");
  nav.innerHTML = "<h4>On this page</h4>";
  heads.forEach(function (h) {
    var copy = h.cloneNode(true);
    copy.querySelectorAll(".anchor").forEach(function (a) { a.remove(); });
    var li = document.createElement("li"), a = document.createElement("a");
    if (h.tagName === "H3") li.className = "sub";
    a.href = "#" + h.id;
    a.textContent = copy.textContent.trim();
    a.title = a.textContent;
    li.appendChild(a);
    ul.appendChild(li);
    links.push(a);
  });
  nav.appendChild(ul);
  layout.appendChild(nav);
  layout.classList.add("has-toc");

  var ticking = false;
  function mark() {
    ticking = false;
    var on = 0;
    heads.forEach(function (h, k) { if (h.getBoundingClientRect().top < 110) on = k; });
    links.forEach(function (a, k) { a.classList.toggle("on", k === on); });
  }
  window.addEventListener("scroll", function () {
    if (!ticking) { ticking = true; window.requestAnimationFrame(mark); }
  }, { passive: true });
  mark();
});

// Mermaid diagrams are drawn in the browser, and Mermaid is only loaded for pages that have one
(function () {
  var URL = "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js";

  function dark() {
    var theme = document.documentElement.getAttribute("data-theme");
    if (!theme) return window.matchMedia("(prefers-color-scheme: dark)").matches;
    return ["gruvbox-light", "catppuccin-latte", "rose-pine-dawn"].indexOf(theme) < 0;
  }

  document.addEventListener("DOMContentLoaded", function () {
    var blocks = document.querySelectorAll("pre.mermaid");
    if (!blocks.length) return;
    blocks.forEach(function (block) { block.dataset.source = block.textContent; });

    function draw() {
      blocks.forEach(function (block) {
        block.textContent = block.dataset.source;
        block.removeAttribute("data-processed");
      });
      window.mermaid.initialize({ startOnLoad: false, theme: dark() ? "dark" : "default" });
      window.mermaid.run({ nodes: blocks });
    }

    var tag = document.createElement("script");
    tag.src = URL;
    tag.onload = function () {
      draw();
      var select = document.querySelector("select.theme");
      if (select) select.addEventListener("change", draw);
    };
    document.head.appendChild(tag);
  });
})();

// each heading with an id, and each entry of a list, gets a link to itself
document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll("main h2[id], main h3[id], main .item[id] > h3").forEach(function (heading) {
    var id = heading.id || heading.parentElement.id;
    var link = document.createElement("a");
    link.className = "anchor";
    link.href = "#" + id;
    link.textContent = "#";
    link.setAttribute("aria-label", "Link to this section");
    heading.appendChild(link);
  });
});
