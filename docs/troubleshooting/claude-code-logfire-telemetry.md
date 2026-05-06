# Claude Code → Logfire Telemetry: Agents Tab Empty

Tracking Claude Code sessions in Pydantic Logfire was set up using two surfaces in succession, and neither populated the Logfire **Agents** tab. This page captures the bug chain, the spec gap, and the working setup.

## Problem

- Claude Code sessions sent traces to Logfire via the official plugin `pydantic/claude-code-logfire-plugin`, but the Logfire **Agents** tab stayed empty.
- After switching to Claude Code's native OpenTelemetry export (`CLAUDE_CODE_ENABLE_TELEMETRY=1` + `OTEL_*`), traces stopped flowing entirely.

## Root Causes

There are three independent issues stacked on top of each other.

### 1. Logfire Agents tab keys off OTel GenAI semconv only

Logfire's **Agents** tab discovers spans via the OpenTelemetry GenAI semantic conventions:

- `gen_ai.agent.name` (required)
- `gen_ai.operation.name = "invoke_agent"` (or `"chat"` for sub-spans)
- Span name like `invoke_agent <agent>` or `chat <model>`

If a span lacks these, the tab does not list the run regardless of what the rest of the trace looks like.

Reference: [OpenTelemetry GenAI agent span semconv](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/).

### 2. The Logfire plugin emits flat `chat <model>` spans, not agent spans

`pydantic/claude-code-logfire-plugin` v0.4.2 produces:

- A pending root span `Claude Code session` (closed at `SessionEnd`).
- One `chat <model>` child span per Anthropic API call, with `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.*`.
- **No `gen_ai.agent.name`. No `invoke_agent` operation.** No agent grouping.

So plugin output is correct OTel telemetry but never matches the Agents-tab discovery rules. Spans show up in Logfire's **Live** / **Explore** views, not in **Agents**.

There is currently no GitHub issue requesting agent-span emission on the plugin repo (only 2 issues total — both unrelated).

### 3. Claude Code's own native OTel is broken in 2.1.113+ (silent no-op)

Anthropic ships Claude Code as a Bun-compiled single-file binary. Since v2.1.113 that bundle ships only `@opentelemetry/api` plus the **console** exporter — the OTLP exporter packages are not bundled. The runtime `require()` for them fails silently:

- The OTel SDK initializes; spans/metrics accumulate in memory.
- The console exporter works.
- Every OTLP destination (`http/protobuf`, `http/json`, `grpc`) silently drops everything.
- No error surfaces in `~/.config/claude/debug/<session>.txt`.

