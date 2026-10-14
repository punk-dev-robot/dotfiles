# Baseline: pi agent cost/context before piewf → pi-herdsman (KUB-171)

Source: Logfire project `coding-agent`, personal org `kuba-gaj`, via MCP `logfire-swap` → `logfire-swap_query_run`
(`service_name='pi'`). Queried 2026-10-14 ~14:30 UTC. Pass `start_timestamp`/`end_timestamp` on every call (≤14d window).

**Window.** "14d" = sessions whose first `chat` span is 2026-10-01..2026-10-14 (data end 14:20 UTC on the 14th).
"3d" = 2026-10-12..14. **Telemetry only exists for 2026-10-01, 02, 07, 08, 09, 13, 14**; Oct 3–6, 10–12 have no
records (exporter "Request timed out" flood / pi not running — not distinguishable). So "14d" = 7 live days, "3d" = 2 live days
(Oct 13, 14). Day-level numbers are per-live-day, not per-calendar-day.

## Method: main vs child (and its error)
- **child** = session that either (a) has an `invoke_agent pi` span whose `pi.user_prompt` starts `Workflow: ` (piewf prefix),
  or (b) has an `execute_tool workflow_result` span (children must call `workflow_result`). **main** = everything else with ≥1 `chat` span.
- Overlap (all sessions incl. no-chat, per-day check): prefix-only 21, workflow_result-only 4, so the two signals agree ≈85–90%; children matching neither (aborted before first prompt span / no prefix) fall into *main* → child count/cost is a **lower bound**, main slightly overstated. Error not directly measurable; estimate ≲5–10 sessions (≈3–5%).
- **Prefix is NOT actually gone** in this data: `Workflow: X\nAgent: <label>` still present through Oct 14 (≈60% of Oct-14 sessions). What broke is *role effect*, not the prefix (see §Attribution). `Agent:` is the per-run **label**, never the role name (`pi.agent.role` resource attr: 0 rows so far, herdsman patch not deployed).
- Cost = sum of `pi.cost.usd` over `chat *` spans. `claude-opus-5` rows have cost 0 (no price in pi) → understated; `capture` pseudo-model also 0.
- Input tokens = `input_tokens + cache_read + cache_write` (prompt footprint). Wall = last chat end − first chat start (excludes idle before first call / after last).
- **Fresh main session** = first `chat` span has `gen_ai.input.messages` length 1. First-turn input = that span's total input tokens (includes cache reads, so it is footprint, independent of cache hits).

## Common CTE (prefix to every query below)
```sql
WITH kid AS (
  SELECT attributes->>'pi.session.id' AS sid FROM records WHERE service_name='pi' AND span_name='invoke_agent pi' AND attributes->>'pi.user_prompt' LIKE 'Workflow: %'
  UNION
  SELECT attributes->>'pi.session.id' FROM records WHERE service_name='pi' AND span_name='execute_tool workflow_result'),
chat AS (
  SELECT attributes->>'pi.session.id' AS sid, start_timestamp, end_timestamp,
    attributes->>'gen_ai.request.model' AS model,
    coalesce((attributes->>'pi.cost.usd')::double,0) AS cost,
    coalesce((attributes->>'gen_ai.usage.input_tokens')::double,0) AS in_fresh,
    coalesce((attributes->>'gen_ai.usage.cache_read_input_tokens')::double,0) AS in_cr,
    coalesce((attributes->>'gen_ai.usage.cache_write_input_tokens')::double,0) AS in_cw,
    coalesce((attributes->>'gen_ai.usage.output_tokens')::double,0) AS out_tok,
    json_length(attributes->'gen_ai.input.messages') AS nmsg,
    row_number() OVER (PARTITION BY attributes->>'pi.session.id' ORDER BY start_timestamp) AS rn
  FROM records WHERE service_name='pi' AND span_name LIKE 'chat %' AND attributes->>'pi.session.id' IS NOT NULL),
sess AS (
  SELECT c.sid, min(c.start_timestamp) AS t0, max(c.end_timestamp) AS t1, count(*) AS calls,
    max(c.model) AS model, sum(c.cost) AS cost, sum(c.in_fresh+c.in_cr+c.in_cw) AS in_tok, sum(c.out_tok) AS out_tok,
    max(CASE WHEN c.rn=1 THEN c.in_fresh+c.in_cr+c.in_cw END) AS first_in,
    max(CASE WHEN c.rn=1 THEN c.nmsg END) AS first_nmsg,
    (k.sid IS NOT NULL) AS is_child
  FROM chat c LEFT JOIN kid k ON k.sid=c.sid GROUP BY c.sid, (k.sid IS NOT NULL))
```
Window filter: replace `<F>` with `t0 >= TIMESTAMP '2026-10-01'` (14d) or `'2026-10-12'` (3d); at trial end use the trial dates.
Call with start 2026-10-01T00:00:00Z / end 2026-10-14T23:59:00Z (adjust).

