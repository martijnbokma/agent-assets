---
name: module-graph-audit
description: >-
  Audits the import/module graph for barrels, tree-shaking readiness, and modular
  scope violations. Use when the user asks about barrel files, tree shaking,
  sideEffects, export *, package boundaries, circular imports, or module-graph
  health — not for general tech-debt matrices or runtime Core Web Vitals.
metadata:
  author: Martijn Bokma
maintained_by: self
version: 1.0.0
tags: [modules, barrels, tree-shaking, imports, architecture, audit]
---

# Module Graph Audit

**Analysis-only by default.** Map the import graph, score graph-health findings, publish a findings matrix. Do not edit files unless the user explicitly opts into a fix pass after approving the matrix.

Sibling skill: **`bundle-strategy-audit`** (code splitting, lazy `import()`, externals, chunks). Do not mix scopes.

## When to use

- “Audit barrels / tree shaking / import graph”
- Package or feature boundary leaks
- Suspected dead exports or `export *` / namespace-import graphs
- Follow-up after `finding-refactor-candidates` flagged `barrel=yes`

## NOT when to use

- Exhaustive per-file tech-debt matrix → **`finding-refactor-candidates`**
- Route-level lazy loading / vendor chunks / library `external` → **`bundle-strategy-audit`**
- Runtime LCP/INP/CLS or N+1 → **`performance-optimization`** / **`high-perf-browser`**
- Deep module interface design → **`codebase-design`**

## Configuration (pin once)

| Variable | Meaning |
|----------|---------|
| **SCAN_ROOTS** | App/package roots to map (e.g. `apps/web/src`, `packages/*/src`) |
| **ENTRYPOINTS** | App entries + package `exports` / `main` / `module` |
| **BOUNDARY_RULES** | Optional allow/deny (e.g. `features/*` must not import `features/*/internal`) |
| **VERIFY_COMMAND** | Required only for fix pass |
| **MATRIX_ID** | ISO timestamp or short git SHA |

## Workflow

### Phase 0 — Scope

1. Detect bundler/package manager from config (`vite.config.*`, `webpack.config.*`, `rollup.config.*`, `package.json` `sideEffects` / `exports`).
2. List `ENTRYPOINTS` and `SCAN_ROOTS`.
3. Note library vs application packages (tree-shaking advice differs).

### Phase 1 — Graph signals

Apply the checklist in [references/signal-checklist.md](references/signal-checklist.md) to every in-scope module (or entry-reachable subgraph if user scopes to “reachable only”).

Minimum signals per finding:

| Signal | Severity driver |
|--------|-----------------|
| **barrel** | `index.*` re-exports; worse with `export *` or side-effectful imports |
| **tree-shake-bailout** | CJS interop, missing/incorrect `sideEffects`, namespace `import *`, `export *` chains |
| **boundary-leak** | Cross-feature/package import violating `BOUNDARY_RULES` or inferred layering |
| **deep-relative** | `../../../` chains that skip public package entrypoints |
| **cycle** | Import cycles involving ≥2 packages or features |
| **fan-in-hub** | Single barrel/util imported by ≥N modules (document N; default 8) |

### Phase 2 — Score and publish

Score with [references/scoring.md](references/scoring.md). Publish:

1. Configuration block
2. Findings matrix: `# | Path | Signal | Evidence | Impact | Effort | Score | Priority | Fix seed`
3. Graph summary: top hubs, cycles, barrel hotspots
4. Fix wave plan (one concern cluster per wave; no edits yet)

**Stop** unless the user opts into fixes with:

```text
APPROVE MODULE-GRAPH FIXES: matrix-id=<MATRIX_ID>
```

### Phase 3 — Fix pass (optional)

After approval only: apply approved rows, prefer direct imports over barrels, restore ESM-friendly exports, enforce boundaries. Run `VERIFY_COMMAND` after each wave.

## Key principles

- **Graph evidence over taste** — every finding cites import paths or package fields.
- **Context matters** — app code vs published library; barrels hurt libraries and cold graphs hardest.
- **Positive target** — prefer direct named imports from concrete modules; granular `package.json` `exports`.
- **No silent scope mix** — splitting/lazy/externals belong in `bundle-strategy-audit`.

## Constraints

- Analysis does not edit files.
- No fix pass without verbatim approval + matching `MATRIX_ID`.
- Do not recommend deleting barrels without naming replacement import paths.
- Do not claim tree-shaking works without checking ESM + `sideEffects` reality.