Tracking issue: [`anthropics/claude-code#50567`](https://github.com/anthropics/claude-code/issues/50567). Multi-tenant Datadog evidence in the thread shows zero sessions emitted from any version 2.1.119–2.1.126. Status as of 2026-05-06: still open, not fixed in latest 2.1.129.

Last working version for native OTel: **2.1.118**.

### 4. Even when native OTel works, span names are still proprietary

When native OTel does ship spans, the names are `claude_code.interaction`, `claude_code.llm_request`, `claude_code.tool`, `claude_code.tool.execution`, `claude_code.hook` — not `invoke_agent` / `chat`. Token usage is exported as `input_tokens` / `output_tokens` instead of the spec's `gen_ai.usage.input_tokens` / `gen_ai.usage.output_tokens`.

Tracking issues for the spec gap:

- [`anthropics/claude-code#50776`](https://github.com/anthropics/claude-code/issues/50776) — non-standard token attrs on `claude_code.llm_request`.
- [`anthropics/claude-code#53954`](https://github.com/anthropics/claude-code/issues/53954) — Agent SDK / ACP path only emits `llm_request`, missing `interaction` / `tool` parents.
- No issue yet asking for `gen_ai.agent.name` + `invoke_agent` span emission so Agents-tab UIs (Logfire, LangSmith, Honeycomb LLM panels) populate. Filing one would help.

## Why Anthropic Docs Sound Compliant But Agents Tab Stays Empty

`code.claude.com/docs/en/monitoring-usage` reads like Claude Code is fully OTel-compatible — `CLAUDE_CODE_ENABLE_TELEMETRY=1`, standard `OTEL_*` env vars, links to the OTel spec. Two different compliance layers are being conflated.

| Layer | Standard | Claude Code 2026 |
| --- | --- | --- |
| **Transport** — OTLP envelope, `OTEL_EXPORTER_OTLP_*` env vars, `OTEL_TRACES_EXPORTER=otlp`, etc. | OTel base spec | ✅ Yes (when bundle bug #50567 lands) |
| **Generic semconv** — `service.name`, `error.type`, span timing attrs | OTel core | ✅ Mostly |
| **GenAI semconv** — `gen_ai.system`, `gen_ai.agent.name`, `gen_ai.operation.name=invoke_agent`, `gen_ai.usage.input_tokens` | OTel GenAI subspec | ❌ No |

What Anthropic actually emits, per the same docs that say "OpenTelemetry compatible":

- Metrics: `claude_code.session.count`, `claude_code.cost.usage`, `claude_code.token.usage`, `claude_code.lines_of_code.count` — all proprietary.
- Spans: `claude_code.interaction`, `claude_code.llm_request`, `claude_code.tool`, `claude_code.tool.execution`, `claude_code.hook` — all proprietary.
- Token attrs: `input_tokens`, `output_tokens` — not `gen_ai.usage.input_tokens` / `gen_ai.usage.output_tokens` per OTel GenAI semconv v1.41.

So:

- **Plug Claude Code into any OTLP-capable backend (Logfire, Datadog, Honeycomb, OTel Collector)** — works at the transport layer once the bundling bug clears. Spans land. Live/Explore views populate.
- **Spans automatically populate AI-aware UIs that need GenAI semconv** — fails until vocabulary lands. Logfire Agents tab, Sentry AI Monitoring, Honeycomb LLM panel agent grouping all key off `gen_ai.*`. Until #50776 (and a future `gen_ai.agent.name` issue someone still needs to file), all of those views stay empty for Claude Code data even with full transport-level export working.

The doc page does enumerate the proprietary metric/span names — they just aren't flagged as deviations from the GenAI semconv. The link to the OTel spec is about env vars and transport, not vocabulary.

## Current Posture: Inert Native OTel, Wait for Upstream Fix

After evaluating the alternatives below, the configuration on this machine is set up so that **native** OTel is fully wired but currently produces no traffic, because of the bundling regression in `anthropics/claude-code#50567`. When Anthropic ships a fix and Claude Code is upgraded, telemetry resumes automatically with no further changes.

What is in place:

- `dotfiles/config/claude/settings.json` — `otelHeadersHelper` + the full native OTel env block (`CLAUDE_CODE_ENABLE_TELEMETRY`, `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA`, `OTEL_TRACES_EXPORTER`, `OTEL_LOGS_EXPORTER`, `OTEL_METRICS_EXPORTER`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_EXPORTER_OTLP_ENDPOINT=https://logfire-eu.pydantic.dev`, `OTEL_SERVICE_NAME=claude-code`, `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_DETAILS`, `OTEL_LOG_TOOL_CONTENT`).
- `dotfiles/local/bin/claude-otel-headers` — small helper that prints `Authorization=$LOGFIRE_TOKEN`. Dotter-managed symlink at `~/.local/bin/claude-otel-headers`.
- `~/.config/claude/secrets.env` — `LOGFIRE_TOKEN=op://AI/Swap-Logfire-Token/password`. Resolved at process start by `op run` (the `cld` wrapper), then read by the helper.
- `cld()` in `dotfiles/config/zsh/rc.d/090-aliases.zsh` — plain `claude` (not `claudia`), wrapped in `op run` + `script -q /dev/null` PTY workaround.
- Plugin (`logfire-session-capture@pydantic-claude-code-logfire-plugin`) is **disabled** (`false` in `enabledPlugins`).

What that means in practice:

- Until #50567 is fixed and the local `claude` is upgraded into a working version, **no spans flow to Logfire** — accepted trade-off so the dotfiles stop oscillating between half-working states.
- When the fix lands, traces will start appearing in Logfire under `service_name = 'claude-code'` automatically. They will be `claude_code.*` spans, **not** `gen_ai.*` semconv, so they show in **Live** / **Explore** but **not** in the **Agents** tab until #50776 / equivalent lands. That second gap is acknowledged and tracked, not fixed here.

### Tried and rejected: claudia (`TechNickAI/claude_telemetry`)

The `claudia` CLI looked promising — its README sells it as a "thin wrapper around the Claude CLI". Installed via `uv tool install --with logfire claude_telemetry`, the `cld()` wrapper was switched to call `claudia` instead of `claude`. Telemetry **did** flow to Logfire with proper `gen_ai.agent.name` populated, so the Agents tab would have populated.

It was rolled back because it is **not** a thin wrapper:

- It runs the `claude-agent-sdk` Python SDK directly, **not** the Claude Code CLI binary.
- It rejects unknown flags (`cld -c` died with `error: unknown option '--c'`).
- It replaces the Claude Code TUI with its own minimal `Claudia Interactive Mode` panel — losing the full TUI, slash commands, the configured MCP server set, hooks, the permission model, and the rest of Claude Code's interactive surface.

If a future setup ever needs Logfire Agents-tab visibility from CI / headless contexts where the Claude Code TUI is irrelevant, `claudia` is fine for that narrow use case — but it is not a replacement for interactive `claude`.

### Verification (when upstream lands)

```sql
SELECT span_name, service_name, start_timestamp
FROM records
WHERE start_timestamp > now() - INTERVAL '5 minutes'
  AND service_name = 'claude-code'
ORDER BY start_timestamp DESC
LIMIT 10
```

Run via the `mcp__logfire__query_run` tool with `project=ac-monorepo-agents`. Expect rows whose `span_name` starts with `claude_code.` once the bundling bug is fixed.

Sanity-check the helper any time:

```bash
LOGFIRE_TOKEN=test ~/.local/bin/claude-otel-headers
# → Authorization=test
```

### Caveats

- Telemetry only flows when launching Claude through `cld`. A bare `claude` invocation gets no telemetry by design — the token never leaves the `op run` scope.
- The `script -q /dev/null` PTY workaround in `cld()` is still in place for [anthropics/claude-code#6820](https://github.com/anthropics/claude-code/issues/6820). Unrelated to OTel.
- `DISABLE_TELEMETRY=1` (already in the env block) opts out of Anthropic's own product analytics. Independent of OTel export — leave it as-is.

## Key Files

- `~/dotfiles/config/zsh/rc.d/090-aliases.zsh` — `cld()` wrapper, swap-point.
- `~/dotfiles/config/claude/settings.json` — env block, plugin enabled-state.
- `~/.config/claude/secrets.env` — `LOGFIRE_TOKEN` 1Password reference.
- `~/.local/bin/claudia` — uv-managed Python wrapper (not in dotfiles; `uv tool install` is the source of truth).

## Upstream Issues to Watch

- [`anthropics/claude-code#50567`](https://github.com/anthropics/claude-code/issues/50567) — OTLP exporter packages not bundled (the bundling bug). Fix here re-enables native OTel.
- [`anthropics/claude-code#50776`](https://github.com/anthropics/claude-code/issues/50776) — non-standard token attrs.
- [`anthropics/claude-code#53954`](https://github.com/anthropics/claude-code/issues/53954) — streaming/Agent SDK path missing parent spans.
- [`anthropics/claude-code#56153`](https://github.com/anthropics/claude-code/issues/56153) — docs gap on `OTEL_*` subprocess inheritance.
- [`open-telemetry/opentelemetry-collector-contrib#46069`](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/46069) — `genainormalizer` collector processor donation. Once merged, a future setup could route Claude Code's native `claude_code.*` spans through a local OTel Collector that maps them to `gen_ai.*` semconv before forwarding to Logfire — bypassing the need for `claudia` if Anthropic fixes the bundling bug but does not adopt semconv.

## Tags

#claude-code #logfire #opentelemetry #observability #pydantic #1password #dotter #solved
