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
