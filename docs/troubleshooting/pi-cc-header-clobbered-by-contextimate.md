# pi-cc-header replaced by pi's built-in header a few seconds after startup

## Symptom

The pi-cc-header logo/status block renders at startup, then ~2s later gets replaced by
pi's built-in header (`pi v0.82.1 · escape interrupt · ctrl+c/ctrl+d clear/exit …`).

## Cause

`pine-of-glass`'s contextimate resets the custom header unconditionally on `session_start`:

```ts
// ~/.pi/agent/npm/node_modules/pine-of-glass/extensions/pi-contextimate/index.ts:1886
// Restore Pi's normal header; this extension now renders below Pi's loaded-resource list.
ctx.ui.setHeader(undefined);
```

`pi-cc-header` installs its header from `setTimeout(…, 0)` inside its own `session_start`
handler, so the last of the two extensions to run wins:

- `pi-cc-header` before `pine-of-glass` in `settings.json` → contextimate's reset lands
  after cc-header's timer → built-in header wins (the bug).
- `pi-cc-header` after `pine-of-glass` → cc-header's timer fires after contextimate already
  reset → cc-header wins.

Extension load order = `settings.packages` array order (`discoverAndLoadExtensions` in
`dist/core/extensions/loader.js`: locals, then globals, then configured package paths in
array order; no sorting). The regression appeared when the packages array got rewritten in
alphabetical order — `pi-cc-header` sorts before `pine-of-glass`.

## Fix

Keep `"npm:pi-cc-header"` **last** in `packages` in
`config/custom/pi/agent/settings.json`. Nothing else needed.

Re-breaks if the array is re-sorted, or if `pine-of-glass` is (re)installed after
cc-header (installs append to the end of the array). Same fix each time: move
`npm:pi-cc-header` back to the end and restart the session.

## Verify

Start pi in a scratch dir, wait ~15s: the pixel-Pi logo block must still be at the top with
the `[Contextimate]` block below it.
