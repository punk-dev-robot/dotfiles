# AeroSpace Ultrawide/Widescreen Support — Research

Research into solutions for a 5120x1440 ultrawide monitor with AeroSpace tiling WM.

**Goals:**
1. Single tiled window centered at max ~2560px width (not full-stretch)
2. Master-stack layout: centered master at ~50% width with side windows
3. Swap any window into the master/center position

## TL;DR — Viability Assessment

| Approach | Single-window centering | Master-stack | Swap-to-master | Complexity | Verdict |
|---|---|---|---|---|---|
| Dynamic gaps script | Yes (hacky) | No | No | Low | Quick win for goal 1 only |
| Per-monitor outer gaps (static) | Partial | No | No | Trivial | Too rigid |
| AeroSpace native (future) | Planned | Planned | Unknown | N/A | Not available yet |
| Scripted layout via aerospace CLI | Partial | Yes | Yes | High | **Most viable for all 3 goals** |
| Hammerspoon hybrid | Yes | Yes | Yes | Medium-High | **Best fallback / complement** |
| Floating + center script | Yes | No | No | Medium | Good for single-window only |

**Recommendation:** A custom shell script using `aerospace` CLI commands (`resize`, `move`, `join-with`, `swap`, `flatten-workspace-tree`) to enforce a master-stack layout, triggered via keybinds. Supplement with Hammerspoon for pixel-precise centering of floating/single windows.

---

## 1. Native AeroSpace Support (Not Yet Available)

### Issue #60 — Ultrawide Monitor Support (OPEN, 59 upvotes)
- **Status:** Open, labeled "discussion-needed" and "feature"
- **Proposed solution:** `window-max-width` config option restricting max width of tiling windows
- **Discussed in:** Discussion #621 — maintainer prefers per-monitor max-width over per-window
- **Also discussed:** Conditional gaps, ghost windows, shell-like combinators
- **Maintainer concern:** "What is the point of using ultra-wide screen, if you effectively cut left and right gaps from it?" — user Marty-W clarified realistic use cases (single vs multi-window workspaces)
- **Timeline:** No implementation merged as of March 2026

