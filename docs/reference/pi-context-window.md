# pi context window, compaction & prompt cache

Tuned in KUB-149 (Sep 2026). Cache-leak follow-up: KUB-153. Full analysis: `docs/.scratch/kub-149-context-window-plan.md` (transient).

## The knobs

| Knob | Where | Ours | Effect |
|---|---|---|---|
| `contextWindow` | pi model catalog / `models.json` `modelOverrides` | Claude Fable 5.1 / Opus 5 / Sonnet 5: 1M (catalog); Codex `gpt-6-astra`: **872000** (override; catalog default 272K is a Codex-family cost default, server `max_context_window` = 872K on our account, probed OK at 691K input) | **Route's real cap, not the working set.** Feeds pi's overflow-net threshold, `maxTokens` clamp (`≤ contextWindow − context − 4096`) and the OM ratio below. Lie upward = 400s once the route rejects (1.05M would); leave it small (272K) and OM compacts every ~49K. Working set is set by the OM ratio and lands at ~200–230K request on both Fable and Astra. |
| `compaction.reserveTokens` | `settings.json` | 64000 | Threshold: compact when `contextTokens > contextWindow − reserve`. Also summarizer budget (`0.8·reserve`, split-turn `0.5·reserve`). With 1M/872K windows this is an overflow net only; OM below is the real trigger. |
| `compaction.keepRecentTokens` | `settings.json` | 40000 | Verbatim suffix kept at compaction. Bigger = fewer split turns. |
| `observational-memory.compactAfterTokensRatio` | `settings.json` | 0.18 | **The real compaction trigger.** `floor(contextWindow × ratio)` *source* tokens since last compaction (excludes system/tools, ~50K). 0.18 × 1M ≈ 180K source ≈ 230K request on Claude; 0.18 × 872K ≈ 157K on Codex. Fires only when idle between turns. |
| `PI_CACHE_RETENTION` | `config/custom/zsh/.zshenv` | `long` | Anthropic `cache_control.ttl: "1h"` (2× write price vs 1.25× for 5m). Right for long-lived orchestrator sessions with >5 min pauses. pi's `$` display assumes 5m pricing → under-reports cacheWrite by ~60%. |

## Who decides what (mental model)

Three knobs, three separate jobs — no shared formula:

- **When** → `compactAfterTokensRatio` (OM). Fires when source tokens since last compaction ≥ ratio × window, only while idle. A single autonomous run can overshoot past it.
- **How much survives** → `keepRecentTokens`. Post-compaction request ≈ system+tools (~50K) + OM summary (10–20K) + 40K verbatim ≈ 100–110K.
- **Overflow net + summarizer ceiling** → `reserveTokens`. Threshold `window − reserve` (936K/808K — should never be reached); `0.8×reserve` caps pi's built-in summarizer, which OM normally replaces.

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
