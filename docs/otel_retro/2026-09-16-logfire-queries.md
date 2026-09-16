# Logfire queries used in the 2026-09-16 review

DataFusion SQL against `records`. Always pass `start_timestamp` and `end_timestamp` to
`query_run` (max 14d; `now()`-relative start fails by a few seconds). `service_name='pi'` is
implicit below. Gotchas: `event.name` lands as `span_name`; cost from `chat *` only; `LATERAL`
correlated subqueries are not supported; `regexp_match()` returns an array → `[1]`.

Snippets reused everywhere:

```sql
-- strip "cd X && " prefix, take command head
regexp_match(regexp_replace(trim(attributes->'pi.tool.input'->>'command'),
             '^cd [^&;|]+(&&|;)\s*', ''), '^\(?([A-Za-z0-9_./-]+)')[1]
-- host
CASE WHEN attributes->>'pi.cwd' LIKE '/Users/%' THEN 'mac' ELSE 'omarchy' END
-- context size of a call
(attributes->>'gen_ai.usage.cache_read_input_tokens')::double
  + (attributes->>'gen_ai.usage.cache_write_input_tokens')::double
```

## Inventory / health

```sql
-- span types and volume
SELECT service_name, span_name, count(*) n, min(start_timestamp) first, max(start_timestamp) last
FROM records GROUP BY 1,2 ORDER BY n DESC LIMIT 50;

-- exporter self-noise
SELECT count(*) FROM records WHERE span_name LIKE '{"message":"Request timed out%'
   OR span_name LIKE '{"message":"PeriodicExportingMetricReader%' LIMIT 1;
```

## Cost

