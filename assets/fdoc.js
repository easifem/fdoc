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
