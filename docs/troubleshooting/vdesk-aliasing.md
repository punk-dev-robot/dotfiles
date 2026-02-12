# Vdesk Aliasing (Two Vdesks Show Same Workspace)

## Problem
- [issue] Two vdesks appear identical — switching between them shows the same windows #virtual-desktops
- [symptom] Moving a window from one removes it from the other #aliasing
- [symptom] Sticky-ruled windows land on wrong vdesks #stickyrule
- [frequency] Intermittent, triggered by monitor hotplug events #intermittent

## Root Cause
- [cause] Runtime state corruption in `virtual-desktops` plugin v2.2.8 (upstream issue #44) #plugin-bug
- [mechanism] Plugin's internal vdesk→workspace mapping table gets corrupted during monitor connect/disconnect #architecture
- [trigger] Lid close/open, external monitor plug/unplug, or any event that changes monitor count #hotplug
- [detail] Plugin cannot distinguish user-initiated vs Hyprland-initiated workspace changes during these events #limitation
- [detail] `rememberlayout` setting (any value including `none`) does NOT prevent this #config

## Diagnosis

### Confirm aliasing
```bash
# Switch to each suspect vdesk and compare workspace IDs
for i in VDESK_A VDESK_B; do
  hyprctl dispatch vdesk $i
  sleep 0.2
  hyprctl monitors -j | python3 -c "
import json, sys
for m in json.load(sys.stdin):
    print(f\"{m['name']}: ws {m['activeWorkspace']['id']}\")"
done
```
If two vdesks activate the same workspace IDs on any monitor, they're aliased.

### Map all vdesks
```bash
for i in $(seq 1 10); do
  hyprctl dispatch vdesk $i >/dev/null 2>&1; sleep 0.2
  ws=$(hyprctl monitors -j | python3 -c "
import json, sys
for m in sorted(json.load(sys.stdin), key=lambda x: x['id']):
    print(f\"{m['name']}=ws{m['activeWorkspace']['id']}\", end='  ')")
  echo "vdesk $i: $ws  (expected: eDP-1=ws$((2*i-1))  DP-3=ws$((2*i)))"
done
```

## Fix
- [fix] `hyprctl dispatch vdeskreset` rebuilds the mapping table at runtime #immediate
- [keybind] `SUPER+CTRL+SHIFT+R` bound to `vdeskreset` in `keybinds-sys.conf` #shortcut
- [auto] Lid switch binds chain `vdeskreset` after a 2s delay to auto-recover #prevention
- [fallback] Full Hyprland restart if `vdeskreset` doesn't resolve it #nuclear

## Key Files
- [file] `config/hypr/configs/keybinds-sys.conf` — vdeskreset keybind + lid switch auto-recovery #config
- [file] `config/hypr/configs/settings.conf` — plugin config with `rememberlayout = size` (lines 172-179) #config
- [file] `config/hypr/configs/rules-window.conf` — stickyrules that may land on wrong vdesks during corruption #config

## Upstream
- [upstream] https://github.com/levnikmyskin/hyprland-virtual-desktops/issues/44 #tracking
- [status] Open, acknowledged by developer as architectural limitation requiring Hyprland core changes #wontfix
