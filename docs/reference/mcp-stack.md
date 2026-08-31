# MCP Stack

Remote MCP servers, lazy-loaded through `pi-mcp-adapter`, replacing composio + per-service CLIs. Linear: KUB-18 (proxy/shared config), KUB-19 (gmail/gcal), both under project “Setup modern mcp tools”.

## Servers (`config/custom/pi/agent/mcp.json`)

| Server | Endpoint | Auth | Lifecycle |
|---|---|---|---|
| logfire | `https://logfire-eu.pydantic.dev/mcp` | token | lazy |
| notion | `https://mcp.notion.com/mcp` | OAuth (localhost cb) | lazy |
| linear | `https://mcp.linear.app/mcp` | OAuth 2.1 + DCR | lazy |
| exa | `https://mcp.exa.ai/mcp` | keyless free tier; on 429 add `headers: { "x-api-key": ... }` | lazy |
| firecrawl | `https://mcp.firecrawl.dev/v2/mcp-oauth` | OAuth sign-in (key variant: `/v2/mcp` + `Authorization: Bearer`) | lazy |
| slack | `https://mcp.slack.com/mcp` | pre-registered internal Slack app (no DCR): `oauth.clientId` + `clientSecret` via `!op read`, exact `redirectUri`, **`authorizationParams.user_scope`** (comma-separated — Slack ignores standard `scope`) | lazy |
| gmail | `https://gmailmcp.googleapis.com/mcp/v1` | pre-registered Google OAuth client needed (no DCR) — pending, KUB-19 | lazy |
| calendar | `https://calendarmcp.googleapis.com/mcp/v1` | pre-registered Google OAuth client needed (no DCR) — pending, KUB-19 | lazy |
| newrelic | `https://mcp.eu.newrelic.com/mcp/` (EU; US: `mcp.newrelic.com`) | OAuth (DCR works); NRAK `api-key` header alternative | lazy |
| context7 | `https://mcp.context7.com/mcp/oauth` | OAuth (DCR works); Bearer-key variant at `/mcp` | lazy |

Config is dotter-symlinked; adapter reads at startup — run `/reload` in pi after edits. OAuth: `/mcp-auth <server>` or `mcp({ action: "auth-start", server })`.

Work network constraint: custom OAuth apps blocked, localhost redirect whitelisted. Remote MCP OAuth (client flow, localhost callback) fits; composio's hosted OAuth did not — that's why Notion/Linear never went through composio.

## Why this shape

Code-mode + lazy discovery: `mcp({ search })` / `describe` / `mcpScript` keep tool schemas out of context until needed (Anthropic "Code execution with MCP", Cloudflare Code Mode, MCP SEP-2636). One gateway tool instead of 10k+ tokens of tool definitions per server.

## Validation (2026-08-31)

- All 5 servers connected via `/mcp-auth`; OAuth localhost callback passes work network policy.
- 206 tools total (notion 41, linear 67, firecrawl 26, exa 3, logfire 69) — none loaded upfront; `mcp({ search })` + `describe` on demand.
- `mcpScript` batch validated: notion-search + linear_list_issues + linear_get_issue in one round trip.
- Context cost vs skills: `notion` skill ≈ 1.7k tokens + `linear-cli` skill ≈ 2.5k tokens loaded per triggering session, plus verbose CLI output per op. MCP route: fixed gateway tool (already present), ~0.3–0.7k per search, schemas on demand. Conventional (non-lazy) MCP client would pay ~30–50k tokens upfront for the same 137 remote tool schemas.

## Slack (working since 2026-08-31)

Slack MCP requires a **pre-registered internal Slack app** (no DCR). Working recipe, validated end-to-end:

1. Internal app with MCP enabled (Agents & AI Apps → "Slack MCP Server" toggle, or manifest `settings.is_mcp_enabled`), user-token scopes, redirect `http://localhost:3118/callback`. PKCE opt-in NOT needed (irreversible — avoid).
2. Adapter config: `auth: "oauth"` + `oauth.clientId/clientSecret/redirectUri` **plus `authorizationParams.user_scope`** with comma-separated scopes — Slack's `v2_user/authorize` ignores the standard `scope` param ("Invalid permissions requested / No scopes requested" otherwise).
3. No workspace admin approval was required (self-serve internal app + user OAuth).

Settings gotcha: the "MCP servers" tab in app settings is the *opposite* feature (Slackbot-as-client) — ignore it. Full research trail: `docs/.scratch/research-mcp-non-dcr-oauth.md`.

## Composio removal — COMPLETE (2026-08-31, KUB-22)

Composio fully removed. Every service migrated to direct remote MCP servers (see table above); gmail/gcal have no route until KUB-19 (explicitly acceptable).

Removed: opencode `prefer-composio-web.ts` plugin; composio branches in claude `prefer-web-tools.py` hook (Glob/Grep→chunkhound nudge kept); zsh `COMPOSIO_INSTALL_DIR`/PATH; `skill-gate.json` entry; composio prose in `comms` role, both `linear-agent-workflow` skills, `piewf-role-config.md`, CLAUDE.md rules; `~/.agents/skills/composio-cli/`; `~/.composio/`.

## Roles

`comms` and `researcher` roles use the pi MCP adapter directly (linear/notion/slack/exa/firecrawl via mcp/mcpScript tools); no CLI-skill selectors remain.
