# Agentic workflow review — Logfire data

Session 2026-09-16. Window: 2026-09-03 → 2026-09-16 (14d, Logfire max). Service `pi`.
Purpose: observations + hypotheses feeding ticket creation at end of session. Not fixing here.

## What jumps out (TL;DR)

1. **Real spend is $582/14d (~$42/day), not $1181** — `pi.cost.usd` is double-counted by legacy `pi.llm_request` spans. Fable = 84%. Main session = $472; all subagents ≈ $55.
2. **Cost ≈ turns × context.** Cache hit 96%, output ~500 tok/turn, 92% of turns are tool turns. Only levers: fewer turns, smaller context, cheaper model.
3. **Preamble is ~60k tokens/call and it is tool schemas, not prose.** Steering+AGENTS = 3.3k tok, skill catalog = 4.6k tok, the rest (~35–40k) is ~80 tool definitions. Subagents with restricted tools start at 16k. Direct saving from halving is modest ($20–40/14d); indirect win is headroom.
4. **Tool output into context ≈ 2.2M tok/14d; `read` 33%, `bash` 26%.** (Corrected: first cut summed `pi.tool.output` incl. `details`, which pi does not send to the model.) `read` hashline JSON = 1.94× raw file → ~370k tok/14d avoidable; `edit` returns 49 tok (fine); `write` echo 791 tok/call = 28k total (minor). The real growth engine is *who* reads: main session does the `read`/`bash` navigation that scouts should.
5. **5 sessions = 39% of spend**, peaks 265–330k, zero compactions observed. KUB-149 addresses this; mac was not deployed until 09-16 21:30Z, so post-change data is omarchy-only so far (0 sessions >200k there).
6. **Steering text does not move behaviour**: bash = 43% of tool calls, ~500 of them navigation (`grep`/`cat`/`ls`/`sed`), 987 prefixed with `cd … &&` (165 to the cwd itself). repowise 10 calls, cymbal 0, readSeek_def/refs 3, `subagents_run` 20 in 14d. Installed-package source read from the main session 50×.
7. **Skills: 21 organic loads across ~315 sessions** (65 installed, tessl ~40 → 8 loads). Catalog cost is small (4.6k tok) but the value is near zero.
8. **Telemetry self-harm**: ~200k `Request timed out` exporter diag records (2× all real spans); tool output stored 3× per span; no role attribution (label ≠ role); no compaction/OM/handoff events (fixed this session: `context-events.ts`).
9. **Anomalies**: one gpt-6-astra call = $13.85 for 195 output tokens (841k uncached input, cwd `/tmp`); `ctx_execute_file` 46% error rate (sandbox root); `herdr_pane` 37% error rate (JSON output mismatch).

Priority order for tickets: (6) enforcement via punk-steering v2 (guard + block + telemetry) → (4) `read` at 1× raw (drop readSeek `read` override or pi-better-read-edit) → (8) telemetry hygiene → (3) tool-schema pruning → (5) verify KUB-149 on mac → model routing.
## Baseline (14d)

| metric | value |
|---|---|
| sessions (`pi.session.id`) | 315 |
| chat calls | 3238 |
| cost, `chat *` spans only | **$582** (~$42/day) — `$1181` if summing all `pi.cost.usd`, double-counted by legacy `pi.llm_request` (see O2) |
| cache read tokens | 366M (chat spans) |
| cache write tokens (`gen_ai.usage.cache_write_input_tokens`) | 18M |
| uncached input | 0.85M — almost all gpt-6-astra |
| output tokens | 1.74M |
| cache hit rate | ~96% — caching is not the problem |

### Cost per model

