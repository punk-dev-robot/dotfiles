---
title: Tmux State Management System
type: note
permalink: system/tmux-state-management-system
---

# Tmux State Management System

## Philosophy
"I can reboot at any time and want my system to come back to the last state as much as possible"

## Current Implementation

### Components
1. **tmux-resurrect plugin** - Saves/restores tmux sessions
2. **tmux-save.service/timer** - Saves state every 10 minutes with systemd-inhibit
3. **tmux-cleanup.service/timer** - Cleans old saves daily (keeps last 12)
4. **tmux-server.service** - Creates sessions on boot
5. **alacritty services** - Attach to pre-existing sessions

### Flow
1. Every 10 minutes: tmux-save captures all windows, panes, working directories
2. On boot: tmux-server creates sessions
3. tmux-resurrect automatically restores saved state
4. Alacritty services attach to restored sessions
5. User continues exactly where they left off

## Benefits
- Survives unexpected reboots
- No manual session management
- Automatic cleanup of old saves
- Works with browser session restore
- Truly stateless workstation

## Integration with New Services
The tmux-server.service we created fits perfectly:
- Creates sessions that resurrect will populate
- Alacritty services wait for sessions to exist
- No changes needed to save/restore mechanism