```sql
-- per model
SELECT attributes->>'gen_ai.request.model' model, count(*) calls,
       count(DISTINCT attributes->>'pi.session.id') sessions,
       round(sum((attributes->>'pi.cost.usd')::double),2) cost,
       round(avg((attributes->>'pi.cost.usd')::double),4) cost_per_call,
       sum((attributes->>'gen_ai.usage.input_tokens')::double) in_tok,
       sum((attributes->>'gen_ai.usage.output_tokens')::double) out_tok,
       sum((attributes->>'gen_ai.usage.cache_read_input_tokens')::double) cache_read,
       sum((attributes->>'gen_ai.usage.cache_write_input_tokens')::double) cache_write,
       round(avg((attributes->>'gen_ai.usage.cache_read_input_tokens')::double)) avg_ctx,
       count(*) FILTER (WHERE attributes->>'gen_ai.response.finish_reasons' LIKE '%toolUse%') tool_turns
FROM records WHERE span_name LIKE 'chat %' GROUP BY 1 ORDER BY cost DESC LIMIT 20;

-- per session (top spenders, peak & start context)
SELECT substr(attributes->>'pi.session.id',1,19) started, attributes->>'gen_ai.request.model' model,
       attributes->>'pi.cwd' cwd, count(*) calls,
       round(sum((attributes->>'pi.cost.usd')::double),2) cost,
       round(max((attributes->>'gen_ai.usage.cache_read_input_tokens')::double)/1000) peak_ctx_k,
       round(min((attributes->>'gen_ai.usage.cache_write_input_tokens')::double
               + (attributes->>'gen_ai.usage.cache_read_input_tokens')::double)/1000) start_ctx_k
FROM records WHERE span_name LIKE 'chat %' GROUP BY 1,2,3 ORDER BY cost DESC LIMIT 20;

-- first-call context (preamble size) by host/model
WITH f AS (SELECT attributes->>'pi.session.id' sid, attributes->>'gen_ai.request.model' model,
  CASE WHEN attributes->>'pi.cwd' LIKE '/Users/%' THEN 'mac' ELSE 'omarchy' END host,
  (attributes->>'gen_ai.usage.cache_write_input_tokens')::double
   + (attributes->>'gen_ai.usage.cache_read_input_tokens')::double
   + (attributes->>'gen_ai.usage.input_tokens')::double ctx,
  row_number() OVER (PARTITION BY attributes->>'pi.session.id' ORDER BY start_timestamp) rn
  FROM records WHERE span_name LIKE 'chat %')
SELECT host, model, count(*) sessions, round(approx_percentile_cont(ctx,0.5)/1000) p50_k,
       round(min(ctx)/1000) min_k, round(approx_percentile_cont(ctx,0.9)/1000) p90_k
FROM f WHERE rn=1 GROUP BY 1,2 ORDER BY sessions DESC LIMIT 12;

-- per role (piewf prefix; label not role — see reference/logfire-pi-role-attribution.md)
WITH first_agent AS (SELECT attributes->>'pi.session.id' sid, attributes->>'pi.user_prompt' prompt,
  row_number() OVER (PARTITION BY attributes->>'pi.session.id' ORDER BY start_timestamp) rn
  FROM records WHERE span_name='invoke_agent pi'),
session_role AS (SELECT sid, coalesce(regexp_match(prompt,'^Workflow: [^\n]+\nAgent: ([^\n]+)')[1],'main') agent
  FROM first_agent WHERE rn=1)
SELECT coalesce(r.agent,'<unresolved>') agent, count(DISTINCT c.attributes->>'pi.session.id') sessions,
       count(*) calls, round(sum((c.attributes->>'pi.cost.usd')::double),2) cost
FROM records c LEFT JOIN session_role r ON r.sid=c.attributes->>'pi.session.id'
WHERE c.span_name LIKE 'chat %' GROUP BY 1 ORDER BY cost DESC LIMIT 40;

-- before/after a change, main-model sessions
WITH s AS (SELECT attributes->>'pi.session.id' sid,
  CASE WHEN attributes->>'pi.cwd' LIKE '/Users/%' THEN 'mac' ELSE 'omarchy' END host,
  CASE WHEN min(start_timestamp) >= '2026-09-15T23:35:00Z' THEN 'after' ELSE 'before' END period,
  count(*) calls, sum((attributes->>'pi.cost.usd')::double) cost,
  max((attributes->>'gen_ai.usage.cache_read_input_tokens')::double
    + (attributes->>'gen_ai.usage.cache_write_input_tokens')::double) peak
  FROM records WHERE span_name LIKE 'chat %' AND attributes->>'gen_ai.request.model' LIKE 'claude-fable%' GROUP BY 1,2)
SELECT host, period, count(*) sessions, round(approx_percentile_cont(peak,0.5)/1000) p50_peak_k,
       round(max(peak)/1000) max_peak_k, count(*) FILTER (WHERE peak>200000) over_200k,
       round(sum(cost),2) cost, round(avg(calls)) avg_calls
FROM s GROUP BY 1,2 ORDER BY 1,2 LIMIT 10;
```

## Tools

