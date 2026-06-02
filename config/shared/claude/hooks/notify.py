#!/usr/bin/env python3
"""Send desktop notification with sound for Claude notifications."""

import json
import os
import subprocess
import sys

SOUND_FILE = "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"
ICON = "/usr/share/icons/AdwaitaLegacy/32x32/legacy/utilities-terminal.png"


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    message = input_data.get("message", "Notification")
    cwd = input_data.get("cwd", "")

    # Extract project name from cwd
    project = os.path.basename(cwd) if cwd else ""
    title = f"Claude Code • {project}" if project else "Claude Code"

    # Desktop notification with category and timeout
    subprocess.run(
        [
            "notify-send",
            "-a", "Claude Code",
            "-i", ICON,
            "-c", "im.received",
            "-t", "5000",  # 5 second timeout
            title,
            message,
        ],
        capture_output=True,
    )

    # Play sound (non-blocking)
    subprocess.Popen(
        ["paplay", SOUND_FILE],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    sys.exit(0)


if __name__ == "__main__":
    main()