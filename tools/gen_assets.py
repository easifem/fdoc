#!/usr/bin/env python
"""Generate src/fdoc_assets.f90, which holds assets/ in the program. Run: pixi run gen-assets"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WIDTH = 96


def literal(text: str):
    """The Fortran expression for ``text``, as lines of a concatenation"""
    chunks = [text[i : i + WIDTH] for i in range(0, len(text), WIDTH)]
    lines = []
    for chunk in chunks:
        parts = []
        for piece in chunk.split("\n"):
            parts.append("'" + piece.replace("'", "''") + "'")
        lines.append("//NL//".join(parts))
    return lines


def function(name: str, text: str) -> str:
    # one assignment per 100 lines: compilers limit the continuation lines of a statement
    lines = literal(text)
    body = [f"    !> The contents of `assets/{name}`.", f"subroutine asset_{name.replace('.', '_')}(text)"]
    body = [
        f"!> The contents of `assets/{name}`.",
        f"subroutine asset_{name.replace('.', '_')}(b)",
        "    type(buffer_t), intent(inout) :: b  !! where they go",
    ]
    for start in range(0, len(lines), 100):
        group = lines[start : start + 100]
        body.append("    call add(b, &")
        for i, line in enumerate(group):
            prefix = "        " + ("//" if i else "")
            body.append(prefix + line + (" &" if i < len(group) - 1 else ")"))
    body.append(f"end subroutine asset_{name.replace('.', '_')}")
    return "\n".join(body)


def main():
    names = ["fdoc.css", "fdoc.js"]
    parts = [
        "module fdoc_assets",
        "!! The style sheet and script of the site. Generated from `assets/` by `tools/gen_assets.py`.",
        "use fdoc_buffer, only: buffer_t, add",
        "implicit none",
        "private",
        "",
        "public :: " + ", ".join("asset_" + n.replace(".", "_") for n in names),
        "",
        "character, parameter :: NL = achar(10)",
        "",
        "contains",
        "",
    ]
    for name in names:
        parts.append(function(name, (ROOT / "assets" / name).read_text(encoding="utf-8")))
        parts.append("")
    parts.append("end module fdoc_assets")
    (ROOT / "src" / "fdoc_assets.f90").write_text("\n".join(parts) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
