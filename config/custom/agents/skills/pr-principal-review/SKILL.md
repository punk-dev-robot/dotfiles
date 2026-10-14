---
name: pr-principal-review
description: Principal-level review of a PR or branch — two reviewers on different models review independently, debate to consensus, a neutral arbiter writes the report.
argument-hint: "<PR number> | base=<git ref>  [rounds=<n>, default 1; 0 = no debate]"
disable-model-invocation: true
---

# PR principal review

You are the Lead and the **orchestrator**: you dispatch, relay result refs, and count
rounds. The reviewers and the arbiter do every reading of code. Each wait below ends your
turn; the delivered results wake you.

Agents (Herdsman definitions, dotter templates in `~/dotfiles/config/custom/pi/agent/agents/`):

| Side | Definition | Label |
|---|---|---|
| A | `reviewer` | `rev-a` |
| B | `reviewer-sol` (OpenAI model) | `rev-b` |
| Arbiter | `arbiter` | `arbiter` |

This replaces the piewf `pr-principal-review.js` workflow and the `/review`,
`/parallel-review`, `/review-loop` starters: `rounds=0` is a parallel review; a
single-reviewer pass needs no skill, delegate `reviewer` directly.

## 1. Resolve the target

Inputs: a PR number **or** `base=<ref>` (exactly one), and `rounds` (default 1).
Run from the repo checkout: agents inherit your cwd and read surrounding source there.

- **PR**: `gh pr view <n> --json number,title,url,baseRefName,headRefOid`. Compare
  `headRefOid` with `git rev-parse HEAD`; on mismatch, stop and ask the user to check out
  the PR head (`gh pr checkout <n>`). Save `gh pr diff <n>` to
  `.pi-herdsman/pr-review/PR-<n>.diff`.
  Report path: `reviews/PR-<n>-review-reviewer-vs-reviewer-sol.md`.
- **Branch**: save `git diff <base>...HEAD` to `.pi-herdsman/pr-review/branch-<base>.diff`
  (`<base>` with every character outside `[A-Za-z0-9._-]` replaced by `_`).
  Report path: `reviews/branch-review-vs-<base>-reviewer-vs-reviewer-sol.md`.

Done when the diff file exists and is non-empty, and `TARGET` (`PR #<n>` or
`the branch diff vs <base>`) and the report path are fixed.

## 2. Independent review

In one turn, `delegate_agent` side A and side B with the **review brief** below and
`files: [<diff file>]`. End the turn.

Done when both results have arrived. For each side record its latest **result ref** and
**session** (both come with the completion). If one arrives first, end the turn again.

## 3. Debate (up to `rounds` rounds)

For each round, in one turn, `continue_agent` each side's session with the **debate
brief** and `files: [<other side's latest result ref>]`. End the turn. When both
arrive, update each side's result ref and session.

Stop early when both final lines read `CONSENSUS: yes`.

**Retired reviewer.** Herdsman rejects `continue_agent` on a retired session (and a
retired result says so). Replace that side with a fresh `delegate_agent` of the same
definition and label, using the debate brief prefixed by
`Your previous position is in <own ref>; the other reviewer's is in <other ref>.` and
`files: [<own latest ref>, <other side's latest ref>, <diff file>]`. The new session
replaces the old one for later rounds. The round still counts.

A side that fails outright (not retired): delegate it fresh once with its last brief.
If it fails again, stop and report to the user with the refs you have.

Done when `rounds` rounds have run or consensus was reached; you hold one final result
ref per side.

## 4. Arbiter

`delegate_agent arbiter` with the **arbiter brief** and
`files: [<A final ref>, <B final ref>, <diff file>]`. End the turn.

## 5. Relay

Give the user: the arbiter's verdict and top 3 findings, the report path, the rounds run,
and whether consensus was reached. The arbiter's report is the deliverable: relay it
as written.

## Briefs

Fill `<…>` before sending.

**Review brief**

```text
Review <TARGET>. The change set is in the attached diff file; the repo is checked out at
cwd. Read surrounding source for context: judge every hunk against the code around it.

You are doing a principal-engineer review. Report ONLY high-priority findings:
- correctness bugs, data loss/corruption, broken invariants
- security issues, auth/trust-boundary gaps
- breaking API/contract/schema changes, unsafe migrations
- concurrency/race/idempotency hazards
- significant performance or cost regressions
- architectural violations with system-wide blast radius
Leave out style, naming, nits, minor test gaps and subjective preferences.

For each finding: severity (blocker/major), file:line, what breaks and why it matters,
concrete evidence from the actual code (quote it), and a suggested fix direction.
Verify each claim by reading the relevant source before reporting it.
Output markdown. End with a line: FINDINGS: <n>
```

**Debate brief**

```text
Another principal reviewer reviewed <TARGET> too; their latest position is in the
attached result. For each of their findings: AGREE (with refinement if any) or CONTEST
(contesting requires quoting code evidence, not opinion). For each of your own: MAINTAIN
or WITHDRAW, and say why. Add a new finding only if it is high-priority and evidenced.
Re-read source wherever the two of you disagree.

Output your full updated position as markdown. End with exactly one line:
CONSENSUS: yes   (nothing remains contested)
CONSENSUS: no    (contested items remain)
```

**Arbiter brief**

```text
Arbitrate the principal-level review of <TARGET>. Reviewer A (`reviewer`) final position:
<A ref>. Reviewer B (`reviewer-sol`) final position: <B ref>. The diff is attached; the
repo is checked out at cwd. Debate: <k> round(s), consensus <reached|not reached>.
Write the report to <report path>.
```
