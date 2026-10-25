# Scoring rubric

Score **every** manifest file 0–100. Priority labels filter attention; they do **not** remove rows from the matrix.

## Category size thresholds

Adjust labels to stack; thresholds inform Tech debt sub-score only.

| Category | High size | Medium size |
|----------|-----------|-------------|
| View / component | >350 lines | 200–350 |
| Hook / composable | >200 lines | 100–200 |
| Service / module | >300 lines | 150–300 |
| Route / handler | >250 lines | 120–250 |
| Util | >200 lines | 80–200 |

## Dimension weights (default)

Keep weights consistent across all files in one run.

| Dimension | Weight | Inputs |
|-----------|--------|--------|
| **Technical debt** | 40% | Size tier, `: any` + `as any`, hardcoded values, TODO density, barrel/dead-code flags, **skeleton_score** (v4.1) |
| **Impact** | 30% | Importer count (fan-in), exported public API surface |
| **Risk** | 20% | Risk tags, missing tests on risk paths, touches auth/payment/persist |
| **Complexity** | 10% | Nesting heuristic, branch density |

### Sub-score calibration (0–100 per dimension)

**Technical debt**

- Size high → 80–100; medium → 40–70; low → 0–30
- Each `: any` / `as any`: +5 (cap dimension at 100)
- Each TODO/FIXME: +3 (cap +15)
- Hardcoded hex in UI file: +10 per occurrence (cap +30)
- **Skeleton score** (v4.1): add `min(skeleton_score, 30)` to tech-debt sub-score (cap dimension at 100)
- **Dup hints** on file: `export-name-collision` +10; `high-import-overlap` +8; `parallel-basename` +5 (cap +20 combined)

**Impact**

- 0 importers, private util → 0–20
- 1–3 importers → 30–50
- 4–10 → 60–80
- >10 or entry-point route → 85–100

**Risk**

- No risk tags, tests present → 0–15
- Missing tests on non-risk module → 25–40
- Risk tag + missing tests → 70–100

**Complexity**

- Low nesting + low branch density → 0–25
- Medium → 40–60
- High → 70–100

**Total score** = weighted sum, rounded integer.

## Priority labels

| Label | Score | Action in wave plan |
|-------|-------|---------------------|
| **critical** | ≥85 | Wave 1–2; concrete refactor goals required |
| **high** | 70–84 | Early waves |
| **medium** | 40–69 | Later waves — assess every assigned file at execution; refactor only when **Refactor goals** are concrete |
| **low** | <40 | Matrix row required; wave `—` unless user expands scope; same assess-per-file rule if assigned to a wave |

## Refactor goals column

Required when priority is **critical** or **high**. Optional but encouraged for **medium**.

Good: “Extract payment validation to `payment-validators.ts`; replace 4× `: any` with Stripe types; add unit tests.”

Bad: “Clean up”, “Refactor”, “Improve quality”.

## Consistency checks

- Same line count → same size tier for same category
- File with 0 importers cannot have Impact >25 unless marked entry-point
- Document any manual overrides in matrix footnote
