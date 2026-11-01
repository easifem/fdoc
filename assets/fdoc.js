(function () {
  var root = document.documentElement;
  var saved = null;
  try { saved = localStorage.getItem("fdoc-theme"); } catch (e) {}
  if (saved) root.setAttribute("data-theme", saved);
  document.addEventListener("DOMContentLoaded", function () {
    var button = document.querySelector(".theme");
    if (button) button.addEventListener("click", function () {
      var dark = root.getAttribute("data-theme") ? root.getAttribute("data-theme") === "dark"
        : window.matchMedia("(prefers-color-scheme: dark)").matches;
      var next = dark ? "light" : "dark";
      root.setAttribute("data-theme", next);
      try { localStorage.setItem("fdoc-theme", next); } catch (e) {}
    });
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

  function search(query, limit) {
    var words = query.toLowerCase().split(/\s+/).filter(Boolean);
    if (!words.length) return [];
    var found = [];
    entries.forEach(function (e) { var s = score(e, words); if (s > 0) found.push([s, e]); });
    found.sort(function (a, b) { return b[0] - a[0]; });
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
