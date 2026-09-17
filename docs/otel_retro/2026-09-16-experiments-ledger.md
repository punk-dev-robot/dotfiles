# Agentic workflow experiments ledger

Every deliberate change to the pi setup that is expected to move a Logfire metric gets a row
here *before* it ships: baseline, expectation, how to measure. Score it a few days later.
Baseline window = 7d before the change unless stated. Queries: DataFusion SQL, `service_name='pi'`,
cost from `pi.cost.usd` on `chat *` spans only (legacy `pi.llm_request` double-counts).

Status: `open` (not yet scored) · `confirmed` · `refuted` · `inconclusive` (say why).

## Standard queries

Per-session shape (drop-in for any window):

```sql
SELECT count(DISTINCT sid) sessions,
       round(approx_percentile_cont(cost,0.5),2) p50_cost, round(sum(cost),2) total_cost,
       round(approx_percentile_cont(peak,0.5)/1000) p50_peak_k,
       count(*) FILTER (WHERE peak > 200000) over_200k,
       round(avg(calls)) avg_calls
FROM (SELECT attributes->>'pi.session.id' sid, count(*) calls,
             sum((attributes->>'pi.cost.usd')::double) cost,
             max((attributes->>'gen_ai.usage.cache_read_input_tokens')::double
               + (attributes->>'gen_ai.usage.cache_write_input_tokens')::double) peak
      FROM records WHERE span_name LIKE 'chat %'
        AND attributes->>'gen_ai.request.model' LIKE 'claude-fable%'   -- main-session models
      GROUP BY 1) LIMIT 1
```

Context lifecycle events (from `context-events.ts`, live 2026-09-16 21:45Z):

```sql
SELECT span_name, count(*) n, round(avg((attributes->>'pi.compaction.tokens_before')::double)/1000) avg_before_k
FROM records WHERE span_name LIKE 'pi.context.%' GROUP BY 1 LIMIT 20
-- pi.context.compaction | compaction_failed | om.observations.recorded | om.reflections.recorded
-- | om.observations.dropped | om.folded | nudge   — all carry pi.session.id, pi.context.tokens, model
```

## Ledger

### E1 — KUB-149: compaction reserve 64k / keepRecent 40k, OM ratio 0.18, nudge @150k
- **Shipped:** 2026-09-15 23:35Z (commit `6a97826`); mac pulled 2026-09-16 ~21:30Z.
- **Baseline (fable main sessions, 09-03 → 09-15, both hosts):** 29 sessions, p50 peak 114k,
  max 330k, **6 sessions >200k**, $9.63/session, avg 43 calls/session. 0 compactions observed
  (no telemetry — inferred from monotonic ctx growth).
- **Expect:** no session >200k peak; OM compaction fires ≥1× in any session passing ~180k;
  p50 cost/session down (fewer 250k+ cache reads); nudge fires once per long session; handoffs
  replace runaway sessions.
- **Measure:** standard query with window ≥ 2026-09-16T21:30Z (both hosts deployed); count
  `pi.context.compaction` per session vs sessions with peak >180k (should be ≈ equal);
  `pi.context.nudge` count vs sessions >150k.
- **Early read (omarchy only, 09-15 23:35 → 09-16 21:00):** 24 sessions, p50 76k, max 200k,
  0 over 200k. Mac not yet deployed in that window (3 sessions >200k, max 298k) — excluded.
- **Status:** open — score ≥ 2026-09-19.

### E2 — context-events extension (this)
- **Shipped:** 2026-09-16 21:45Z. Not a cost change; enables E1 scoring. Cost of the extension
  itself: one log record per compaction/OM entry — negligible.
- **Expect:** `pi.context.*` records appear for every real session; `pi.session.id` joins chat spans.
- **Status:** confirmed on omarchy test session (compaction_failed + om.observations.recorded, join ok).
  Verify on mac after next pull.

### E3 — KUB-164: punk-steering v1 (tool-gated steering rules replace APPEND_SYSTEM.md)
- **Shipped:** 2026-09-16 18:19Z (`651424b`), fixes 20:06Z (`e07631d`); omarchy only until mac pull ~21:30Z.
- **Baseline (09-03 → 09-16 18:19Z, main models fable/opus):** bash-nav-edit share 45–75% by
  model/host (see review "Who does it"); ~600 bash navigation calls/14d; repowise 10 calls,
  cymbal 0, subagents_run 20; installed-package reads from main ≈ 85.
- **Expect:** bash-nav share of main sessions drops toward the subagent level (<20%); repowise/
  readSeek/subagents_run counts rise per session; `cd $cwd &&` no-ops disappear.
- **Measure:** "bash-nav share per model/host" and "daily trend" queries in
  `2026-09-16-logfire-queries.md`, window ≥ 2026-09-16T21:30Z, main models only.
- **Early read (first 3h omarchy, 15 sessions):** bash-nav share 45% → 58%, repowise 0, delegated 2.
  No step change visible; sample too small.
