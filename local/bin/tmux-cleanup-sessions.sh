#!/usr/bin/env bash
# Clean up old tmux resurrect sessions

RESURRECT_DIR="$HOME/.local/share/tmux/resurrect"
KEEP_SESSIONS=12  # Keep last 12 saves (about 2 hours worth)

# Check if directory exists
if [ ! -d "$RESURRECT_DIR" ]; then
    echo "[$(date)] Resurrect directory not found: $RESURRECT_DIR"
    exit 0
fi

# Count current files
total_files=$(ls -1 "$RESURRECT_DIR"/*.txt 2>/dev/null | wc -l)
if [ "$total_files" -le "$KEEP_SESSIONS" ]; then
    echo "[$(date)] Only $total_files session files found, keeping all (threshold: $KEEP_SESSIONS)"
    exit 0
fi

# Get files to delete (all but the most recent KEEP_SESSIONS)
files_to_delete=$(ls -t "$RESURRECT_DIR"/*.txt 2>/dev/null | tail -n +$((KEEP_SESSIONS + 1)))
delete_count=$(echo "$files_to_delete" | wc -l)

if [ -z "$files_to_delete" ]; then
    echo "[$(date)] No files to delete"
    exit 0
fi

echo "[$(date)] Cleaning up $delete_count old session files..."

# Use systemd-inhibit to prevent interruption
echo "$files_to_delete" | systemd-inhibit --what="sleep:shutdown" \
                                         --why="Cleaning tmux resurrect sessions" \
                                         xargs -d "\n" rm -v

echo "[$(date)] Cleanup complete"