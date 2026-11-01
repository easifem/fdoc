#!/usr/bin/env python
"""Compare the speed of fdoc and FORD on real projects, and print Markdown tables.

    pixi run bench PROJECT_FILE...

Each tool runs on the project's own settings, then again with graphs turned off. fdoc runs three times
and FORD once, and the best time of the runs is reported.
"""

import argparse
import os
import re
import shutil
import statistics
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = {".f90", ".F90", ".f95", ".f03", ".f08"}


def fdoc_binary() -> str:
    subprocess.run(["fpm", "build", "--profile", "release"], cwd=ROOT, check=True, capture_output=True)
    out = subprocess.run(
        ["fpm", "run", "fdoc", "--profile", "release", "--runner", "echo"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return str(ROOT / out.stdout.split()[-1])


def source_lines(project_file: Path) -> int:
    text = project_file.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"^src_dir:\s*(\S+)", text, re.MULTILINE)
    source = project_file.parent / (match.group(1) if match else "src")
    total = 0
    for path in source.rglob("*"):
        if path.suffix in SOURCE:
            total += path.read_bytes().count(b"\n")
    return total


def measure(command, cwd: Path):
    """Time ``command``, returning seconds and peak memory in MB, or None if it failed"""
    run = subprocess.run(["/usr/bin/time", "-l", *command], cwd=cwd, capture_output=True, text=True)
    if run.returncode != 0:
        return None
    seconds = float(re.search(r"([\d.]+) real", run.stderr).group(1))
    memory = int(re.search(r"(\d+)\s+maximum resident set size", run.stderr).group(1))
    return seconds, memory / 1e6


def size_of(directory: Path) -> float:
    return sum(p.stat().st_size for p in directory.rglob("*") if p.is_file()) / 1e6


def best(command, cwd, output, repeats):
    results = []
    for _ in range(repeats):
        shutil.rmtree(output, ignore_errors=True)
        result = measure(command, cwd)
        if result is None:
            return None
        results.append(result)
    return min(r[0] for r in results), max(r[1] for r in results), size_of(output)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project_files", nargs="+")
    parser.add_argument("--repeats", type=int, default=3, help="runs of fdoc")
    args = parser.parse_args()
    binary = fdoc_binary()
    out = Path(tempfile.mkdtemp(prefix="fdoc-bench-"))
    rows = []
    for name in args.project_files:
        project_file = Path(name).expanduser().resolve()
        cwd, file = project_file.parent, project_file.name
        title = cwd.name
        lines = source_lines(project_file)
        row = {"name": title, "lines": lines}
        for mode, config in (("full", []), ("nographs", ["--config", "graph=false"])):
            target = out / "ford"
            row["ford", mode] = best(["ford", file, "-o", str(target), *config], cwd, target, 1)
            target = out / "fdoc"
            row["fdoc", mode] = best([binary, "-q", "-o", str(target), *config, file], cwd, target, args.repeats)
            print(f"{title} {mode}: ford {row['ford', mode]} fdoc {row['fdoc', mode]}", file=sys.stderr, flush=True)
        rows.append(row)
    shutil.rmtree(out, ignore_errors=True)

    def cell(value):
        return f"{value:,.2f} s" if value < 100 else f"{value:,.0f} s"

    print("| Project | Lines | FORD | fdoc | Speedup | FORD, no graphs | fdoc, no graphs | Speedup |")
    print("|---|---:|---:|---:|---:|---:|---:|---:|")
    speedups = []
    for r in rows:
        a, b, c, d = r["ford", "full"], r["fdoc", "full"], r["ford", "nographs"], r["fdoc", "nographs"]
        if not all((a, b, c, d)):
            print(f"| {r['name']} | {r['lines']:,} | failed | | | | | |")
            continue
        speedups.append(c[0] / d[0])
        print(
            f"| {r['name']} | {r['lines']:,} | {cell(a[0])} | {cell(b[0])} | {a[0] / b[0]:.0f}× "
            f"| {cell(c[0])} | {cell(d[0])} | {c[0] / d[0]:.0f}× |"
        )
    print()
    print("| Project | FORD memory | fdoc memory | FORD site | fdoc site |")
    print("|---|---:|---:|---:|---:|")
    for r in rows:
        a, b = r["ford", "full"], r["fdoc", "full"]
        if a and b:
            print(f"| {r['name']} | {a[1]:,.0f} MB | {b[1]:,.0f} MB | {a[2]:,.0f} MB | {b[2]:,.0f} MB |")
    if speedups:
        print(f"\nmedian speedup without graphs: {statistics.median(speedups):.0f}×", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