## T1. Cost per day, children vs main (share)
14d (3d = last two rows):

| day | child sess | child $ | main sess | main $ | child % of $ |
|---|---|---|---|---|---|
| 10-01 | 67 | 23.56 | 65 | 71.71 | 24.7 |
| 10-02 | 42 | 19.23 | 38 | 24.10 | 44.4 |
| 10-07 | 0 | – | 1 | 5.73 | – |
| 10-08 | 6 | 5.16 | 5 | 4.97 | 51.0 |
| 10-09 | 14 | 15.28 | 23 | 26.25 | 36.8 |
| 10-13 | 16 | 41.78 | 15 | 22.69 | 64.8 |
| 10-14 | 23 | 24.58 | 27 | 22.90 | 51.8 |
| **14d total** | **168** | **129.59** | **174** | **178.35** | **42.1** |
| **3d total (13–14)** | 39 | 66.36 | 42 | 45.59 | 59.3 |

Live-day mean: 14d child $18.5/day, main $25.5/day; 3d child $33.2/day, main $22.8/day.
(Totals are sums of the day rows; Oct 14 is partial, ends 14:20 UTC.)

```sql
<CTE> SELECT date_trunc('day',t0) day, count(*) FILTER (WHERE is_child) child_sess, round(sum(cost) FILTER (WHERE is_child),2) child_usd,
  count(*) FILTER (WHERE NOT is_child) main_sess, round(sum(cost) FILTER (WHERE NOT is_child),2) main_usd,
  round(100*sum(cost) FILTER (WHERE is_child)/sum(cost),1) child_pct
FROM sess WHERE <F> GROUP BY 1 ORDER BY 1
```

## T2. Child sessions per model (cost USD per session, tokens, wall)
14d:

| model | n | p50 $ | p90 $ | mean $ | total $ | avg in tok | avg out tok | avg chat calls | wall p50 s | wall p90 s |
|---|---|---|---|---|---|---|---|---|---|---|
| claude-opus-5-5 | 56 | 1.14 | 2.87 | 1.56 | 87.40 | 3,135,823 | 18,545 | 31.8 | 252 | 1487 |
| claude-sonnet-5-5 | 45 | 0.14 | 0.42 | 0.18 | 8.07 | 227,897 | 4,251 | 8.5 | 31 | 145 |
| gpt-6.1-sol | 23 | 0.18 | 0.34 | 0.18 | 4.18 | 584,199 | 4,760 | 16.0 | 247 | 685 |
| claude-sonnet-5 | 21 | 0.29 | 0.53 | 0.30 | 6.20 | 339,024 | 8,326 | 11.6 | 99 | 162 |
| claude-opus-5 (cost unpriced=0) | 9 | 0 | 0 | 0 | 0 | 1,570,346 | 24,427 | 21.4 | 340 | 3072 |
| claude-fable-5-1 | 5 | 1.80 | 2.87 | 1.93 | 9.65 | 754,837 | 11,390 | 14.8 | 136 | 388 |
| gpt-6-astra | 5 | 1.09 | 2.33 | 1.40 | 7.00 | 634,156 | 4,718 | 15.4 | 219 | 340 |
| claude-fable-5 | 4 | 1.67 | 2.13 | 1.78 | 7.10 | 378,782 | 12,546 | 11.8 | 178 | 231 |

3d (Oct 13–14):

| model | n | p50 $ | p90 $ | mean $ | total $ | avg in tok | avg out tok | avg calls | wall p50 s | wall p90 s |
|---|---|---|---|---|---|---|---|---|---|---|
| claude-opus-5-5 | 28 | 1.51 | 3.98 | 2.05 | 57.49 | 4,459,998 | 22,598 | 38.4 | 293 | 2068 |
| gpt-6.1-sol | 6 | 0.32 | 0.40 | 0.25 | 1.48 | 605,364 | 2,676 | 14.5 | 330 | 417 |
| claude-fable-5-1 | 3 | 1.80 | 1.83 | 1.43 | 4.28 | 401,983 | 6,033 | 8.3 | 120 | 132 |
| claude-sonnet-5-5 | 1 | 0.32 | 0.32 | 0.32 | 0.32 | 480,514 | 3,389 | 10.0 | 51 | 51 |
| gpt-6-astra | 1 | 2.81 | 2.81 | 2.81 | 2.80 | 1,550,187 | 5,831 | 25.0 | 366 | 366 |

Child sessions overall (all models, 14d): 168 sessions, $129.59 → mean $0.77/session. 3d: 39 sessions, $66.36 → mean $1.70.
Session model = `max(model)` over its chat spans (children rarely switch).

