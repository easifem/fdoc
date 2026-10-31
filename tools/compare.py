#!/usr/bin/env python
"""Compare fdoc with FORD, which serves as the reference. Run in the pixi env.

    pixi run compare settings PROJECT_FILE...
    pixi run compare modules PROJECT_FILE...
    pixi run compare links PROJECT_FILE...
"""

import argparse
import json
import re
import subprocess
import sys
import tempfile
from collections import Counter
from dataclasses import asdict
from pathlib import Path

import ford
import ford.fortran_project
import ford.sourceform

ROOT = Path(__file__).resolve().parent.parent

# Calls that FORD's regular expressions miss, checked by hand: (procedure, name).
FORD_MISSES = {("ffmt_format/format_text", "same_code")}

# Not expected to agree: the time of the run, packaged paths, defaults that are fdoc's own.
IGNORED = {"creation_date", "favicon", "parallel", "extra_filetypes_lexer"}


def fdoc_binary() -> str:
    subprocess.run(
        ["fpm", "build", "--profile", "release"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    out = subprocess.run(
        ["fpm", "run", "fdoc", "--profile", "release", "--runner", "echo"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return str(ROOT / out.stdout.split()[-1])


def ford_settings(project_file: Path) -> dict:
    """FORD's settings for ``project_file``, as plain JSON-style values"""
    text = project_file.read_text(encoding="utf-8")
    directory = project_file.parent
    docs, data = ford.load_settings(text, directory, str(project_file))
    data = ford.convert_types_from_commandarguments(data, {})
    data.normalise_paths(directory)
    result = {}
    for key, value in asdict(data).items():
        if isinstance(value, Path):
            value = str(value)
        elif isinstance(value, list):
            value = [str(v) for v in value]
            if key == "extensions":
                value = sorted(value)
        elif isinstance(value, dict) and key == "extra_filetypes":
            value = {k: v["comment"] for k, v in value.items()}
        result[key] = value
    return result


def fdoc_settings(binary: str, project_file: Path) -> dict:
    out = subprocess.run(
        [binary, "--dump-settings", str(project_file)],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(out.stdout)


def compare_settings(project_files) -> int:
    binary = fdoc_binary()
    failures = 0
    for name in project_files:
        project_file = Path(name).resolve()
        try:
            reference = ford_settings(project_file)
        except Exception as e:  # FORD itself rejects this file
            print(f"SKIP {name}: FORD fails: {e}")
            continue
        try:
            ours = fdoc_settings(binary, project_file)
        except subprocess.CalledProcessError as e:
            print(f"FAIL {name}: fdoc fails: {e.stderr.strip()}")
            failures += 1
            continue
        differences = [
            f"  {key}:\n    ford: {reference[key]!r}\n    fdoc: {ours.get(key, '<missing>')!r}"
            for key in reference
            if key not in IGNORED and reference[key] != ours.get(key, "<missing>")
        ]
        if differences:
            failures += 1
            print(f"FAIL {name}")
            print("\n".join(differences))
        else:
            print(f"ok   {name}")
    print(f"{len(project_files) - failures} of {len(project_files)} agree")
    return 1 if failures else 0


def canonical(value):
    """``value`` from ``modules.json``, with lists keyed by name so that order does not matter"""
    if isinstance(value, dict):
        return {k: canonical(v) for k, v in value.items()}
    if isinstance(value, list):
        if value and all(isinstance(v, dict) and "name" in v for v in value):
            return {v["name"].lower(): canonical(v) for v in value}
        return value
    if isinstance(value, str):
        return re.sub(r"~\d+", "", value)
    return value


def differences(ours, theirs, path, found):
    """Add to ``found`` a description of each difference between two values"""
    if isinstance(ours, dict) and isinstance(theirs, dict):
        for key in sorted(set(ours) | set(theirs)):
            where = f"{path}/{key}"
            if key not in ours:
                found.append((where, "missing in fdoc", theirs[key]))
            elif key not in theirs:
                found.append((where, "extra in fdoc", ours[key]))
            else:
                differences(ours[key], theirs[key], where, found)
    elif ours != theirs:
        found.append((path, ours, theirs))


def ford_modules(project_file: Path, cache: Path) -> dict:
    """FORD's ``modules.json`` for ``project_file``, run once and cached"""
    target = cache / f"{project_file.parent.name}-{project_file.stem}"
    if not (target / "modules.json").exists():
        subprocess.run(
            [
                "ford",
                project_file.name,
                "-o",
                str(target),
                "--config",
                "graph=false;source=false;search=false",
            ],
            cwd=project_file.parent,
            check=True,
            capture_output=True,
        )
    return json.loads((target / "modules.json").read_text(encoding="utf-8"))


def compare_modules(project_files, limit: int) -> int:
    binary = fdoc_binary()
    cache = Path(tempfile.gettempdir()) / "fdoc-compare"
    failures = 0
    for name in project_files:
        project_file = Path(name).resolve()
        try:
            reference = ford_modules(project_file, cache)
        except subprocess.CalledProcessError as e:
            print(f"SKIP {name}: FORD fails: {e.stderr.decode()[-200:]}")
            continue
        output = cache / f"fdoc-{project_file.parent.name}"
        run = subprocess.run(
            [binary, "-o", str(output), project_file.name],
            cwd=project_file.parent,
            capture_output=True,
            text=True,
        )
        if run.returncode != 0:
            print(f"FAIL {name}: fdoc fails ({run.returncode}): {run.stderr[-300:]}")
            failures += 1
            continue
        ours = json.loads((output / "modules.json").read_text(encoding="utf-8"))
        found = []
        differences(
            canonical(ours["modules"]), canonical(reference["modules"]), "", found
        )
        if found:
            failures += 1
            print(f"FAIL {name}: {len(found)} differences")
            kinds = Counter(re.sub(r"/[^/]+/", "/*/", f[0]).split("/")[-1] for f in found)
            print("  by field:", kinds.most_common(10))
            for where, a, b in found[:limit]:
                print(f"  {where}\n    fdoc: {str(a)[:150]}\n    ford: {str(b)[:150]}")
        else:
            print(f"ok   {name}")
    print(f"{len(project_files) - failures} of {len(project_files)} agree")
    return 1 if failures else 0


def ford_links(project_file: Path) -> dict:
    """How FORD connects the entities of ``project_file``"""
    text = project_file.read_text(encoding="utf-8")
    docs, data = ford.load_settings(text, project_file.parent, str(project_file))
    data = ford.convert_types_from_commandarguments(data, {})
    data.normalise_paths(project_file.parent)
    data.graph = False
    project = ford.fortran_project.Project(data)
    project.correlate()

    def label(item):
        return getattr(item, "name", item).lower()

    def qualified(item):
        names = []
        while item is not None and getattr(item, "obj", "") != "sourcefile":
            names.append(item.name.lower())
            item = item.parent
        return "/".join(reversed(names))

    links = {}

    def visit(item):
        entry = {}
        if hasattr(item, "uses"):
            entry["uses"] = sorted({label(u) for u in item.uses})
        if hasattr(item, "calls"):
            entry["calls"] = sorted({label(c) for c in item.calls})
        if hasattr(item, "bindings"):
            entry["bindings"] = sorted({label(b) for b in item.bindings})
        if getattr(item, "modprocs", None):
            entry["modprocs"] = sorted(
                {label(getattr(m, "procedure", m.name) or m.name) for m in item.modprocs}
            )
        if isinstance(getattr(item, "ancestor_module", None), ford.sourceform.FortranModule):
            entry["ancestor"] = label(item.ancestor_module)
        if isinstance(getattr(item, "extends", None), ford.sourceform.FortranType):
            entry["extends"] = label(item.extends)
        tag = "#type" if getattr(item, "obj", "") == "type" else ""
        links[qualified(item) + tag] = entry
        for attr in (
            "functions",
            "subroutines",
            "interfaces",
            "absinterfaces",
            "types",
            "boundprocs",
            "modprocedures",
        ):
            for child in getattr(item, attr, []) or []:
                visit(child)

    for item in (*project.modules, *project.submodules, *project.programs):
        visit(item)
    for item in project.procedures:
        if item.parobj == "sourcefile":
            visit(item)
    return links


def compare_links(project_files, limit: int) -> int:
    binary = fdoc_binary()
    failures = 0
    for name in project_files:
        project_file = Path(name).resolve()
        try:
            reference = ford_links(project_file)
        except Exception as e:
            print(f"SKIP {name}: FORD fails: {e}")
            continue
        run = subprocess.run(
            [binary, "--dump-links", project_file.name],
            cwd=project_file.parent,
            capture_output=True,
            text=True,
        )
        if run.returncode != 0:
            print(f"FAIL {name}: fdoc fails: {run.stderr[-300:]}")
            failures += 1
            continue
        ours = json.loads(run.stdout)
        found = []
        for key, entry in reference.items():
            if key not in ours:
                continue
            for field, value in entry.items():
                theirs = ours[key].get(field)
                if field in ("uses", "calls", "bindings", "modprocs"):
                    theirs = sorted(set(theirs or []))
                if field == "calls":
                    theirs = [c for c in theirs if (key, c) not in FORD_MISSES]
                if theirs != value:
                    found.append((f"{key}:{field}", theirs, value))
        if found:
            failures += 1
            fields = Counter(f[0].split(":")[1] for f in found)
            print(f"FAIL {name}: {len(found)} of {len(reference)} entities: {fields.most_common()}")
            for where, a, b in found[:limit]:
                a, b = set(a or []), set(b or [])
                print(f"  {where}\n    only fdoc: {sorted(a - b)[:8]}\n    only ford: {sorted(b - a)[:8]}")
        else:
            print(f"ok   {name}")
    print(f"{len(project_files) - failures} of {len(project_files)} agree")
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="what", required=True)
    settings = sub.add_parser("settings", help="compare settings")
    settings.add_argument("project_files", nargs="+")
    modules = sub.add_parser("modules", help="compare modules.json")
    modules.add_argument("project_files", nargs="+")
    modules.add_argument("--limit", type=int, default=8, help="differences to print")
    links = sub.add_parser("links", help="compare how entities are connected")
    links.add_argument("project_files", nargs="+")
    links.add_argument("--limit", type=int, default=8, help="differences to print")
    args = parser.parse_args()
    if args.what == "links":
        return compare_links(args.project_files, args.limit)
    if args.what == "modules":
        return compare_modules(args.project_files, args.limit)
    return compare_settings(args.project_files)


if __name__ == "__main__":
    sys.exit(main())
