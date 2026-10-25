---
name: finding-refactor-candidates
description: >-
  Exhaustive analysis by default: enumerate every in-scope file under configured
  roots, score all files, publish a coverage manifest plus full priority matrix
  and wave plan. Never truncates to top N unless the user explicitly requests a
  quick scan. Execution uses a mandatory wave progression gate between waves;
  optional execution runs only after verbatim approval with matching matrix-id;
  never auto-dispatches agents. Triggers: refactor candidates, tech debt audit, debt matrix,
  exhaustive scan, wave plan, or quality audit Phase 1.
metadata:
  author: Martijn Bokma
maintained_by: self
version: 4.2.0
complexity: medium
success_rate: 80
last_updated: 2026-07-09
tags: [refactor, code-quality, agents, technical-debt, audit, exhaustive]
---

# Finding Refactor Candidates

**Exhaustive by default.** Every in-scope file gets a matrix row and a manifest entry. Truncation (`top N`, “highlights only”) is allowed **only** when the user explicitly requests a **quick scan**.

Two modes — never mix them silently:

| Mode | Purpose | Ends when |
|------|---------|-----------|
| **Analysis** | Manifest, score every file, dependency-map, publish matrix + plan | Coverage gate passes and deliverables are published |
| **Execution** | Apply refactors per approved plan | Approved scope closed wave-by-wave; each wave passes the progression gate; `VERIFY_COMMAND` green |

During **analysis**: do **not** spawn write-capable agents or edit files.

## Scan depth

| Depth | When | Behavior |
|-------|------|----------|
| **Exhaustive** (default) | User asks for audit, refactor candidates, debt scan, or “check everything” | Phase 0 manifest → every file scored → full matrix |
| **Quick** | User explicitly says “quick scan”, “top 20”, “sample”, or “highlights only” | Record `QUICK_SCAN=true` in config; heuristics + top N allowed |

If depth is unclear, use **exhaustive**. Never downgrade to quick without explicit user consent.

## Configuration (pin once per run)

Record at the top of every deliverable:

| Variable | Meaning |
|----------|---------|
| **SCAN_ROOTS** | Roots to scan (no hard-coded `src/`) — e.g. `cli`, `apps/hub/src`, `packages/*/src` |
| **SOURCE_EXTENSIONS** | In-scope extensions — e.g. `ts tsx` |
| **VERIFY_COMMAND** | Must pass between execution waves — from `package.json` / `Makefile` / ask once |
| **QUICK_SCAN** | `false` (default) or `true` only with explicit user opt-in |
| **MATRIX_ID** | ISO timestamp or short git SHA — required in header and approval line |

Optional: run [`scripts/build-manifest.sh`](scripts/build-manifest.sh) per root for a reproducible file count; per-file v4.1 signals via [`scripts/collect-signals.sh`](scripts/collect-signals.sh). Validate script behavior after changes via [`scripts/smoke-check.sh`](scripts/smoke-check.sh). See [exhaustive-scan-protocol.md](references/exhaustive-scan-protocol.md), [signal-detection.md](references/signal-detection.md).

## Validation

Run smoke checks whenever this skill or its scripts change:

```bash
skills/finding-refactor-candidates/scripts/smoke-check.sh
```

Expected result:

- `PASS: finding-refactor-candidates smoke checks`

If smoke fails, do not update the skill version claim or mark the workflow stable until the failing check is fixed.

## Workflow (analysis)

### Phase 0 — Manifest (mandatory)

1. Enumerate **all** files under each `SCAN_ROOT` matching `SOURCE_EXTENSIONS`.
2. Write an **exclusion log** for every skipped path (with reason). Defaults: [exclusion-defaults.md](references/exclusion-defaults.md).
3. Build **manifest**: `path | lines | ext | category | batch`.
4. **Coverage gate** — do not proceed until:

```text
files_in_manifest + files_excluded == files_found_by_enumeration
SCAN_COVERAGE: <analyzed>/<manifest_total> (0 pending)
```

If the repo is large (>150 in-scope files), process in **batches** (~50 files). Maintain a ledger: `processed / total`. No batch is complete without listing every file in that batch. Merge into one manifest before Phase 4.

### Phase 1 — Per-file signals

Apply to **every manifest file** (not a sample). Full checklist: [exhaustive-scan-protocol.md](references/exhaustive-scan-protocol.md).

Minimum per file: line count, category, `: any` count (TS), TODO/FIXME count, nesting heuristic, test pairing, applicable project-rule flags, **skeleton_score**, **dup_hints** (file-scope), **perf_hints**, score (0–100 even when low).

Also load project standards once: `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/*.mdc` (or repo equivalents) — flag violations per file where relevant.

### Phase 1.5 — Cross-file duplication hints (v4.1)

After Phase 1 completes for all files, run Phase 3.5 from [exhaustive-scan-protocol.md](references/exhaustive-scan-protocol.md): export-name collisions, parallel basenames, high import overlap. Merge into per-file `dup_hints`.

### Phase 2 — Scoring

Score **every** manifest file using [scoring-rubric.md](references/scoring-rubric.md). Thresholds for priority labels only — **low-score files still appear in the matrix**.

### Phase 3 — Dependency mapping

Map imports between **all** matrix files (or all files above a score floor if `QUICK_SCAN=true`). Interdependent files must not share an execution wave.

### Phase 4 — Deliverables

Publish in order:

1. **Configuration block** — all variables including `QUICK_SCAN` and `SCAN_COVERAGE`
2. **Exclusion log** — path + reason
3. **Full priority matrix** — one row per manifest file: `# | File | Lines | Tech debt | Impact | Risk | Complexity | Score | Priority | Skeleton | Dup hints | Pass routing | Wave | Status | Refactor goals`
4. **Architectural violations** — cross-file patterns (include Phase 3.5 duplication hints)
5. **Pass handoff bundle** — route hotspots to `architecture-pass`, `maintainability-pass`, `performance-pass` per [pass-handoff.md](references/pass-handoff.md)
6. **Missing tests** — complete list
7. **Execution wave plan** — plan only; high-priority rows first; one file per agent per wave

**Coverage gate (publish):** matrix row count must equal manifest file count unless `QUICK_SCAN=true` (then document how many files were omitted and why).

**Stop here** unless the user opts into execution **and** sends the approval line.

---

## Execution mode (after explicit approval only)

### Approval checkpoint (mandatory)

User must reply with **exactly**:

```text
APPROVE REFACTOR EXECUTION: matrix-id=<MATRIX_ID>
```

- `MATRIX_ID` must match the published matrix header.
- Reject: “yes”, “go ahead”, “LGTM”, or altered lines.

### After approval

1. Re-print `MATRIX_ID` and approved file scope (default: **all waves** in the published plan unless the approval line narrows scope).
2. **At most one refactor agent per file per wave** (or edit yourself with same discipline).
3. Run **VERIFY_COMMAND** after **each** wave that included refactors; on failure → `blocked`, do not start the next wave.
4. Update matrix `Status` after **every** file in the wave: `not started` / `in progress` / `done` / `assessed-clean` / `deferred` / `blocked` (definitions: [wave-progression-gate.md](references/wave-progression-gate.md)).

### Wave progression gate (mandatory between waves)

Full checklist: [wave-progression-gate.md](references/wave-progression-gate.md).

After **each** wave:

1. **Wave closure** — table of every file in that wave with terminal status and one-line notes.
2. **Wave N → N+1 decision** — explicit `PROCEED` | `STOP — execution complete` | `STOP — blocked` with rationale tied to per-file evidence.
3. If `PROCEED`, start wave N+1 only when every file in wave N is terminal and `VERIFY_COMMAND` passed (when refactors ran).

**Forbidden:** sampling a few files in a later wave and skipping the rest with “same pattern / legitimate complexity” prose. Medium/low waves still require **opening each assigned file**; use `assessed-clean` when no concrete refactor goals apply.

End execution only when all waves in **approved scope** are closed, or scope was limited (e.g. `waves 1-2 only`) in the approval line.

### Agent prompt template

```markdown
You are a refactoring agent. Refactor exactly ONE file.

File: `<path>`
Wave: <n> | Priority: <label> | Score: <number>

Goals:
- <from matrix Refactor goals column>

Constraints: No behavior change unless pre-approved in writing. No public API break. One file only; no drive-by edits.
Return: edit summary, risks, expected VERIFY_COMMAND outcome.
```

---

## Key principles

- **Exhaustive default:** no file left uncounted; no silent top-N.
- **Coverage gates:** Phase 0 and publish both require `SCAN_COVERAGE` proof.
- **Analysis before execution:** matrix is the contract; approval line is the only execution trigger.
- **Configurable roots:** discover `SCAN_ROOTS`; never assume `src/`.
- **Dependency-safe waves:** never parallelize mutual importers.
- **Wave progression gate:** close each wave with per-file status; decide explicitly before the next wave or stop.

## Constraints

- No refactor agents or file edits during analysis.
- No execution without verbatim approval + matching `MATRIX_ID`.
- No interdependent files in the same wave.
- No wave skip via sampling — every file in the wave gets a terminal status before closure.
- No execution summary that omits wave progression decisions for remaining planned waves.
- No publish without passing coverage gate (unless `QUICK_SCAN=true` with documented omissions).
- If `VERIFY_COMMAND` is unknown, execution cannot start until the user supplies it.

## When to use

- Full technical-debt audits, pre-refactor scoping, “what should we refactor first?”
- User wants **every file** checked — this is the default behavior.

## NOT when to use

- Immediate single-file refactor without a matrix → **`refactor`** or **`refactor-specialist`**
- Cross-file DRY, coupling, barrels (checklist) → **`architecture-pass`**
- Import/module graph: barrels, tree-shaking readiness, package boundaries → **`module-graph-audit`**
- Code splitting, lazy `import()`, vendor chunks, library externals → **`bundle-strategy-audit`**
- Deep architectural deepening, HTML review, seams → **`improve-codebase-architecture`**
- Readability, skeleton/placeholder code, naming hygiene → **`maintainability-pass`**
- Runtime performance, Core Web Vitals, N+1 → **`performance-pass`**
- Full multi-pass audit (matrix + architecture + maintainability + performance) → **`workflow-quality-audit`**
- Unrelated bugs or greenfield features

## Examples

Smoke prompts: [finding-refactor-candidates-smoke-prompts.md](references/finding-refactor-candidates-smoke-prompts.md).

### Success (exhaustive analysis)

**Input:** “Audit all refactor candidates in our monorepo.”

1. Set `SCAN_ROOTS`, extensions, `VERIFY_COMMAND`, `QUICK_SCAN=false`.
2. Phase 0 manifest for all roots; `SCAN_COVERAGE: 412/412`.
3. Score all 412 files; full matrix + wave plan; stop. No edits.

### Common pitfalls

- **Top 20 only:** forbidden in exhaustive mode — use batches + ledger instead.
- **Matrix shorter than manifest:** blocked at publish gate.
- **Generic approval:** execution must not run.
- **Assuming `src/`:** breaks Laravel, Astro `apps/`, CLI layouts.
