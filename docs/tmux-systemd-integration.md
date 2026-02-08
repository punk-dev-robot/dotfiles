# Tmux and Alacritty Systemd Integration

## Overview

This setup provides a robust, stateful terminal environment that survives reboots and maintains session state automatically. It combines tmux session management with systemd service orchestration and automatic state persistence.

## Philosophy

> "I can reboot at any time and I want my system to come back to the last state as much as possible"

This principle drives the entire architecture - creating a truly stateless workstation where work state persists across reboots without manual intervention.

## Architecture

### Core Components

1. **tmux-server.service** - Master tmux server that creates all sessions on boot
2. **tmux-resurrect plugin** - Saves and restores tmux session state (windows, panes, working directories)
3. **tmux-save.service/timer** - Periodically saves session state every 10 minutes
4. **tmux-cleanup.service/timer** - Daily cleanup of old session saves
5. **alacritty-*.service** - Individual terminal services that attach to tmux sessions
6. **pyprland** - Manages scratchpad terminals and window placement

### Service Dependencies

```
graphical-session.target
    ├── tmux-server.service (creates sessions)
    ├── pyprland.service (window management, wants tmux-server)
    └── alacritty@*.service (requires tmux-server, after pyprland)
```

**Dependency Types Explained**:
- `After=` - Ensures start order but doesn't wait for readiness (unless Type=oneshot)
- `Requires=` - Hard dependency, fails if required service fails
- `Wants=` - Soft dependency, starts the service if not running but doesn't fail

**Why This Matters**: 
- Systemd starts services in parallel for speed
- Without proper dependencies, you get race conditions
- `Type=oneshot` makes systemd wait for service completion
- Pyprland uses `Wants=tmux-server.service` so it doesn't fail if tmux fails

## Session Layout

- **main** - Primary tmux session
- **dots** - Dotfiles work (workspace 2)
- **work** - Work projects (workspace 3)
- **claude** - AI assistance (workspace 8 or scratchpad)
- **dropterm** - Dropdown terminal (pyprland scratchpad)

## Implementation Details

### tmux-server.service

Creates all tmux sessions on boot. Uses `Type=oneshot` to ensure systemd waits for ALL sessions to be created before considering the service "active".

```ini
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/tmux new-session -d -s main
ExecStart=/usr/bin/bash -c 'tmux has-session -t dots || tmux new-session -d -s dots'
ExecStart=/usr/bin/bash -c 'tmux has-session -t claude || tmux new-session -d -s claude'
ExecStart=/usr/bin/bash -c 'tmux has-session -t work || tmux new-session -d -s work'
ExecStart=/usr/bin/bash -c 'tmux has-session -t dropterm || tmux new-session -d -s dropterm'
```

**Key point**: `Type=oneshot` ensures all ExecStart commands complete before dependent services start. This prevents race conditions where alacritty might start before its tmux session exists.

### alacritty@.service Template

A single template unit handles all terminal instances using systemd's instance parameter:

```ini
[Unit]
Description=Alacritty terminal - %i session
After=tmux-server.service pyprland.service
Requires=tmux-server.service

[Service]
Type=exec
ExecStartPre=/usr/bin/bash -c 'until tmux has-session -t %i; do sleep 0.5; done'
ExecStart=/usr/bin/alacritty --class term-%i -e tmux attach -d -t %i
Restart=on-failure
```

This allows starting terminals with:
- `systemctl --user start alacritty@dots.service`
- `systemctl --user start alacritty@work.service`
- `systemctl --user start alacritty@claude.service`

### State Persistence

The tmux-save service runs every 10 minutes with systemd-inhibit to prevent interruption:

```bash
systemd-inhibit --why="Tmux session save in progress" \
                --what="sleep:shutdown" \
                --mode="delay" \
                /bin/bash /path/to/tmux-resurrect/scripts/save.sh
```

### Cleanup Strategy

Old session saves are cleaned daily, keeping the most recent 12 saves:

```bash
ls -t ~/.local/share/tmux/resurrect | tail -n +13 | xargs -I {} rm -v "~/.local/share/tmux/resurrect/{}"
```

## Boot Sequence

1. System reaches graphical-session.target
2. tmux-server.service starts, creates empty sessions
3. tmux-resurrect automatically restores saved state into sessions
4. pyprland.service starts for window management
5. alacritty services start and attach to restored sessions
6. User continues exactly where they left off

## Benefits

- **Zero manual session management** - Everything is automated
- **Survives unexpected reboots** - State saved every 10 minutes
- **Clean dependency management** - Systemd ensures proper startup order
- **Integrated with window management** - Works with pyprland scratchpads
- **Automatic cleanup** - Old saves removed daily
- **Centralized logging** - All output goes to journald

## Monitoring and Debugging

```bash
# Check service status
systemctl --user status tmux-server.service
systemctl --user status alacritty-dots.service

# View logs
journalctl --user -u tmux-server.service
journalctl --user -u alacritty-dots.service

# Check timer status
systemctl --user list-timers | grep tmux

# Manually save tmux state
systemctl --user start tmux-save.service

# View saved sessions
ls -la ~/.local/share/tmux/resurrect/
```

## Migration from exec-once

Previously, terminals were launched via Hyprland's exec-once with timing-based dependencies:

```bash
# Old approach
exec-once=tmux new -A -d -s main
exec-once=sleep 2 && alacritty --class term-dots -e tmux attach -d -t dots
```

The systemd approach provides:
- Proper dependency management (no sleep hacks)
- Automatic restart on failure
- Better resource tracking
- Cleaner logs via journald
- Integration with session lifecycle

## Future Enhancements

1. **Alacritty daemon mode** - Could use socket activation for faster window creation
2. **Dynamic session creation** - Create sessions on-demand rather than predefined
3. **Session templates** - Define session layouts in configuration
4. **Multi-monitor awareness** - Restore to specific monitors based on state