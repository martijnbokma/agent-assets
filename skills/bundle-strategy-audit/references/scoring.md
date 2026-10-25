# Bundle strategy — scoring

Score each finding 0–100. Keep low-score rows in the matrix.

## Weights

| Dimension | Weight | Inputs |
|-----------|--------|--------|
| **Load impact** | 50% | On critical path? Heavy lib? Stats size if known |
| **Strategy gap** | 30% | No async boundary; wrong externals for mode |
| **Fix effort** | 20% | Inverse: Suspense/route wiring vs config one-liner |

## Impact bands

| Band | Score | Criteria |
|------|-------|----------|
| Critical | 85–100 | Heavy lib static-imported from entry; or library bundles React/Vue peers |
| High | 70–84 | Primary routes missing split; vendor blob with exclusive heavies |
| Medium | 40–69 | Secondary routes / admin-only eager heavies |
| Low | 0–39 | Micro-optimizations; over-split polish |

## Additives

- Evidence confidence high + >150KB attributed (when stats exist): +10
- `BUILD_MODE=library` + `external-miss` for framework peer: +20
- `BUILD_MODE=application` + `external-overuse`: +15 (correctness risk)

## Priority labels

| Score | Priority |
|-------|----------|
| ≥85 | P0 |
| 70–84 | P1 |
| 40–69 | P2 |
| <40 | P3 |

## Reporting sizes

- With stats: cite chunk name + kB (raw or gzip — label which).
- Without stats: write `est. impact=high|medium|low (needs stats)` — never fake kB.
