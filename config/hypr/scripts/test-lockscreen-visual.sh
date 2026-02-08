#!/bin/bash

# Visual test of lockscreen without security
# WARNING: This is only for testing appearance!

echo "Starting visual lockscreen test..."
echo "Press Ctrl+C to exit"
echo ""
echo "Your lockscreen will show:"
echo "- Time: Large clock center-top" 
echo "- Date: Below time"
echo "- System info: Bottom center"
echo "- Battery: Center (laptop only)"
echo "- 5K extras: System stats left, workspace right"
echo ""
echo "Locking in 3 seconds..."
sleep 3

# Run hyprlock
hyprlock --immediate