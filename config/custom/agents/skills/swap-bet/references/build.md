# build

Turn ready tickets into verified, stacked PRs. Everything below is a default.

Reads `spec.md`, `tickets.md`, the ticket. Writes branches and PRs; PR links, scores
and `## Deploy order` into `tickets.md`.

**Hard rule:** `spec.md` not signed off (SKILL.md hard rule 1) → stop and say so.

## Dispatch

`swap-bet build <KEY>` lists the frontier (tickets whose Linear blockers are done **and**
whose spec decisions are not `OPEN`) and gives one launch line per ticket:
`/poteto-mode swap-bet build <KEY> <AGIT-n>`. Default (trial): the owner types it in a single
session; the pi-pstack-herdsman `poteto-mode` workflow then owns implementation dispatch
through its pstack role table, and the steps below are the ticket's defaults. The mode is
switched on by that extension command only (`disable-model-invocation`), so an agent hands
the line to a human or a Manager. Big bets, at the owner's call: one Manager-mode session,
a Lead per ticket; the Manager sends the same line into each Lead's pane via `herdr_agent`
prompt.

## Preflight

| Tool | Probe (read-only) |
|---|---|
| Linear MCP | `linear_get_issue` on the ticket |
| GitHub | `gh auth status` |
| gh-stack | `gh stack --help` exits 0 |
| run-local / verify | `gcloud auth print-access-token >/dev/null`, `docker info >/dev/null` (verify-window-shop's `scripts/doctor.sh` runs once the stack is up) |
| Logfire MCP | `logfire-swap_project_list` (when Verification asks for `--live`) |
| LaunchDarkly | `ldcli projects list --json` — only when the ticket creates a flag or runs an experiment (reading a flag in code needs none). Missing: `eget launchdarkly/ldcli --to ~/.local/bin` |
| Plannotator | `plannotator_inbox` tool listed, or `plannotator inbox --help` exits 0 |

## Steps (one ticket)

1. **Plan the stack before coding** with `gh-stack` (its `references/stack-design.md`): layers
   per repo in dependency order. Writing on one branch and splitting later is the failure
   mode to avoid.
   - **Across tickets**: a branch can sit in one stack only; stacking ticket B on ticket A's
     branch makes `gh stack submit` fail. Either B joins A's stack as more layers, or B is
     cut from `develop` with an explicit merge order. If `gh stack submit` rejects the
     cross-ticket base: plain `git push` + `gh pr edit --base`.
   - **Linear id from the start** in every branch name or PR title (shopmr runs a Linear
     check). A title-only fix doesn't re-trigger the check and a job re-run reuses the old
     title: close and reopen the PR, and tell the owner.
   - **Out-of-bet prerequisite** found mid-bet (a fix, a review finding outside the bet):
     its own ticket first, related to the bet ticket, before its branch exists, and a row in
     `tickets.md` under the slices (marked out-of-bet) so Deploy order can place it.
2. **Build layer by layer.** Repo `AGENTS.md` rules apply, with the owner's local overrides
   of the shopmr agent instructions.
3. **Verify end to end, locally**, across every service the slice touches, before UAT. E.g.
   shopmr `run-local --db uat` (read-only, no migrations) plus the local merchdash pointed at
   the local gateway. Skills: `verify-window-shop`
   (`~/dev/swapc/agentctx/shopmr/pi/skills/verify-window-shop`) for shopmr widget surfaces,
   `verify-merchdash` (`~/dev/swapc/merchdash/.pi/skills/verify-merchdash`) for merchdash
   work, both when the slice spans both. When `--live` is asked for, pull the traces through
   Logfire MCP and put a table in the PR body: Case · What the user got · Trace link.
4. **Open the stack ready for review** (`gh stack submit --open`; without `--open` new PRs
   are drafts). Draft only when the owner asks. PR bodies follow `cock-pr` (summary, evidence,
   merge danger) plus the verification table (CI posts the score as a sticky comment).
5. **Size for auto-approve.** Per layer PR, in shopmr (merchdash has no scorer):
   `node tools/pr-risk-score/score-pr.mjs --pr <n>` (`--pr` is required, `--base-sha` /
   `--head-sha` alone throw). Setup: `pnpm install --ignore-workspace` in
   `tools/pr-risk-score`. Aim ≤ 15: the approver bot approves at or under
   `PR_SCORE_APPROVE_THRESHOLD`, capped at 15. Over → split the layer, or route it to a
   human. Lower the score honestly — tests, additive changes, real evidence in the PR body;
   never pad evidence.
6. **`no-auto-approve` only when the owner asks.** Auto-approve is not auto-merge: a person
   still merges, and the scorer already refuses PRs over threshold. When asked: the label,
   one line "why human" in the PR body, a requested reviewer.
7. **Review per stack**, from the stack's top branch: `/ponytail-review the branch vs develop` first, then
   one `pr-panel-review base=develop` run (whole stack). Fix the findings; that one run is
   the review.
8. **Watch** the stack's top PR with pi-prs: `/pr watch --babysit`, a slash command typed
   from its branch (one PR per session); it delivers review and CI feedback as it arrives.
   The session that raised the stack types it: the owner in the default single-session
   `/poteto-mode` path, the Lead when running as Lead (a Manager sends it to a Lead's pane via
   `herdr_agent`). Lower layers: watch each as it becomes the top. Act on the feedback with
   shopmr `swap-autopilot` (`.cursor/skills/swap-autopilot`); its conflict step merges
   `develop`, but in a stack sync via `gh stack rebase` instead, so the two do not fight over
   topology.
9. Record PR links and scores in the ticket's `tickets.md` row, and the strict cross-repo
   `## Deploy order`. Rough edges go to `~/dev/swapc/specs/_skill-feedback.md`.

Done when every layer PR is open with verification evidence, a score (where a scorer
exists), a principal review and a watch, and `tickets.md` has the deploy order. Commit the spec dir.
