# Tmux + Alacritty Systemd Integration

## Overview

A systemd-orchestrated terminal environment that survives reboots by combining tmux session persistence with socket activation and automatic state save/restore. The setup uses tmux-resurrect to capture window/pane state every 10 minutes and restore it on boot.

> "I can reboot at any time and I want my system to come back to the last state as much as possible"

## Architecture

### Service Dependency Graph

```
sockets.target
    └── tmux.socket (socket activation for tmux)

multiplexer.target
    ├── tmux.service (creates main session, WantedBy multiplexer.target)
    ├── tmux-restore.service (Requires tmux.service, restores sessions via resurrect)
    └── tmux-term@*.service (Requires tmux-restore.service, opens alacritty terminals)

timers.target
    ├── tmux-save.timer (saves state every 10 minutes)
    └── tmux-cleanup.timer (daily cleanup of old saves)
```

### Boot Sequence

1. `sockets.target` -- `tmux.socket` starts listening on `/tmp/tmux-%U/default`
2. `multiplexer.target` -- `tmux.service` starts (Type=forking), creates the `main` session
3. `tmux-restore.service` -- runs `tmux-restore-wrapper.sh` inside the main session, restoring all saved sessions via tmux-resurrect, then waits 4 seconds for tmux to settle
4. `tmux-term@*.service` -- alacritty instances start after restore completes, each attaching to its session with `tmux new-session -t %i -A` (creates-or-attaches)
5. User continues where they left off

## Systemd Units

### tmux.socket

Socket activation for the tmux server. Listens on the default tmux socket path.

```ini
[Socket]
ListenStream=/tmp/tmux-%U/default
SocketMode=0600
```

- **Starts at:** `sockets.target` (early boot)
- **Purpose:** Ensures tmux server is available before any client connects

### tmux.service

Creates the tmux server with an initial `main` session.

```ini
[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -t main -d
ExecStop=/usr/bin/tmux kill-server
```

- **Requires:** `tmux.socket`
- **WantedBy:** `multiplexer.target`
- **Purpose:** Bootstrap the tmux server; additional sessions are created by tmux-resurrect during restore

### tmux-restore.service

Restores previously saved tmux sessions on boot using tmux-resurrect.

```ini
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/home/kuba/.local/bin/tmux-restore-wrapper.sh
ExecStart=/bin/echo "Giving tmux couple of seconds to settle down"
ExecStart=/bin/sleep 4
```

- **Requires:** `tmux.service`
- **After:** `graphical-session.target`, `tmux.service`
- **Condition:** Only runs when Hyprland is active (`ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE`)
- **Purpose:** Runs resurrect restore script inside tmux, then waits for sessions to become attachable

### tmux-term@.service (template)

Template unit for alacritty terminal instances. Each instance attaches to a named tmux session.

```ini
[Service]
Type=exec
ExecStart=/usr/bin/alacritty --class %i-term -e tmux new-session -t %i -A
Restart=on-failure
RestartSec=3
```

- **Requires:** `tmux-restore.service`
- **After:** `tmux-restore.service`, `graphical-session.target`, `multiplexer.target`
- **Usage:** `systemctl --user start tmux-term@dots.service`
- **Purpose:** Opens an alacritty window attached to the specified tmux session

### alacritty@.service (legacy template)

An older template unit from before the tmux-term@ migration. Uses direct `tmux attach` without the restore dependency chain.

```ini
[Service]
Type=exec
ExecStart=/usr/bin/alacritty --class %i-term -e tmux attach -t %i
```

- **After:** `graphical-session.target`
- **Note:** Superseded by `tmux-term@.service` which adds proper restore ordering

### tmux-save.service / tmux-save.timer

Periodically saves tmux session state (windows, panes, working directories) every 10 minutes.

```ini
# tmux-save.service
[Service]
Type=oneshot
ExecStart=/home/kuba/.local/bin/tmux-save-wrapper.sh

# tmux-save.timer
[Timer]
OnCalendar=*:0/10
```

- **Prerequisite:** `tmux-restore.service` must have completed (prevents saving empty state)
- **Conflicts:** `shutdown.target` (does not save during shutdown)

### tmux-cleanup.service / tmux-cleanup.timer

Daily cleanup of old tmux-resurrect save files, keeping the most recent 12.

```ini
# tmux-cleanup.service
[Service]
Type=oneshot
ExecStart=/home/kuba/.local/bin/tmux-cleanup-sessions.sh

# tmux-cleanup.timer
[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h
```

- **Conflicts:** `tmux-save.service` (prevents cleanup during a save operation)

### multiplexer.target

Custom target that groups all tmux-related units for dependency management.

## Session Layout

| Session   | Purpose                          |
|-----------|----------------------------------|
| main      | Primary workspace                |
| dots      | Dotfiles work (workspace 2)      |
| work      | Work projects (workspace 3)      |
| claude    | AI assistance                    |
| dropterm  | Dropdown terminal (scratchpad)   |

## Scripts

All scripts live in `local/bin/`.

### tmux-restore-wrapper.sh

Wrapper around tmux-resurrect's `restore.sh`. Logs sessions before and after restore, runs the restore script inside the `main` tmux session via `tmux run-shell`, and waits 0.5s for tmux to settle.

### tmux-save-wrapper.sh

Validates session state before saving: checks tmux server is responsive, verifies minimum 3 sessions exist, confirms required sessions (`dots`, `work`, `dropterm`) are present. Runs the resurrect save script with `systemd-inhibit` to prevent interruption during sleep/shutdown.

### tmux-cleanup-sessions.sh

Counts `.txt` save files in `~/.local/share/tmux/resurrect/`, deletes all but the most recent 12. Uses `systemd-inhibit` to prevent interruption during cleanup.

### test-tmux-alacritty.sh

Automated test script for the tmux+alacritty+systemd integration. Runs configurable iterations of stop-start cycles, checking that all services activate correctly, sessions attach to the right tmux sessions, and Hyprland windows are created. Uses a lock file to prevent concurrent runs.

## Quick Reference

### Service Management

```bash
# Start tmux and all terminals
systemctl --user start multiplexer.target

# Restart a specific terminal
systemctl --user restart tmux-term@dots.service

# Check service status
systemctl --user status tmux.service
systemctl --user status tmux-term@dots.service

# Stop everything
systemctl --user stop multiplexer.target
```

### Session State

```bash
# Manually save current state
systemctl --user start tmux-save.service

# Force cleanup of old saves
systemctl --user start tmux-cleanup.service

# View save/cleanup schedule
systemctl --user list-timers | rg tmux

# Check last save time
eza -la ~/.local/share/tmux/resurrect/ | tail -1
```

### Debugging

```bash
# View service logs
journalctl --user -u tmux.service -f
journalctl --user -u tmux-term@dots.service --since "5 min ago"

# Check if tmux sessions exist
tmux list-sessions

# Verify service dependencies
systemctl --user list-dependencies multiplexer.target
```

### Adding a New Terminal Session

1. Enable and start the new template instance:

```bash
systemctl --user daemon-reload
systemctl --user enable tmux-term@newsession.service
systemctl --user start tmux-term@newsession.service
```

No new service file needed -- the template handles everything. tmux-resurrect will save the new session automatically once created.

## Migration History

Originally terminals were launched via Hyprland `exec-once` with timing-based hacks (`sleep 2 && alacritty ...`). The systemd approach replaced this with proper dependency management, automatic restart on failure, journald logging, and session lifecycle integration. See [race-condition-troubleshooting.md](race-condition-troubleshooting.md) for the full debugging history.