| model | calls | sessions | cost | $/call | avg ctx | tool turns | avg out tok |
|---|---|---|---|---|---|---|---|
| claude-fable-5 | 1098 | 29 | $300 | 0.27 | 125k | 93% | 570 |
| claude-fable-5-1 | 1099 | 25 | $191 | 0.17 | 133k | 91% | 460 |
| claude-opus-5 | 519 | 14 | $56 | 0.11 | 101k | 97% | 613 |
| claude-sonnet-5 | 485 | 35 | $18 | 0.04 | 58k | 97% | 565 |
| gpt-6-astra | 21 | 1 | $17 | 0.81 | — | | zero caching; one call = $13.85 for 195 out tokens (cwd `/tmp`) |
| claude-haiku-4-5 | 17 | 6 | $0.87 | | | | |

Fable = 84% of spend. **Cost ≈ calls × context size.** Every lever is one of: fewer turns, smaller context, cheaper model.

### Cost per role (piewf `Agent:` prefix)

main: 49 sessions, 2144 calls, **$472** ($9.63/session). All subagents combined ≈ $55. Unresolved: 23 sessions / $57.
**Caveat:** `Agent:` carries the free-text *label*, not the role → role-level attribution impossible today (O4).

### Session shape (top by cost)

| started | model | cwd | calls | cost | peak ctx | start ctx |
|---|---|---|---|---|---|---|
| 09-10 10:12 | fable-5 | swapc | 231 | $75.59 | 330k | 58k |
| 09-11 13:48 | fable-5 | dotfiles (mac) | 151 | $47.51 | 265k | 60k |
| 09-16 07:49 | fable-5-1 | swapc/shopai | 243 | $39.03 | 297k | — |
| 09-16 03:18 | fable-5-1 | swapc/shopmr | 156 | $36.69 | 297k | — |
| 09-16 14:29 | fable-5-1 | dotfiles | 53 | $29.65 | 179k | 61k |

**Start context = 56–69k tokens** before the first user message (system prompt + tool schemas + steering + skill list + AGENTS.md). At avg ctx ~130k that preamble is ~half of every call's cache read. Top 5 sessions = $228 = 39% of spend; peaks at 265–330k with no compaction.

## Observations

### O1 — Telemetry self-noise: ~200k OTel exporter error logs
`Request timed out` / `PeriodicExportingMetricReader: metrics export failed` from pi-otel
exporter. ~196k records 09-12 → 09-16, now the dominant record type (2× all real spans).
Two install paths seen: `pi/agent/git/.../pi-otel/node_modules` and `pi/agent/npm/node_modules`.
- Impact: query noise, ingestion volume, possible lost spans (if export fails, data gaps).
- Hypothesis: exporter timeout too low or endpoint slow; metrics export retried every interval.
- Todo: check whether span exports also drop (session count vs `pi.session.start` = 396 vs 315 sids).

### O2 — Two overlapping span schemas
Legacy `pi.tool.*`, `pi.llm_request`, `pi.interaction` (09-11 → 09-16) coexist with genai
`execute_tool *`, `chat *`, `pi.turn`. Double-count risk in any aggregate; need to pick one.

### O3 — Tool output stored 3× per span
`execute_tool` spans carry the full output in `gen_ai.tool.call.result`, `pi.tool.output`, and `details`. A 76-line `read` = ~30KB span. Ingestion cost + slow queries. Query rule: never `SELECT attributes` raw.

### O4 — Role attribution impossible
piewf injects `Workflow: <name>\nAgent: <label>`; label is free text (`ps-plan-html`, `agip257-final-review`). Role (`recon`/`impl`/…) is never recorded. Need a `pi.agent.role` attribute or `Role:` line in the prefix.

### O5 — `bash` is 43% of all tool calls; ~60% of them are `cd … && …`
1650 bash calls / 64 sessions. `cd X && <cmd>` = 987. After the `cd`: grep 194, git 193, sed 120, cat 44, ls 27, python3 49. Plus bare `grep` 56, `cat` 39, `ls` 49, `sed` 21.
- **Navigation via bash ≈ 500 calls** (grep/cat/ls/head/find) despite steering "bash is for processes". `sed` 141 → edits bypassing `edit`.
- `cd` targets: 494 elsewhere / 329 subdir of cwd / **165 identical to cwd (pure habit)**. "Elsewhere" = sibling repos in the `swapc` workspace (209; multi-repo work from a member-repo cwd, `multi-repo-ticket` skill loaded 1×), plus **installed-package source read from the main session** (`uv/tools/repowise/site-packages` 38, `@plannotator` node_modules 12) — steering says that goes to `recon`, always.
- bash avg 10.5s, max 1680s; 74 errors.

