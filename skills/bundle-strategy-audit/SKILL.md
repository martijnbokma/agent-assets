---
name: bundle-strategy-audit
description: >-
  Audits code splitting, dynamic import / lazy-loading of heavy modules, vendor
  chunks, and externalizing large libraries for library builds. Use when the user
  asks about bundle size, code splitting, lazy routes, dynamic import(), manualChunks,
  rollup/vite/webpack externals, or initial-load JS — not for barrel/tree-shake
  graphs alone or general tech-debt matrices.
metadata:
  author: Martijn Bokma
maintained_by: self
version: 1.0.0
tags: [bundle, code-splitting, lazy-loading, externals, vite, webpack, audit]
---

# Bundle Strategy Audit

**Analysis-only by default.** Inspect how the app/library is split and shipped. Publish a findings matrix with evidence from source + bundler config + (when available) build stats. Do not edit unless the user approves a fix pass.

Sibling skill: **`module-graph-audit`** (barrels, tree-shaking readiness, modular boundaries). Do not mix scopes.

## When to use

- Slow first load / large main chunk / “too much JS”
- Missing route- or feature-level `import()` / `React.lazy` / framework lazy routes
- Library build bundling React/Vue/peers that should be external
- Tuning `manualChunks` / splitChunks / rollup `external`

## NOT when to use

- Barrel files, `export *`, package boundary leaks → **`module-graph-audit`**
- Exhaustive file tech-debt matrix → **`finding-refactor-candidates`**
- Protocol/CDN/caching/Core Web Vitals deep dive → **`high-perf-browser`** / **`performance-optimization`**
- Fixing after measurement already named the bottleneck → those skills’ fix phases

## Configuration (pin once)

| Variable | Meaning |
|----------|---------|
| **BUILD_TOOL** | `vite` \| `webpack` \| `rollup` \| `esbuild` \| `next` \| `astro` \| other |
| **BUILD_MODE** | `application` \| `library` |
| **ENTRYPOINTS** | App routes/entries or library entry file(s) |
| **STATS_PATH** | Optional: stats.json / rollup-plugin-visualizer / `.next` analyze output |
| **HEAVY_LIBS** | Known heavy deps (charts, editors, PDF, maps, moment, lodash-full, …) |
| **VERIFY_COMMAND** | Required only for fix pass (prefer build + size budget check) |
| **MATRIX_ID** | ISO timestamp or short git SHA |

## Workflow

### Phase 0 — Tooling and mode

1. Detect `BUILD_TOOL` and `BUILD_MODE` from config and `package.json`.
2. Locate split/external knobs: Vite/Rollup `build.rollupOptions`, webpack `optimization.splitChunks`, Next `dynamic()`, Astro `client:*`.
3. If `STATS_PATH` missing, note **size evidence = qualitative** until user provides a stats artifact or allows generating one (visualizer / `ANALYZE=true`).

### Phase 1 — Strategy signals

Apply [references/signal-checklist.md](references/signal-checklist.md).

| Signal | Focus |
|--------|--------|
| **eager-heavy** | Static import of heavy lib on entry/critical route |
| **missing-split** | Large feature/route with no async boundary |
| **over-split** | Tiny async chunks / waterfall of sequential `import()` |
| **vendor-blob** | Single undifferentiated vendor chunk dominating size |
| **external-miss** | Library mode bundling peers/framework that consumers provide |
| **external-overuse** | App mode marking everything external (broken runtime) |

### Phase 2 — Score and publish

Score with [references/scoring.md](references/scoring.md). Publish:

1. Configuration block (`BUILD_MODE` required)
2. Findings matrix: `# | Target | Signal | Evidence | Est. impact | Effort | Score | Priority | Fix seed`
3. Split map: entry → async boundaries → heavy libs
4. Mode-specific externals advice (library vs app)
5. Fix wave plan

**Stop** unless:

```text
APPROVE BUNDLE-STRATEGY FIXES: matrix-id=<MATRIX_ID>
```

### Phase 3 — Fix pass (optional)

After approval: introduce route/feature `import()`, wrap UI in Suspense/framework equivalents, adjust `manualChunks` / `external` / `peerDependencies`. Re-run build; prefer comparing before/after chunk sizes when stats exist.

## Key principles

- **Measure when possible** — prefer stats over folklore; label confidence.
- **Mode-aware externals** — externalize peers in **library** builds; in **apps**, bundle or vendor-split instead.
- **Split on user boundaries** — routes, modals, admin, editors — not arbitrary file cuts.
- **Lazy the heavy tail** — charts, PDF, maps, rich text, large icon sets.
- **Sibling for graph disease** — if eager-heavy is caused by a barrel, hand off to `module-graph-audit`.

## Constraints

- Analysis does not edit files.
- No fix pass without verbatim approval + matching `MATRIX_ID`.
- Never recommend externalizing app framework deps in application mode without an explicit CDN/import-map plan.
- Do not invent byte savings; use ranges or “needs stats”.
