# Bundle strategy — signal checklist

Use during Phase 1 of `bundle-strategy-audit`. Always record `BUILD_MODE`.

## Eager heavy imports

```bash
# Static imports of known heavy packages (extend HEAVY_LIBS)
rg -n "from ['\"](recharts|chart\\.js|monaco-editor|@monaco-editor|pdfjs|mapbox|leaflet|moment|lodash)['\"]" $ENTRY_AND_ROUTES
```

Flag when the importer is:

- App bootstrap / root layout
- Default marketing/home route
- Shared shell that every page loads

Fix seed: `const X = lazy(() => import('…'))` or framework `dynamic(() => import('…'), { ssr: … })` / Vite async route component.

## Missing split (routes / features)

Check that each major route or admin/editor surface has an async boundary:

| Framework | Look for |
|-----------|----------|
| React SPA | `React.lazy` + `Suspense`, or router `lazy: () => import(...)` |
| Next.js | `next/dynamic`, or App Router split via separate client islands |
| Vue | `defineAsyncComponent` / route `component: () => import(...)` |
| Astro | heavy islands not on `client:load` for whole-page chrome |

If a 500+ line page/feature module is only statically imported from the shell → `missing-split`.

## Over-split / waterfalls

Flag chains like:

```ts
const a = await import('./a');
const b = await import('./b'); // depends on a, sequential
```

Prefer a single feature chunk or `import()` parallelized at the boundary. Tiny <5KB async chunks that always load together → consider merging.

## Vendor / chunk strategy

Inspect config:

- Vite: `build.rollupOptions.output.manualChunks`
- Webpack: `optimization.splitChunks`
- Default automatic splitting is fine; flag when one `vendor` chunk includes mutually exclusive heavies (charts + editor + pdf).

Fix seed: group by **co-use** (framework core vs feature heavies), not one mega-vendor.

## Externals (mode-aware)

### Library mode (`BUILD_MODE=library`)

Expected: peer/framework deps in `external` (Rollup/Vite `rollupOptions.external`) and listed as `peerDependencies`.

```js
// Pattern (Vite library)
external: ['react', 'react-dom', 'vue']
```

Flag `external-miss` when peers are bundled into the library output.

### Application mode (`BUILD_MODE=application`)

Do **not** externalize React/Vue/etc. unless the app has an explicit runtime loader (import maps / CDN). Flag `external-overuse` if app config externalizes everything “to save size”.

Apps should **split or lazy-load**, not externalize, for heavy optional libs.

## Evidence confidence

| Level | When |
|-------|------|
| High | Stats/visualizer shows chunk name + size |
| Medium | Static import on entry + known heavy package |
| Low | Heuristic file size without build output |

Always state confidence on each row.