- **Status:** open — score ≥ 2026-09-19. If refuted → E4 = hard `tool_call` hook on bash (reject
  grep/cat/ls/head/find/`sed -n` with redirect), which the subagent data predicts will work.

### E4 — uninstall pi-readseek; vanilla read/edit/write
- **Shipped:** 2026-09-16 ~23:00Z omarchy (settings.json package + `readseek` block removed;
  roles/steering/webui references cleaned). Mac on next pull. Research + decision:
  `2026-09-16-research-file-tools.md`.
- **Baseline (14d):** `read` avg 2234 tok/call (1.94× raw), 737k tok total; `write` 791 tok/call;
  `edit` 188 calls, **33 (18%) rejected `You must get fresh anchors`**; readSeek_grep 111,
  _def 2, _refs 1, _search 0, _view 0. ~9 tool schemas in preamble.
- **Expect:** `read` avg ≈ 1150 tok/call (−45%), ~−370k tok/14d; `write` one line; `edit` error
  rate ≤ 18% (str_replace ambiguity/mis-copy vs stale-anchor guard — unknown, that is the
  experiment); first-call ctx down ~2–3k; no rise in `bash sed -n`/`cat` as a substitute for
  line-numbered reads.
- **Measure:** tool leaderboard (content ktok, err%) for `read`/`edit`/`write` + bash heads,
  window ≥ 2026-09-16T23:00Z. Compare edit err% against 18%.
- **Fallback if refuted:** `pi-hashline-edit-pro-lean` with auto-read off (selective override,
  423 preamble tok, 1.09× read).
- **Status:** open — score ≥ 2026-09-23.

### E5 — punk-steering v2 `guard` rules (reject → block, telemetry)
- **Spec:** `specs/punk-steering-v2.md`. Ships at `level: observe` first (log only).
- **Baseline (14d, main models fable/opus):** bash-nav/edit share 45–75% by host/model;
  ~600 bash navigation calls; sed -n 129, python3 inline 59, sed -i 13; installed-package reads
  from main ≈ 85; subagents_run 22.
- **Expect (observe, day 1):** `pi.steering.violation` count ≈ the bash-nav rate above; false
  positives (legit commands flagged) < 5% of violations — else fix patterns before flipping.
