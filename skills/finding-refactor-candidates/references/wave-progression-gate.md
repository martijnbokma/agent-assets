# Wave progression gate (execution mode)

Use between **every** execution wave. Prevents closing a run after sampling a few files or generalizing “the rest looks similar.”

## Status values (matrix `Status` column)

| Status | Meaning |
|--------|---------|
| `not started` | In wave scope; not yet opened this run |
| `in progress` | Currently being refactored or assessed |
| `done` | Refactored this run; VERIFY_COMMAND passed for its wave |
| `assessed-clean` | File read/assessed; no behavior-preserving refactor warranted (one-line reason required) |
| `deferred` | In wave plan but skipped this run — only with user-scoped approval (e.g. `waves 1-2 only`) |
| `blocked` | VERIFY_COMMAND failed or refactor unsafe until user decision |

Do **not** leave wave files at `not started` when closing a wave or ending execution.

## Per-wave closure (mandatory)

Before starting wave **N+1** or publishing an execution summary, emit:

```markdown
### Wave <N> closure — matrix-id=<MATRIX_ID>

| File | Status | Notes |
|------|--------|-------|
| ... | done / assessed-clean / blocked | ≤1 line |

VERIFY_COMMAND: <pass|fail> (after refactors in this wave, if any)
Wave <N> totals: <refactored> refactored, <assessed-clean> assessed-clean, <blocked> blocked
```

## Wave N → N+1 decision (mandatory)

Immediately after wave closure, publish **one** explicit decision:

```markdown
### Wave progression — matrix-id=<MATRIX_ID>

- Current wave: <N> (closed)
- Next wave in plan: <N+1 or none>
- Approved scope: <all planned waves | waves 1–2 only | … from approval line>
- Decision: **PROCEED to wave <N+1>** | **STOP — execution complete** | **STOP — blocked**

Rationale: <1–3 sentences; per-file evidence only — no “remaining files look similar”>
```

### PROCEED when

- Every file assigned to wave **N** has a terminal status (`done`, `assessed-clean`, `deferred`, or `blocked`).
- `VERIFY_COMMAND` passed after any refactors in wave **N** (or wave had zero refactors and last verify still green).
- Wave **N+1** exists in the **approved scope** and has at least one file with `not started` or `in progress`.

### STOP — execution complete when

- No next wave in approved scope, **or**
- All waves in approved scope are closed with per-wave closure blocks.

### STOP — blocked when

- `VERIFY_COMMAND` failed after refactors; do not start the next wave until fixed or user redirects.

## Medium / low waves (3+)

Default execution for medium/low is **assess every assigned file**, not bulk skip:

1. Open **each** file in the wave (read source; do not infer from siblings).
2. If **Refactor goals** is empty or goals are stale → `assessed-clean` + reason (e.g. legitimate complexity, already decomposed).
3. If goals are concrete and still valid → refactor → `done`.
4. Never close wave 3+ with a single paragraph like “wave 3–4 not pursued”; use the closure table.

Refactor only when goals are **specific and behavior-preserving** (see scoring rubric). “File is large” alone is not a refactor trigger.

## Forbidden patterns

- Sampling 2–3 files in a wave and generalizing to the rest without per-file status.
- Ending execution after wave 2 when waves 3+ are in approved scope and unclosed.
- Marking files `assessed-clean` without opening them.
- Proceeding to wave N+1 while any wave N file remains `not started`.

## Approval line scope

Default approval (`APPROVE REFACTOR EXECUTION: matrix-id=…`) = **all waves in the published wave plan** unless the user adds scope, e.g.:

```text
APPROVE REFACTOR EXECUTION: matrix-id=<MATRIX_ID>
Scope: waves 1-2 only
```

If scope is omitted, the agent must run the wave progression gate through the last planned wave or stop with `blocked` and a clear unblock step.