### O6 — Skills barely used organically
50 distinct SKILL.md read in 14d, but one bulk-recon session read 30+. Excluding bulk sessions: 16 skills, **1–2 loads each, 21 loads total across ~315 sessions**. tessl skills (~40 installed): 8 organic loads. Yet every skill's description sits in the system prompt of every call (see preamble recon).

### O7 — Steering-recommended tools mostly unused
| tool | calls (14d) | steering says |
|---|---|---|
| repowise_* | 10 | "Repowise FIRST for concept/history/risk" |
| readSeek_grep | 84 | "prefer over grep" — grep 132 |
| readSeek_def / refs / search | 2 / 1 / 0 | |
| cymbal_impact / changed | 0 / 0 | "before refactors or PRs" |
| subagents_run | 20 (recon 12, impl 3, comms 2, researcher 2, dev 1) in 12 sessions | "third tool call is the tripwire" |
| ctx_execute / ctx_batch_execute | 281 / 49 | used, but ctx_execute_file 13/28 errors (`File access blocked` outside project root) |
| ask_advisor | 30 in 27 sessions | ~1/session, ok |
| herdr_pane | 63, 23 errors (37%) | `Expected JSON output from herdr pane …` — CLI output format mismatch |

### O8 — Tool output size (model-facing `content` only; `details` is UI-only)
| tool | calls | content ktok | avg tok | p95 tok | input ktok |
|---|---|---|---|---|---|
| read | 357 | **737** | 2234 | 5954 | 8 |
| bash | 1662 | **585** | 353 | 1437 | 153 |
| ctx_batch_execute | 49 | 225 | 4598 | 8905 | 15 |
| ctx_execute | 282 | 215 | 766 | 2342 | 49 |
| mcp | 73 | 87 | 1186 | 6535 | 6 |
| grep | 140 | 86 | 612 | 2025 | 4 |
| readSeek_grep | 111 | 28 | 253 | 1129 | 3 |
| write | 70 | 28 | 791 | 1762 | 148 |
| edit | 188 | ~9 | 49 | — | 51 |
- Total ≈ 2.2M tok/14d. `read` (readSeek digest, JSON hashlines) measured 1.94× raw on a real file → ~370k tok avoidable. Built-in pi `read` is 1×; `@pi-kaush/pi-better-read-edit` 1.07×. Anchors can be minted from `readSeek_grep`/`_def` on demand. See `2026-09-16-research-file-tools.md`.
- `edit` is already minimal (one summary line). `write` echo is waste but small.
- First version of this table (superseded) claimed read/write/edit = 64% and write 43k chars — that was span storage size (O3), not model context. Lesson: always measure `pi.tool.output->>'content'`.

### O9 — LLM errors
116 `operation was aborted` (user interrupts) over 3238 calls = 3.6%. 2× `400 … Claude Code 2.1.160` invalid_request. Not a cost issue; wasted partial output unknown.

### O11 — KUB-149 (compaction/OM ratio 0.18, context-nudge @150k) — early read
Commit 6a97826 landed 2026-09-15 23:35Z. Fable sessions after:
| host | sessions | p50 peak | max peak | >200k | cost |
|---|---|---|---|---|---|
| omarchy | 24 | 76k | 200k | 0 | $110 |
| mac | 8 | 129k | **298k** | **3** | $102 |
| mac before (13d) | 23 | 114k | 330k | 3 | $281 |

