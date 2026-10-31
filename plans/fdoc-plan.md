# fdoc: a FORD replacement in modern Fortran

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
| Parallel read + parse, all state local to a called procedure | Results match serial, file by file (8,969 files, 3 passes each at 4/8/10 threads) |
| Same, repeated at 6 and 8 threads | Intermittent segfault: 0 of 10 runs with default stacks, 3 of 10 with `OMP_STACKSIZE=64M` |
| OpenMP `private()` on a deferred-length string | **Wrong**: 76 bad lengths in 3M iterations at 8 threads, with no file I/O |
| Parallel parse with reads serialized | Correct at 1/4/8/10 threads, even with `private()` on strings |
| Parse scaling | 2.9 s at 1 thread, 1.6 s at 2, 1.1 s at 4, ~1.5 s at 8+ (machine has 4 performance cores) |
| Parallel writes (4,000 files) | Correct at 1–8 threads; speedup stops at 3–4 |

### Conclusions

- Parsing will not be the bottleneck, and fformat is good enough to build on.
- `dot` is the largest single cost and is external, so graph runs have a floor that fdoc only
  partly controls. See M7.
- OpenMP is viable, but the two failures have to be handled separately:
  - The wrong counts came from the spike's `private(text)`, a gfortran problem with
    deferred-length strings. It is avoided by keeping per-iteration state in a called procedure.
  - The segfault is not explained. It was caught once in libgfortran (`read` →
    `data_transfer_init` → `check_for_recursive`), with fformat having no shared state on that
    path. A separate threaded test also produced a truncated deferred-length path string
    (`1924.t` for `1924.txt`), so another string problem may be involved.
- The env's `libgomp` is a symlink to LLVM's `libomp`, so GCC-compiled OpenMP runs on LLVM's
  runtime here. Whether that matters is untested.

## 2. Decisions

1. **Use fformat as an fpm dependency, not a copy, and improve it upstream.** It links unchanged.
   Move it from `[dev-dependencies]` to `[dependencies]`, pinned to tag `1.0.1`, and bump the tag as
   changes land. Both projects have the same owner, so general Fortran parsing belongs in fformat
   and documentation logic belongs in fdoc. Likely upstream changes:
   - Fixed-form lexing (M8), rather than a text conversion pass in fdoc, if it keeps
     formatter behavior unchanged.
   - Declaration parsing (attributes, kinds, argument lists) if fformat's own rules can use it too.
   - Lower allocation in `statement_view_t` and the token paths if profiling at M2 shows contention.
   - A `read_file` fix if the stress test shows it is needed.
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
   `parallel:` overrides. Loop bodies call a procedure that owns its state, and `private()` is never
   used on deferred-length strings. File I/O starts serial, which costs little. Enable parallel
   I/O only once the M0 stress test passes.
7. **Handles, not pointers.** All entities live in one array and refer to each other by integer
   index, with name lookup through hash tables. Each file parses into a private result; a serial
   merge step builds the global model.

## 3. Pipeline

```
ford.md / fpm.toml [extra.ford] + CLI
  → settings
  → discover files → read (serial for now) → preprocess → fixed→free
  → parse (parallel): tokens, statements, structure, doc comments, entities
  → merge → correlate (use/rename, extends, generics, bound procs, submodules, calls)
  → markdown (parallel): doc text → HTML, resolving [[links]] and |aliases|
  → render pages (parallel, to buffers) + graphs + search index + modules.json
  → write (serial for now), copy media/assets
```

## 4. Source layout

| Area | Modules (`src/`) | Rough size |
|---|---|---|
| Config | `fdoc_cli`, `fdoc_settings`, `fdoc_project_file` | 1,000 |
| Input | `fdoc_discover`, `fdoc_preproc`, `fdoc_fixed` | 500 |
| Fortran | `fdoc_model`, `fdoc_docs` (doc comments, meta, doxygen), `fdoc_parser`, `fdoc_decl` | 3,000 |
| Semantics | `fdoc_correlate`, `fdoc_calls`, `fdoc_intrinsics`, `fdoc_external` | 1,500 |
| Markdown | `fdoc_md_block`, `fdoc_md_inline`, `fdoc_md_ext` | 2,000 |
| Output | `fdoc_html`, `fdoc_pages`, `fdoc_lists`, `fdoc_pagetree`, `fdoc_highlight`, `fdoc_search`, `fdoc_json` | 3,000 |
| Graphs | `fdoc_graph`, `fdoc_dot` | 800 |

Sizes are estimates, about 12k lines of Fortran in total.

Reused from fformat: `ffmt_lexer`, `ffmt_tokens`, `ffmt_statements`, `ffmt_constructs`,
`ffmt_structure`, `ffmt_source`, `ffmt_io` (serial only), `ffmt_fs`, `ffmt_walk`, `ffmt_strings`.

Still missing: declarations (`fformat` classifies statements but doesn't parse attributes, types
or argument lists), doc comment attachment, and fixed-form input. Doc comments go in fdoc; the
other two are candidates for fformat (decision 1), which would shrink `fdoc_decl` and `fdoc_fixed`.

