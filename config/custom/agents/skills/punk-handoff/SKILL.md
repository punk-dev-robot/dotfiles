---
name: punk-handoff
description: Compact the current conversation into a handoff document for another agent to pick up, then optionally continue immediately in a new Herdr pane.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

# Punk Handoff

## 1. Write the handoff document

Write a handoff document summarising the current conversation so a fresh agent
can continue the work.

Content rules:

- Start the document body with a metadata header (this is what `/punk-resume`
  shows in its picker):

  ```markdown
  ---
  date: <ISO 8601 timestamp>
  cwd: <absolute working directory>
  repo: <project slug, see below>
  branch: <git branch, or "-">
  goal: <one line — what the next session should do>
  ---
  ```

- Include a "Suggested skills" section naming which skills the next agent
  should load.
- Do not duplicate content already captured in other artifacts (specs, plans,
  ADRs, issues, commits, diffs). Reference them by path or URL instead.
- Redact any sensitive information: API keys, passwords, PII.
- If the user passed arguments, treat them as a description of what the next
  session will focus on and tailor the document accordingly.

## 2. Save location

- State dir: `${XDG_STATE_HOME:-$HOME/.local/state}` (works without XDG set,
  including macOS).
- Project slug: `basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"`.
  This collapses git worktrees to their parent repo name. If not in a git
  repo, use `basename "$PWD"`.
- Save to:
  `<state dir>/punk/handoffs/<slug>/<YYYY-MM-DDTHHMM>--<branch>.md`
  using local time for the timestamp
  (sanitize `/` in branch names to `-`). When not on a branch or not in a
  git repo, use the cwd basename in place of the branch so the filename is
  self-describing, e.g. `<YYYY-MM-DDTHHMM>--swapc.md`.
  Create the directory with `mkdir -p` first.

Never save into `/tmp` or the workspace.

## 3. Continue the work

**If `HERDR_ENV=1`, Herdr tools (`herdr_layout`, `herdr_agent`) are available,
and the user's arguments do not indicate the work continues later** (e.g.
"for tomorrow", "later", "picking this up next week"):

1. Get the current pane ID via `herdr_layout` action `current`.
2. Split a sibling pane (`pane_split` with `focus: true` so the user lands in
   the new pane) and start a new pi agent in it (`herdr_agent` action
   `start`).
3. Prompt the new agent with:

   > Read the handoff document at `<absolute path>`. Once you have read it
   > successfully, tell the user you will close the old pane `<pane ID>` in
   > 5 seconds unless they say anything, run `sleep 5` in bash, and — if no
   > user message arrived meanwhile — close it with `herdr_pane`. Any user
   > input at all counts as an objection to the close. Sessions are
   > preserved by the harness for resume, so closing is safe. Then continue
   > the work described in the handoff.

4. Do nothing else in this session — the new pane closes it after the 5s
   grace period, or the user keeps it.

**Otherwise** (not inside Herdr, Herdr tools unavailable, or user deferred):

Print the absolute path of the saved handoff prominently and tell the user:
start a fresh agent session and either run `/punk-resume` or ask the agent to
read that file and continue. Do not assume any specific agent CLI — keep the
instruction harness-agnostic.
