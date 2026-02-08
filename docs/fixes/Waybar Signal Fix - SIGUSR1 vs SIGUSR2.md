---
title: Waybar Signal Fix - SIGUSR1 vs SIGUSR2
type: note
permalink: fixes/waybar-signal-fix-sigusr1-vs-sigusr2
tags:
- waybar
- hyprland
- signals
- hyprevents
- virtual-desktops
---

# Waybar Signal Fix - SIGUSR1 vs SIGUSR2

## Problem
- [issue] Waybar disappeared when zen browser windows moved to virtual desktops #waybar
- [symptom] Waybar layer dropped to level 1 (bottom) instead of level 2 (top) #wlr-layer-shell
- [trigger] hyprevents script sending wrong signal when moving windows #hyprevents

## Root Cause
- [cause] `pkill -SIGUSR1 waybar` in hyprevents toggled visibility OFF #signals
- [signal] SIGUSR1 = toggle visibility (hide/show) #waybar-signals
- [signal] SIGUSR2 = reload configuration/refresh #waybar-signals
- [context] Signal was added to refresh waybar-vd module showing populated vdesks #waybar-vd

## Solution
- [fix] Changed `pkill -SIGUSR1 waybar` to `pkill -SIGUSR2 waybar` in hyprevents #implementation
- [file] `local/bin/hyprevents` - handles Hyprland IPC events #files
- [result] Waybar stays visible and vdesks properly refresh when windows move #verified

## Failed Approaches
- [attempted] systemd `After=shikane.service` - only waits for process launch, not completion #systemd
- [attempted] `ExecStartPre=/usr/bin/sleep 4` - timing still varied #systemd
- [attempted] shikane exec waybar restart - issue happened later in session #shikane

## Related Fix - cld Alias
- [issue] `cld -c` and `cld -r` stopped working (Claude CLI with 1password) #zsh
- [cause] Alias put arguments after `/dev/null` instead of passing to claude #aliases
- [fix] Converted alias to function in `090-aliases.zsh` using `$*` for args #implementation

## Key Learnings
- [learning] Waybar signal semantics: SIGUSR1=toggle, SIGUSR2=reload #signals
- [learning] Shell aliases can't properly pass arguments in complex pipelines #zsh
- [learning] systemd After= only waits for process start, not completion #systemd
