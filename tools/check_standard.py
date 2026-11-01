#!/usr/bin/env python
"""Check that fdoc is standard Fortran, with no compiler extensions, so that it can build with others.

Each source file is compiled with ``-std=f2018``, using the modules of an existing build. Lines over 132
characters are errors there too. Run in the pixi env: ``pixi run check-standard``.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    builds = sorted({path.parent for path in ROOT.glob("build/gfortran_*/*.mod")}, key=lambda p: p.stat().st_mtime)
    if not any((build / "fdoc_util.mod").exists() for build in builds):
        sys.exit("build fdoc first: pixi run build")
    if not any((build / "testdrive.mod").exists() for build in builds):
        sys.exit("build the tests first: pixi run test")
    problems = 0
    with tempfile.TemporaryDirectory() as scratch:
        includes = [f"-I{build}" for build in reversed(builds)]
        files = [path for folder in ("src", "app", "example") for path in sorted((ROOT / folder).glob("*.f90"))]
        tests = sorted((ROOT / "test").glob("*.f90"), key=lambda path: (not path.name.startswith("test_"), path.name))
        for path in files + tests:
            command = ["gfortran", "-std=f2018", "-fopenmp", "-fsyntax-only", f"-I{scratch}", f"-J{scratch}"]
            result = subprocess.run(command + includes + [str(path)], capture_output=True, text=True, cwd=ROOT)
            if result.returncode != 0:
                problems += 1
                print(f"{path.relative_to(ROOT)}:\n{result.stderr[:600]}")
    print(f"{problems} problem file(s)")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