```sql
-- leaderboard: popularity, errors, latency, wall time, context injected
SELECT attributes->>'gen_ai.tool.name' tool, count(*) calls,
       count(DISTINCT attributes->>'pi.session.id') sess,
       round(100.0*count(*) FILTER (WHERE attributes->>'pi.tool.is_error'='true')/count(*)) err_pct,
       round(approx_percentile_cont(duration,0.5),1) p50_s, round(approx_percentile_cont(duration,0.95),1) p95_s,
       round(sum(duration)/60) total_min,
       round(sum(length(attributes->>'pi.tool.output'))/4000.0) out_ktok,
       round(avg(length(attributes->>'pi.tool.output'))/4) avg_out_tok
FROM records WHERE span_name LIKE 'execute_tool %' GROUP BY 1 HAVING count(*)>=9 ORDER BY calls DESC LIMIT 40;

-- error messages grouped
SELECT attributes->>'gen_ai.tool.name' tool, substr(attributes->>'pi.tool.output',1,110) err_head, count(*) n
FROM records WHERE span_name LIKE 'execute_tool %' AND attributes->>'pi.tool.is_error'='true'
GROUP BY 1,2 ORDER BY n DESC LIMIT 25;

-- bash command heads (cd-prefix stripped)
WITH b AS (SELECT regexp_replace(trim(attributes->'pi.tool.input'->>'command'),'^cd [^&;|]+(&&|;)\s*','') cmd,
  duration d, attributes->>'pi.tool.is_error'='true' err, length(attributes->>'pi.tool.output') out
  FROM records WHERE span_name='execute_tool bash')
SELECT regexp_match(cmd,'^\(?([A-Za-z0-9_./-]+)')[1] head, count(*) n,
       round(100.0*count(*) FILTER (WHERE err)/count(*)) err_pct,
       round(approx_percentile_cont(d,0.5),1) p50_s, round(sum(d)/60) total_min, round(avg(out)/4) avg_out_tok
FROM b GROUP BY 1 ORDER BY n DESC LIMIT 45;

-- bash nav targets: repo vs installed pkgs vs ~/.config; sed print vs edit
WITH b AS (SELECT regexp_replace(trim(attributes->'pi.tool.input'->>'command'),'^cd [^&;|]+(&&|;)\s*','') cmd
  FROM records WHERE span_name='execute_tool bash'),
c AS (SELECT cmd, regexp_match(cmd,'^\(?([A-Za-z0-9_./-]+)')[1] head FROM b)
SELECT head, CASE WHEN head='sed' AND cmd LIKE '%sed -i%' THEN 'in-place edit' WHEN head='sed' THEN 'print range'
  WHEN cmd LIKE '%node_modules%' OR cmd LIKE '%site-packages%' OR cmd LIKE '%.local/share%' THEN 'installed pkg'
  WHEN cmd LIKE '%/.config/%' THEN 'dotconfig' WHEN cmd LIKE '%/tmp/%' THEN 'tmp' ELSE 'repo/other' END kind, count(*) n
FROM c WHERE head IN ('sed','grep','cat','ls','head','find') GROUP BY 1,2 ORDER BY head, n DESC LIMIT 30;

-- cd target vs cwd
SELECT CASE WHEN regexp_match(attributes->'pi.tool.input'->>'command','^cd ([^ &;]+)')[1] = attributes->>'pi.cwd' THEN 'same_as_cwd'
  WHEN regexp_match(attributes->'pi.tool.input'->>'command','^cd ([^ &;]+)')[1] LIKE attributes->>'pi.cwd'||'%' THEN 'subdir_of_cwd'
  ELSE 'elsewhere' END target, count(*) n, count(DISTINCT attributes->>'pi.session.id') sessions
FROM records WHERE span_name='execute_tool bash' AND attributes->'pi.tool.input'->>'command' LIKE 'cd %' GROUP BY 1 LIMIT 10;

-- bash-nav share per model/host (tool availability vs steering)
WITH m AS (SELECT attributes->>'pi.session.id' sid, min(attributes->>'gen_ai.request.model') model
  FROM records WHERE span_name LIKE 'chat %' GROUP BY 1),
t AS (SELECT attributes->>'pi.session.id' sid,
  CASE WHEN attributes->>'pi.cwd' LIKE '/Users/%' THEN 'mac' ELSE 'omarchy' END host,
  attributes->>'gen_ai.tool.name' tool,
  regexp_match(regexp_replace(trim(attributes->'pi.tool.input'->>'command'),'^cd [^&;|]+(&&|;)\s*',''),'^\(?([A-Za-z0-9_./-]+)')[1] bcmd
  FROM records WHERE span_name LIKE 'execute_tool %')
SELECT m.model, t.host, count(DISTINCT t.sid) sess, count(*) tool_calls,
  count(*) FILTER (WHERE tool='bash') bash,
  count(*) FILTER (WHERE tool='bash' AND bcmd IN ('grep','cat','ls','head','find','rg','tail','wc','sed')) bash_nav_edit,
  count(*) FILTER (WHERE tool IN ('read','grep','find','ls','readSeek_grep','readSeek_def','readSeek_refs','readSeek_search','edit','write')) proper
FROM t JOIN m USING (sid) GROUP BY 1,2 ORDER BY tool_calls DESC LIMIT 12;

-- daily trend of the same
WITH t AS (SELECT date_trunc('day',start_timestamp) day, attributes->>'gen_ai.tool.name' tool,
  regexp_match(regexp_replace(trim(attributes->'pi.tool.input'->>'command'),'^cd [^&;|]+(&&|;)\s*',''),'^\(?([A-Za-z0-9_./-]+)')[1] bcmd
  FROM records WHERE span_name LIKE 'execute_tool %')
SELECT day, count(*) FILTER (WHERE tool='bash' AND bcmd IN ('grep','cat','ls','head','find','rg','tail','wc')) bash_nav,
  count(*) FILTER (WHERE tool='bash' AND bcmd IN ('sed','perl','awk')) bash_edit, count(*) FILTER (WHERE tool='bash') bash_all,
  count(*) FILTER (WHERE tool IN ('read','grep','find','ls','readSeek_grep','readSeek_def','readSeek_refs','readSeek_search')) nav_tools,
  count(*) FILTER (WHERE tool IN ('edit','write')) edit_tools,
  count(*) FILTER (WHERE tool LIKE 'repowise%' OR tool LIKE 'cymbal%') smart_tools,
  count(*) FILTER (WHERE tool='subagents_run') delegated, count(*) total
FROM t GROUP BY 1 ORDER BY 1 LIMIT 20;

-- skill loads (SKILL.md reads), excluding bulk-recon sessions
WITH s AS (SELECT attributes->>'pi.session.id' sid, regexp_match(attributes->'pi.tool.input'->>'path','([^/]+)/SKILL\.md')[1] skill
  FROM records WHERE span_name='execute_tool read' AND attributes->'pi.tool.input'->>'path' LIKE '%SKILL.md'),
bulk AS (SELECT sid FROM s GROUP BY sid HAVING count(*)>5)
SELECT skill, count(*) loads, count(DISTINCT sid) sessions FROM s WHERE sid NOT IN (SELECT sid FROM bulk)
GROUP BY 1 ORDER BY loads DESC LIMIT 40;

-- subagent roles dispatched
SELECT attributes->'pi.tool.input'->>'role' role, count(*) n, count(DISTINCT attributes->>'pi.session.id') sessions
FROM records WHERE span_name='execute_tool subagents_run' GROUP BY 1 ORDER BY n DESC LIMIT 20;
```

