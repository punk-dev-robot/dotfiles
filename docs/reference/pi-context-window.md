# pi context window, compaction & prompt cache

Tuned in KUB-149 (Sep 2026). Cache-leak follow-up: KUB-153. Full analysis: `docs/.scratch/kub-149-context-window-plan.md` (transient).

## The split policy

Two separate concerns, don't conflate them:

- **`contextWindow`** (pi's working budget for a model) — what pi uses locally for the overflow-net threshold, the `maxTokens` clamp, and (indirectly, via `reserveTokens`) the native overflow point. Set via `config/custom/pi/model-overrides.json` `providers.<id>.modelOverrides` (repo-only, dotter does **not** manage the live, plugin-owned `~/.config/pi/agent/models.json` — see `.dotter/pre_deploy.sh` / `post_deploy.sh`, which merge the overrides into it on every deploy).
- **Route ceiling** (the API's actual accepted input for that model) — a separate, larger number we do not encode in `contextWindow` because lying upward makes pi request past what the route accepts once other knobs push it there. Documented below for reference only.

## The knobs

| Knob | Where | Ours | Effect |
|---|---|---|---|
| `contextWindow` | `config/custom/pi/model-overrides.json` `modelOverrides` (Codex); pi catalog (Anthropic) | Sol `gpt-5.6-sol`: **272000**; Astra `gpt-6-astra`: **400000** (both providers: `openai-codex`, `openai-codex-account-2`); Claude Fable 5.1 / Opus 5 / Sonnet 5: 1M (catalog, unchanged) | Pi's working budget for this model. Feeds the overflow-net threshold (`contextWindow − reserve`) and the `maxTokens` clamp. **Not** the route's real cap — see route ceilings below. |
| `compaction.reserveTokens` | `settings.json` | 64000 (unchanged) | Threshold: compact when `contextTokens > contextWindow − reserve`. Also summarizer budget (`0.8·reserve`, split-turn `0.5·reserve`). Native overflow point per model: Sol 208K, Astra 336K, Anthropic 936K — overflow net only, OM below is the real trigger. |
| `compaction.keepRecentTokens` | `settings.json` | 40000 (unchanged) | Verbatim suffix kept at compaction. Bigger = fewer split turns. |
| `observational-memory.compactAfterTokens` / `compactAfterTokensMode` | `settings.json` | `180000` / `"calibrated"` | **The real compaction trigger**, now one global, calibrated source-token threshold instead of `contextWindow × ratio` — same 180K trip point regardless of model/window. Fires once ~180K source tokens (excludes system/tools, ~50K) have accumulated since last compaction, only while idle between turns. The old `compactAfterTokensRatio` (0.18) is unused and removed. |
| `pi-multi-account` guard backstop | plugin-internal (unchanged) | 190400 (Sol) / 280000 (Astra + Anthropic) | Independent safety net inside pi-multi-account that stops a request before the route would reject it. Threshold = `0.7 × min(contextWindow, 400K)` — derived from `contextWindow`, independent only of the OM trigger. |
| `PI_CACHE_RETENTION` | `config/custom/zsh/.zshenv` | `long` | Anthropic `cache_control.ttl: "1h"` (2× write price vs 1.25× for 5m). Right for long-lived orchestrator sessions with >5 min pauses. pi's `$` display assumes 5m pricing → under-reports cacheWrite by ~60%. |

## Route ceilings (separate from `contextWindow`)

What the API actually accepts, independent of what we tell pi locally. Not wired into any knob above; kept here so a future bump has a reference point.

- Anthropic: 1M catalog value observed as the practical max.
- Astra (`gpt-6-astra`): 872000 observed max on our account (`max_context_window`); 691000 input tested OK.
- Sol (`gpt-5.6-sol`): untested beyond the 272000 catalog default.

## Who decides what (mental model)

Three knobs, three separate jobs — no shared formula:

- **When** → `compactAfterTokens` (OM, calibrated). Fires when source tokens since last compaction ≥ 180K, only while idle. A single autonomous run can overshoot past it.
- **How much survives** → `keepRecentTokens`. Post-compaction request ≈ system+tools (~50K) + OM summary (10–20K) + 40K verbatim ≈ 100–110K.
- **Overflow net + summarizer ceiling** → `reserveTokens`. Threshold `window − reserve` (208K/336K/936K per model — should never be reached); `0.8×reserve` caps pi's built-in summarizer, which OM normally replaces.

Steady state on a long session: oscillates ~105K ↔ ~230K; the 150K nudge fires mid-cycle. System+tools prefix stays cache-hot across compaction; the summary onward is one ~60K cache write.

Extensions: **pi-observational-memory** is the mechanism (supplies the summary via `session_before_compact`, inherits pi's `keepRecentTokens` cut). **pi-recap** is orthogonal — stored via `appendEntry`, never in LLM context, no compaction.

Target: **never reach 270K** on Claude. `context-nudge.ts` (extension) warns once at 150K: prefer `/punk-handoff` at a semantic boundary over a compaction summary when the goal is shifting anyway.

## Anthropic prompt-cache rules that bite

- Exact prefix `tools → system → messages`. **Any tool-definition change invalidates everything** — lazy MCP servers connecting mid-session count.
- Thinking config / effort are rendered into the prompt: changing thinking level mid-session kills the messages cache. Model switch = full re-write (model is in the key). Fork a new session instead.
- Plan mode (plannotator), caveman level, recap — system-prompt changes → `cacheRead: 0` next turn. Batch at boundaries.
- `thinking_dropped` / `prefix_binding_mismatch` (pi diagnostic): Anthropic dropped a signed thinking block because the prefix changed → cache dies from that message onward, and tends to persist turn after turn (`cacheRead` plateaus at system+tools size). ~90% of our mid-session cache waste. → KUB-153.
- Min cacheable prefix: 512 tok (Fable/Opus 5), 1024 (Sonnet 5). Below → silent no-cache.
- Hits refresh TTL for free; TTL clock starts at request *start*.

## Measuring

Logfire project `coding-agent` (pi-otel; MCP route `localhost:3000/logfire` via agentgateway, all hosts).

```sql
-- miss turns + waste per model (records table, 14d max range)
SELECT attributes->>'gen_ai.request.model' AS model, count(*) AS turns,
  sum((attributes->>'gen_ai.usage.cache_write_input_tokens')::bigint) AS cache_write,
  sum(CASE WHEN (attributes->>'gen_ai.usage.cache_write_input_tokens')::bigint > 20000 THEN 1 ELSE 0 END) AS miss_turns,
  sum(CASE WHEN (attributes->>'pi.anthropic.thinking_dropped')::int > 0 THEN 1 ELSE 0 END) AS thinking_dropped_turns
FROM records WHERE attributes->>'gen_ai.usage.cache_read_input_tokens' IS NOT NULL
GROUP BY 1 ORDER BY cache_write DESC
```

Offline fallback over `~/.pi/agent/sessions`: `pi-cache-audit [days]` (`local/bin`). Baseline 2026-09-15 (5d): 68% of cacheWrite in miss turns, `thinking_dropped` 132 turns / $283 real; 8 sessions > 270K; 1 compaction.

Codex pricing note: our enterprise rate card exempts Astra-in-Codex from the >272K multiplier and doesn't bill cache writes — pi's `openai-codex` `tiers` block over-estimates. Upstream fix pending.

Blog that started it: workos.com/blog/coding-agent-context-window-compaction-settings — mechanics verified exact against pi 0.85.1; its `320000/64000` numbers are OpenAI-272K-tier specific, don't copy.
