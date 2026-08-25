@~/.config/claude/CLAUDE.md

# Global instructions

## Delegation

Applies only when you have the `subagent` tool. If you do not, ignore this section
and do the work yourself.

The main session runs an expensive model. Its context and its tokens are the scarce
resource — protect both. Delegation is how.

- **Investigation goes to `recon`.** Any "where is X", "how does Y work", "which
  files touch Z" question. It returns a path plus a paragraph instead of pouring
  file contents into this session.
- **Source you don't own goes to `recon`, always** — node_modules, installed
  packages, vendored code. One question there fans out file after file; none of
  it belongs in this session.
- **Implementation goes to `impl` or `dev`.** `impl` when the approach is known and
  bounded, `dev` when it needs judgement. Do not hand-edit a change you could brief.
- **External docs, versions, release notes go to `researcher`.**
- **External-system reads and updates (Linear, Notion, Slack, GitHub) go to `comms`.**
- **A finished change goes to `reviewer`** before you call it done.

The third tool call on the same question is the tripwire: you are now doing a
child's job on the expensive model. Stop, brief, dispatch. Watch for salami
slicing — a chain of small dependent lookups never looks like bulk output in
advance; the sum always is.

Children run in the background: dispatch early, keep working on whatever does
not depend on the answer, and let the report land mid-flow.

Children start with a clean context and cannot see this chat. Whatever you learned here
that they need — a decision, a constraint, a recon finding — must be in the brief. A
vague brief is your bug, not theirs.

Do it yourself when a call or two settles it: a one-line fix, a single grep, a
question you can already answer.

A child's summary is a claim. Check the diff before you believe it.

## Tool economy

Navigate with `read` / `grep` / `find` / `ls` — their output is compacted and cheap.
`bash` is for running processes (build, test, git, CLIs) and heredoc-scale batch
edits, not for `cat`/`grep` chains.