## Context lifecycle (context-events.ts, from 2026-09-16 21:45Z)

```sql
SELECT span_name, attributes->>'pi.compaction.reason' reason,
       attributes->>'pi.compaction.tokens_before' tok_before, attributes->>'pi.context.tokens' ctx_tok,
       attributes->>'pi.om.items' om_items, attributes->>'gen_ai.request.model' model, attributes->>'pi.session.id' sid
FROM records WHERE span_name LIKE 'pi.context.%' ORDER BY start_timestamp DESC LIMIT 50;
```

## Steering guards (punk-steering v2, from 2026-09-16 23:20Z)

```sql
SELECT span_name, attributes->>'pi.steering.rule' rule, attributes->>'pi.steering.enforced' enforced,
       attributes->>'pi.steering.subagent' subagent, count(*) n,
       count(DISTINCT attributes->>'pi.session.id') sessions
FROM records WHERE span_name LIKE 'pi.steering.%' GROUP BY 1,2,3,4 ORDER BY n DESC LIMIT 20;

-- false-positive review: what got flagged
SELECT attributes->>'pi.steering.pattern' pattern, attributes->>'pi.steering.segment' segment, count(*) n
FROM records WHERE span_name = 'pi.steering.violation' GROUP BY 1,2 ORDER BY n DESC LIMIT 60;
```
