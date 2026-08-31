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

## Composio removal checklist

Blocked on: gmail/gcal (KUB-19, needs pre-registered Google OAuth client), new relic (no MCP found yet). Slack: DONE via internal app (KUB-21).

When coverage complete, remove:

- [ ] `config/shared/opencode/plugins/prefer-composio-web.ts`
- [ ] `config/shared/claude/hooks/prefer-web-tools.py` (composio branches)
- [ ] `config/custom/zsh/rc.d/062-dev.zsh:57-59` (COMPOSIO_INSTALL_DIR + PATH)
- [ ] `config/custom/pi/agent/config/skill-gate.json` `composio-cli` entry
- [ ] `config/custom/pi/agent/pi-extensible-workflows/roles/comms.md` — migrated to MCP for Linear/Notion; still `composio-cli` for Slack (KUB-21)
- [x] `config/custom/pi/agent/pi-extensible-workflows/roles/researcher.md` — migrated to MCP (exa/firecrawl/notion)
- [ ] `config/shared/{opencode,claude}/skills/linear-agent-workflow/SKILL.md` composio mentions
- [ ] `docs/reference/piewf-role-config.md` composio mentions
- [ ] `~/.agents/skills/composio-cli/` installed skill
- [ ] `~/.composio/` install dir
- [ ] `config/shared/claude/CLAUDE.md` residual composio rule (line ~58)

Already done: CLAUDE.md external-services rules point at MCP first; exa/firecrawl composio routing removed.

## Roles migration note

`comms` and `researcher` roles run as subagents — they get the same pi MCP adapter, so once OAuth is done they can use notion/linear/exa/firecrawl MCP directly; update their skill selectors and prose then.