- **Expect (advise, week 1):** bash-nav share < 10%; ≤ 1 `pi.steering.block` per 10 sessions
  (more = budget too tight or model can't recover); `subagents_run`/session up; `read` calls
  with node_modules/site-packages paths → 0 in main; no rise in `ctx_execute` used as a
  cat/grep substitute (watch its content).
- **Measure:** `SELECT span_name, attributes->>'pi.steering.rule', attributes->>'pi.steering.enforced', count(*) FROM records WHERE span_name LIKE 'pi.steering.%' GROUP BY 1,2,3` + bash-nav share query, window from flip time.
- **Shipped:** 2026-09-16 23:20Z omarchy, per-rule `level: observe` on both guard rules (global level stays `advise`). Smoke: observe → violation logged, command ran; advise → rejected with strike text, haiku stopped after strike 1.
- **Status:** open — flip = delete `level: observe` in `steering/guard-*.md` ≥ 09-17 23:00Z after false-positive check; score ≥ 09-24.

### E6 — pi-otel noise: logLevel warn, metrics off
- **Shipped:** 2026-09-16 23:40Z omarchy (settings.json `otel.logLevel`, `signals.metrics`).
- **Baseline:** ~14k noise records/day omarchy (metrics-reader ~5k, request-timeout ~9k); 0 on mac.
- **Expect:** metrics-reader records → 0; request-timeout unchanged (Bun/http issue, separate
  ticket); no loss of chat/execute_tool spans (compare session count vs `pi.session.start`).
- **Measure:** inventory query, `span_name LIKE '{"message":%'` grouped by day/host.
- **Status:** open — score ≥ 09-18.

### E7 — ctx_execute_file allow-list (unblocks recon outside the repo)
- **Shipped:** 2026-09-17 00:05Z omarchy; mac on pull (uses `{{home_dir}}`).
- **Baseline (14d):** ctx_execute_file 43 calls, 37% `File access blocked`; each failure → bash `cat`/`grep` fallback in main.
- **Expect:** ctx_execute_file err% → <5%; recon runs on installed-package questions succeed; precondition for flipping `guard-read-outside-repo` to advise.
- **Status:** open — score with E5.

### E8 — repowise augment: telemetry + read success path + SessionStart decisions
- **Shipped:** 2026-09-17 omarchy (`extensions/repowise-augment.ts`: `pi.augment.fired` log on every
  call, read success-path `tool_response` in Claude's file shape, `before_agent_start` →
  SessionStart standing-decisions block; shared git hooks `config/custom/git/hooks/*` +
  `core.hooksPath` so the index also updates on merge/branch-checkout). Mac on next pull + `dotter`.
  Research: `2026-09-17-research-repowise-plugin.md` §6.
- **Baseline (14d):** `repowise_*` MCP tools 10 calls; augment firings **unknown — no telemetry at
  all** (read success path skipped outright, so stale-read / re-read / changed-outside surfaces
  could never fire); index updated on commit only.
- **Expect:** `pi.augment.fired` visible with a computable hit rate (hit=false emitted too);
  read-path notices appear (`stale`, `unchanged re-read`, `changed outside`) — verified by hand:
  read→edit→read returns the 110-char stale notice; SessionStart decisions block ≤150 tok/session
  and silent when nothing clears the floor; p95 `pi.augment.ms` ≤ FAST_TIMEOUT_MS (3s) on non-search
  tools, timeouts flagged `pi.augment.timeout`.
- **Measure:**
  ```sql
  SELECT attributes->>'pi.augment.event' ev, attributes->>'pi.augment.tool' tool, count(*) n,
    sum(CASE WHEN attributes->>'pi.augment.hit' = 'true' THEN 1 ELSE 0 END) hits,
    avg(CAST(attributes->>'pi.augment.ms' AS DOUBLE)) avg_ms,
    sum(CAST(attributes->>'pi.augment.chars' AS BIGINT)) chars
  FROM records WHERE service_name='pi' AND span_name='pi.augment.fired'
  GROUP BY 1,2 ORDER BY n DESC
  ```
  Plus p95 latency for read specifically:
  `approx_percentile_cont((attributes->>'pi.augment.ms')::double, 0.95) FILTER (WHERE attributes->>'pi.augment.tool'='read')`.
  Cross-check cost: injected chars/4 ≈ tokens vs `repowise_search_codebase` 1.6k tok/result.
- **Verified live (09-17 01:45Z):** read → `hit=false, 87 ms` on a fresh read (correct);
  SessionStart → `hit=true, 269 chars` but freshness-only, so the extension injected nothing.
- **Untested — watch next time:**
  - The standing-decisions injection has never run against real content: **no indexed repo has any
    decision** (`repowise decision list` → 0 in dotfiles; `docs/adr/*` not picked up because no LLM
    provider is configured for repowise, so adr/git/pr/session extraction stages are skipped —
    see O12). First real decisions block: check it renders, size ≤150 tok, and that the
    `[repowise] Standing decisions` slice logic in `repowise-augment.ts` holds.
  - Every `read` in an indexed repo now pays an augment round-trip (~0.1–0.5 s, 3 s cap). Watch
    p95 `pi.augment.ms` for `tool=read` and `pi.augment.timeout` count; if p95 > 1 s or timeouts
    > 2% → revert the read path, keep telemetry.
  - `repowise update` (fired by the new hooks) writes `.vscode/mcp.json` + `extensions.json` into
    every indexed repo on every commit/checkout — gitignored in dotfiles, may not be elsewhere.
  - Global `core.hooksPath` chains to per-repo hooks; untested with a real pre-commit/lefthook repo.
- **Status:** open — score ≥ 2026-09-20 (need ≥20 sessions). Refuted if hit rate <5% on read
  (notices never fire → revert the read path and keep telemetry only).

### E9 — repowise full setup on dotfiles (claude_cli/opus + gemini embedder + decisions)
- **Shipped:** 2026-09-17 02:25Z omarchy. `repowise init --provider claude_cli --model claude-opus-5
  --embedder gemini --prose --no-editor-setup --no-claude-md --no-agents --concurrency 4` (4m07s,
  135 pages / 11 model-written, 31 candidates → 32 governing after review). Runbook:
  `docs/reference/repowise-repo-setup.md`.
- **Baseline:** `embedder: mock`, no provider → 0 decisions, template-only wiki, SessionStart
  augment `hit=true / 269 chars` freshness-only, `get_why` on ADR-governed files = git archaeology.
- **Expect:** decisions ≥ 3 from ADRs; SessionStart block injected ≤ 400 tok when a governed file
  is in the working set, silent on a clean tree; `get_why <governed file>` answers from a decision;
  edit-time "governed by" notice fires.
- **Measured (hand-driven `repowise-augment` payloads, 02:40Z):**
  - Decisions: 18 ADR + 5 git + 8 comment candidates (31); all confirmed. 16 ADR ones were blocked
    "no scope" — needed `confirm --scope`. **Upstream bug:** `confirm --scope` writes
    `affected_files` but no `decision_node_links` rows → augment scores them 0 → silence. Backfilled
    42 links by SQL (runbook §Gotchas); after that SessionStart with dirty `bindings.lua` → block of
    4 decisions, 1184 chars (~296 tok). Clean tree → freshness line only (by design).
  - Edit `bindings.lua` → 262-char "governed by a standing decision" notice. Read→edit→read →
    139-char stale notice. `repowise why config/omarchy/hypr/bindings.lua` → 8 decisions, alignment
    medium. `why docs/adr/0001…` still archaeology — ADR files are evidence, not scope; ask about
    the governed file.
  - 4 `.zshenv` decisions report `staleness 1.00` with "nothing changed" — hidden-file quirk,
    not chased.
- **Status:** open — Logfire check ≥ 09-18: `pi.augment.fired` `event='SessionStart' AND hit`
  with `chars > 300` in dotfiles sessions; `tool=edit hit=true` count > 0.