Mac still blows past 200k within a day of the change → either mac checkout not pulled, or OM compaction doesn't fire there. **Verify on mac before judging KUB-149.**
**Instrumentation gap (partly closed this session):** there were zero records for compaction, OM, nudge, handoff. Added `config/custom/pi/agent/extensions/context-events.ts` (+ nudge event in `context-nudge.ts`) → `pi.context.{compaction,compaction_failed,om.*,nudge}` log records via `pi-otel:log`, keyed by `pi.session.id`. Verified live. Ledger: `docs/otel_retro/2026-09-16-experiments-ledger.md` (E1 = KUB-149, E2 = this).

**Still missing (tickets):**
- Handoff link: `/punk-handoff` is a skill, leaves no event; need `pi.context.handoff` with `from_session` → `to_session` to measure "did the handoff replace a runaway session".
- Role attribution (O4): `pi.agent.role` attribute from piewf/subagents_run.
- Exporter noise (O1): ~200k `Request timed out` diag records; investigate metrics exporter timeout / disable metrics signal (metrics are role-blind anyway per `logfire-pi-role-attribution.md`).
- Tool output stored 3× (O3): `captureContent: "full"` — consider dropping `details` / one copy.
- Logfire quirk to document: `event.name` → `span_name`, not an attribute.

## Hypotheses (to test)

- H0 (KUB-149): with OM ratio 0.18, no fable session should exceed ~200k peak. Falsified on mac so far; check deployment first. Success metric: `count(peak>200k)=0` and p50 cost/session down vs $9.63.

### O10 — Preamble composition (first-call context per session)
| session type | first-call ctx (p50) |
|---|---|
| main fable-5/5-1 | **56–64k** |
| opus main | 33–35k (fewer tools? check) |
| sonnet subagents (restricted tools) | **16–19k** |

Measured text: steering 9 files = 8.9k chars, AGENTS.md×2 + RULES = 4.6k → **~3.3k tokens total, negligible**. Skill catalog: 65 SKILL.md, descriptions 18.4k chars ≈ **4.6k tokens**. Remainder **~35–40k tokens = tool schemas** (~80 tools: repowise×6 verbose, ctx_*×9, workflow×7, herdr×4, subagents×5, mcp proxies×5, readSeek×6, plannotator, web/fetch, advisor). Subagent 16k vs main 60k confirms tools are the lever, not prose. Recon file: `.scratch/recon-context-budget.md` (gitignored; estimates, sandbox blocked outside repo).

- H1: Cutting preamble 60k → ~30k (lazy-load tool groups: workflow, herdr, plannotator, ctx_index/purge/upgrade, repowise → skill-gated or MCP-search) saves ~30k × 2200 fable calls = **66M cache-read tokens/14d ≈ $20–40 direct** — modest. Bigger indirect win: lower peak ctx and fewer truncation/compaction events. Prose trimming is not worth effort.
- H2: Suppressing `write` echo and shrinking `edit`/`read` envelopes cuts ~8MB/14d (~2M tokens) of context growth → fewer 250k+ sessions, less cache-read per subsequent call (compounding).
- H3: Skill descriptions in prompt cost more than skill usage delivers; move rarely-used skills behind an index/lookup tool.
- H4: `cd &&` prefix and bash navigation are behavioural; steering text is not enough — hooks/blocking (cupcake policy?) would change data.
- H5: Main-session model downgrade (fable → opus/sonnet) for dotfiles-type work saves 2–5× per session; test on a category of sessions.

## Open questions


## Deep dive: tool usage & steering (points 4 and 6)

Data caveat: exports have gaps (09-08→09-10, 09-12→09-15 near-empty); 09-11 and 09-16 hold
~70% of tool calls. punk-steering v1 (KUB-164) landed 2026-09-16 18:19Z, omarchy only → 13 of
14 days are `APPEND_SYSTEM.md`-era. Mac deployed ~21:30Z.

### Tool leaderboard (14d, `execute_tool` spans)