toml-f (for `[extra.ford]`) and fregex already come in through fformat. Declare toml-f directly
at fformat's pinned tag (`v0.5.2`).

## 5. Milestones

Each milestone ends with something that can be run and compared against FORD.

### M0. Foundation

- Fix the build. `pixi run fpm build` currently fails with `ar: no archive members specified`:
  `auto-executables = false` with no `[[executable]]` entry means nothing uses the library, so
  fpm prunes every object. Adding the `[[executable]]` and having `app/main.f90` use the library
  fixed this in a scratch copy.
- Move fformat to `[dependencies]`; add toml-f and `openmp = "*"`.
- Add pixi tasks: `build`, `test`, `doc`, `compare`, `bench`.
- Replace `say_hello` with a `test-drive` suite.
- Add an OpenMP stress test: repeated parallel read + parse over the corpus, compared with serial
  results, built with `pixi run fpm`. Use it to settle the intermittent segfault in section 1.
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
  gives an exact parser oracle before any HTML exists.

### M3. Correlation

- Resolve `use` (renames, `only`), `extends` and inherited components and bound procedures,
  generics, interface bodies, submodule-to-parent, `extra_mods`, external projects through
  `modules.json` (`-L`, `external:`, local path or URL), and intrinsics.
- Call analysis from tokens, including `call a%b%c()`, and function references distinguished from
  arrays using the resolved scope.
- Done when: uses, calls and inheritance lists match FORD, with differences reviewed one by one.
  Token-based call analysis should beat FORD's regexes in places, so a difference may be a fix.

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

### M6. Pages, search, externals

- `page_dir` tree (`title`, `ordered_subpage`, `copy_subdir`), `media_dir`.
- Client-side search with a small vanilla JS file: compact name + summary index first, full text
  optional, well under FORD's 7.1 MB for json-fortran.
- `modules.json` export finalized and checked by loading it from a real FORD project and vice
  versa.

### M7. Graphs

- All FORD graph types: module, uses, used-by, file, type, inherits, calls, called-by, and project
  graphs; `graph_maxdepth`, `graph_maxnodes`, `coloured_edges`, `graph_dir`.
- Deduplicate identical graphs, then pass batches of `.gv` files to one `dot -Tsvg -O` per worker
  rather than one process per graph. The saving needs measuring; if `dot` layout itself dominates,
  batching helps less than hoped.
- Small own pan/zoom script; theme-aware SVG colors.
- Warn clearly if `graph: true` and `dot` is missing, and carry on without graphs.

### M8. Preprocessing and fixed form

- `preprocessor:` runs the configured command, in parallel subprocesses to temp files.
- FORD's default is `pcpp`, which is Python: when that default is in effect, use `gfortran -E -cpp`
  and say so. Respect `macro`, `include`, `fpp_extensions`.
- `fixed_extensions`, `fixed_length_limit`: fformat is free-form only today, so add fixed-form
  lexing there if practical, otherwise a fixed→free pass in `fdoc_fixed`. Either way, doc comments
  and line numbers must survive.

### M9. Parity and handover

- Full corpus runs clean; publish benchmark table.
- README: migration notes and the differences in section 7.
- Parity bar for swapping: every corpus project builds, no missing entities, no broken internal
  links (checked by script), accepted differences listed.
- After that, move `ford` and `python` in `pixi.toml` to a `compare` feature, so the default env
  has no Python. Provide `ford` as a pixi task or symlink for scripts that call it by name.

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

- `html_template_dir` is not supported, because there are no Jinja templates.
- `md_extensions` beyond the built-ins can't load Python extensions; they warn and are skipped.
- `preprocessor: pcpp` runs through gfortran.
- Generated HTML differs in markup, so user CSS that targets FORD's classes needs rewriting.

## 8. Risks

| Risk | Handling |
|---|---|
| Markdown dialect edge cases are the largest source of visible bugs | Differential tests against Python-Markdown on the real corpus from day one |
| Corpus is mostly one author's style | Add third-party projects (stdlib, fpm, toml-f) at M2 |
| Fypp sources: fformat tokenizes them but they aren't valid Fortran | Match FORD: require `preprocessor:`; test with stdlib |
| Allocator contention limits scaling (worse past 4 threads) | Reduce per-token allocations in fdoc's own code; reuse buffers; profile at M2 |
| gfortran-only behavior | Only gfortran is supported through the pixi env for v1 |
| Windows: `win-64` is in `pixi.toml`, but `ffmt_fs` binds POSIX `opendir`/`readdir`, untested there | Test at M0. If it fails, drop `win-64` until v1 or fix upstream |
| Intermittent segfault in parallel runs is unexplained | M0 stress test settles it; file I/O stays serial until it passes |
| Deferred-length strings under threads (`private()` confirmed, truncated path seen) | Keep state in called procedures; the stress test compares every result with serial |
