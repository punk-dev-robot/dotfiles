#!/bin/bash
# PreToolUse Bash gate: block cat/head/tail/find/grep/rg/wc/bare-ls invocations.
# Global CLAUDE.md bans these in favour of Read/Grep/Glob/rtk. RTK wrappers pass.
# Escape hatch: touch /tmp/bash-raw-unlock-$PPID.
set -uo pipefail
# Per-repo opt-out: skip enforcement when project marks itself exempt.
[ -f "${CLAUDE_PROJECT_DIR:-}/.claude/.no-tool-enforce" ] && exit 0
# NOTE: deliberately NOT using `set -e`. Malformed JSON on stdin would make jq
# exit non-zero; with -e the whole hook would exit 1, which Claude Code may
# interpret as a tool block (false positive). Without -e, jq returns empty
# string on parse failure and we fall through to `exit 0` (allow).

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
[ "$TOOL" = "Bash" ] || exit 0

UNLOCK=/tmp/bash-raw-unlock
# Unlock expires after 10 min (prevents silent permanent bypass).
check_unlock() {
  local f=$1
  [ -f "$f" ] || return 1
  local mtime
  mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
  local age=$(($(date +%s) - mtime))
  # Negative age = future mtime (clock skew, manual touch -t) → treat as expired
  # so a stale/forged unlock can't bypass the gate indefinitely.
  if [ "$age" -ge 0 ] && [ "$age" -lt 600 ]; then return 0; fi
  rm -f "$f"
  return 1
}
check_unlock "$UNLOCK" && exit 0
check_unlock "/tmp/bash-raw-unlock-$PPID" && exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# Strip leading env/timeout/nice wrappers.
TRIMMED=$(echo "$CMD" | sed -E 's/^[[:space:]]*//')

# Match only first token (command head, unwrapped). Allow `rtk <tool>` wrappers.
FIRST=$(echo "$TRIMMED" | awk '{print $1}')

banned=0
case "$FIRST" in
cat | head | tail | find | grep | rg | wc) banned=1 ;;
rtk)
  # rtk wraps git/cargo/pytest/docker/etc — pass through.
  exit 0
  ;;
esac

# Catch truncation pipes only when pipeline source is a file-reader (cat/grep/rg/find).
# `curl | head`, `git log | head`, `browse ... | head` are fine — they produce bounded output.
if echo "$CMD" | grep -qE '\|\s*(tail|head)\b' && echo "$FIRST" | grep -qE '^(cat|grep|rg|find)$'; then
  cat >&2 <<EOF
BLOCKED: '| tail'/'| head' pipeline. Output truncation not allowed — raw output still floods context before trim.

REPLACE WITH mcp__plugin_context-mode_context-mode__ctx_batch_execute:
  commands: [{"label": "lint", "command": "npm run lint --silent"}]
  queries:  ["error", "warning", "fail"]

Sandbox captures full output, returns only matching sections. Works for single or many commands.
For ONE short command (<20 lines) drop the pipe — just run it raw.
Override (rare): touch $UNLOCK
EOF
  exit 2
fi

# Let other compound commands with `&&`, `|`, `;` past (users chain safe invocations).
# But still catch blatant pipelines starting with banned tool.
if [ "$banned" -eq 0 ]; then
  exit 0
fi

case "$FIRST" in
cat | head | tail)
  echo "BLOCKED Bash '$FIRST'. Use the Read tool (absolute path, optional offset/limit). Override: touch $UNLOCK." >&2
  ;;
find)
  echo "BLOCKED Bash 'find'. Use the Glob tool (pattern='**/...'). Override: touch $UNLOCK." >&2
  ;;
grep | rg)
  echo "BLOCKED Bash '$FIRST'. Use the Grep tool (pattern, glob, output_mode). Override: touch $UNLOCK." >&2
  ;;
wc)
  echo "BLOCKED Bash 'wc'. If you need line count, Read the file (line count is visible) or pipe via 'rtk wc'. Override: touch $UNLOCK." >&2
  ;;
esac
exit 2
