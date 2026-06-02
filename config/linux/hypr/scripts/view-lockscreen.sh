#!/bin/bash

# View lockscreen appearance
echo "Testing lockscreen appearance..."
echo "This will lock your screen for real - you'll need to enter your password!"
echo ""
echo "The lockscreen should show:"
echo "- Large clock at center-top"
echo "- Date below the clock"
echo "- Your profile picture ABOVE the password input"
echo "- Password input field"
echo "- System info at bottom"
echo ""
echo "On your 5K monitor, you should also see:"
echo "- System stats (CPU/RAM/Load) on the LEFT"
echo "- YouTube Music status and workspace on the RIGHT"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# Lock with immediate render
hyprlock --immediate-render