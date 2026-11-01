#!/usr/bin/env python
"""Check that code running in parallel has no static string lengths.

gfortran keeps the length of a deferred-length function result in a static ``slen.N`` variable, which
threads share (see ``example/slen_race.f90``). The objects of modules used in parallel loops must have
none. Run in the pixi env: ``pixi run check-threads``.
"""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# modules whose code runs in parallel loops
PARALLEL = [
    "fdoc_parser",
    "fdoc_decl",
    "fdoc_model",
    "fdoc_markdown",
    "fdoc_fypp",
    "fdoc_shell",
    "fdoc_urls",
    "fdoc_docs",
    "fdoc_site",
    "fdoc_highlight",
    "fdoc_buffer",
    "fdoc_progress",
    "fdoc_graphs",
    "ffmt_lexer",
    "ffmt_statements",
    "ffmt_constructs",
    "ffmt_structure",
    "ffmt_directives",
    "ffmt_source",
    "ffmt_tokens",
    "ffmt_strings",
]


def main() -> int:
    bad = 0
    for module in PARALLEL:
        objects = sorted(
            (ROOT / "build").glob(f"gfortran_*/fdoc/*{module}.f90.o"),
            key=lambda p: p.stat().st_mtime,
        )
        if not objects:
            print(f"{module}: no object file")
            bad += 1
            continue
        symbols = subprocess.run(
            ["nm", str(objects[-1])], check=True, capture_output=True, text=True
        ).stdout
        count = sum("slen." in line for line in symbols.splitlines())
        if count:
            print(f"{module}: {count} static string length(s)")
            bad += 1
    print(f"{bad} problem module(s)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
