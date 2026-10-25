# Pass handoff bundle (v4.1)

After Phase 4 matrix publish, emit a **Pass handoff** section routing hotspots to Pro pass skills. Analysis-only — passes do not auto-run unless the user asks.

## Trigger rules

| Pass skill | Include file/hotspot when |
|------------|---------------------------|
| **`maintainability-pass`** | `skeleton_score ≥ 25`, or `not-implemented`, or `debugger`, or priority ≥ high with TODO density |
| **`architecture-pass`** | `dup_hints` contains `export-name-collision` or `high-import-overlap`, or `barrel=yes`, or Architectural violations appendix non-empty |
| **`module-graph-audit`** | `barrel=yes` (graph-depth follow-up; do not expand this skill’s Phase 1 into bundle/split signals) |
| **`performance-pass`** | `perf_hints` non-empty, or category `route`/`view` with lines > threshold and importer count >5 |
| **`improve-codebase-architecture`** | ≥3 architecture-pass findings with same pattern, or user requests deepening after architecture-pass |
| **`performance-optimization`** | performance-pass blockers with evidence — fix phase only |
| **`code-review-specialist`** | Not part of repo audit — use for PR scope only |
| **`bundle-strategy-audit`** | Not auto-routed from this matrix — invoke only when the user asks about bundles/splitting/lazy/externals |

## Handoff output format

```markdown
## Pass handoff (matrix-id=<MATRIX_ID>)

### maintainability-pass
| File | Trigger | Refactor goal seed |
|------|---------|-------------------|
| src/api/checkout.ts | skeleton_score=40, not-implemented×1 | Remove stub; implement or gate route |

### architecture-pass
| Hotspot | Trigger | Pattern |
|---------|---------|---------|
| src/utils/format.ts + src/lib/format.ts | parallel-basename | dry |

### performance-pass
| File | Trigger |
|------|---------|
| src/app/dashboard/page.tsx | large-list-render, importers=12 |

### Suggested operator command
Run `workflow-quality-audit.md` Phases 2–4 on hotspots above, or invoke each pass with `FILE_LIST` / `MATRIX_INPUT` set.
```

## Matrix column extension (optional)

When publishing v4.1 matrices, append columns after `Refactor goals`:

`Skeleton | Dup hints | Pass routing`

Example row tail: `35 | export-name-collision | maintainability-pass, architecture-pass`

Quick scan (`QUICK_SCAN=true`): handoff covers **matrix rows only**, not omitted files.
