# AeroSpace — Deferred Config Items

Keybinds and features to implement later, carried over from Hyprland parity audit.

## Master Layout

Implemented. See `docs/reference/aerospace-master-workflow.md` for the current AeroSpace workflow and keybinds.

## Screenshot Submap

Will use macshot. Hyprland had `SUPER+S` → submap with region/fullscreen/window/monitor modes.

## Currency Symbols

Karabiner config for Shift+F3/4/5 → €/£/¥ (currently handled by keyd on Linux).

## Workspace Cycling

Low priority — user doesn't use much:

- `alt-[` / `alt-]` — previous/next workspace
- `alt-shift-[` / `alt-shift-]` — move window to prev/next workspace

## Session Restore / App-to-Workspace Assignment

AeroSpace doesn't persist workspace assignments across restarts. macOS restores all windows to a single space. Options:

- `on-window-detected` rules can auto-assign apps to workspaces, but `app-id` is per-app not per-window
- Differentiating windows of the same app (e.g., multiple Zen profiles) requires `window-title-regex-substring` which is fragile
- Same problem existed on Hyprland — needed hacks for Zen and others
- Investigate: could a startup script query window titles and assign programmatically?
