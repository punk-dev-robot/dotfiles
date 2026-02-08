#!/usr/bin/env python3
"""Suggest preferred alternatives for certain tools (allows fallback)."""

import json
import sys

_PREFERRED_TOOLS = {
    "WebSearch": "mcp__plugin_exa-mcp-server_exa__web_search_exa (exa) or mcp__firecrawl-lab__firecrawl_search (firecrawl)",
    "WebFetch": "mcp__firecrawl-lab__firecrawl_scrape or mcp__firecrawl-cloud__firecrawl_scrape (firecrawl)",
}


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    tool_name = input_data.get("tool_name", "")
    if tool_name in _PREFERRED_TOOLS:
        preferred = _PREFERRED_TOOLS[tool_name]
        hint = f"💡 Preferred: {preferred}"
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": hint,
                "additionalContext": f"IMPORTANT: Consider using {preferred} instead of {tool_name} for better results. Fallback allowed.",
            }
        }
        print(json.dumps(output))
        sys.exit(0)

    sys.exit(0)


if __name__ == "__main__":
    main()
