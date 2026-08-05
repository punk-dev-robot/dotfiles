# pi Langfuse dashboard widgets

Reproducible source of truth for the coding-agent dashboard widgets, created/updated via
the Langfuse "unstable dashboard widgets" API. `widgets.json` is the array of widget
payloads (each has `id` — the live widget id — and `key` for local reference; strip
both before POSTing a *new* widget, `key` is never part of the API schema and `id` is
assigned by the server).

## What each widget answers

KPI numbers:

| key | question |
|---|---|
| `spend` | Total spend in the period. |
| `cache-hit-rate` | Average cache hit ratio across models. |
| `tool-success-rate` | Share of tool calls that succeeded. |
| `tool-calls` | Total tool calls in the period. |
| `context-compactions` | How often context ran out and had to compact. |

Trend:

| key | question |
|---|---|
| `cache-hit-rate-over-time` | Is cache efficiency degrading over time? |

Composition / breakdowns:

| key | question |
|---|---|
| `tool-calls-by-category` | What is the agent doing over time (tool category, over time)? |
| `bash-command-breakdown` | Where does shell time go (bash command category)? |
| `skill-usage` | Which skills actually get loaded? |
| `subagent-usage` | Which subagents do the work? |
| `tool-latency-p95` | Which tools are slowest (p95 latency)? |
| `tool-errors-by-tool` | Which tools fail, and how often (tool x outcome)? |
| `cost-by-model-over-time` | What am I spending, and on which model, over time? |
| `ttft-p95-by-model` | How fast does each model start replying (p95 TTFT)? |
| `cache-hit-ratio-by-model` | Is prompt caching working, per model? |
| `nudge-ab-tool-success-rate` | Did an AGENTS.md/instruction change move tool success rate? (`traceRelease` = 8-char hash of instruction files) |
| `nudge-ab-turn-count` | Did an AGENTS.md/instruction change move turn count? |

## Suggested dashboard layout

- Row 1: the 5 KPI `NUMBER` widgets.
- Row 2: the trend widget (`cache-hit-rate-over-time`) plus other time-series widgets
  (`tool-calls-by-category`, `cost-by-model-over-time`).
- Row 3+: composition/breakdown bars and pies (skills, subagents, latency, errors,
  nudge A/B).

## Grid placement is manual

The create endpoint only creates the widget object; it cannot place it on a dashboard
grid. After creating/updating, open Langfuse → Dashboards → your dashboard → Add
widget, and pick each `pi ·`-prefixed widget from the list to lay it out.

## Create vs. update

- **New widget** → `POST /api/public/unstable/dashboard-widgets` with the full payload
  (`name`, `description`, `view`, `dimensions`, `metrics`, `filters`, `chartType`,
  `chartConfig`). Strip `id` and `key` first — the server assigns `id`.
- **Existing widget** → `PATCH /api/public/unstable/dashboard-widgets/{widgetId}`.
  Only send the fields you're changing. **Do not touch `query` fields
  (`dimensions`/`metrics`/`filters`/`view`) on an update unless you mean to** — they are
  independently validated and easy to break. If you change `chartType`, always send
  `chartConfig` in the same request: omitting it resets the config to that chart type's
  defaults.

There is no delete/list endpoint on this unstable API surface — remove stray widgets
by hand in the UI.

## Recreate a widget from `widgets.json`

```bash
export LANGFUSE_HOST=... LANGFUSE_PUBLIC_KEY=... LANGFUSE_SECRET_KEY=...
W=config/custom/pi/agent/langfuse-dashboards/widgets.json
jq '.[] | select(.key == "spend") | del(.id, .key)' "$W" | curl -s -X POST \
  "$LANGFUSE_HOST/api/public/unstable/dashboard-widgets" \
  -u "$LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY" \
  -H "Content-Type: application/json" -d @-
```

## Push name/description/chartType changes from `widgets.json`

```bash
jq '.[] | select(.key == "tool-calls-by-category") |
  {name, description, chartType, chartConfig}' "$W" | curl -s -X PATCH \
  "$LANGFUSE_HOST/api/public/unstable/dashboard-widgets/<id>" \
  -u "$LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY" \
  -H "Content-Type: application/json" -d @-
```

## Hard constraints (learned the hard way)

- `metadata` is **filter-only**, never a valid group-by dimension.
- `userId`, `sessionId`, `traceId` are rejected as dimensions.
- Cache-token counts are not exposed as a `metrics` measure on the `observations`
  view, which is why cache-hit ratio is sourced from a `scores-numeric` score
  (`cache_read_ratio`) instead of a token-based metric.
- `view: traces` is not supported by this unstable API; use `observations`,
  `scores-numeric`, or `scores-categorical`.
- `chartConfig.type`, when present, must match the widget's `chartType`.
- Sending `chartConfig.defaultSort` can trigger `"nullable" cannot be used without
  "type"` — omit `defaultSort` rather than fighting it.
- `show_value_labels` is accepted (and applied) on bar charts, but is silently dropped
  by the API on `PIE` widgets — not a bug on our end, nothing to retry.
- There is no `timeDimension` field on the widget object itself; time bucketing for
  `*_TIME_SERIES` chart types is resolved at query/render time from the dashboard's
  date range, not stored on the widget.
- The `langfuse-cli` tool cannot build these requests: `unstable-dashboard-widgets
  create`/`update` only expose scalar body flags. `dimensions`/`metrics`/`filters` are
  required arrays-of-objects with no CLI flag equivalent, so widgets are created/updated
  with raw `curl` (Basic auth: `publicKey:secretKey`) instead — see the commands above.
