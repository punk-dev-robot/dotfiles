#!/usr/bin/env python3
"""Block dangerous commands that should never be run by Claude."""

import json
import re
import sys

_DANGEROUS = [
    (re.compile(r"sudo\s+dotter"), "Do not run dotter with sudo. Dotter handles privilege escalation internally. Running with sudo deploys to /root/ and corrupts the cache."),
    (re.compile(r"dotter\s+undeploy"), "dotter undeploy removes ALL symlinks. This would break the entire dotfiles deployment."),
    (re.compile(r"rm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+[~/]|rm\s+-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*\s+[~/]"), "Recursive force-delete on home or root directory. Too destructive."),
    (re.compile(r"chmod\s+-R\s+777"), "Recursive 777 permissions would break security on the entire tree."),
    (re.compile(r"\bdd\s+if="), "Raw disk write via dd. Too dangerous to run without explicit user confirmation outside Claude."),
    (re.compile(r"\bmkfs\b"), "Filesystem formatting. Too dangerous to run without explicit user confirmation outside Claude."),
    (re.compile(r"git\s+push\s+.*(-f\b|--force(?!-with-lease)\b)"), "Force push can overwrite remote history. Use --force-with-lease for safer force pushes, or get explicit user confirmation."),
    (re.compile(r"git\s+reset\s+--hard\b"), "git reset --hard discards all uncommitted changes. This is destructive and irreversible."),
    (re.compile(r"git\s+clean\s+.*-[a-zA-Z]*f"), "git clean -f removes untracked files permanently. This is destructive and irreversible."),
]


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(1)

    command = input_data.get("tool_input", {}).get("command", "")
    if not command:
        sys.exit(0)

    for pattern, reason in _DANGEROUS:
        if pattern.search(command):
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
