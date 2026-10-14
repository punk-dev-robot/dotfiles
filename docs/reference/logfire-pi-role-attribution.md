# Logfire: role attribution for pi OTel data

Mapping from a pi session to the pi-herdsman agent role that ran it. pi-otel (KUB-171 patch)
reads the env herdsman launches each delegated child `pi` with and sets OTel **resource**
attributes:

| resource attr | from env | meaning |
|---|---|---|
| `pi.agent.role` | `PI_HERDSMAN_AGENT_DEFINITION` | agent definition name |
| `pi.agent.label` | `PI_HERDSMAN_LABEL` | per-run label |
| `pi.parent.session.id` | `PI_SUBAGENT_PARENT_SESSION` | delegating session |
| `pi.agent.owner.session.id` | `PI_HERDSMAN_OWNER_SESSION_ID` | owning session |
| `pi.agent.child` | `PI_SUBAGENT_CHILD` | bool |

Unset var → attr absent, so main sessions carry none and fall to `'main'`. Logfire stores resource
attrs in the JSON text column `otel_resource_attributes` (on `records` and `metrics`), **not**
`attributes` (per `query_schema_reference`; pi-otel's existing `pi.cwd` resource attr lands
there). They are on every span/log/metric from process start — no wait for the session-end
`invoke_agent pi` span. CTE syntax-checked live 2026-10-14 via the `logfire-swap` MCP (48h:
all `main`, as expected pre-deploy); role values not yet observed.

**Pre-Herdsman data** (pi-extensible-workflows) has no such attrs. It was attributed by matching
the `Workflow: <name>\nAgent: <role>` prefix of `pi.user_prompt` on the first `invoke_agent pi`
span (recipe in git history of this file, commit `50f83fb`). Under this CTE it reads as `main`.

## The CTE

```sql
WITH session_role AS (
  SELECT attributes->>'pi.session.id' AS sid,
         max(service_instance_id)    AS iid,
         coalesce(max(otel_resource_attributes->>'pi.agent.role'), 'main') AS agent,
         max(otel_resource_attributes->>'pi.agent.label')       AS label,
         max(otel_resource_attributes->>'pi.parent.session.id') AS parent_sid
  FROM records
  WHERE service_name = 'pi' AND attributes->>'pi.session.id' IS NOT NULL
    AND start_timestamp >= now() - interval '14 days'
  GROUP BY attributes->>'pi.session.id'
)
```

Resource attrs are constant per process, so `max()` only collapses rows. Span join key:
`attributes->>'pi.session.id'` (on `chat *`, `execute_tool *`, `pi.turn`, `pi.session.*`);
`gen_ai.conversation.id` holds the same value. Single-table queries can skip the join and read
`coalesce(otel_resource_attributes->>'pi.agent.role', 'main')` off the row.

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

Cost is `pi.cost.usd`, **not** `gen_ai.usage.*`.
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

## Query (c) — metrics: **no session id on data points**

Verified 2026-09-16: across 5907 pi metric points `pi.session.id` appears on **0**; labels are
only `gen_ai.system|tool.name|operation.name|request.model|response.model|token.type`,
`error.type`, and the `service_instance_id` join to spans had zero overlap. Role now rides on the
metric resource, so no join is needed (unproven until herdsman children export metrics):

```sql
SELECT coalesce(m.otel_resource_attributes->>'pi.agent.role', 'main') AS agent,
       m.attributes->>'gen_ai.token.type' AS token_type,
       SUM(metric_sum(m.value)) AS tokens
FROM metrics m
WHERE m.service_name = 'pi' AND m.metric_name = 'gen_ai.client.token.usage'
  AND m.recorded_timestamp >= now() - interval '14 days'
GROUP BY 1, 2 LIMIT 20
```

Per-session metrics remain impossible; prefer span sums (query a) for per-role cost.

## Reuse: no server-side view

No CREATE VIEW / saved-SQL primitive; `saved_searches_ext` stores a WHERE clause, not SQL.
Dashboard panels (`logfire_dashboard_add_panel`) and alerts (`logfire_alert_create`) each embed
full SQL, so the CTE is copy-pasted per panel. Variables (`$var`, multi-select → `= ANY($var)`,
role dropdown via `LogfireQueryListVariable`) substitute values, not SQL. Nothing was created.

## Caveats

- **Needs patched pi-otel.** Stock `npm:pi-otel` sets none of these attrs; everything reads `main`.
- **Leads read as `main`.** Manager's `delegate_project` starts the Lead with `herdr agent start`
  in a fresh worktree pane and passes no `--env`, so no herdsman vars reach it (herdsman
  `startHerdrAgentInPane`). Only agents started via `startHerdrAgent` (delegation) carry them.
- `agent` is the herdsman agent definition name. `gen_ai.agent.name` is always `pi`.
- Pre-Herdsman sessions read as `main` (see note at top).
