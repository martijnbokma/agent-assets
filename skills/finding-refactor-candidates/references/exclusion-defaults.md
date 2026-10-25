# Default exclusion patterns

Apply during Phase 0 unless the user explicitly includes a path. Every exclusion must appear in the **exclusion log**.

## Always exclude (path segment or glob)

| Pattern | Reason |
|---------|--------|
| `node_modules/` | Third-party |
| `dist/`, `build/`, `.next/`, `out/` | Build output |
| `coverage/` | Generated reports |
| `*.min.js`, `*.bundle.js` | Minified bundles |
| `*.d.ts` (optional) | Type declarations only — include if auditing types |
| `.git/` | VCS metadata |
| `vendor/` (PHP) | Third-party |
| `__pycache__/`, `.venv/`, `venv/` | Python env |

## Usually exclude (document if included)

| Pattern | Reason |
|---------|--------|
| `*.generated.ts`, `*.gen.ts` | Codegen |
| `registry/index.yaml` (chain-hub) | Generated — never hand-edit |
| `**/fixtures/**`, `**/__snapshots__/**` | Test fixtures |
| `**/*.test.ts`, `**/*.spec.ts` | Test files — scan separately if `INCLUDE_TESTS=true` |

## Theme / token paths (exclude from hex-color debt)

Do not count hardcoded hex violations in:

- `tailwind.config.*`
- `**/theme/**`, `**/tokens/**`
- `**/*.css` with `@theme` (Tailwind v4) when file is the canonical token source
- `design-tokens.*`, `globals.css` when designated token file in project docs

Flag hex in **components/views** and **inline styles** in source files.

## Chain Hub monorepo hints

When scanning chain-hub:

| Root | Typical extensions |
|------|-------------------|
| `cli/` | `ts` (exclude `cli/dist/`) |
| `apps/hub/src/` | `ts`, `tsx` |
| `apps/web/src/` | `ts`, `tsx`, `astro` |

Read `CLAUDE.md` for generated assets (`registry/index.yaml`, hub `dist/`).

## User overrides

If the user says “include tests” or “include dist for audit”, set `INCLUDE_TESTS=true` or document the override in the configuration block and shrink the exclusion log accordingly.
