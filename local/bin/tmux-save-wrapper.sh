#!/usr/bin/env bash
# Wrapper for tmux-resurrect save with validation

# Configuration
MIN_SESSIONS=3  # Adjust based on your needs
REQUIRED_SESSIONS=("dots" "work" "dropterm")

# Check if tmux server is responsive
if ! tmux list-sessions &>/dev/null; then
    echo "[$(date)] ERROR: tmux server not responding, skipping save" >&2
    exit 1
fi

# Count active sessions
session_count=$(tmux list-sessions 2>/dev/null | wc -l)
if [ "$session_count" -lt "$MIN_SESSIONS" ]; then
    echo "[$(date)] ERROR: Only $session_count sessions found (minimum: $MIN_SESSIONS), skipping save" >&2
    exit 1
fi

# Verify required sessions exist
for session in "${REQUIRED_SESSIONS[@]}"; do
    if ! tmux has-session -t "$session" 2>/dev/null; then
        echo "[$(date)] ERROR: Required session '$session' missing, skipping save" >&2
        exit 1
    fi
done

echo "[$(date)] Validation passed: $session_count sessions, saving..."

# Run the actual save with systemd-inhibit
systemd-inhibit --why="Tmux session save in progress" \
                --what="sleep:shutdown" \
                --mode="delay" \
                /bin/bash /home/kuba/.config/tmux/plugins/tmux-resurrect/scripts/save.sh