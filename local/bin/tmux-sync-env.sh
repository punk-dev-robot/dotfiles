#!/usr/bin/env bash
# Sync environment variables from systemd to tmux based on update-environment setting

# Get list of variables from tmux update-environment
VARS=$(tmux show-options -g update-environment 2>/dev/null | sed 's/update-environment\[[0-9]*\] //g')

if [ -z "$VARS" ]; then
    echo "No update-environment variables configured"
    exit 1
fi

# Sync each variable from systemd to tmux global environment
for var in $VARS; do
    value=$(systemctl --user show-environment | grep "^${var}=" | cut -d= -f2-)
    
    if [ -n "$value" ]; then
        tmux setenv -g "$var" "$value"
    else
        # Remove from tmux if not in systemd environment
        tmux setenv -gu "$var" 2>/dev/null
    fi
done

