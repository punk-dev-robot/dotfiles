# AeroSpace — Deferred Config Items

Keybinds and features to implement later, carried over from Hyprland parity audit.

## Master Layout

Implemented. See `docs/reference/aerospace-master-workflow.md` for the current AeroSpace workflow and keybinds.

## Screenshot Submap

Will use macshot. Hyprland had `SUPER+S` → submap with region/fullscreen/window/monitor modes.

## Currency Symbols

Karabiner config for Shift+F3/4/5 → €/£/¥ (currently handled by keyd on Linux).

## Workspace Cycling

Implemented (2026-08 audit):

- `alt-[` / `alt-]` — previous/next workspace (`workspace --wrap-around prev|next`)
- `alt-shift-[` / `alt-shift-]` — move window to prev/next workspace

## Focus Follows Mouse

Implemented natively (2026-08 audit): `focus-follows-mouse.enabled = true`, shipped in AeroSpace 0.21.0 (#12). AutoRaise cask removed from Brewfile and uninstalled. Native version focuses AND raises on hover, drag-safe, but has no delay/ignore-list/warp knobs — if that's missed, revert flag and reinstall `dimentium/autoraise/autoraiseapp`.

## Daily Restart (removed as experiment)

`aerospace-restart` script + `com.user.aerospace-restart` LaunchAgent (daily 05:00 kill/relaunch to reset CLI latency drift) removed in 2026-08 audit while on 0.21.3-Beta. Re-add from git history if latency drift reappears (upstream perf issue, no tracking fix).

## Upstream feature watch (checked against 0.21.3-Beta, 2026-08)

- #278 shell scriptability — **shipped 0.21.0**: `&& || ; |` in bindings, `test`/`eval`/`echo`. Future simplification: small wrapper scripts could fold into bindings.
- #60 `window-max-width`, #260 master-stack layout, #1515 dynamic-config CLI, #272 native scratchpad — **all still open**. So `aerospace-widescreen` (sed+reload gap hack), `aerospace-master-layout` (weight math), and the `aerospace-scratchpad` wrapper remain necessary.
- `list-windows` still exposes no window geometry vars — osascript position hacks in `aerospace-roll-stack` / `aerospace-scratchpad-frame` / `aerospace-float-cmd` stay.
- `aerospace subscribe` (0.21.0, JSON event stream) could replace `aerospace-post-startup`'s readiness polling loop — candidate for a later pass.
## Session Restore / App-to-Workspace Assignment

AeroSpace doesn't persist workspace assignments across restarts. macOS restores all windows to a single space. Options:

- `on-window-detected` rules can auto-assign apps to workspaces, but `app-id` is per-app not per-window
- Differentiating windows of the same app (e.g., multiple Zen profiles) requires `window-title-regex-substring` which is fragile
- Same problem existed on Hyprland — needed hacks for Zen and others
- Investigate: could a startup script query window titles and assign programmatically?
