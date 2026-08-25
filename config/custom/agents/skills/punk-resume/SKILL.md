---
name: punk-resume
description: Resume work from a punk-handoff document — find recent handoffs for the current project, let the user pick one, read it, and continue.
argument-hint: "Optional: which handoff or what to focus on"
disable-model-invocation: true
---

# Punk Resume

## 1. Locate candidates

- Handoff root: `${XDG_STATE_HOME:-$HOME/.local/state}/punk/handoffs`.
- Project slug: `basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"`.
  If not in a git repo, use `basename "$PWD"`.
- List the last 3 handoffs by modification time in `<root>/<slug>/`:
  `ls -t <root>/<slug>/*.md 2>/dev/null | head -3`
- If the project has none, fall back to the last 3 across all projects:
  `ls -t <root>/*/*.md 2>/dev/null | head -3`
- If there are none at all, say so and stop.

## 2. Pick

Read the metadata header (date, repo, branch, goal) of each candidate and
present them to the user as options — date, repo, branch, goal per option —
plus the ability to describe a different handoff instead. Use a structured
question tool if available, otherwise ask in plain text. If the user's
arguments already identify one candidate unambiguously, pick it without
asking.

## 3. Continue

Read the chosen handoff fully. Load any skills its "Suggested skills" section
names. Then continue the work it describes, honoring the user's arguments as
additional focus if given.
