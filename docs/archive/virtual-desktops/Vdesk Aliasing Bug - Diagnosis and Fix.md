---
title: Vdesk Aliasing Bug - Diagnosis and Fix
type: note
permalink: hyprland/vdesk-aliasing-bug-diagnosis-and-fix
tags:
- hyprland
- virtual-desktops
- bug
- monitor-hotplug
- vdeskreset
---

# Vdesk Aliasing Bug

## Problem
- Two vdesks (e.g. 2 and 8) become aliased — they switch to the same workspace IDs
- Moving a window from one removes it from the other
- Sticky-ruled windows land on wrong vdesks

## Root Cause
- Known bug in `virtual-desktops` plugin v2.2.8 (upstream: levnikmyskin/hyprland-virtual-desktops#44)
- Plugin's internal vdesk→workspace mapping corrupts during monitor hotplug events
- Triggered by: lid close/open, external monitor plug/unplug
- `rememberlayout` setting does NOT prevent this (any value including `none`)

## Diagnosis Session (2026-02-12)
- vdesk 8 mapped to ws 5+4 instead of ws 15+16
- vdesk 8 shared ws 4 with vdesk 2 (external) and ws 5 with vdesk 3 (laptop)
- `work-term` (stickyrule=vdesk3) ended up on ws 16 (orphaned vdesk 8 workspace)
- All other vdesks (1-7, 9-10) mapped correctly

## Fix Applied
- `hyprctl dispatch vdeskreset` rebuilds mapping at runtime
- Added keybind: `SUPER+CTRL+SHIFT+R` → vdeskreset
- Chained vdeskreset (2s delay) into lid switch binds for auto-recovery
- Documented in `docs/troubleshooting/vdesk-aliasing.md`

## Files Changed
- `config/hypr/configs/keybinds-sys.conf` — keybind + lid switch auto-recovery
- `docs/troubleshooting/vdesk-aliasing.md` — new troubleshooting doc
