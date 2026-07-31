---
description: Five-axis code review (correctness, readability, architecture, security, performance) via the code-reviewer subagent
argument-hint: "[scope]"
---

Review the current changes across all five axes. Scope: ${@:-the staged changes, or the most recent commit if nothing is staged}.

Do not review the diff yourself — delegate to the `code-reviewer` subagent. It runs a different
model family on purpose: nobody reviews their own work.

1. Establish the exact scope first (`git diff --cached`, `git diff`, or `git show`), so the brief
   names concrete files and commits rather than "the recent work".
2. Launch one `code-reviewer` child with a self-contained brief: the scope, the intent of the
   change, any constraint it must respect, and the risk threshold if it is not the default.
   The child starts with a clean context and cannot see this chat.
3. Relay its report — five axes, findings graded blocker / should-fix / nit, each with
   `file:line` — and then act on the blockers.

The child reads and runs tests; it cannot edit. Any fix it recommends is implemented here or by
`impl` / `dev`, not by the code-reviewer.

For a full pre-launch gate with security and coverage passes, use `/ship` instead.
