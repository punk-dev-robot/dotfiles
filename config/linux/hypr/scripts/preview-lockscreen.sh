#!/bin/bash

# Test lockscreen appearance safely

# Option 1: Quick lock and screenshot
# This locks for real but tries to grab screenshot immediately
echo "Testing lockscreen - will lock for 3 seconds..."
sleep 1

# Lock and schedule unlock
hyprlock &
LOCK_PID=$!

# Wait a moment for lock to appear
sleep 0.5

# Try to screenshot (might not work due to security)
grim /tmp/lockscreen-test.png 2>/dev/null || echo "Screenshot blocked by lockscreen"

# Kill hyprlock after 3 seconds
(sleep 3 && kill $LOCK_PID 2>/dev/null) &

wait $LOCK_PID 2>/dev/null

if [[ -f /tmp/lockscreen-test.png ]]; then
    notify-send "Lockscreen Preview" "Saved to /tmp/lockscreen-test.png"
    # Open in image viewer
    feh /tmp/lockscreen-test.png || xdg-open /tmp/lockscreen-test.png
else
    notify-send "Lockscreen Preview Failed" "Couldn't capture - security prevents screenshots"
fi