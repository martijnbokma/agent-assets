# Signal detection (v4.1)

Reproducible heuristics for Phase 1 per-file signals and Phase 3.5 duplication hints. Use `rg` / `grep` per file unless `collect-signals.sh` is run.

## Skeleton signals (per file)

Count **reachable-risk** skeleton markers. Exclude `*.test.*`, `*.spec.*`, and `__mocks__` unless the user scopes tests.

| Signal | Pattern | Weight |
|--------|---------|--------|
| **not-implemented** | `throw new Error\(['\"]not implemented` or `NotImplementedError` | +15 tech debt each |
| **stub-return** | `return null;` / `return undefined;` / `return \[\];` immediately after `// TODO` on prior line (manual review) | flag |
| **bare-todo** | `TODO` or `FIXME` without ticket (`TODO:` with no `#\d+` or `JIRA-`) | +3 (included in TODO count) |
| **debugger** | `\bdebugger\b` | +10 |
| **console-debug** | `console\.(log|debug|info)\(` in non-test production paths | +5 each (cap +15) |
| **placeholder-comment** | `// \.\.\.` or `/* TODO */` blocking logic | flag |

```bash
# Per-file skeleton scan (TS/JS)
rg -n "throw new Error\(['\"]not implemented|NotImplementedError|\bdebugger\b" "$FILE" || true
rg -c "console\.(log|debug|info)\(" "$FILE" || true
```

**Skeleton score (0–100):** sum weights, cap at 100. Record as `skeleton_score` in manifest extension column.

Feeds **`maintainability-pass`** when `skeleton_score ≥ 25` or any `not-implemented` hit.

## Duplication hints (per file, Phase 1)

Lightweight flags — full DRY proof is Phase 3.5 / **`architecture-pass`**.

| Hint | Detection |
|------|-----------|
| **export-name-collision** | Exported symbol name appears in ≥2 manifest files (see Phase 3.5) |
| **twin-filename** | `foo.ts` and `foo2.ts` / `foo-copy.ts` / `foo.old.ts` in same directory |
| **parallel-basename** | Same basename in different folders (e.g. `utils/format.ts` and `lib/format.ts`) |
| **high-import-overlap** | ≥80% import path overlap with another file (Phase 3.5) |

Record `dup_hints` as comma-separated tokens or `none`.

## Performance hints (per file, optional)

| Hint | Detection |
|------|-----------|
| **large-list-render** | `.map(` count >5 in view/component without `virtual` / `window` keywords nearby |
| **sync-io** | `readFileSync` / `execSync` in route/handler |
| **unbounded-find** | `.findMany\(\)` or `SELECT \*` without `take`/`limit` in same function block (manual) |

Feeds **`performance-pass`** when file is route/view with `sync-io` or `unbounded-find`.

## Barrel and dead code (unchanged)

See main protocol table. `barrel=yes` feeds **`architecture-pass`**.

## Optional script

```bash
./skills/finding-refactor-candidates/scripts/collect-signals.sh --file path/to/module.ts
```

Returns JSON: `skeleton_score`, `skeleton_flags[]`, `dup_hints` (twin-filename only at file scope).
