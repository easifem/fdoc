# fdoc: a FORD replacement in modern Fortran

Scope: **free-form Fortran only for now.** Fixed-form input is deferred (see M8).

**Requirement: fdoc must run on Windows, macOS and Linux.** This applies to the program, its tests and
its output, not only to the build. Commands that depend on the shell belong in `fdoc_shell`, and code
must not depend on POSIX-only functions unless a tested alternative exists for each platform. It has only been tested on macOS so far; what
stands in the way is listed in M9.

**Requirement: portable, standard Fortran.** fdoc must be able to build with other compilers, such as
ifx, though only gfortran is tested for now. Compiler extensions are not used, which `pixi run
check-standard` checks with `-std=f2018`. C library routines are used only for what has no Fortran
equivalent: sleeping (`usleep`), detecting a terminal (`isatty`), and in fformat listing directories
(`opendir`, `readdir`, `closedir`) and the current directory (`getcwd`).

**Requirement: test in the pixi env.** The pixi env is what users run, so results count only from
that configuration, with the exact compiler and runtime in `pixi.lock`.

Goal: `fdoc ford.md` takes the same project file, flags and doc comments as FORD and produces a
clean, modern HTML site, fast. It runs from a single Fortran binary with no Python at runtime.

All commands run in the pixi env and everything builds with fpm: `pixi run fpm build`,
`pixi run fpm test`. Dependency sources live in `build/dependencies/`.

## 1. What was measured

| Measurement | Result |
|---|---|
| FORD 7.0.13, bspline-fortran (13.2k lines, `source`+`graph`) | 25.3 s, 182 MB, 165 pages |
| FORD 7.0.13, json-fortran (18.2k lines, `source`+`graph`) | 65.4 s, 356 MB, 400 pages, 80 MB output (7.1 MB is the search DB) |
| Where FORD's time goes (bspline, profiled run) | Roughly half is ~450 `dot` subprocess calls; the rest was not broken down |
| fformat lexer + statements + structure, as a dependency, unmodified | ~950k lines/s; 3.2M lines in 8,969 files in 3.4 s (serial, release) |
| Same parse on json-fortran | 18 ms |
| Parallel parse with fformat 1.0.1 | **Not thread-safe**: heap corruption and wrong results, even with serial reads |
| Parallel read + parse with fformat 1.0.2 | Correct: 40 runs of 8,969 files at 1–10 threads, plus debug and guard-page allocator runs |
| gfortran 15.3 and 16.2 deferred-length function results under threads | **Compiler defect**: wrong lengths in valid code (`example/slen_race.f90`) |
| Parse scaling (before the cause was known, so indicative only) | 2.9 s at 1 thread, 1.6 s at 2, 1.1 s at 4, ~1.5 s at 8+ (machine has 4 performance cores) |
| Parallel writes (4,000 files) | Correct at 1–8 threads; speedup stops at 3–4 |

### Conclusions

- Parsing will not be the bottleneck, and fformat is good enough to build on.
- `dot` is the largest single cost and is external, so graph runs have a floor that fdoc only
  partly controls. See M7.
- OpenMP works, except for one gfortran 15.3 defect that explains every failure seen. The caller of
  a function returning `character(len=:), allocatable` keeps the result's length in static storage
  (`slen.N` in `__bss`), which threads share. The code is valid and the result is wrong lengths,
  wild copies and heap corruption.
  - No option helps: `-frecursive`, `-fstack-arrays`, `-fautomatic`, `-fmax-stack-var-size` and the
    `recursive` attribute all fail. An `intent(out)` deferred-length argument is clean.
  - fformat's parser calls such functions (`word`, `view_word`, `opened`, ...), caught exactly in
    `classify_statement` with the guard-page allocator. Earlier crashes in `read` and `malloc` were
    this corruption surfacing elsewhere; file I/O itself was never shown to be at fault.
  - `nm` on an object file lists the `slen.` symbols, so affected code can be found mechanically.

## 2. Decisions

