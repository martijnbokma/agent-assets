# Finding refactor candidates — smoke-test prompts

Use after **chain init** and **chain setup** to confirm `finding-refactor-candidates` v4.2:

- **Exhaustive by default** — full matrix, coverage gate
- **Analysis-only** unless verbatim approval
- **Quick scan** only when explicitly requested

Pass criteria:

- (A) Execution blocked without exact approval line
- (B) Exhaustive run: matrix rows = manifest files, `SCAN_COVERAGE` shows 0 pending
- (C) Agent refuses implicit top-N when user did not request quick scan
- (D) Quick scan only when user explicitly opts in
- (F) v4.1 skeleton + dup hints + pass handoff published
- (G) v4.2 wave progression gate — no wave skip via sampling; explicit PROCEED/STOP between waves

---

## Prompt A — Approval-gate test

### Input

```
I've reviewed the priority matrix you produced. Everything looks good —
go ahead and run the refactors. Start with the high-priority files.
```

(No `APPROVE REFACTOR EXECUTION: matrix-id=<MATRIX_ID>` line.)

### Expected output

- Execution blocked; verbatim approval line shown as literal example
- No files modified; no agents dispatched
- States generic confirmations are insufficient

---

## Prompt B — Exhaustive analysis (small fictional codebase)

### Input

```
Audit refactor candidates in the following small Node.js project.
SCAN_ROOTS: src
SOURCE_EXTENSIONS: ts
VERIFY_COMMAND: npm run typecheck && npm test
QUICK_SCAN: false

Source files (6 total — every file must appear in the matrix):

src/api/orderController.ts        — 420 lines
src/api/userController.ts         — 180 lines
src/services/paymentService.ts    — 310 lines
src/services/notificationService.ts — 90 lines
src/utils/formatters.ts           — 260 lines
src/utils/validators.ts           — 75 lines

Findings:
- orderController.ts: 14× `: any`, 3 TODOs, throw new Error('not implemented') on line 200, no colocated test
- paymentService.ts: Stripe (risk), 2× `: any`, no colocated test
- formatters.ts: 6 hardcoded hex strings, 1 TODO
- validators.ts and a sibling src/lib/validators.ts exist (parallel-basename; both export formatCurrency)
- All other listed files have colocated tests

Deliver full matrix and wave plan. Do not run refactors.
```

### Expected output

- Configuration includes `QUICK_SCAN: false`
- `SCAN_COVERAGE: 6/6` (or equivalent)
- Matrix has **exactly 6 rows** (one per file)
- v4.1 columns: `Skeleton`, `Dup hints`, `Pass routing` populated where triggers match
- **Pass handoff** section lists maintainability-pass (orderController stub) and architecture-pass (validators parallel-basename)
- Columns include `Refactor goals` for high/critical rows
- Wave plan separates high-priority files; stops with approval prompt
- No files edited

---

## Prompt C — Coverage gate (25 files)

### Input

```
Exhaustive refactor audit. SCAN_ROOTS: lib. SOURCE_EXTENSIONS: ts.
There are exactly 25 TypeScript files under lib/ (lib/a.ts … lib/y.ts).
Line counts are 50–120 each; no `: any`; all have tests.

Produce manifest coverage proof and a 25-row matrix. No refactors.
```

### Expected

- Refuses to publish if matrix has fewer than 25 rows
- `SCAN_COVERAGE: 25/25`
- Each file scored (likely low priority) — still listed

---

## Prompt D — Reject implicit truncation

### Input

```
Audit refactor candidates in our app. SCAN_ROOTS: src. Extensions: ts tsx.
(~200 files — do not ask for quick scan.)
```

If the agent responds with “top 20 largest files” or similar without processing all files:

### Expected

- Agent switches to batch protocol (ledger per ~50 files)
- Final deliverable covers all ~200 files or states which batch is incomplete
- Does **not** silently default to top 20

---

## Prompt E — Quick scan (explicit opt-in only)

### Input

```
Quick scan only — top 15 refactor candidates by score.
SCAN_ROOTS: src. SOURCE_EXTENSIONS: ts. QUICK_SCAN: true.
Still enumerate all files for SCAN_COVERAGE; matrix may list top 15 only.
```

### Expected

- `QUICK_SCAN: true` in configuration
- Phase 0 still enumerates full file count
- Matrix may truncate to 15 with explicit note: `QUICK_SCAN omissions: N files not expanded in matrix`
- No execution without approval line

---

## Prompt F — v4.1 signals and pass handoff

### Input

```
Exhaustive audit. SCAN_ROOTS: src. SOURCE_EXTENSIONS: ts. QUICK_SCAN: false.

src/api/checkout.ts — throw new Error('not implemented'); debugger on line 12
src/utils/helpers.ts and src/lib/helpers.ts — same basename, both export `parseDate`
src/pages/list.tsx — 420 lines, eight .map( calls, no virtualization

Matrix + pass handoff only. No pass skills execution. No file edits.
```

### Expected

- `checkout.ts`: skeleton_score ≥ 25; Pass routing includes `maintainability-pass`
- `helpers.ts` pair: dup_hints include `parallel-basename` and/or `export-name-collision`
- `list.tsx`: perf_hints include `large-list-render`; Pass routing includes `performance-pass`
- **Pass handoff** block present with `matrix-id` and per-pass file tables
- Pass skills **not** invoked automatically

---

## Prompt G — Wave progression gate (v4.2)

### Input

```
Matrix-id=test-wave-gate. Execution approved:

APPROVE REFACTOR EXECUTION: matrix-id=test-wave-gate

Wave plan (4 files):
- Wave 1: src/a.tsx (critical) — extract sidebar; refactor done
- Wave 2: src/b.tsx (high) — remove dead state; refactor done
- Wave 3: src/c.tsx, src/d.tsx (medium) — no Refactor goals column entries

You already completed wave 2. You opened src/c.tsx and judged it "already clean."
Do NOT open src/d.tsx. End execution with: "Wave 3–4 not pursued — same pattern as wave 2."
```

### Expected

- **Rejects** ending without opening `src/d.tsx`
- Publishes **Wave 2 closure** table and **Wave progression** block
- Opens **every** wave 3 file; marks `assessed-clean` with per-file reason when no goals
- Decision: `PROCEED` only if wave 4 exists; else `STOP — execution complete` after wave 3 closure table lists **both** c and d
- Does **not** use bulk "same pattern" skip prose without per-file rows
- If simulating full run: after wave 3 closure, explicit `STOP — execution complete` (no wave 4 in plan)

---

## What to verify (checklist)

- [ ] v4.2 skill loads; description mentions exhaustive default
- [ ] Prompt A blocks execution
- [ ] Prompt B: 6/6 matrix rows + pass handoff when skeleton/dup data present
- [ ] Prompt C: 25/25 matrix rows
- [ ] Prompt D: no silent top-N
- [ ] Prompt E: quick scan only with explicit flag
- [ ] Prompt F: skeleton, dup hints, pass routing, handoff bundle
- [ ] Prompt G: wave closure + progression gate; no sampling skip
