# AeroSpace Master Workflow

Current macOS/AeroSpace approximation of the Hyprland ultrawide master layout.

## Keybinds

- `alt-shift-,` — reset current workspace to flat equal `h_tiles`
- `alt-;` — promote the focused tiled window into the centered master slot
- `alt-,` — roll layout left
- `alt-.` — roll layout right
- `alt-shift-h` / `alt-shift-l` — swap adjacent windows left/right
- `alt-shift-.` — fallback accordion layout

## Behavior

- Master layout targets the Philips ultrawide and keeps the center pane wider than side panes.
- Roll keys rotate the whole ring of tiled windows, then keep focus in the same screen slot.
- Swap keys are kept simple to avoid the focus churn and border flicker caused by re-centering after every swap.

## Notes

- `alt-;` and reset are clean because they use a direct promotion/reset path.
- Roll works, but AeroSpace still requires intermediate swaps internally, so it may never be as perfectly smooth as Hyprland.
- The roll helper temporarily mutes JankyBorders during the swap sequence to reduce visible border flicker.

## Files

- `local/bin/aerospace-master-layout`
- `local/bin/aerospace-roll-stack`
- `local/bin/aerospace-reset-layout`
- `config/aerospace/aerospace.toml`
- `config/borders/bordersrc`