1. **Use fformat as an fpm dependency, not a copy, and improve it upstream.** It links unchanged.
   Move it from `[dev-dependencies]` to `[dependencies]`, pinned to tag `1.0.2`, and bump the tag as
   changes land. Both projects have the same owner, so general Fortran parsing belongs in fformat
   and documentation logic belongs in fdoc. Likely upstream changes:
   - Fixed-form lexing, when fixed-form support is taken up (deferred, see M8).
   - Declaration parsing (attributes, kinds, argument lists) if fformat's own rules can use it too.
   - Lower allocation in `statement_view_t` and the token paths if profiling at M2 shows contention.
   - Done in 1.0.2: deferred-length functions removed from the parse path, with the same public
     interfaces (`to_s`, `token_text`, `token_lower`, `construct_label` and `word`).
   - Any Windows fix to `ffmt_fs`.
2. **Reimplement from behavior; never translate FORD's code.** FORD is GPLv3 and fdoc is MIT, so
   no FORD code, templates or CSS may be copied or ported. Work from its docs and observed
   output. The `modules.json` schema is treated as an interface.
3. **Same URLs, new look.** Keep FORD's URL layout and anchors (`module/x.html`,
   `proc/x.html`, `#variable-rk`, `sourcefile/`, `lists/`, `page/`, `modules.json`) so existing
   links and external projects keep working. Markup and styling are all new.
4. **No template engine.** Pages are rendered by Fortran procedures into string buffers. That is
   faster and simpler, but it means `html_template_dir` is not supported (see section 7).
5. **Keep Graphviz in v1**, batched and parallel. Replacing it is optional later work.
6. **Concurrency model:** OpenMP via fpm's `openmp` metapackage, defaulting to 4 threads;
   `parallel:` overrides.
   - Parsing is parallel, on fformat 1.0.2 or later.
   - Parallel stages (markdown, rendering) are fdoc's own code. They never call a function returning
     a deferred-length string; they use `intent(out)` arguments or caller-supplied buffers.
   - File I/O moves into the parallel loops only if measurement shows a gain.
   - `test/stress_parallel.f90` checks parallel parsing as part of `fpm test`.
7. **Handles, not pointers.** All entities live in one array and refer to each other by integer
   index, with name lookup through hash tables. Each file parses into a private result; a serial
   merge step builds the global model.

## 3. Pipeline

```
ford.md / fpm.toml [extra.ford] + CLI
  → settings
  → discover files → read (serial) → preprocess
  → parse (parallel): tokens, statements, structure, doc comments, entities
  → merge → correlate (use/rename, extends, generics, bound procs, submodules, calls)
  → markdown (parallel): doc text → HTML, resolving [[links]] and |aliases|
  → render pages (parallel, to buffers) + graphs + search index + modules.json
  → write (serial), copy media/assets
```

## 4. Source layout

| Area | Modules (`src/`) | Rough size |
|---|---|---|
| Config | `fdoc_cli`, `fdoc_settings`, `fdoc_project_file` | 1,000 |
| Input | `fdoc_input` (discovery, preprocessing, `include`) | 500 |
| Fortran | `fdoc_model`, `fdoc_docs` (doc comments, meta, doxygen), `fdoc_parser`, `fdoc_decl` | 3,000 |
| Semantics | `fdoc_correlate`, `fdoc_calls`, `fdoc_intrinsics`, `fdoc_external` | 1,500 |
| Markdown | `fdoc_md_block`, `fdoc_md_inline`, `fdoc_md_ext` | 2,000 |
| Output | `fdoc_html`, `fdoc_pages`, `fdoc_lists`, `fdoc_pagetree`, `fdoc_highlight`, `fdoc_search` | 3,000 |
| Graphs | `fdoc_graph`, `fdoc_dot` | 800 |

Sizes are estimates, about 12k lines of Fortran in total.

Reused from fformat: `ffmt_lexer`, `ffmt_tokens`, `ffmt_statements`, `ffmt_constructs`,
`ffmt_structure`, `ffmt_source`, `ffmt_io` (serial only), `ffmt_fs`, `ffmt_walk`, `ffmt_strings`.

Still missing: declarations (`fformat` classifies statements but doesn't parse attributes, types
or argument lists) and doc comment attachment. Doc comments go in fdoc; declarations are a candidate
for fformat (decision 1), which would shrink `fdoc_decl`. Fixed-form input is deferred.

No hand-written JSON or TOML: json-fortran handles all JSON (`modules.json`, search index,
settings dump) and toml-f handles TOML, both as direct fpm dependencies. fregex comes in through
fformat, and toml-f stays at fformat's pinned tag (`v0.5.2`).

## 5. Milestones

Each milestone ends with something that can be run and compared against FORD.

### M0. Foundation

