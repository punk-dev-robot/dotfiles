# Tmux Systemd Quick Reference

## Common Commands

### Service Management
```bash
# Start/stop all terminal services
systemctl --user start tmux-server.service
systemctl --user stop tmux-server.service

# Restart a specific terminal
systemctl --user restart alacritty-dots.service

# Check service status
systemctl --user status tmux-server.service
systemctl --user status alacritty-*.service
```

### Session State
```bash
# Manually save current state
systemctl --user start tmux-save.service

# Check last save time
ls -la ~/.local/share/tmux/resurrect/ | tail -1

# Force cleanup of old saves
systemctl --user start tmux-cleanup.service

# View save/cleanup schedule
systemctl --user list-timers | grep tmux
```

### Debugging
```bash
# View service logs
journalctl --user -u tmux-server.service -f
journalctl --user -u alacritty-dots.service --since "5 minutes ago"

# Check if tmux sessions exist
tmux list-sessions

# Verify service dependencies
systemctl --user list-dependencies tmux-server.service
systemctl --user list-dependencies alacritty-dots.service
```

### Adding New Terminal Session

1. Add session to tmux-server.service:
```ini
ExecStartPost=/usr/bin/bash -c 'tmux has-session -t newsession || tmux new-session -d -s newsession'
```

2. Enable and start the new instance:
```bash
systemctl --user daemon-reload
systemctl --user enable alacritty@newsession.service
systemctl --user start alacritty@newsession.service
```

No need to create new service files - the template handles everything!

## Troubleshooting

### Terminal won't start
```bash
# Check if tmux session exists
tmux has-session -t dots && echo "exists" || echo "missing"

# Check service status
systemctl --user status alacritty-dots.service

# View detailed logs
journalctl --user -xeu alacritty-dots.service
```

### State not restoring
```bash
# Check if resurrect save exists
ls ~/.local/share/tmux/resurrect/last

# Manually restore
tmux source-file ~/.local/share/tmux/resurrect/last

# Check save timer
systemctl --user status tmux-save.timer
```

### Services not starting on boot
```bash
# Verify services are enabled
systemctl --user is-enabled tmux-server.service
systemctl --user is-enabled alacritty-dots.service

# Check target dependencies
systemctl --user status graphical-session.target
```