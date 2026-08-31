#!/usr/bin/env python3
"""Nudge away from built-in search tools. Allow retry within TTL window.

On first call for a tool, creates a marker and denies with a message pointing
to preferred alternatives. If the same tool is retried within the TTL window,
the marker is consumed and the tool is allowed as fallback. Each cycle is
independent -- after consumption, the next call starts fresh.
"""

import json
import sys
import time
from pathlib import Path

_PREFERRED_TOOLS = {
    "Glob": ("the Chunkhound search tool, as well as bash rg and fd tools instead"),
    "Grep": (
        "the Chunkhound search and research are preferred tools and great replacement. Alternatively search tools provided by serena"
    ),
}

_TTL_SECONDS = 120


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    tool_name = input_data.get("tool_name", "")
    if tool_name not in _PREFERRED_TOOLS:
        sys.exit(0)

    session_id = input_data.get("session_id", "default")
    marker = Path(f"/tmp/claude-prefer-{session_id}-{tool_name}")

    if marker.exists():
        age = time.time() - marker.stat().st_mtime
        if age < _TTL_SECONDS:
            marker.unlink(missing_ok=True)
            sys.exit(0)
        marker.unlink(missing_ok=True)

    marker.touch()

    preferred = _PREFERRED_TOOLS[tool_name]
    reason = f"Use {preferred} instead of {tool_name}. If the alternative fails, retry {tool_name} as fallback."
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }
    print(json.dumps(output))
    sys.exit(0)


if __name__ == "__main__":
    main()