- Fix the build. `pixi run fpm build` currently fails with `ar: no archive members specified`:
  `auto-executables = false` with no `[[executable]]` entry means nothing uses the library, so
  fpm prunes every object. Adding the `[[executable]]` and having `app/main.f90` use the library
  fixed this in a scratch copy.
- Move fformat to `[dependencies]`; add json-fortran, toml-f and `openmp = "*"`.
- Add pixi tasks: `build`, `test`, `doc`, `compare`, `bench`.
- Replace `say_hello` with a `test-drive` suite.
- Add `test/stress_parallel.f90` (parallel parse compared with serial) and `example/slen_race.f90`
  (the compiler defect, run with `fpm run --example`).
- Add `tools/check_docs.py` (`pixi run check-docs`): every routine has an `!>` block and every
  argument an inline `!!`.
- Add `tools/compare.py` (run in the pixi env, dev-only) and a corpus: bspline-fortran,
  json-fortran, roots-fortran, fformat, plus the other `ford.md` projects under `~/git`.

### M1. Settings and CLI

- Project file: optional `---` fences, `key: value`, indented continuation lines, repeated keys,
  body as the front-page markdown.
- `[extra.ford]` in `fpm.toml` **replaces** the project file's metadata when present, matching
  FORD.
- All `ProjectSettings` keys parse. Implement defaults, type coercion, path normalization, docmark
  conflict checks, `extra_filetypes`, `extra_mods`, `license` mapping, `creation_date` (strftime).
- All CLI flags, including `--config`, `-m`, `-I`, `-L`, `--no-search`, `--no-externalize`.
- Unknown keys warn. Recognized but unsupported keys warn by name.
- Done when: every `ford.md` in the corpus loads, and a settings dump matches FORD's.

### M2. Fortran model

- Doc comments: `docmark`, `predocmark`, both `_alt` forms, inline after code, inside continued
  statements (per-argument docs), `!!` meta lines (`author`, `summary`, `date`, `since`, `display`,
  `graph`, `source`, `deprecated`, `category`, `license`, `version`), doxygen translation.
- Entities: module, submodule, program, block data, subroutine, function, separate module
  procedure, interface (generic, abstract, operator, assignment), derived type, enum, bound
  procedure, final, variable, parameter, namelist, common, `use`.
- Declarations: full attribute, kind, length, dimension and initializer parsing from tokens.
- `display`, `hide_undoc`, `proc_internals`, `sort` modes, `lower`.
- `source: true` slices original bytes from token ranges, with no re-reading.
- Done when: fdoc writes `modules.json`, and it matches FORD's output across the corpus. This
  gives an exact parser oracle before any HTML exists. **Reached:** `pixi run compare modules`
  agrees on the 34 local projects. Page names with `~N` suffixes are not compared yet (M5).

### M3. Correlation

- Resolve `use` (renames, `only`), `extends` and inherited components and bound procedures,
  generics, interface bodies, submodule-to-parent, `extra_mods`, external projects through
  `modules.json` (`-L`, `external:`, local path or URL), and intrinsics.
- Call analysis from tokens, including `call a%b%c()`, and function references distinguished from
  arrays using the resolved scope.
- Done when: uses, calls and inheritance lists match FORD, with differences reviewed one by one.
  Token-based call analysis should beat FORD's regexes in places, so a difference may be a fix.
  **Reached:** `pixi run compare links` agrees on the 34 local projects, apart from calls FORD
  misses (listed in `tools/compare.py`). External projects were tried by hand against one
  FORD-written `modules.json`; remote `http` ones use `curl` and are untested.

### M4. Markdown

Python-Markdown's dialect, not CommonMark: the corpus was written against it (4-space list
nesting, for example).

- Core blocks and inlines, HTML passthrough.
- `extra`: fenced code, tables, footnotes, `attr_list`, `def_list`, `abbr`, `md_in_html`.
- Built-in `toc` and `smarty` (used by json-fortran and fpm), `{!file!}` includes (`md_base_dir`),
  math passthrough, `${ENV}` substitution.
- FORD extensions: `[[name]]`, `[[name(type)]]`, `[[parent:child]]`, `|alias|` with `\|` escape,
  `|url|`, `|media|`, `|page|`, admonitions (`@note`, `@warning`, `@todo`, `@bug`, `@history`, with
  all four ending rules).
- Highlighting: Fortran from fformat's tokens; small table-driven lexers for bash, python, C,
  JSON, TOML. Anything else is plain, escaped.
