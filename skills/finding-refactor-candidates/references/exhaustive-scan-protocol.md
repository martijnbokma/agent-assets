# Exhaustive scan protocol

Use this reference during **Phase 0–1** of `finding-refactor-candidates`. The agent must not skip files or substitute sampling unless `QUICK_SCAN=true`.

## Phase 0: Build the manifest

### Step 1 — Discover roots

If the user did not set `SCAN_ROOTS`, infer from repo layout once:

- Monorepo: `cli/`, `apps/*/src/`, `packages/*/src/`
- Next.js: `app/`, `src/`
- Laravel: `app/`, `routes/`
- List chosen roots in the configuration block; do not scan outside them without noting expansion.

### Step 2 — Enumerate files

For each root, collect every file matching `SOURCE_EXTENSIONS`.

Preferred (reproducible):

```bash
./skills/finding-refactor-candidates/scripts/build-manifest.sh \
  --root "$ROOT" \
  --extensions "ts,tsx" \
  --output manifest-$ROOT.jsonl
```

Fallback: `find` + `wc -l` per file with the same exclusion rules.

### Step 3 — Exclusion log

Every excluded path needs a row: `path | reason`.

Standard reasons live in [exclusion-defaults.md](exclusion-defaults.md). Project-specific excludes (e.g. generated `registry/index.yaml`) must be explicit.

### Step 4 — Coverage gate

Before Phase 1:

```text
enumeration_count = manifest_count + excluded_count
```

If `enumeration_count` does not match, reconcile (missing subdirectory, wrong glob, typo in extensions) and fix before continuing.

### Step 5 — Batching (large repos)

When manifest size > 150 files:

| Batch size | ~50 files |
| Ledger | After each batch: `Batch 3/9 — 150/412 files processed` |
| Completion | No batch done until every file in that batch has Phase 1 signals |
| Merge | Single manifest + single matrix at end |

Never skip a batch because “remaining files look similar.”

## Phase 1: Per-file signal checklist

Apply **every row** below to **every manifest file**. Use `—` when not applicable (e.g. `: any` on `.php`).

| Signal | How | Notes |
|--------|-----|-------|
| **Lines** | `wc -l` or manifest script | Already in manifest |
| **Category** | Path + exports heuristics | `view`, `hook`, `service`, `route`, `test`, `config`, `util`, `other` |
| **`: any` count** | `rg ': any\b'` per file | TS/TSX only |
| **`as any` count** | `rg '\bas any\b'` | TS/TSX only |
| **TODO / FIXME** | `rg 'TODO|FIXME'` | Count per file |
| **Hardcoded hex** | `rg '#[0-9a-fA-F]{3,8}\b'` | Exclude theme/token paths per [exclusion-defaults.md](exclusion-defaults.md) |
| **Deep nesting** | Lines with ≥6 levels leading whitespace (heuristic) | Flag count |
| **Branch density** | `if\|else\|switch\|catch\|&&\|\|\|` matches / lines | Complexity proxy |
| **Test pairing** | Colocated `*.test.*` / `*.spec.*` or mirrored path per project convention | `missing` / `present` / `n/a` |
| **Barrel file** | Filename `index.ts` re-exporting siblings | Flag if project forbids barrels |
| **Importer count** | `rg` for imports of this module path | Fan-in for Impact score |
| **Project rules** | Violations of `CLAUDE.md`, `AGENTS.md`, scoped rules | e.g. English UI, no `any`, theme tokens |
| **Risk tags** | Path/content keywords | `auth`, `payment`, `persist`, `crypto`, `migration` |
| **Skeleton score** | [signal-detection.md](signal-detection.md) or `collect-signals.sh --file` | 0–100; flags: `not-implemented`, `debugger`, `console-debug`, `todo-fixme` |
| **Dup hints (file)** | Twin filenames in same dir; optional `collect-signals.sh` | `twin-filename` or `none` |
| **Perf hints (file)** | `readFileSync`, `execSync`, heavy `.map(` in views | `sync-io`, `large-list-render`, `unbounded-find`, or `none` |

### Phase 3.5 — Duplication hints (cross-file)

After all files have Phase 1 signals, scan manifest for:

| Hint | Rule |
|------|------|
| **export-name-collision** | Same exported function/class name in ≥2 files (parse `export function` / `export class` / `export const X =`) |
| **parallel-basename** | Identical filename in different directories under `SCAN_ROOTS` |
| **high-import-overlap** | Pair of files sharing ≥80% of import paths (same count denominator = smaller file) |

Append `dup_hints` on affected manifest rows. Feed **Architectural violations** + **`architecture-pass`** handoff.

Details: [signal-detection.md](signal-detection.md). Handoff rules: [pass-handoff.md](pass-handoff.md).

### Project standards pass (once per run)

Read before scoring:

- `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md` if present
- `.cursor/rules/*.mdc` or equivalent

Map rule violations to affected files in the matrix `Refactor goals` or a separate **Rule violations** appendix.

## Phase 1 completion gate

```text
files_with_signals == files_in_manifest
```

If any file lacks signals, Phase 1 is incomplete.

## Quick scan exception

When `QUICK_SCAN=true` only:

- May report top N by score or size
- Must still run Phase 0 manifest and publish `SCAN_COVERAGE` for enumeration
- Must document: `QUICK_SCAN omissions: <count> files below score <threshold> not expanded in matrix`

Default remains exhaustive: **omissions forbidden**.
