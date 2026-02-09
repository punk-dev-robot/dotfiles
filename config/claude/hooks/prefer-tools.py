#!/usr/bin/env python3
"""Deny WebSearch/WebFetch, suggest MCP. Allow retry within TTL window.

On first call for a tool, creates a marker and denies with a message pointing
to MCP alternatives. If the same tool is retried within 30 seconds (MCP failed),
the marker is consumed and the tool is allowed as fallback. Each cycle is
independent -- after consumption, the next call starts fresh.
"""

import json
import sys
import time
from pathlib import Path

_PREFERRED_TOOLS = {
    "WebSearch": "exa (mcp__plugin_exa-mcp-server_exa__web_search_exa) or firecrawl (mcp__firecrawl-lab__firecrawl_search)",
    "WebFetch": "firecrawl (mcp__firecrawl-lab__firecrawl_scrape or mcp__firecrawl-cloud__firecrawl_scrape)",
}

_TTL_SECONDS = 30


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
    reason = f"Use {preferred} instead of {tool_name}. If MCP tools fail, retry {tool_name} as fallback."
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
