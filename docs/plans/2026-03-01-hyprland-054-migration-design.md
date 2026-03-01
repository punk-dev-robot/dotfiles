# Hyprland 0.54 Migration Design

## Context

Hyprland updated to 0.54 which redesigns the layout engine with native per-workspace layouts. This breaks the current config (~80 startup errors) because:

1. `virtual-desktops` plugin fails to build -> all vdesk dispatchers undefined (~40 keybinds)
2. `hyprWorkspaceLayouts` plugin conflicts with native layout engine -> `layout = workspacelayout` is invalid
3. All `layoutopt:wslayout-layout:` workspace rules are invalid

## Decision: Strip to Vanilla, Rebuild Minimally

### Plugins

**Remove completely:**
- `virtual-desktops` — all config, dispatchers, keybinds, stickyrules, lid switch vdeskreset
- `hyprWorkspaceLayouts` (wslayout) — replaced by native 0.54 per-workspace layouts
- `hyprpm reload` from execs.conf

**Keep config (inactive until plugin rebuilds):**
- `hyprfocus` — animation config stays, ignored if plugin absent
- `hyprwinwrap` — same

### Workspace & Layout

Replace plugin-based per-workspace layouts with native 0.54 syntax:

```ini
general {
    layout = dwindle  # Default for all workspaces
}

# Philips ultrawide gets master layout
workspace = m[desc:Philips Consumer Electronics Company PHL 499P9], layout:master, layoutopt:orientation:center
```

This replaces 20 lines of `layoutopt:wslayout-layout:` rules with 1 line using the `m[monitor]` workspace selector. Verified working via `hyprctl keyword`.

### Keybind Migration

| Old (virtual-desktops) | New (native) |
|---|---|
| `vdesk, N` | `workspace, N` |
| `movetodesk, N` | `movetoworkspace, N` |
| `movetodesksilent, N` | `movetoworkspacesilent, N` |
| `prevdesk` / `nextdesk` | `workspace, r-1` / `workspace, r+1` |
| `lastdesk` | `workspace, previous` |
| `mouse_down nextdesk` / `mouse_up prevdesk` | `mouse_down workspace, r+1` / `mouse_up workspace, r-1` |
| `vdeskreset` | removed |
| `stickyrule` | removed |

**Behavior change accepted:** Workspace switching affects focused monitor only (not all monitors synchronized). Standard tiling WM behavior.

### Files Changed

1. `settings.conf` — `layout = dwindle`, remove wslayout + virtual-desktops plugin config
2. `workspaces.conf` — replace 20 plugin rules with 1 native monitor-based rule
3. `keybinds-sys.conf` — replace all vdesk dispatchers with native workspace dispatchers, remove vdeskreset, remove lid switch vdeskreset
4. `rules-window.conf` — remove stickyrules
5. `execs.conf` — remove `hyprpm reload`
6. `hyprtogglelayout` script — update to work without plugin dependency
7. `hyprfocusIn`/`hyprfocusOut` animations — keep (they're harmless if plugin absent)

### What We're NOT Doing

- Not re-implementing synchronized desktop switching (future research)
- Not adding scroll or monocle layouts yet (future enhancement)
- Not changing scratchpad, window rules, or other non-broken config
