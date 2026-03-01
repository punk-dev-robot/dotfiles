# Hyprland 0.54 Migration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate Hyprland config from plugin-dependent (virtual-desktops, hyprWorkspaceLayouts) to vanilla 0.54 with native per-workspace layouts.

**Architecture:** Strip broken plugins, replace vdesk dispatchers with native workspace dispatchers, replace plugin-based per-workspace layouts with native `layout:` workspace rules using monitor selectors.

**Tech Stack:** Hyprland 0.54, hyprctl, dotter

---

### Task 1: Fix Layout Engine (settings.conf)

The root cause of most errors. Change general layout from plugin to native, remove plugin configs.

**Files:**
- Modify: `config/hypr/configs/settings.conf`

**Step 1: Change layout from plugin to native dwindle**

In `settings.conf:13`, change:
```ini
# OLD
layout = workspacelayout  # Uses hyprWorkspaceLayouts plugin

# NEW
layout = dwindle
```

**Step 2: Remove virtual-desktops and wslayout plugin config**

In `settings.conf:172-183`, remove the `virtual-desktops` and `wslayout` blocks from `plugin {}`:
```ini
# REMOVE these blocks:
  virtual-desktops {
    names = 1:1, 2:2, 3:3, 4:4, 5:5, 6:6, 7:7, 8:8, 9:9, 10:10
    cycleworkspaces = 0
    rememberlayout = size
    notifyinit = 0
    verbose_logging = 0
  }

  wslayout {
    default_layout = dwindle
  }
```

Keep `hyprfocus` and `hyprwinwrap` blocks intact.

**Step 3: Verify with hyprctl**

Run: `hyprctl reload 2>&1`
Expected: Significant reduction in errors (layout + wslayout errors gone)

**Step 4: Commit**

```
fix(hyprland): switch to native dwindle layout, remove broken plugin configs
```

---

### Task 2: Replace Workspace Layout Rules (workspaces.conf)

Replace 20 plugin-based workspace rules with 1 native monitor-based rule.

**Files:**
- Modify: `config/hypr/configs/workspaces.conf`

**Step 1: Replace entire file contents**

```ini
# Per-workspace layout rules (native Hyprland 0.54)
# Default layout is dwindle (set in general{})
# Philips ultrawide gets master layout with center orientation
workspace = m[desc:Philips Consumer Electronics Company PHL 499P9], layout:master, layoutopt:orientation:center
```

**Step 2: Verify**

Run: `hyprctl reload 2>&1`
Expected: No workspace-related errors. If Philips is connected, new windows on it should use master layout.

**Step 3: Commit**

```
fix(hyprland): replace plugin workspace rules with native 0.54 per-monitor layout
```

---

### Task 3: Migrate Keybinds (keybinds-sys.conf)

Replace all virtual-desktops dispatchers with native workspace dispatchers.

**Files:**
- Modify: `config/hypr/configs/keybinds-sys.conf`

**Step 1: Replace vdesk switch binds (lines 33-47)**

```ini
# OLD
bind = $mainMod, 1, vdesk, 1
...
bind = $mainMod, bracketleft, prevdesk,
bind = $mainMod, bracketright, nextdesk,
bind = $mainMod, TAB, lastdesk,
bind = $mainMod CTRL SHIFT, R, vdeskreset,

# NEW
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10
bind = $mainMod, bracketleft, workspace, r-1
bind = $mainMod, bracketright, workspace, r+1
bind = $mainMod, TAB, workspace, previous
# vdeskreset removed (not needed)
```

**Step 2: Replace movetodesk binds (lines 50-61)**

```ini
# OLD
bind = $mainMod SHIFT, 1, movetodesk, 1
...
bind = $mainMod SHIFT, bracketleft, movetoprevdesk,
bind = $mainMod SHIFT, bracketright, movetonextdesk,

# NEW
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10
bind = $mainMod SHIFT, bracketleft, movetoworkspace, r-1
bind = $mainMod SHIFT, bracketright, movetoworkspace, r+1
```

**Step 3: Replace movetodesksilent binds (lines 64-75)**

```ini
# OLD
bind = $mainMod CTRL, 1, movetodesksilent, 1
...
bind = $mainMod CTRL, bracketleft, movetoprevdesksilent,
bind = $mainMod CTRL, bracketright, movetonextdesksilent,

# NEW
bind = $mainMod CTRL, 1, movetoworkspacesilent, 1
bind = $mainMod CTRL, 2, movetoworkspacesilent, 2
bind = $mainMod CTRL, 3, movetoworkspacesilent, 3
bind = $mainMod CTRL, 4, movetoworkspacesilent, 4
bind = $mainMod CTRL, 5, movetoworkspacesilent, 5
bind = $mainMod CTRL, 6, movetoworkspacesilent, 6
bind = $mainMod CTRL, 7, movetoworkspacesilent, 7
bind = $mainMod CTRL, 8, movetoworkspacesilent, 8
bind = $mainMod CTRL, 9, movetoworkspacesilent, 9
bind = $mainMod CTRL, 0, movetoworkspacesilent, 10
bind = $mainMod CTRL, bracketleft, movetoworkspacesilent, r-1
bind = $mainMod CTRL, bracketright, movetoworkspacesilent, r+1
```

**Step 4: Replace mouse scroll binds (lines 95-96)**