| tool | calls | sessions | err% | p50 s | p95 s | wall min | ctx injected (ktok) | avg tok/call |
|---|---|---|---|---|---|---|---|---|
| bash | 1662 | 66 | 4 | 0.3 | 27 | 288 | 636 | 383 |
| read | 357 | 72 | 0 | 0.0 | 0.5 | 1 | **1820** | **5098** |
| ctx_execute | 282 | 26 | 2 | 0.2 | 40 | 90 | 217 | 772 |
| edit | 188 | 35 | 1 | 0.1 | 0.7 | 1 | 633 | 3365 |
| grep | 140 | 32 | 0 | 0.0 | 1.7 | 1 | 89 | 634 |
| readSeek_grep | 111 | 31 | 3 | 0.1 | 0.3 | 0 | 72 | 652 |
| mcp | 73 | 15 | 3 | 0.4 | 5.1 | 1 | 127 | 1745 |
| write | 70 | 46 | 4 | 0.1 | 0.2 | 0 | 769 | **10981** |
| herdr_pane | 63 | 11 | **37** | 0.0 | 148 | 24 | 9 | 150 |
| ls / find | 58 / 55 | 13 / 18 | 2 / 0 | 0 | 0.1 | 0 | 7 / 21 | 119 / 383 |
| ctx_batch_execute | 49 | 20 | 2 | 1.0 | 14 | 6 | 226 | 4605 |
| ask_user_question | 44 | 22 | 5 | 127 | 644 | 158 (human) | 10 | 222 |
| ctx_execute_file | 43 | 16 | **37** | 0.1 | 0.2 | 0 | 16 | 377 |
| ask_advisor | 30 | 27 | 0 | 35 | 50 | 18 | 46 | 1522 |
| plannotator_submit_plan | 25 | 12 | 0 | 141 | 1044 | 115 (human) | 5 | 210 |
| subagents_run | 22 | 14 | 0 | 0.1 | 0.1 | 0 | 1 | 46 |
| repowise_search_codebase | 9 | 7 | 0 | 3.7 | 6.6 | 1 | 15 | 1622 |

- **Most popular:** bash (43%). **Most expensive (context, model-facing):** read 737k tok, bash 585k,
  ctx_batch 225k, ctx_execute 215k → ~2.2M total. (Table above shows storage size incl. `details`; see O8.)
- **Longest wall time:** bash 288 min (p95 27s; `for` loops 70 min, `sleep` 43 min, `mkdir`
  20 min — suspicious, likely `mkdir && long-cmd`), ctx_execute 90 min, then human waits.
- **Broken:** herdr_pane 37% err (`Expected JSON output from herdr pane …`), ctx_execute_file 37%
  err (`File access blocked … outside the project root` — sandbox root = cwd, so any read of
  installed packages / other repo fails; the model then falls back to bash `cat`/`grep`).
- `write`/`edit` are cheap model-facing (791 / 49 tok); the 11k/3.4k in the table is span storage.

### Bash command leaderboard (14d, `cd …&&` prefix stripped)

| head | n | err% | p50 s | wall min | avg tok out | note |
|---|---|---|---|---|---|---|
| grep | 250 | 3 | 0.2 | 4 | 333 | 185 repo, **52 installed pkgs**, 10 ~/.config |
| git | 244 | 3 | 0.2 | 12 | 495 | legit |
| sed | 142 | 1 | 0.1 | 10 | 532 | **129 = `sed -n 'a,bp'` range print** (= `read --start/--end`), 13 `sed -i` |
| gh | 96 | 5 | 1.2 | 4 | 369 | legit |
| cat | 83 | 5 | 0.2 | 4 | 663 | 45 repo, 22 /tmp, 10 ~/.config |
| ls | 78 | 4 | 0.2 | 1 | 280 | 17 installed pkgs |
| python3 | 59 | 3 | 0.3 | 3 | 144 | inline scripts (ctx_execute exists) |
| pnpm | 41 | 2 | 7.3 | 9 | 326 | legit |
| for | 40 | 8 | 0.3 | **70** | 845 | loops over files → recon job |
| echo / herdr / sleep / ssh | 39 / 38 / 29 / 27 | | | 43 (sleep) | | |
| find / head / wc | 15 / 16 / 7 | | | | | |

