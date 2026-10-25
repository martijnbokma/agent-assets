# Module graph — scoring

Score each finding 0–100. Priority labels are thresholds only — low scores still appear in the matrix.

## Weights

| Dimension | Weight | Inputs |
|-----------|--------|--------|
| **Impact** | 45% | Importer count, on entry/cold path, published package surface |
| **Graph damage** | 35% | `export *`, barrel chains, cycles, boundary leaks |
| **Fix effort** | 20% | Inverse: many call-site renames → lower urgency unless impact is critical |

## Impact bands

| Band | Score | Criteria |
|------|-------|----------|
| Critical | 85–100 | Public package entry is a fat barrel; or hub barrel on app bootstrap |
| High | 70–84 | Feature boundary leak or cycle across packages |
| Medium | 40–69 | Local barrels / deep relatives inside one feature |
| Low | 0–39 | Cosmetic; unused private re-export with ≤2 importers |

## Graph damage additives

- `export *` or barrel→barrel: +15 (cap once)
- Missing/`incorrect` `sideEffects` on published package: +15
- Cross-boundary leak: +20
- Cycle across ≥2 packages: +20

## Effort discount

If fix touches >20 import sites without codemod path, cut total score by up to 15 (still list the finding; mark Effort=high).

## Priority labels

| Score | Priority |
|-------|----------|
| ≥85 | P0 |
| 70–84 | P1 |
| 40–69 | P2 |
| <40 | P3 |
