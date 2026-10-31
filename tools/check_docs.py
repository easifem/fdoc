#!/usr/bin/env python
"""Check that every routine and argument of fdoc is documented.

A routine needs an ``!>`` block before it, and each argument an inline ``!!`` on its declaration
(or a ``!!`` line straight after it). Run in the pixi env: ``pixi run check-docs``.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HEADER = re.compile(
    r"^\s*(?:(?:pure|elemental|recursive|impure|integer|logical|real|module|character\(len=\d+\))\s+)*"
    r"(subroutine|function)\s+(\w+)\s*(?:\(([^)]*)\))?",
    re.IGNORECASE,
)
END = re.compile(r"^\s*end\s+(subroutine|function)\b", re.IGNORECASE)


def declared(line: str):
    """The names declared on ``line``, if it is a declaration"""
    code = line.split("!")[0]
    if "::" not in code:
        return []
    names = re.sub(r"\([^()]*\)|\[[^\]]*\]", "", code.split("::", 1)[1])
    return [n.split("=")[0].strip().lower() for n in names.split(",")]


def check(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines()
    problems = []
    for i, line in enumerate(lines):
        match = HEADER.match(line)
        if not match or END.match(line):
            continue
        name = match.group(2)
        where = f"{path.relative_to(ROOT)}:{i + 1}: {name}"
        if i == 0 or not lines[i - 1].lstrip().startswith("!>"):
            problems.append(f"{where}: no !> block before it")
        args = [a.strip().lower() for a in (match.group(3) or "").split(",") if a.strip()]
        for arg in args:
            for j in range(i + 1, len(lines)):
                if END.match(lines[j]):
                    problems.append(f"{where}: argument {arg} not declared")
                    break
                names = declared(lines[j])
                if arg in names:
                    following = j + 1 < len(lines) and lines[j + 1].lstrip().startswith("!!")
                    if len(names) > 1:
                        problems.append(f"{where}: argument {arg} shares a declaration")
                    elif "!!" not in lines[j] and not following:
                        problems.append(f"{where}: argument {arg} is not documented")
                    break
    return problems


def main() -> int:
    problems = []
    for directory in ("app", "src", "test", "example"):
        for path in sorted((ROOT / directory).glob("*.f90")):
            problems += check(path)
    print("\n".join(problems))
    print(f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