Navigation-via-bash (grep+cat+ls+head+find+sed-print+wc) ≈ **600 calls = 36% of bash, 15% of
all tool calls**. Every one had a dedicated tool available (`grep`, `read`, `ls`, `find`,
`readSeek_grep`); ~85 targeted installed-package source that steering routes to `recon`.

### Who does it — tool availability beats prose

bash_share = bash-nav-edit / (bash-nav-edit + proper nav/edit tools):

| model (session) | host | sessions | bash share |
|---|---|---|---|
| **sonnet** (subagent, restricted tools) | omarchy | 10 | **4%** |
| sonnet | mac | 28 | 18% |
| opus | omarchy | 8 | 38% |
| fable-5-1 | omarchy | 16 | 45% |
| fable-5 | mac | 23 | 50% |
| opus | mac | 7 | 53% |
| fable-5 | omarchy | 6 | 74% |
| fable-5-1 | mac | 8 | 75% |

Subagents run with `tools:` allow-lists (recon has no bash) → near-zero bash nav, same
steering text. Main session with full toolset → 45–75%. **The lever is what is in the toolset
and what a tool refuses, not what the prompt says.** Fable is also the worst offender and the
most expensive model per call.

### Did punk-steering v1 change anything (first 3h, omarchy, main models)

| period | sessions | calls | bash | bash nav/edit | proper tools | delegated | repowise |
|---|---|---|---|---|---|---|---|
| before (09-16 00:00→18:19Z) | 16 | 724 | 318 | 96 | 119 | 3 | 0 |
| after (18:19→22:00Z) | 15 | 259 | 135 | 54 | 39 | 2 | 0 |

bash-nav share 45% → **58%**. Too early and too small to conclude, but no visible step change.
Add to ledger as E3 with proper measure window.

### Findings → ticket candidates