```sql
<CTE> SELECT model, count(*) n, round(approx_percentile_cont(cost,0.5),3) p50, round(approx_percentile_cont(cost,0.9),3) p90,
  round(avg(cost),3) mean, round(sum(cost),2) total, round(avg(in_tok)) avg_in, round(avg(out_tok)) avg_out, round(avg(calls),1) avg_calls,
  round(approx_percentile_cont(extract(epoch from (t1-t0)),0.5)) wall_p50_s, round(approx_percentile_cont(extract(epoch from (t1-t0)),0.9)) wall_p90_s
FROM sess WHERE is_child AND <F> GROUP BY 1 ORDER BY n DESC
```

## T3. Fresh main sessions: first-turn input tokens (system prompt + tool schemas + AGENTS/steering footprint)

| window | n fresh main | first-turn in p50 | p90 | main session $ p50 | p90 | mean |
|---|---|---|---|---|---|---|
| 14d | 171 | 38,960 | 51,550 | 0.39 | 2.20 | 1.03 |
| 3d | 41 | 42,205 | 52,592 | 0.78 | 2.80 | 1.07 |

Child first-turn input (fresh children, same definition): 14d p50 18,776 / p90 46,644; 3d p50 39,748 / p90 48,548
(14d children p50 is low because Oct 1–2 children ran role-restricted toolsets/prompts; recent children carry the full ~40k footprint).

```sql
<CTE> SELECT is_child, count(*) n, round(approx_percentile_cont(first_in,0.5)) p50, round(approx_percentile_cont(first_in,0.9)) p90,
  round(approx_percentile_cont(cost,0.5),2) cost_p50, round(approx_percentile_cont(cost,0.9),2) cost_p90, round(avg(cost),2) cost_mean
FROM sess WHERE first_nmsg=1 AND <F> GROUP BY 1
```

## T4. Cost by model × (main|child), 14d

| role | model | sessions | $ |
|---|---|---|---|
| main | claude-opus-5-5 | 90 | 129.16 |
| main | gpt-6-astra | 11 | 31.30 |
| main | claude-fable-5-1 | 7 | 10.63 |
| main | gpt-6.1-sol | 26 | 3.99 |
| main | claude-sonnet-5-5 | 8 | 1.40 |
| main | claude-fable-5 / sonnet-5 | 1 / 3 | 1.09 / 0.77 |
| child | claude-opus-5-5 | 56 | 87.40 |
| child | claude-fable-5-1 | 5 | 9.65 |
| child | claude-sonnet-5-5 | 45 | 8.07 |
| child | claude-fable-5 | 4 | 7.10 |
| child | gpt-6-astra | 5 | 7.00 |
| child | claude-sonnet-5 | 21 | 6.20 |
| child | gpt-6.1-sol | 23 | 4.18 |

```sql
<CTE> SELECT is_child, model, count(*) n, round(sum(cost),2) usd FROM sess WHERE <F> GROUP BY 1,2 ORDER BY 1, usd DESC
```

## Attribution break (child model mix by day, prefix-matched children)

| day | children by model (n / $) |
|---|---|
| 10-01 | sonnet-5 21/6.20, gpt-6.1-sol 14/2.71, sonnet-5-5 12/1.71, opus-5 8/0, gpt-6-astra 4/4.20, fable-5 4/7.10, opus-5-5 3/1.64 |
| 10-02 | sonnet-5-5 32/6.04, opus-5-5 8/7.83, fable-5-1 2/5.36 |
| 10-08 | opus-5-5 3/5.16, gpt-6.1-sol 3/0 |
| 10-09 | **opus-5-5 14/15.28 (100%)** |
| 10-13 | opus-5-5 11/34.50, gpt-6.1-sol 2/0.76, fable-5-1 1/0.62, gpt-6-astra 1/2.80 |
| 10-14 | opus-5-5 14/15.20, gpt-6.1-sol 4/0.72, fable-5-1 2/3.66 |

**Break is between Oct 2 and Oct 8** (no data Oct 3–6; Oct 7 has no children). Through Oct 2 children were mostly cheap
role models (sonnet-5/5-5, gpt-6.1-sol; sonnet-5-5 p50 $0.14); from Oct 8 ≥70% are opus-5-5 (p50 ≈ $0.9–1.9). The non-opus
children on Oct 13–14 are explicitly-modelled `pr-principal-review` workflows (sol/fable/astra), not role defaults.
Exact day can't be narrowed further from this data; piewf 6.2.1 upgrade date isn't in telemetry.

