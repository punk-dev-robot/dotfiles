# MCP Stack

Remote MCP servers, lazy-loaded through `pi-mcp-adapter`, replacing composio + per-service CLIs. Linear: KUB-18 (proxy/shared config), KUB-19 (gmail/gcal), both under project “Setup modern mcp tools”.

## Servers (`config/custom/pi/agent/mcp.json`)

| Server | Endpoint | Auth | Lifecycle |
|---|---|---|---|
| logfire | `https://logfire-eu.pydantic.dev/mcp` | token | eager |
| notion | `https://mcp.notion.com/mcp` | OAuth (localhost cb) | lazy |
| linear | `https://mcp.linear.app/mcp` | OAuth 2.1 + DCR | lazy |
| exa | `https://mcp.exa.ai/mcp` | keyless free tier; on 429 add `headers: { "x-api-key": ... }` | lazy |
| firecrawl | `https://mcp.firecrawl.dev/v2/mcp-oauth` | OAuth sign-in (key variant: `/v2/mcp` + `Authorization: Bearer`) | lazy |

Config is dotter-symlinked; adapter reads at startup — run `/reload` in pi after edits. OAuth: `/mcp-auth <server>` or `mcp({ action: "auth-start", server })`.

Work network constraint: custom OAuth apps blocked, localhost redirect whitelisted. Remote MCP OAuth (client flow, localhost callback) fits; composio's hosted OAuth did not — that's why Notion/Linear never went through composio.

## Why this shape

Code-mode + lazy discovery: `mcp({ search })` / `describe` / `mcpScript` keep tool schemas out of context until needed (Anthropic "Code execution with MCP", Cloudflare Code Mode, MCP SEP-2636). One gateway tool instead of 10k+ tokens of tool definitions per server.

## Validation (2026-08-31)

- All 5 servers connected via `/mcp-auth`; OAuth localhost callback passes work network policy.
- 206 tools total (notion 41, linear 67, firecrawl 26, exa 3, logfire 69) — none loaded upfront; `mcp({ search })` + `describe` on demand.
- `mcpScript` batch validated: notion-search + linear_list_issues + linear_get_issue in one round trip.
- Context cost vs skills: `notion` skill ≈ 1.7k tokens + `linear-cli` skill ≈ 2.5k tokens loaded per triggering session, plus verbose CLI output per op. MCP route: fixed gateway tool (already present), ~0.3–0.7k per search, schemas on demand. Conventional (non-lazy) MCP client would pay ~30–50k tokens upfront for the same 137 remote tool schemas.

## Slack (investigated, deferred)

Slack MCP server requires the MCP client to be backed by a **registered Slack app with a fixed app ID**; only directory-published or internal apps may use MCP; workspace admins approve via the standard app-approval process. OAuth: `https://slack.com/oauth/v2_user/authorize` / `oauth.v2.user.access`. Generic clients (pi adapter, gateways) cannot just connect — needs an internal Slack app + work admin approval. Until then: composio slack.

## Composio removal checklist

Blocked on: slack (needs internal Slack app), gmail/gcal (KUB-19), new relic (no MCP found yet).

When coverage complete, remove:

- [ ] `config/shared/opencode/plugins/prefer-composio-web.ts`
- [ ] `config/shared/claude/hooks/prefer-web-tools.py` (composio branches)
- [ ] `config/custom/zsh/rc.d/062-dev.zsh:57-59` (COMPOSIO_INSTALL_DIR + PATH)
- [ ] `config/custom/pi/agent/config/skill-gate.json` `composio-cli` entry
- [ ] `config/custom/pi/agent/pi-extensible-workflows/roles/comms.md` (skills list + Slack-via-composio prose → Slack MCP or drop)
- [ ] `config/custom/pi/agent/pi-extensible-workflows/roles/researcher.md` (skills list + exa/firecrawl-via-composio prose → exa/firecrawl MCP)
- [ ] `config/shared/{opencode,claude}/skills/linear-agent-workflow/SKILL.md` composio mentions
- [ ] `docs/reference/piewf-role-config.md` composio mentions
- [ ] `~/.agents/skills/composio-cli/` installed skill
- [ ] `~/.composio/` install dir
- [ ] `config/shared/claude/CLAUDE.md` residual composio rule (line ~58)

Already done: CLAUDE.md external-services rules point at MCP first; exa/firecrawl composio routing removed.

## Roles migration note

`comms` and `researcher` roles run as subagents — they get the same pi MCP adapter, so once OAuth is done they can use notion/linear/exa/firecrawl MCP directly; update their skill selectors and prose then.
