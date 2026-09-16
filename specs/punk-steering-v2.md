# punk-steering v2 — `guard` rules: reject, block, telemetry

Extends `specs/punk-steering-v1.md` (KUB-164). Fills the reserved slots D2 (`block` = terminate
+ flag, never deny-and-retry) and D3 (`rewrite`, still deferred). Motivation and data:
`docs/otel_retro/2026-09-16-logfire-review.md` §"Proposal" — prose does not move behaviour
(bash-nav 45–75% in full-toolset sessions vs 4% in restricted ones); the model routes around
single hooks with pipes, `cd`, `python -c`, heredocs.

## Problem

~600 of 1662 bash calls in 14d were navigation/editing with a dedicated tool available
(`grep`/`cat`/`ls`/`head`/`find`/`sed -n`, `sed -i`, inline `python3`), ~85 of them reading
installed-package source that steering routes to `recon`. Steering rules only *advise*; v1 has
no `tool_call` hook. Nothing measures whether a rule was followed.

## Solution

New rule `kind: guard`: a `tool_call` inspector with deny/allow regexes over a **normalised
command**, a per-session strike counter, and three outcomes — `reject` (strikes 1–2), `block`
(strike 3: session ends via the `punk-handoff` skill), always with OTel telemetry through
`pi-otel:log`. Level dial: `observe` logs only; `advise` enforces.

## User stories

1. As the owner, I want `cat`/`grep`/`ls`/`sed -n` in bash rejected with a one-line pointer to
   the right tool, so the model switches tools instead of retrying bash.