- Hand-written scanners, not regex, for speed.
- Done when: differential tests of corpus doc text against Python-Markdown (run from
  `tools/compare.py`) pass with an agreed list of accepted differences.
  **Reached:** `pixi run compare markdown` agrees on 16,593 of 16,649 corpus texts. A further 40
  differ because FORD drops everything after a `<` such as `x<y`; fdoc keeps that text. Of the
  other 16, most are FORD output that is itself wrong (`<script>` nested in `<script>`, a literal
  `@note`), and the rest are odd runs of `*` and backticks in link addresses. To do for parity:
  - Abbreviations are per text. FORD's one Markdown object lets them leak from text to text, in
    processing order, so make a `*[X]:` definition apply to the whole project.
  - Doxygen `@param` and `@see` are not translated yet.
  - `toc` and `smarty` have unit tests, but the comparison does not turn them on.
  - Code blocks are not highlighted yet (M5).

### M5. HTML site

- All page types: index, module, procedure, type, interface, program, block data, namelist,
  sourcefile, and the `lists/` pages.
- Design, in hand-written CSS with no Bootstrap or Font Awesome:
  - Left navigation, right "on this page" outline, content column capped for reading.
  - Light and dark themes via `prefers-color-scheme`, plus a toggle.
  - System font stack, inline SVG icons, responsive to phone width.
  - Procedure signatures as readable cards; argument tables with intent and type linked.
  - Copy button on code, deep links on headings.
- Self-contained except math: CSS/JS are embedded in the binary. fpm has no pre-build step, so
  `pixi run gen-assets` turns `assets/` into a committed `src/fdoc_assets.f90`.
- MathJax loads only on pages that contain math.
- `css:` and `favicon:` overrides work as in FORD.
- Check: Lighthouse-style accessibility pass, keyboard navigation.
- **Reached so far:** `fdoc ford.md` writes the site. Page sets match FORD's on the projects compared
  (apart from `search.html`, M6), and `pixi run check-links` checks every internal link. Code in
  languages other than Fortran is not highlighted yet.

### M6. Pages, search, externals

- `page_dir` tree (`title`, `ordered_subpage`, `copy_subdir`), `media_dir`.
- Client-side search with a small vanilla JS file: compact name + summary index first, full text
  optional, well under FORD's 7.1 MB for json-fortran.
- `modules.json` export finalized and checked by loading it from a real FORD project and vice
  versa.
- **Reached.** Static pages match FORD's file set on json-fortran's `pages/`, tried with `-p pages`
  because no local project sets `page_dir`. The search index is 64 KB against FORD's 7.1 MB, is a
  script so that it works from `file://`, and does not hold full text. FORD reads fdoc's
  `modules.json` and fdoc reads FORD's; `http` projects were tried against a local server.

### M7. Graphs

- All FORD graph types: module, uses, used-by, file, type, inherits, calls, called-by, and project
  graphs; `graph_maxdepth`, `graph_maxnodes`, `coloured_edges`, `graph_dir`.
- Deduplicate identical graphs, then pass batches of `.gv` files to one `dot -Tsvg -O` per worker
  rather than one process per graph. The saving needs measuring; if `dot` layout itself dominates,
  batching helps less than hoped.
- Small own pan/zoom script; theme-aware SVG colors.
- Warn clearly if `graph: true` and `dot` is missing, and carry on without graphs.
- **Reached.** Module, type, file and interface graphs have the same nodes as FORD's on bspline-fortran
  and json-fortran, and call graphs nearly so; `dot` takes batches of 25 files, with no process per
  graph. Unlike FORD, project-wide graphs of more than 400 nodes are left out, and graphs too large
  for `graph_maxnodes` are not turned into tables. Graphs are embedded, and rewritten after `dot` to
  take half the space with the same drawing: json-fortran's site is 29 MB, against 80 MB with FORD.

### M8. Preprocessing

- `preprocessor:` runs the configured command, in parallel subprocesses to temp files.
- FORD's default is `pcpp`, which is Python: when that default is in effect, use `gfortran -E -cpp`
  and say so. Respect `macro`, `include`, `fpp_extensions`.

**Fixed form is deferred.** Files with `fixed_extensions` are skipped with a warning naming them;
`fixed_extensions` and `fixed_length_limit` are still read from the project file. If taken up later,
add fixed-form lexing to fformat if practical, otherwise a fixed→free pass in `fdoc_fixed`; either
way doc comments and line numbers must survive.

