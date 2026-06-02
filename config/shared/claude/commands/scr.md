---
description: Read or list screenshots from ~/Pictures/Screenshots/
argument-hint: [count|list|today|1h]
allowed-tools: Bash(ls:*), Bash(find:*), Read
---

## Context

Screenshots directory: `~/Pictures/Screenshots/`
Recent screenshots: !`ls -lt ~/Pictures/Screenshots/*.png 2>/dev/null | head -10`
Argument provided: $ARGUMENTS

## Arguments (all optional)

| Argument | Behavior |
|----------|----------|
| (empty) | Read the most recent screenshot |
| `3` | Read the last 3 screenshots |
| `list` | List last 10 screenshots (don't read) |
| `list 20` | List last 20 screenshots |
| `today` | Read all screenshots from today |
| `1h` | Read screenshots from the last hour |

## Task

Based on `$ARGUMENTS`:

1. **Empty or number**: Use the Read tool to read the last N screenshots (default N=1)
2. **"list" or "list N"**: Show filenames with modification times, do NOT read file contents
3. **"today"**: Find and read all screenshots with today's date in modification time
4. **Time pattern (1h, 2h, 30m)**: Find and read screenshots modified within that time window

For reading screenshots, use the Read tool on each file path.
For listing, just output the file list from the context above.
