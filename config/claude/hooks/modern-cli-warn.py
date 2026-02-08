#!/usr/bin/env python3
"""Block legacy CLI tools and suggest modern alternatives."""

import json
import re
import sys

_MODERN_ALTERNATIVES = {
    "grep": "rg",
    "find": "fd",
    "sed": "sd",
    "ls": "eza",
    "du": "dust",
    "df": "duf",
    "ps": "procs",
    "top": "btm",
    "htop": "btm",
    "dig": "dog",
    "nslookup": "dog",
    "curl": "xh",
    "watch": "viddy",
    "cut": "choose",
    "cloc": "tokei",
}

_LEGACY_PATTERN = re.compile(r"\b(" + "|".join(_MODERN_ALTERNATIVES) + r")\b")


def _validate_command(command: str) -> list[str]:
    """Check command for legacy tools and return suggestions."""
    found = set(_LEGACY_PATTERN.findall(command))
    return [f"Use '{_MODERN_ALTERNATIVES[t]}' instead of '{t}'" for t in found]


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    command = input_data.get("tool_input", {}).get("command", "")
    if not command:
        sys.exit(0)

    issues = _validate_command(command)
    if issues:
        reason = "Modern CLI alternatives: " + ", ".join(issues)
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }
        print(json.dumps(output))
        sys.exit(0)

    sys.exit(0)


if __name__ == "__main__":
    main()