**Fypp is ported, in part.** fdoc does not call external Python programs, and `fypp` is one, so
`fdoc_fypp` is a port of what stdlib needs, in a single module; its output for stdlib is byte-identical
to Fypp's. A `preprocessor:` of `fypp` uses it. Deferred until a project needs them: `#:del`,
`#:global`, `#:stop`, `#:nextarg`, `#:contains`, direct calls (`@:`, `@{...}@`), line numbering, the
predefined variables such as `_LINE_`, and any Python beyond the expressions and functions it lists.
What is not supported stops with an error naming it, and the file is read as it is, with a warning.

- Measured on macOS arm64 with `example/io_race.f90`: Fortran file I/O from several threads, on
  separate units, crashes in `check_for_recursive` with libgfortran 16.2, which is what the pixi env
  uses (51 of 949 runs). File statements in parallel code go inside `!$omp critical (file_io)`.

### M9. Parity and handover

- Full corpus runs clean; publish benchmark table.
- README: migration notes and the differences in section 7.
- Parity bar for swapping: every corpus project builds, no missing entities, no broken internal
  links (checked by script), accepted differences listed.
- After that, move `ford` and `python` in `pixi.toml` to a `compare` feature, so the default env
  has no Python. Provide `ford` as a pixi task or symlink for scripts that call it by name.
- Platforms: Windows, macOS and Linux are all required, and the bar for swapping includes the tests
  and `pixi run test-projects` on each, in CI, where Windows does not count yet. Known work:
  - File system commands are in `fdoc_shell`, which picks the command for the platform at run time, as
    standard Fortran cannot create or copy directories. `curl` for external projects is still needed.
  - POSIX functions: `usleep` and `isatty` in fdoc, and `opendir`, `readdir`, `closedir` and `getcwd`
    in fformat, need checking on Windows.
  - Paths: backslashes, drive letters and case-insensitive names, in settings, `exclude` and URLs.
  - Text: CRLF line endings, and UTF-8 paths.
  - `execute_command_line(wait=.false.)` is expected to run in turn on Windows. Check that, and the
    speed of graph layout there.
  - A preprocessor default that works where `gfortran -E` does, and `curl` for external projects,
    which may need to be optional.

Suggested order: M0 → M1 → M2 → M3, then M4 and M5 together with a first usable site at the end of
M5. M6–M8 are independent.

## 6. Performance targets

| Case | FORD | fdoc target |
|---|---|---|
| json-fortran, no graphs | not measured yet | under 0.5 s |
| json-fortran, full | 65.4 s | under 5 s, depends on `dot` |
| Peak memory, json-fortran | 356 MB | under 100 MB |

Targets, not results. `pixi run bench` tracks them from M2 on.

## 7. Known differences from FORD

- Fixed-form sources are not documented yet: they are skipped with a warning.
- `html_template_dir` is not supported, because there are no Jinja templates.
- `md_extensions` beyond the built-ins can't load Python extensions; they warn and are skipped.
- `preprocessor: pcpp` runs through gfortran.
- `preprocessor: fypp` uses the port in `fdoc_fypp`, which covers what stdlib needs (see M8).
- Generated HTML differs in markup, so user CSS that targets FORD's classes needs rewriting.

## 8. Risks

| Risk | Handling |
|---|---|
| Markdown dialect edge cases are the largest source of visible bugs | Differential tests against Python-Markdown on the real corpus from day one |
| Corpus is mostly one author's style | Add third-party projects (stdlib, fpm, toml-f) at M2 |
| Fypp sources aren't valid Fortran, and Fypp is Python | `fdoc_fypp` ports what stdlib needs; what it lacks is reported as an error (see M8) |
| Scaling past 4 threads is unknown; earlier numbers were affected by the defect | Reuse buffers in parallel stages; measure at M4 |
| gfortran-only behavior | Only gfortran is supported through the pixi env for v1 |
| Windows is required but untested: `win-64` is in `pixi.toml`, but `ffmt_fs` binds POSIX `opendir`/`readdir` | Test at M0. If it fails, drop `win-64` until v1 or fix upstream |
| gfortran deferred-length defect reaches a parallel stage | A `check-threads` tool (with M4, the first parallel code) fails if parallel modules contain `slen.` symbols; retest `slen_race` on compiler upgrades |
