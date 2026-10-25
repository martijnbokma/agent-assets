# Module graph — signal checklist

Use during Phase 1 of `module-graph-audit`. Record evidence as `path:line` or package.json field paths.

## Barrel

Detect:

```bash
# Candidate barrels: index files that mostly re-export
rg -n "^export .* from |^export \* from " --glob '**/index.{ts,tsx,js,jsx,mjs,cjs}' $SCAN_ROOTS
```

Flag when:

| Pattern | Why |
|---------|-----|
| `export * from './x'` | Pulls full module graph; weak tree-shaking |
| Many named re-exports in `index.*` | Convenient DX, costly cold import graphs |
| Barrel imports another barrel | Cascading graph inflation |
| App/feature code imports only via barrels | Hides concrete module boundaries |

Mitigation seed: replace with `import { X } from './x'` or package subpath `pkg/x`.

**Exception:** tiny public package entry that re-exports a *stable* public API with `"sideEffects": false` and ESM — still prefer granular `exports` map.

## Tree-shake bailout

| Check | How |
|-------|-----|
| Module format | Prefer ESM (`"type":"module"`, `.mjs`, `module`/`exports` ESM). CJS consumers cannot reliably tree-shake. |
| `sideEffects` | Missing → bundler assumes side effects. Over-broad `false` can drop CSS/polyfills. Prefer accurate array of side-effect files. |
| `import * as ns` | Namespace objects often retain unused members |
| `export *` chains | See webpack/MDN: re-export graphs obscure used exports |
| Side-effect imports | `import './polyfill'` must stay reachable if required |

Evidence: cite the import site + package field. Do not invent bundle sizes without a build report.

## Modular scope / boundaries

If `BOUNDARY_RULES` unset, infer once from layout:

- `features/<name>/` or `packages/<name>/` = boundary
- `shared/` / `ui/` may be imported inward; features should not import each other's `internal/` or private paths

Flag:

| Leak | Example |
|------|---------|
| Cross-feature private import | `features/a` → `features/b/internal/db` |
| Skip public entry | `packages/ui/src/Button.tsx` instead of `@org/ui` / `@org/ui/button` |
| Layer inversion | `domain` importing `app` or route handlers |

## Cycles

```bash
# Prefer project tooling if present (madge, dependency-cruiser, nx graph)
npx madge --circular --extensions ts,tsx $SCAN_ROOT 2>/dev/null || true
```

Report cycles that cross package or feature boundaries first; intra-file mutual imports are lower priority unless they block splitting.

## Fan-in hubs

Count importers per path (rg for the module specifier). Hubs that are barrels score higher impact.

## Evidence format

```text
signal=barrel path=src/components/index.ts evidence="export * from './Button'" importers=14
```