1. **Enforce, don't advise.** A `tool_call` hook on `bash` that rejects `grep|cat|ls|head|find|sed -n` (no pipe to a mutator) with a one-line redirect to the right tool. Expect: bash-nav ≈ 0 within a day; a few legit cases need an escape hatch (`--raw` or `# allow`). Also reject `cd $cwd &&` (165 no-ops).
2. **Fix `ctx_execute_file` root** (or steer away from it): 37% error → bash fallback. Either widen sandbox to `$HOME` read-only or drop the tool from main session.
3. **Fix `herdr_pane` JSON mismatch** (37% err, 23 wasted calls).
4. **`read` at 1× raw:** drop `read` from `readseek.overrideTools` (built-in read) or use `@pi-kaush/pi-better-read-edit`; mint anchors from `readSeek_grep`/`_def`. Expect: −370k tok/14d (~17% of tool-injected context). `write` echo: drop `write` from overrideTools too (−28k, free).
5. **Installed-package reads (85+ from main)** → the `bash` hook above plus a recon that can actually read outside the repo (recon's own sandbox blocked `~/.agents/skills` today).
6. **`read` range for `sed -n`:** already exists (`start`/`end`) — hook redirect message should name it.
7. **Model routing:** fable does 2× the bash-nav of opus at 2.5× the $/call; nothing here says fable is needed for dotfiles/config sessions.
8. `for`-loops (70 wall-min) and `python3` inline (59) → `ctx_execute` or recon; low priority.

## Proposal: punk-steering v2 — `guard` rules (D2 block + D3 rewrite + telemetry)

Spec v1 reserved both: D2 `block` = *terminate session + flag for review, never deny-and-retry*;
D3 `rewrite` = mutate `tool_call` input. Data says restricted toolsets work (4% bash-nav) and
prose does not (45–75%), and the model routes around single hooks via pipes/`cd`/`python3 -c`.
So: match on the *whole command*, not the head; escalate fast; log everything.

### Rule shape (new `kind: guard`)

```yaml
---
kind: guard
when: { tools: [bash] }          # existing gate: rule active only if bash is in the toolset
tool: bash                        # which tool_call to inspect
deny:                             # regex list, tested against the normalised command
  - '(^|[;&|]\s*)(grep|rg|cat|head|tail|ls|find|wc|tree)\b'     # navigation
  - '(^|[;&|]\s*)sed\s+-n\b'                                    # sed range print
  - '(^|[;&|]\s*)(sed\s+-i|perl\s+-p?i)\b'                      # in-place edits
  - '(^|[;&|]\s*)cd\s+\$?CWD\b'                                 # cd into own cwd (substituted)
  - '(^|[;&|]\s*)python3?\s+-c\b.*\b(open|read|glob|walk)\('    # python as cat
allow:                            # exceptions, tested first
  - '\bgit\b'                      # git grep/log/… are fine
  - '#\s*allow:'                   # explicit escape hatch, logged as override
on_deny: rewrite | reject | block
rewrite: "recon"                  # for on_deny=rewrite: what to replace with (see below)
strikes: 3                        # violations per session before block
---
Bash is for processes. Navigation: `read` (with start/end), `readSeek_grep`, `find`, `ls`.
Edits: `edit`. Outside the repo (node_modules, site-packages, ~/.config): dispatch `recon`.
```

Normalisation before matching: strip leading `cd X &&`, collapse whitespace, expand `$PWD`;
match against every segment of `|`, `;`, `&&`, `$( )` — so `git log | grep` is allowed by
`\bgit\b` on the first segment but `cat x | python3 -` is denied on the first.

### Escalation ladder (per session)

| strike | action | model sees | telemetry |
|---|---|---|---|
| 1–2 | **reject** | tool result: `steering/<rule>: denied. <body>` (one line + rule body), no retry loop — the model picks another tool next turn | `pi.steering.violation` {rule, tool, head, segment, strike} |
| 3 | **block** | `sendMessage`: "Session blocked after 3 steering violations. Write a handoff (`punk-handoff`) to `docs/.scratch/handoff-<sid>.md` now, then stop." All tools except `read`(skills), `write`(scratch) removed for the rest of the session via `pi.setActiveTools` | `pi.steering.block` {rule, strikes, sid} + `ctx.ui.notify(error)` |
| after block | owner opens a fresh pi, `/punk-resume` the handoff; blocked sid is in Logfire for analysis | | |

`rewrite` (D3) is the aggressive variant for later: on strike 1 replace the bash call with the
equivalent proper-tool call (`sed -n 'a,bp' f` → `read {path:f,start:a,end:b}`; `grep -rn p d`
→ `readSeek_grep {pattern:p,path:d}`). Skip for v2.0 — mapping table is guesswork until
violation logs show the real shapes; ship reject+block, mine `pi.steering.violation`, then add.

### Delegation guard (second rule, same kind)

```yaml
kind: guard
tool: read
deny: ['node_modules/', 'site-packages/', '\.local/share/', '^/tmp/']   # paths outside the repo
on_deny: reject
```
Body: "Installed-package / other-repo source goes to `recon`." Plus fix recon's own sandbox
(ctx_execute_file root) or delegation fails and bounces back — the one recon today did.

### Level interaction

`off` → nothing. `observe` → log violations only (dry run: measure false positives for a day
before turning on). `advise` → reject+block. `rewrite` → also D3. Level dial already exists.

### Telemetry (via `pi-otel:log`, same as context-events)

`pi.steering.violation`, `pi.steering.override`, `pi.steering.block`, plus `pi.steering.applied`
once per session listing active rules → answers "are the tools/steering used" directly next time.

### Test plan
Resolver stays pure: `(rule, command) → {verdict, segment, matched}` table-tested with the
real bash heads from Logfire (export top 200 distinct commands as fixtures). One pi-level test
for the strike counter and block.

### Decisions needed
1. Strikes: 3 per **session** (proposed) vs per turn.
2. Block scope: remove tools (proposed) vs `ctx.abort()` + notify only (simpler, but the model can't write the handoff).
3. Day-1 level: `observe` for 24h to catch false positives (proposed), or straight to `advise`.
4. `git` blanket allow (proposed) — `git grep` is navigation too, but git is 244 legit calls.
