#!/usr/bin/env python
"""Compare fdoc with FORD, which serves as the reference. Run in the pixi env.

    pixi run compare settings PROJECT_FILE...
"""

import argparse
import json
import subprocess
import sys
from dataclasses import asdict
from pathlib import Path

import ford

ROOT = Path(__file__).resolve().parent.parent

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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="what", required=True)
    settings = sub.add_parser("settings", help="compare settings")
    settings.add_argument("project_files", nargs="+")
    args = parser.parse_args()
    return compare_settings(args.project_files)


if __name__ == "__main__":
    sys.exit(main())