### Issue #260 — Dynamic TWM Normalizations (OPEN)
- **Status:** Open — proposes per-workspace layout normalizations like `primary-others` (Amethyst's "tall")
- **Proposed layouts:** `floating`, `columns`, `rows`, `primary-others`, `others-primary`, `v-primary-others`, `v-others-primary`, `bsp`
- **Config syntax proposed:**
  ```
  h_tiles
   1
   v_tiles
   others
  ```
- **Cross-ref:** Issue #617 (closed as duplicate) — "master and stack layout like dwm"

### Issue #1515 — Dynamic Config via CLI (OPEN, labeled "hard")
- **Status:** Open — proposes `aerospace config-write` commands for runtime config changes
- **Proposed commands:** `--set-scalar`, `--clear-composite`, `--add`, `--remove`, `--reload`
- **Impact:** Would enable proper dynamic gap adjustment without sed-hacking config files

### Discussion #1780 — Configurable Gaps at Runtime
- **Proposal:** `aerospace gaps outer.right=[{monitor.2 = 100}, 0]` or mode-based gap config
- **Status:** Duplicate of #1515

### Issue #278 — Shell-like Combinators (1.0-blocker)
- **Status:** Active implementation — adds `||`, `&&`, `;`, `test`, `eval` to AeroSpace command syntax
- **Impact:** Would enable conditional logic like "if window count = 1, set large gaps"
- **Linked to:** #60, #54, #107, #150, #264

**Bottom line:** Native master-stack and ultrawide support are acknowledged needs but not implemented. The `window-max-width`, dynamic config CLI, and shell combinators are all tracked but none are shipped. Earliest realistic timeline is AeroSpace 1.0.

---

## 2. resize Command — What It Can Do Today

```
resize [-h|--help] [--window-id <window-id>] (smart|smart-opposite|width|height) [+|-]<number>
```

### Key findings:
- **Absolute sizing IS supported:** `resize width 800` sets width to 800 (no `+`/`-` prefix = absolute)
- **Relative sizing:** `resize width +50` / `resize width -50`
- **Smart mode:** `resize smart +50` picks width or height based on parent container orientation
- **Units:** The docs do not specify units explicitly, but testing shows values correspond to **weight units in the tiling tree**, NOT pixels. A value of 800 means "800 weight units relative to siblings," not 800px.

### Critical limitation for ultrawide:
The `resize` command sets **proportional weight**, not absolute pixel dimensions. So `resize width 2560` does NOT guarantee a 2560px window — it sets the weight to 2560 relative to other windows' weights. With a single window, resize has no visible effect (it fills available space regardless of weight).

This means you CANNOT use `resize` alone to cap a single window at 2560px on a 5120px monitor.

---

## 3. Community Workarounds

### 3a. Dynamic Gaps Script (pkwsz/aerospace-dynamic-gaps)

A shell script that adjusts outer gaps based on window count per workspace.

**How it works:**
```bash
gap=10
single_window_gap=1280  # half of ultrawide width as gap on each side

# Detect ultrawide by aspect ratio > 3.5
resolution=($(system_profiler -json SPDisplaysDataType | grep '"_spdisplays_resolution"' | grep -oE '[0-9]+'))
width=${resolution[0]}
height=${resolution[1]}
is_not_wide_enough=$(echo "$width / $height < 3.5" | bc -l)

if [ $is_not_wide_enough -eq 1 ]; then
  set_outer_gap "$gap"
  exit 0
fi

window_count=$(aerospace list-windows --workspace focused | wc -l)
if [ $window_count -gt 1 ]; then
  set_outer_gap "$gap"
else
  set_outer_gap "$single_window_gap"
fi

aerospace reload-config
```

**Integration:** Triggered via `exec-on-workspace-change` or `on-focus-changed` callback.

**Limitations:**
- Uses `sed` to rewrite `aerospace.toml` and `aerospace reload-config` — fragile and causes flicker
- Only handles single-window centering, not master-stack
- Aspect ratio check hardcoded to 3.5 (works for 32:9 but 5120x1440 = 3.56, so it passes)
- For a 5120x1440 monitor: `single_window_gap=1280` gives (5120 - 2*1280 - 2*10_inner) = ~2540px centered window — close to the 2560px target

**Adaptation for your monitor:** Set `single_window_gap` to `1280` for ~2560px centered window. But beware the sed + reload approach is janky.

### 3b. Smart Gaps / inverse_outer (Discussion #1009)

Concept from i3/sway: large horizontal gaps when 1 window, removed when 2+ windows.

```
gaps inner 10px
gaps horizontal 500px
smart_gaps inverse_outer
```

**Status:** Not implemented in AeroSpace. The maintainer linked it to future `window-count-range` functionality in #60.

### 3c. Centered Floating Window (Discussion #633)

Multiple community approaches for floating + centering:

**Swift compiled script (best performance, ~154ms):**
```swift
#!/usr/bin/swift
// Parses -w and -h flags for width/height
// Defaults: 1600x900
// Usage: ./center_floats -w 2560 -h 1400
```
Integrated into aerospace.toml:
```toml
f = [
  'exec-and-forget ~/.config/aerospace/scripts/center_floats -w 2560 -h 1400',
  'move-mouse window-force-center',
  'mode main',
]
```

**Raycast Pro method:**
```toml
alt-i = """exec-and-forget aerospace layout floating && \
  sleep 0.2 && open -g 'raycast://customWindowManagementCommand?\
  &name=Center%20Focus&position=center&relativeWidth=0.5\
  &relativeHeight=0.9' || aerospace layout tiling"""
```

**Hammerspoon integration:** Toggle floating + call Hammerspoon to center/resize.

**Maintainer stance:** "This won't move forward until somebody submits a reasonable synopsis design proposal... I personally don't care about floating windows. AeroSpace is a _tiling_ window manager after all."

### 3d. Static Per-Monitor Outer Gaps

Already supported in AeroSpace config:
```toml
[gaps]
outer.left = [{ monitor.main = 1280 }, 8]
outer.right = [{ monitor.main = 1280 }, 8]
```

**Problem:** Static gaps waste space when you have multiple windows. A single window centers at ~2560px, but two windows each get only ~1280px with giant margins. Not useful for multi-window workflows.

---

## 4. Scripted Master-Stack Layout (Most Viable Approach)

AeroSpace's tree model CAN approximate master-stack via scripting. The key commands:

- `aerospace list-windows --workspace focused` — get window IDs and apps
- `aerospace resize width <N>` — set proportional weight
- `aerospace move left/right` — reposition windows
- `aerospace swap left/right` — swap window positions
- `aerospace join-with left/right` — create nested containers
- `aerospace flatten-workspace-tree` — reset to flat layout
- `aerospace focus --window-id <id>` — focus specific window

### Conceptual script for master-stack:

```bash
#!/bin/bash
# master-stack-layout.sh — enforce master-stack on focused workspace
# Master window = leftmost, ~50% width. Stack = right side, vertical tiles.

WORKSPACE=$(aerospace list-workspaces --focused)
WINDOWS=($(aerospace list-windows --workspace focused --format '%{window-id}'))
COUNT=${#WINDOWS[@]}

if [ $COUNT -le 1 ]; then
  # Single window — could center via floating or just leave tiled
  exit 0
fi

# Reset layout to flat horizontal tiles
aerospace flatten-workspace-tree

# The first window becomes master (leftmost after flatten)
MASTER=${WINDOWS[0]}

# Focus master and set it to ~50% weight relative to stack
aerospace focus --window-id $MASTER
aerospace resize width $((COUNT * 100))  # proportional: master gets N*100 weight

# Remaining windows form a vertical stack on the right
# Join them into a vertical container
for ((i=2; i<COUNT; i++)); do
  aerospace focus --window-id ${WINDOWS[$i]}
  aerospace join-with up  # stack vertically with previous
done
```

### Swap-to-master:
```bash
#!/bin/bash
# swap-master.sh — swap focused window with master (leftmost)
MASTER=$(aerospace list-windows --workspace focused --format '%{window-id}' | head -1)
FOCUSED=$(aerospace list-windows --focused --format '%{window-id}')

if [ "$MASTER" != "$FOCUSED" ]; then
  # Move focused to master position
  aerospace swap left  # may need multiple swaps depending on tree structure
fi
```

### Limitations:
- `resize` uses weight, not pixels — you can set master to weight 100 and stack to weight 100 for 50/50, but exact pixel control is not possible
- `flatten-workspace-tree` resets ALL nesting — may disrupt manual arrangements
- Window ordering after flatten is not guaranteed to be spatial
- The `list-windows` format and ordering need testing to confirm behavior
- Multiple `swap` calls may be needed if the focused window is not adjacent to master
- No event hook for "window added to workspace" means you'd need to re-run the script manually or hook into `on-focus-changed`

### Making it work for 5120x1440:
With 2 windows in h_tiles layout: set master weight to 100, stack weight to 100 — each gets ~2560px (minus gaps). This is actually the default behavior with `balance-sizes`. The challenge is maintaining this ratio when windows are added/removed.

---

## 5. Hammerspoon-Based Approaches

Hammerspoon offers pixel-precise window control and can complement AeroSpace.

### hammerspoon-ultrawide Spoon
- **Repo:** github.com/lkshrk/hammerspoon-ultrawide
- **Features:** Snap to left/right quarter, center half, four corners, maximize, center
- **Useful for:** Quick centering of single windows at exact pixel dimensions
- **Limitation:** No built-in master-stack layout — it's a snap-to-zone tool

### Custom master-stack via Hammerspoon:

```lua
-- Master-stack layout for ultrawide (5120x1440)
function masterStack()
  local screen = hs.screen.mainScreen():frame()
  local wins = hs.window.filter.new():setCurrentSpace(true):getWindows()

  if #wins == 0 then return end

  -- Master: centered at 50% width
  local masterW = 2560
  local masterX = (screen.w - masterW) / 2

  if #wins == 1 then
    -- Single window: center at 2560px
    wins[1]:setFrame({x = screen.x + masterX, y = screen.y, w = masterW, h = screen.h})
    return
  end

  -- Master window (focused or first)
  local master = hs.window.focusedWindow() or wins[1]
  master:setFrame({x = screen.x + masterX, y = screen.y, w = masterW, h = screen.h})

  -- Stack windows on both sides
  local stackWins = {}
  for _, w in ipairs(wins) do
    if w:id() ~= master:id() then table.insert(stackWins, w) end
  end

  local leftCount = math.floor(#stackWins / 2)
  local rightCount = #stackWins - leftCount
  local sideW = masterX  -- width available on each side

  -- Left stack
  for i = 1, leftCount do
    local h = screen.h / leftCount
    stackWins[i]:setFrame({
      x = screen.x, y = screen.y + (i-1) * h,
      w = sideW, h = h
    })
  end

  -- Right stack
  for i = 1, rightCount do
    local h = screen.h / rightCount
    stackWins[leftCount + i]:setFrame({
      x = screen.x + masterX + masterW, y = screen.y + (i-1) * h,
      w = sideW, h = h
    })
  end
end

-- Swap focused window to master
function swapToMaster()
  -- Store current master position, move focused there, move master to focused's old position
  -- Implementation depends on tracking which window is "master"
end

hs.hotkey.bind({"ctrl", "alt"}, "m", masterStack)
```

### Conflict with AeroSpace:
- **Problem:** AeroSpace manages tiled windows. Hammerspoon repositioning tiled windows will fight with AeroSpace's layout engine.
- **Solution options:**
  1. Use Hammerspoon ONLY for floating windows (toggle to floating first, then reposition)
  2. Disable AeroSpace for specific workspaces and let Hammerspoon manage them entirely
  3. Use Hammerspoon only for the single-window centering case (float + center + unfloat is too janky)

### Recommended hybrid approach:
- AeroSpace manages tiling and workspace switching as usual
- For master-stack: use AeroSpace's tree model (h_tiles with nested v_tiles) via scripted keybinds
- For single-window centering: use the dynamic gaps approach (rewrite outer gaps when window count = 1)
- For floating centering: use a Swift/AppleScript helper called via `exec-and-forget`

---

## 6. AeroSpace Config Capabilities Summary

### What works today:
- **Per-monitor gaps:** `outer.left = [{ monitor.main = 1280 }, 8]` — static only
- **Resize with weights:** `resize width 100` — proportional, not pixel-based
- **Tree manipulation:** `join-with`, `split`, `flatten-workspace-tree` — can build nested layouts
- **Window queries:** `list-windows --workspace focused --format '%{window-id}'`
- **Swap:** `swap left/right/up/down` — exchanges window positions
- **Callbacks:** `exec-on-workspace-change`, `on-focus-changed`, `on-window-detected`
- **Exec:** `exec-and-forget <command>` — run arbitrary scripts from keybinds

### What does NOT work today:
- No `window-max-width` config option
- No pixel-based resize (only proportional weight)
- No conditional gaps based on window count
- No dynamic config changes via CLI (must sed + reload-config)
- No master-stack layout normalization
- No floating window positioning commands (must use external tools)

---

## 7. Recommended Implementation Plan

### Phase 1 — Single window centering (quick win)
Adapt the `aerospace-dynamic-gaps` approach but cleaner:
- Script that counts windows on focused workspace
- If 1 window: set large outer.left/right gaps via sed + reload (or just accept the flicker)
- If 2+ windows: restore normal gaps
- Trigger via `exec-on-workspace-change` and a new `on-focus-changed` callback
- **Target:** single window at ~2560px centered on 5120x1440

### Phase 2 — Master-stack via scripted layout
Write a `master-layout.sh` script that:
1. Flattens workspace tree
2. Identifies master window (configurable: first window, or marked window)
3. Arranges remaining windows into a v_tiles container on the right
4. Sets master weight to balance at ~50%
5. Bind to a keybind (e.g., `alt-;` as noted in aerospace-deferred.md)

### Phase 3 — Swap-to-master keybind
Write a `swap-master.sh` that:
1. Identifies the master (leftmost window)
2. Swaps focused window with master using `aerospace swap`
3. Re-applies resize weights

### Phase 4 — Evaluate Hammerspoon supplement
If the AeroSpace-only approach has too many rough edges (flicker, race conditions, weight vs pixel issues), add Hammerspoon for:
- Pixel-precise floating window centering
- As an alternative layout engine for specific workspaces

---

## Related Issues Tracker

| Issue | Title | Status | Relevance |
|---|---|---|---|
| [#60](https://github.com/nikitabobko/AeroSpace/issues/60) | Ultrawide monitor support | Open | Core feature request — `window-max-width` |
| [#260](https://github.com/nikitabobko/AeroSpace/issues/260) | Dynamic TWM normalizations | Open | Master-stack layout (`primary-others`) |
| [#278](https://github.com/nikitabobko/AeroSpace/issues/278) | Shell-like combinators | Active | Conditional logic for gaps/layout |
| [#617](https://github.com/nikitabobko/AeroSpace/issues/617) | Master/stack like dwm | Closed (dup of #260) | — |
| [#633](https://github.com/nikitabobko/AeroSpace/discussions/633) | Centered floating windows | Unanswered | Community workarounds |
| [#621](https://github.com/nikitabobko/AeroSpace/discussions/621) | window-max-width design | Unanswered | Design discussion |
| [#1009](https://github.com/nikitabobko/AeroSpace/discussions/1009) | Smart gaps / inverse_outer | Open | Conditional gap removal |
| [#1515](https://github.com/nikitabobko/AeroSpace/issues/1515) | Dynamic config via CLI | Open (hard) | Runtime gap changes |
| [#1780](https://github.com/nikitabobko/AeroSpace/discussions/1780) | Configurable gaps | Dup of #1515 | — |
