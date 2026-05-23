#!/usr/bin/env python3
"""Suggest ChunkHound MCP for conceptual code searches issued via Bash.

Background: Claude Code v2.1.117 removed the native `Grep`/`Glob` tools on
macOS/Linux builds (replaced by embedded `ugrep`/`bfs` accessed through Bash).
The `chunkhound-integration` plugin's only matcher is `PreToolUse:Grep`, so
its nudge pathway is dead on native builds. This hook restores the nudge at
the Bash layer.

Conservative by design: emits `allow` + `additionalContext` rather than
`ask`/`deny`, so routine searches are never interrupted.
"""

import json
import os
import re
import shlex
import sys
import time
from pathlib import Path

_PLUGIN_DIR = Path.home() / ".config/claude/plugins/marketplaces/shopware-ai-coding-tools/plugins/chunkhound-integration"
_SEARCH_CMDS = {"rg", "ugrep", "fd", "bfs"}
_CONCEPT_TOKENS = {
    "how", "where", "flow", "auth", "handler", "router", "middleware",
    "lifecycle", "pipeline", "dispatcher", "controller", "renderer",
    "subscriber", "publisher", "scheduler", "interceptor", "resolver",
}
_REGEX_METACHARS = re.compile(r"[\[\](){}|*+?^$\\]")
_TTL_SECONDS = 300


def _first_command_token(command: str) -> str:
    try:
        toks = shlex.split(command, comments=False, posix=True)
    except ValueError:
        return ""
    while toks and "=" in toks[0] and not toks[0].startswith("-"):
        toks.pop(0)
    if not toks:
        return ""
    head = Path(toks[0]).name
    if head in {"bash", "sh", "zsh"} and len(toks) >= 3 and toks[1] in {"-c", "-lc"}:
        try:
            inner = shlex.split(toks[2], comments=False, posix=True)
            return Path(inner[0]).name if inner else ""
        except ValueError:
            return ""
    return head


def _extract_pattern(command: str, head: str) -> str:
    try:
        toks = shlex.split(command, comments=False, posix=True)
    except ValueError:
        return ""
    while toks and Path(toks[0]).name != head:
        toks.pop(0)
    if toks:
        toks.pop(0)
    flags_with_value = {"-e", "-g", "-t", "-T", "--type", "--glob", "--regexp", "--iglob"}
    while toks:
        t = toks[0]
        if t.startswith("--") and "=" in t:
            toks.pop(0)
            continue
        if t in flags_with_value:
            toks.pop(0)
            if toks:
                toks.pop(0)
            continue
        if t.startswith("-"):
            toks.pop(0)
            continue
        return t
    return ""


def _looks_conceptual(pattern: str, command: str) -> bool:
    if not pattern:
        return False
    if re.search(r"(?<![A-Za-z])(-F|--fixed-strings)\b", command):
        return False
    if len(pattern.split()) >= 2:
        return True
    low = pattern.lower()
    if any(tok in low for tok in _CONCEPT_TOKENS):
        return True
    if _REGEX_METACHARS.search(pattern) and len(pattern) > 12:
        return True
    return False


def _throttle_ok(session_id: str) -> bool:
    marker = Path(f"/tmp/claude-chunkhound-nudge-{session_id}")
    now = time.time()
    if marker.exists() and now - marker.stat().st_mtime < _TTL_SECONDS:
        return False
    try:
        marker.touch()
    except OSError:
        pass
    return True


def main() -> None:
    if not _PLUGIN_DIR.exists():
        sys.exit(0)

    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    command = input_data.get("tool_input", {}).get("command", "")
    if not command:
        sys.exit(0)

    head = _first_command_token(command)
    if head not in _SEARCH_CMDS:
        sys.exit(0)

    pattern = _extract_pattern(command, head)
    if not _looks_conceptual(pattern, command):
        sys.exit(0)

    session_id = input_data.get("session_id", "default")
    if not _throttle_ok(session_id):
        sys.exit(0)

    nudge = (
        f"This `{head}` query looks conceptual (pattern: {pattern!r}). "
        "ChunkHound MCP often beats text search for architectural questions: "
        "`mcp__plugin_chunkhound-integration_ChunkHound__code_research` for deep research, "
        "`__search_semantic` for meaning-based discovery, "
        "`__search_regex` for cross-file pattern matches. "
        "Proceed with the Bash search if you've already decided, otherwise consider switching."
    )
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "additionalContext": nudge,
        }
    }
    print(json.dumps(output))
    sys.exit(0)


if __name__ == "__main__":
    main()
