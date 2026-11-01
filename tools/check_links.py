#!/usr/bin/env python
"""Check the internal links and anchors of generated sites, and compare their pages with FORD's.

    pixi run check-links SITE_DIR [FORD_SITE_DIR]
"""

import re
import sys
from collections import Counter
from pathlib import Path
from urllib.parse import unquote

HREF = re.compile(r'(?:href|src)="([^"]+)"')
ID = re.compile(r'\sid="([^"]+)"')


def check(site: Path):
    pages = sorted(site.rglob("*.html"))
    ids = {p: set(ID.findall(p.read_text(encoding="utf-8", errors="replace"))) for p in pages}
    broken = Counter()
    examples = {}
    total = 0
    for page in pages:
        text = page.read_text(encoding="utf-8", errors="replace")
        text = re.sub(r"<pre.*?</pre>", "", text, flags=re.S)
        for link in HREF.findall(text):
            if re.match(r"[a-z]+:", link) or link.startswith("//"):
                continue
            total += 1
            path, _, fragment = link.partition("#")
            target = (page.parent / unquote(path)).resolve() if path else page.resolve()
            problem = None
            if not target.exists():
                problem = "missing page"
            elif fragment and target.suffix == ".html":
                if target not in ids:
                    ids[target] = set()
                if unquote(fragment) not in ids[target] and fragment not in ids[target]:
                    problem = "missing anchor"
            if problem:
                broken[problem] += 1
                examples.setdefault(problem, f"{page.relative_to(site)} -> {link}")
    return len(pages), total, broken, examples


def main() -> int:
    site = Path(sys.argv[1]).resolve()
    count, total, broken, examples = check(site)
    print(f"{site.name}: {count} pages, {total} internal links, broken: {dict(broken)}")
    for problem, example in examples.items():
        print(f"  {problem}: {example}")
    if len(sys.argv) > 2:
        ford = Path(sys.argv[2]).resolve()
        ours = {str(p.relative_to(site)) for p in site.rglob("*.html")}
        theirs = {str(p.relative_to(ford)) for p in ford.rglob("*.html")}
        print(f"  pages only in fdoc: {len(ours - theirs)} {sorted(ours - theirs)[:6]}")
        print(f"  pages only in FORD: {len(theirs - ours)} {sorted(theirs - ours)[:6]}")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