2. As the owner, I want the rejection to state the strike budget up front ("strike 1 of 3; at 3
   this session is blocked"), so the model does not treat rejections as free.
3. As the owner, I want pipes, `;`, `&&`, `$( )`, and a leading `cd X &&` to not hide the
   denied command.
4. As the owner, I want inline interpreters (`python3 -c`, `python3 - <<EOF`, `node -e`,
   `perl -e/-pi`, `ruby -e`) treated as edits/navigation in disguise and rejected the same way;
   `ctx_execute` remains the sanctioned scripting route.
5. As the owner, I want `git …` and an explicit `# allow: <why>` comment to pass, the latter
   logged as an override so I can see abuse.
6. As the owner, I want the 3rd strike to end the session's normal work: the model is told to
   invoke the `punk-handoff` skill (write the handoff, spawn the next pane) and stop; no other
   tools remain available.
7. As the owner, I want `read` of installed-package / other-repo paths rejected in the main
   session with "dispatch `recon`".
8. As the owner, I want every verdict in Logfire (`pi.steering.violation | override | block |
   applied`) keyed by `pi.session.id`, so the next retro answers "is steering followed" from data.
9. As the owner, I want `observe` to run the full pipeline without rejecting, so I can measure
   false positives for a day before flipping to `advise`.
10. As the owner, I want `/steering` to show strikes this session and the last verdicts.

## Rule shape

```yaml
---
kind: guard
when: { tools: [bash] }         # v1 gate — rule active only when bash is in the toolset
tool: bash                       # tool_call to inspect (bash | read | any registered tool)
field: command                   # input field holding the text to test (default: command for bash, path for read)
allow:                           # tested first, per segment; any match = pass
  - '^git\b'
  - '#\s*allow:'                 # → verdict override, logged, not counted
deny:                            # tested per segment; first match = violation
  - '^(grep|rg|cat|head|tail|ls|find|wc|tree)\b'
  - '^sed\s+-n\b'
  - '^(sed\s+-i|perl\s+-p?i)\b'
  - '^(python[0-9.]*|node|perl|ruby)\s+(-c|-e|-)\b'
  - '^python[0-9.]*\s+\S+\.py\b'
  - '^cd\s+(\$PWD|\$\{PWD\}|\.|<cwd>)(\s|$)'
strikes: 3                       # per session, shared across all guard rules
---
Bash is for processes. Navigate with `read` (start/end for ranges), `grep`, `find`, `ls`.
Edit with `edit`. Scripts go through `ctx_execute`. Source outside this repo (node_modules,
site-packages, ~/.config) → dispatch `recon`.
```

Body = the redirect text appended to every rejection. `<cwd>` in a pattern is substituted with
the session cwd (regex-escaped) at load.

## Implementation decisions

**Normalisation** (pure, resolver): trim; strip one leading `cd <path> (&&|;)`; split into
segments on `|`, `||`, `;`, `&&`, newline, and `$( … )` / backtick bodies (inner text becomes
its own segment); trim each; drop empty. Heredoc bodies (`<<EOF … EOF`) are **not** split —
only the command line before `<<` is a segment (so `cat <<EOF > file` is denied as `cat`,
which is intended: heredoc writes go through `write`). Quoted strings are not parsed; a denied
head inside quotes is a false positive we accept and measure in `observe`.

**Verdict** (pure): `guard(rule, input, cwd) → { verdict: pass | override | violation, segment,
pattern }`. Allow checked before deny **per segment**. **Pipe filters are not navigation:**
`grep|head|tail|wc|sort|uniq|cut|jq|awk` as a *non-first* pipe segment (`pnpm test | tail -15`,
`git log | grep x`) pass — they trim process output, which is the sanctioned use of bash. The
same heads as the *first* segment of a pipeline or a `;`/`&&` chain (input is a file) are
violations. `cat`/`ls`/`find`/`sed -n` are violations in any position (`cat f | python3 -`
still fails on `cat`). Override = any segment matches an allow pattern flagged `override: true`
(the `# allow:` one). Fixtures: `test/fixtures/guard-bash.jsonl` (50 real Logfire commands,
hand-labelled).

**Strike counter** (adapter): one integer per session, across all guard rules, reset on
`session_start`. Overrides do not count. In `observe`, the counter still increments (so the
log shows what *would* have blocked) but nothing is rejected.

**Reject** (strikes 1–2, level ≥ advise): `tool_call` returns `{ block: true, reason }` with
`reason = "steering/<rule> — strike N of 3; at 3 this session is blocked and must hand off.
Denied: <segment>. <body>"`. No retry, no rewrite.

**Block** (strike 3, level ≥ advise): (1) `tool_call` returns block with reason
`"steering/<rule> — strike 3 of 3. Session blocked. Invoke the punk-handoff skill now (read
~/.agents/skills/punk-handoff/SKILL.md and follow it; argument: 'blocked by steering/<rule>
after 3 violations — continue the task in a fresh session'), then stop."`; (2)
`pi.setActiveTools(HANDOFF_TOOLS)` where `HANDOFF_TOOLS = [read, write, herdr_layout,
herdr_agent, herdr_pane]` — what the skill needs to write the file and spawn the next pane,
nothing else; (3) `ctx.ui.notify(error)`; (4) telemetry. The session stays open; the owner
resumes via the spawned pane / `punk-resume`. No `ctx.abort()` — the model needs the turn to
write the handoff.

**Subagents** (owner amendment): the block step is main-session only. A piewf role must never be
blocked or told to hand off — the parent reruns it, and a handoff would strand the brief. Detect
a subagent at `tool_call` time by the cheapest available signal: the toolset lacks
`herdr_layout`/`herdr_agent` (`pi.getActiveTools()`), or the first user prompt starts with
`Workflow: ` (piewf prefix). In a subagent: strikes still count and log
(`pi.steering.violation` with `enforced` and `pi.steering.subagent: true`), `advise` rejects on
*every* violation with no cap, and there is no `pi.steering.block`, no `pi.setActiveTools`, and no
handoff wording in the reason (`"steering/<rule> — strike N. Denied: …"`).

**Telemetry**: `pi.events.emit("pi-otel:log", { eventName, severity, body, attributes })`,
`pi.session.id` = session file basename (same helper as `context-events.ts`). Events:
`pi.steering.applied` once per session (`rules`, `level`, `guards`), `pi.steering.violation`
(`rule`, `tool`, `segment` ≤200 chars, `pattern`, `strike`, `enforced: bool`),
`pi.steering.override` (`rule`, `segment`), `pi.steering.block` (`rule`, `strikes`). No-op when
pi-otel is absent.

**Levels**: `off` → guards not evaluated. `observe` → evaluate, count, log, never block.
`advise` → reject + block. `rewrite` → as advise (D3 still deferred; first rewrite candidates
come from `pi.steering.violation` shapes after a week).

**Second rule** `read-outside-repo.md`: `tool: read`, `field: path`, deny
`(node_modules|site-packages|\.local/share|/tmp)/`, body "dispatch `recon`". Same counter.
Precondition: recon's own sandbox must be able to read those paths (ctx_execute_file root) —
separate ticket; until fixed this rule ships at `level: observe` per-rule.

**`/steering`** gains: `strikes: N/3`, last 5 verdicts.

**Architecture**: resolver gets `parseGuard`, `normalise`, `guard` (pure, table-tested).
Adapter gets the `tool_call` handler, counter, block sequence, telemetry helper. No new deps.

## Testing

`resolver.test.ts`: fixtures = top ~150 distinct bash commands from Logfire (14d), each
labelled pass/violation/override by hand (`test/fixtures/guard-bash.jsonl`); table test on
`normalise` + `guard`. Key cases: `pnpm jest | tail -15` (pass, pipe filter), `git log | head`
(pass), `head -20 file.md` (violation), `grep -rn x dir` (violation), `cd /x && for f in *; do
cat $f; done` (violation on `cat`), `D=/x; sed -n 1,5p $D/f` (violation — leading `VAR=…;`
assignment is a segment that passes, `sed -n` is the next), `python3 - <<EOF` (violation),
`cat f | python3 -` (violation), `grep x f # allow: why` (override), `cd $PWD && grep x f`
(two violations, **one** strike per call). Adapter: one pi-level test for counter →
reject → block → tools reduced.

## Rollout

Day 0: guards log only. Shipped as per-rule `level: observe` on both guard rules, **not** by
flipping `punk-steering.json` (which stays `advise` — lowering it globally would degrade every v1
briefing/precondition). Day-1 enablement = delete the `level: observe` line in the rule file.
Note: the strike counter is one integer per session shared by all guard rules (spec above), so
`strikes: 3` is a session budget, not a per-rule one. Day 1: query
`pi.steering.violation` for false positives, adjust patterns, flip to `advise`. Ledger entry
E5 in `docs/otel_retro/2026-09-16-experiments-ledger.md`: baseline = bash-nav share 45–75%
(main models), expect <10% within a week and `subagents_run` per session up.

## Out of scope

`rewrite` execution (D3). Guarding `ctx_execute` contents (watch its volume in telemetry
first). Guarding subagent sessions (they already have restricted toolsets). Rules in project
`.pi/steering` for guards (global only in v2 — a project must not weaken a guard).
