#!/usr/bin/env python3
"""Deny first WebSearch/WebFetch call, allow retry after MCP failure.

Uses session-scoped temp files to track denied tools. First call for a tool
creates a marker and denies with a message pointing to MCP alternatives.
Second call (same tool, same session) means MCP failed -- allow as fallback.
"""

import json
import sys
from pathlib import Path

_PREFERRED_TOOLS = {
    "WebSearch": "exa (mcp__plugin_exa-mcp-server_exa__web_search_exa) or firecrawl (mcp__firecrawl-lab__firecrawl_search)",
    "WebFetch": "firecrawl (mcp__firecrawl-lab__firecrawl_scrape or mcp__firecrawl-cloud__firecrawl_scrape)",
}


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
    marker_dir = Path(f"/tmp/claude-prefer-tools-{session_id}")
    marker_file = marker_dir / tool_name

    if marker_file.exists():
        sys.exit(0)

    marker_dir.mkdir(parents=True, exist_ok=True)
    marker_file.touch()

    preferred = _PREFERRED_TOOLS[tool_name]
    reason = f"Use {preferred} instead of {tool_name}. Retry with {tool_name} if MCP tools fail."
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
