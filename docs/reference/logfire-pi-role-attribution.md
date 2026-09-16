# Logfire: role attribution for pi OTel data

Query-time mapping from a pi session to the subagent role that ran it, from the first-turn prompt
prefix pi-extensible-workflows injects (`Workflow: <name>\nAgent: <role>`). No instrumentation
change. DataFusion dialect: `regexp_match(str, pat)` returns an array — index `[1]`. Validated
live 2026-09-16, 14d window, `service_name = 'pi'`.

## The CTE

```sql
WITH first_agent AS (
  SELECT attributes->>'pi.session.id'  AS sid,
         service_instance_id           AS iid,
         attributes->>'pi.user_prompt' AS prompt,
         row_number() OVER (PARTITION BY attributes->>'pi.session.id'
                            ORDER BY start_timestamp) AS rn
  FROM records
  WHERE service_name = 'pi' AND span_name = 'invoke_agent pi'
    AND start_timestamp >= now() - interval '14 days'
),
session_role AS (
  SELECT sid, iid,
         coalesce(regexp_match(prompt, '^Workflow: [^\n]+\nAgent: ([^\n]+)')[1], 'main') AS agent,
         regexp_match(prompt, '^Workflow: ([^\n]+)\n')[1] AS workflow
  FROM first_agent WHERE rn = 1
)
```

`row_number()` picks the earliest of multiple `invoke_agent pi` spans. Span join key:
`attributes->>'pi.session.id'` (on `chat *`, `execute_tool *`, `pi.turn`, `pi.session.*`);
`gen_ai.conversation.id` holds the same value.

## Resolution stats (14d, live)

| agent | workflow | sessions |
|---|---|---|
| `otel role attribution recon` | subagents | 1 |
| `<unresolved>` | – | 1 |

Only 2 sessions in the window (genai export is days old), no legacy `pi.interaction` /
`pi.tool.*` spans: this validates syntax, not population. The unresolved one failed on absence,
not prompt format — it emitted `pi.session.start`, 10× `pi.turn`, 10× `chat claude-opus-5`,
12× `execute_tool mcp` and **zero `invoke_agent pi`**. That span is emitted once per session
with the final `pi.turn_count` (observed 13 for a 13-turn session), i.e. at session end;
in-flight sessions carry no prompt attribute anywhere to sample.

## Query (a) — cost and tokens per role per day (`chat` spans)

```sql
SELECT date_trunc('day', c.start_timestamp) AS day,
       coalesce(r.agent, '<unresolved>') AS agent,
       count(*) AS calls,
       sum((c.attributes->>'gen_ai.usage.input_tokens')::double)  AS in_tok,
       sum((c.attributes->>'gen_ai.usage.output_tokens')::double) AS out_tok,
       sum((c.attributes->>'gen_ai.usage.cache_read_input_tokens')::double) AS cache_read_tok,
       round(sum((c.attributes->>'pi.cost.usd')::double), 4) AS cost_usd
FROM records c
LEFT JOIN session_role r ON r.sid = c.attributes->>'pi.session.id'
WHERE c.service_name = 'pi' AND c.span_name LIKE 'chat %'
  AND c.start_timestamp >= now() - interval '14 days'
GROUP BY date_trunc('day', c.start_timestamp), coalesce(r.agent, '<unresolved>')
ORDER BY day, cost_usd DESC LIMIT 50
```

Cost is `pi.cost.usd`, **not** `gen_ai.usage.*`. Live: recon 13 calls / $0.5036; unresolved 12 / $0.8704.
## Query (b) — tool calls per role per tool (`execute_tool` spans)

```sql
SELECT coalesce(r.agent, '<unresolved>') AS agent,
       t.attributes->>'gen_ai.tool.name' AS tool,
       count(*) AS calls,
       count(*) FILTER (WHERE t.attributes->>'pi.tool.is_error' = 'true') AS errors,
       round(avg(t.duration), 3) AS avg_s
FROM records t
LEFT JOIN session_role r ON r.sid = t.attributes->>'pi.session.id'
WHERE t.service_name = 'pi' AND t.span_name LIKE 'execute_tool %'
  AND t.start_timestamp >= now() - interval '14 days'
GROUP BY coalesce(r.agent, '<unresolved>'), t.attributes->>'gen_ai.tool.name'
ORDER BY calls DESC LIMIT 50
```

Live: recon → read 8, grep 8, ls 2, write 1, workflow_result 1, 0 errors.
## Query (c) — metrics: **no session id on data points**

Verified: across 5907 pi metric points `pi.session.id` appears on **0**. Labels are only
`gen_ai.system|tool.name|operation.name|request.model|response.model|token.type`, `error.type`;
resource attributes carry no session id either, so the join is not symmetric with spans. Only
bridge: `service_instance_id` (1 per session in records, same pid across sessions). Unproven:

```sql
-- CTE as above, then join on the instance id instead of the session id
SELECT coalesce(ir.agent, '<unresolved>') AS agent,
       m.attributes->>'gen_ai.token.type' AS token_type,
       SUM(metric_sum(m.value)) AS tokens
FROM metrics m
LEFT JOIN session_role ir ON ir.iid = m.service_instance_id
WHERE m.service_name = 'pi' AND m.metric_name = 'gen_ai.client.token.usage'
  AND m.recorded_timestamp >= now() - interval '14 days'
GROUP BY coalesce(ir.agent, '<unresolved>'), m.attributes->>'gen_ai.token.type' LIMIT 20
```

Live: 100% `<unresolved>` (11.5M output / 70.9k input tokens) — zero instance-id overlap between
metric-emitting and trace-emitting processes in this window. Treat metrics as role-blind; use
span sums (query a) for per-role cost.

## Reuse: no server-side view

No CREATE VIEW / saved-SQL primitive; `saved_searches_ext` stores a WHERE clause, not SQL.
Dashboard panels (`logfire_dashboard_add_panel`) and alerts (`logfire_alert_create`) each embed
full SQL, so the CTE is copy-pasted per panel. Variables (`$var`, multi-select → `= ANY($var)`,
role dropdown via `LogfireQueryListVariable`) substitute values, not SQL. Nothing was created.

## Caveats

- **Coupling to piewf prompt format.** Role comes from the literal `Workflow: …\nAgent: …` prefix
  in `pi.user_prompt`; change that prefix and attribution silently degrades to `main`.
- `agent` is the free-text role string passed at launch (`otel role attribution recon` here),
  not an enum — expect ad-hoc values, group loosely. `gen_ai.agent.name` is always `pi`.
- In-flight sessions stay unresolved until `invoke_agent pi` exports at session end.
- Tiny sample: 2 sessions / 677 records. Stats validate syntax, not distribution.
