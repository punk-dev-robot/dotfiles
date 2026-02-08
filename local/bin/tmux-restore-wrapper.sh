#!/usr/bin/env bash
# Wrapper for tmux-resurrect restore with logging

LOG_FILE="/tmp/tmux-restore.log"
RESURRECT_SCRIPT="$HOME/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh"

echo "[$(date)] Starting tmux-resurrect restore wrapper" | tee -a "$LOG_FILE"
# Show current sessions before restore

echo "################################"
echo "[$(date)] Sessions before restore:" | tee -a "$LOG_FILE"
echo "################################"

tmux list-sessions | tee -a "$LOG_FILE"

if [ ! -x "$RESURRECT_SCRIPT" ]; then
  echo "[$(date)] ERROR: Resurrect restore script not found or not executable at $RESURRECT_SCRIPT" | tee -a "$LOG_FILE"
  exit 1
fi

echo "[$(date)] Executing resurrect restore script from inside tmux" | tee -a "$LOG_FILE"
EXIT_CODE=$?

# Run the restore script from inside tmux (using the main session)
tmux run-shell -t main "$RESURRECT_SCRIPT" 2>&1 | tee -a "$LOG_FILE"
echo "[$(date)] Resurrect restore completed with exit code: $EXIT_CODE" | tee -a "$LOG_FILE"

echo "################################"
echo "[$(date)] Sessions after restore:" | tee -a "$LOG_FILE"
echo "################################"

# List sessions after restore
tmux list-sessions 2>&1 | tee -a "$LOG_FILE"

# Give tmux a moment to settle after restore
sleep 0.5

exit $EXIT_CODE