```ini
# OLD
bind = $mainMod, mouse_down, nextdesk,
bind = $mainMod, mouse_up, prevdesk,

# NEW
bind = $mainMod, mouse_down, workspace, r+1
bind = $mainMod, mouse_up, workspace, r-1
```

**Step 5: Remove vdeskreset from lid switch handlers (lines 108-109)**

```ini
# OLD
bindl=,switch:off:Lid Switch,exec,hyprctl keyword monitor "eDP-1,preferred,auto,1" && sleep 2 && hyprctl dispatch vdeskreset
bindl=,switch:on:Lid Switch,exec,hyprctl keyword monitor "eDP-1, disable" && sleep 2 && hyprctl dispatch vdeskreset

# NEW
bindl=,switch:off:Lid Switch,exec,hyprctl keyword monitor "eDP-1,preferred,auto,1"
bindl=,switch:on:Lid Switch,exec,hyprctl keyword monitor "eDP-1, disable"
```

**Step 6: Update section comments**

Replace "virtual-desktops plugin" references in comments with "native workspace" equivalents.

**Step 7: Verify**

Run: `hyprctl reload 2>&1`
Expected: No keybind errors. Super+1 through Super+0 should switch workspaces.

**Step 8: Commit**

```
fix(hyprland): migrate vdesk keybinds to native workspace dispatchers
```

---

### Task 4: Remove Stickyrules (rules-window.conf)

**Files:**
- Modify: `config/hypr/configs/rules-window.conf`

**Step 1: Remove stickyrule lines (lines 1-5)**

Remove:
```ini
# Virtual desktop assignments (virtual-desktops plugin stickyrules)
# Note: stickyrule uses vdesk numbers, not raw workspace numbers
stickyrule = class:^(dots-term)$,2
stickyrule = class:^(work-term)$,3
stickyrule = class:^(learn-term)$,8
```

**Step 2: Verify**

Run: `hyprctl reload 2>&1`
Expected: No stickyrule errors.

**Step 3: Commit**

```
fix(hyprland): remove virtual-desktops stickyrules
```

---

### Task 5: Remove hyprpm Auto-Reload (execs.conf)

**Files:**
- Modify: `config/hypr/configs/execs.conf`

**Step 1: Remove or simplify the hyprpm reload line**

```ini
# OLD
exec-once = hyprpm reload && hyprctl seterror disable && hyprctl reload config-only

# NEW
exec-once = hyprctl seterror disable
```

Keep `seterror disable` to clear any startup error overlay. Remove `hyprpm reload` (no plugins to load) and `reload config-only` (not needed if no plugins change state).

**Step 2: Commit**

```
fix(hyprland): remove hyprpm reload from startup execs
```

---

### Task 6: Update Layout Toggle Script

**Files:**
- Modify: `local/bin/hyprtogglelayout`

**Step 1: Simplify the script**

The script already uses `layoutmsg setlayout` which is native Hyprland. But the state-tracking logic assumes the old odd/even workspace mapping. Simplify to query current layout from hyprctl:

```bash
#!/bin/bash
# Toggle layout for current workspace between master and dwindle
# Usage: hyprtogglelayout [master|dwindle]

if [[ -n "$1" ]]; then
  hyprctl dispatch layoutmsg setlayout "$1"
  notify-send -t 1500 "Layout" "Set to $1"
else
  current=$(hyprctl -j activeworkspace | jaq -r '.layout')
  if [[ "$current" == "master" ]]; then
    hyprctl dispatch layoutmsg setlayout dwindle
    notify-send -t 1500 "Layout" "Switched to dwindle"
  else
    hyprctl dispatch layoutmsg setlayout master
    notify-send -t 1500 "Layout" "Switched to master"
  fi
fi
```

Key change: Uses `hyprctl -j activeworkspace | jaq -r '.layout'` to get current layout instead of state files.

**Step 2: Verify `.layout` field exists in hyprctl output**

Run: `hyprctl -j activeworkspace | jaq -r '.layout'`
Expected: `dwindle` or `master`

**Step 3: Commit**

```
fix(hyprland): simplify layout toggle to use hyprctl instead of state files
```

---

### Task 7: Final Verification & Deploy

**Step 1: Run full config check**

Run: `hyprctl reload 2>&1`
Expected: No errors (or only warnings about absent hyprfocus/hyprwinwrap plugins)

**Step 2: Deploy via dotter**

Run: `dotter -v -d` (dry run first)
Then: `dotter -v deploy`

**Step 3: Full reload**

Run: `hyprctl reload`
Test: Super+1-9 workspace switching, window movement, layout toggle, lid switch

**Step 4: Commit all remaining changes**

```
feat(hyprland): complete 0.54 migration - vanilla config with native per-workspace layouts
```

---

## Verification Checklist

- [ ] `hyprctl reload` produces 0 errors
- [ ] Super+1 through Super+0 switch workspaces
- [ ] Super+Shift+1-0 move windows to workspaces
- [ ] Super+[/] cycle workspaces
- [ ] Super+Tab goes to previous workspace
- [ ] Master layout active on Philips ultrawide
- [ ] Dwindle layout active on laptop
- [ ] Super+Ctrl+L toggles layout on current workspace
- [ ] Lid close/open handles monitor correctly
- [ ] Scratchpads still work (no changes expected)