```sql
WITH lab AS (SELECT attributes->>'pi.session.id' sid FROM records WHERE service_name='pi' AND span_name='invoke_agent pi'
  AND attributes->>'pi.user_prompt' LIKE 'Workflow: %' GROUP BY 1),
cs AS (SELECT attributes->>'pi.session.id' sid, min(start_timestamp) t0, max(attributes->>'gen_ai.request.model') model,
  sum(coalesce((attributes->>'pi.cost.usd')::double,0)) cost FROM records WHERE service_name='pi' AND span_name LIKE 'chat %' GROUP BY 1)
SELECT date_trunc('day',t0) day, model, count(*) n, round(sum(cost),2) usd, round(approx_percentile_cont(cost,0.5),2) p50
FROM cs JOIN lab USING(sid) GROUP BY 1,2 ORDER BY 1,n DESC
```

## T5. Cost per role (where attribution "works")
**True role names are not recoverable from any data in the window**: the prefix's `Agent:` is a free-form run label, and
`otel_resource_attributes->>'pi.agent.role'` has 0 rows. Best proxy: bucket prefix-matched children by keywords in the label
(14d, all prefixed children; sessions = 163, $121.5 of the $129.59 child total; rest unprefixed workflow_result-only):

| label bucket (keyword match) | sessions | $ | p50 $ |
|---|---|---|---|
| other (unmatched labels, mostly task slugs e.g. `AGIA-273 …`) | 106 | 76.11 | 0.28 |
| review (`review`/`arbiter`/`debate`) | 37 | 35.44 | 0.34 |
| comms (`comms`/`fyi`) | 7 | 4.03 | 0.26 |
| recon | 8 | 3.65 | 0.28 |
| plan | 4 | 1.70 | 0.44 |
| research | 1 | 0.57 | 0.57 |
| dev / impl / tests | 0 matched | – | – |

By workflow name: `subagents` 142 sessions $106.52; `pr-principal-review*` ~19 sessions $14.8. Treat as indicative only — no
true per-role cost exists for this baseline.

```sql
WITH lab AS (SELECT attributes->>'pi.session.id' AS sid,
    min(regexp_match(attributes->>'pi.user_prompt','^Workflow: ([^\n]+)\nAgent: ([^\n]+)')[1]) AS wf,
    min(regexp_match(attributes->>'pi.user_prompt','^Workflow: ([^\n]+)\nAgent: ([^\n]+)')[2]) AS label
  FROM records WHERE service_name='pi' AND span_name='invoke_agent pi' AND attributes->>'pi.user_prompt' LIKE 'Workflow: %' GROUP BY 1),
cs AS (SELECT attributes->>'pi.session.id' sid, min(start_timestamp) t0, sum(coalesce((attributes->>'pi.cost.usd')::double,0)) cost
  FROM records WHERE service_name='pi' AND span_name LIKE 'chat %' GROUP BY 1)
SELECT CASE WHEN label ILIKE '%recon%' THEN 'recon' WHEN label ILIKE '%review%' OR label ILIKE '%arbiter%' OR label ILIKE '%debate%' THEN 'review'
  WHEN label ILIKE '%research%' THEN 'research' WHEN label ILIKE '%test%' THEN 'tests' WHEN label ILIKE '%plan%' THEN 'plan'
  WHEN label ILIKE '%comms%' OR label ILIKE '%fyi%' THEN 'comms' ELSE 'other' END bucket,
  count(*) n, round(sum(cost),2) usd, round(approx_percentile_cont(cost,0.5),2) p50
FROM cs JOIN lab USING(sid) GROUP BY 1 ORDER BY usd DESC
```
For herdsman trial end, replace the bucket CASE with `coalesce(otel_resource_attributes->>'pi.agent.role','main')` per
`docs/reference/logfire-pi-role-attribution.md`.

## Caveats / not measured
- Only 7 live days; Oct 3–6, 10–12 missing (exporter timeouts or pi idle) — per-day means are per-live-day. Oct 14 partial. Small n in 3d (2 days, 39 children, 28 on opus-5-5): p90s are noisy.
- Child/main split is heuristic (see Method); child totals are a lower bound (~≤3% sessions misfiled).
- Cost via `pi.cost.usd` only: `claude-opus-5` shows $0 (unpriced; 9 child + 7 main sessions) → totals understated; subscription-flat plans not modelled.
- Tokens are summed per-call prompt sizes (cache reads counted every call), so avg in-tok per session (millions) is *processed* tokens, not unique context. Peak context window per session not measured.
- First-turn footprint is from `chat` span totals; it mixes system prompt, tool schemas, AGENTS/steering and any injected memory — not decomposed. Resumed-session first turns excluded via `nmsg=1`.
- Not measured: tool-call counts/errors (`execute_tool` queries in the role-attribution doc), latency to first token, orchestration overhead of the parent waiting on children, Lead/manager sessions started via `herdr agent start` (read as main), metrics-table tokens.
- Wall time excludes pre-first-call and post-last-call time and queueing; children's startup cost is not captured.
- No true per-role data exists (label ≠ role); T5 is keyword-bucketed.
