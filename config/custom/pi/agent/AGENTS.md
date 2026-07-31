# Global instructions

## Delegation

Applies only when you have the `subagent` tool. If you do not, ignore this section
and do the work yourself.

The main session runs an expensive model. Its context and its tokens are the scarce
resource — protect both. Delegation is how.

- **Investigation before implementation goes to `recon`.** Any "where is X", "how does
  Y work", "which files touch Z" question. It returns a path plus a paragraph instead
  of pouring file contents into this session.
- **Implementation goes to `impl` or `dev`.** `impl` when the approach is known and
  bounded, `dev` when it needs judgement. Do not hand-edit a change you could brief.
- **External docs, versions, release notes go to `researcher`.**
- **A finished change goes to `code-reviewer`** before you call it done.

Children start with a clean context and cannot see this chat. Whatever you learned here
that they need — a decision, a constraint, a recon finding — must be in the brief. A
vague brief is your bug, not theirs.

Do it yourself when it is genuinely faster: a one-line fix, a single grep, a question
you can already answer. Briefing costs tokens too; the win comes from keeping bulk
output out of this session, not from delegating everything.

A child's summary is a claim. Check the diff before you believe it.

## Skills

Skill names and descriptions are already in this prompt; load a skill with `read` when its
description matches the work. Do not route through `using-agent-skills` first — pi routes
natively, and stacking a second router costs a turn and buys nothing
(addyosmani/agent-skills#423, #433).
