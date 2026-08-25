# Migrate pi-subagents → pi-extensible-workflows standalone subagents

## Context

Two extensions currently configure the same agents (`recon`, `researcher`, `dev`, `impl`, `reviewer`, `tests`, `comms`; `lead` subagent-only):

- **pi-subagents** (`git:github.com/edxeth/pi-subagents` v2.7.4) — agent defs in `config/custom/pi/agent/agents/`
- **pi-extensible-workflows** (piewf 5.8.0, local dev checkout) — role defs in `config/custom/pi/agent/pi-extensible-workflows/roles/`

Prompt bodies deduped via dotter includes from `config/custom/pi/prompts/`; frontmatter maintained twice. piewf's standalone subagent tools (`subagents_run/inspect/steer/stop/retry`) reuse the same role files → collapse to one surface.

Motivations: single config surface; focus on piewf (user contributes to it); kill the pi-subagents "parent shows idle while child runs" batch-barrier bug machinery.

## Research results

Full briefs: `docs/.scratch/piewf-subagents-research.md` (piewf capabilities, cited to source) and `docs/.scratch/pi-subagents-usage-map.md` (our dependency map).

| Concern | Verdict |
|---|---|
| Role files | Same `AgentDefinition` as workflows; our 7 roles already load clean (no `thinking:`/`disabledAgentResources:` frontmatter — both rejected; thinking goes in `model: provider/model:thinking`, which we do) |
| Nested spawning (`lead`) | **Impossible** — `subagents_*`/`workflow*` are in `EXCLUDED_TOOLS` and the piewf host extension is filtered from child loading. `lead` cannot migrate as a role |
| Roster injection | **None** — only a static tool promptSnippet. Delegation guidance must live in `~/.config/pi/agent/AGENTS.md` |
| Resume with follow-up | **None** — `subagents_retry` = fresh run, new UUID. Follow-ups = new run with re-brief |
| Visible panes | Via `@piewf/herdr` (already installed): `openLiveSession` action in `/subagents`, or `enableFullyInspectableMode` (currently `false`). Otherwise read-only `/subagents` + Trajectory + steering |
| Completion delivery | One steer message with `triggerTurn:true` per background run; **result not embedded** — parent must call `subagents_inspect({id})` |
| Parent idle status | Same idle-parent steady state, but intentional: background widget shows `Subagents (N running)`, notification wakes the parent. pi-subagents' buggy batch-barrier machinery is gone entirely |
| Child result contract (5.8.0) | Every child must call `workflow_result` (injected framing prompt; `RESULT_INVALID` after 2 repair attempts). Prompts written for "final assistant message" need audit |
| Children on parent exit | Aborted on `session_shutdown` (no `parent-close-policy: continue`) — acceptable |
| Concurrency | Setting `concurrency: 8` (max 16), **no queue** — over cap `subagents_run` fails `AGENT_FAILED`, retry after one settles |
| Per-child env | None → reviewer's `PI_SUBAGENT_HERDR_PLACEMENT=tab` has no equivalent and dies with pi-subagents anyway |

## Decisions (user)

1. Background + Trajectory/`/subagents` inspection is acceptable — visible panes were latent capability.
2. **Clean cutover now** — remove pi-subagents entirely (also avoids dual overlapping tool surfaces in `tools.json`).
3. `lead`: nesting impossible → **drop for now**, revisit later as a piewf workflow script (its natural shape).
4. Roster: hand-maintained Delegation section in `~/.config/pi/agent/AGENTS.md` is enough.

## Accepted losses

Visible-terminal-first interactive agents, `subagent_resume` follow-ups, `lead` (temporarily), per-child env, children surviving parent exit, automatic roster.

## Approach

Delete the pi-subagents surface; keep roles + shared prompts exactly as they are (roles already include prompts via dotter). Rewrite delegation guidance around `subagents_run(role:)`. Audit prompts for the `workflow_result` completion contract and role/agent capability parity. Deploy with dotter, verify live.

## Files to modify

| File | Change |
|---|---|
| `config/custom/pi/agent/settings.json:23-24` | Remove both pi-subagents package entries (`git:github.com/edxeth/pi-subagents` + absolute-path twin) |
| `config/custom/pi/agent/agents/` | Delete directory (8 agent defs) |
| `config/custom/pi/agent/tools.json` | Remove `subagent`, `subagent_kill`, `subagent_resume` from allowlist (keep `subagents_*`) |
| `config/custom/pi/agent/AGENTS.md` | Rewrite Delegation section: role list with when-to-use (recon/researcher/dev/impl/reviewer/tests/comms), `subagents_run({role, label, prompt})` usage, on completion-steer call `subagents_inspect({id})` for the result, steer/stop/retry, no-resume (re-brief fresh runs), concurrency 8/no-queue note |
| `.dotter/global.toml:29-31` | Remove `agents` dir mapping; fix comments at `:44` (subagent frontmatter quirk) and `:54` (paired-surface wording) — keep all `pi_model_*`/`pi_think_*`/`pi_tools_*` vars (roles use them) |
| `/Users/kuba.gaj/dotfiles/AGENTS.md` | Rewrite "Pi agents / workflow roles sync" section: single surface (roles include prompts); note `lead` retired pending workflow-script port |
| `docs/reference/piewf-role-config.md` | Update dual-surface doc to single-surface reality |
| `config/custom/pi/prompts/*.md` (7 files) | Audit: remove/adjust any pi-subagents-specific completion instructions ("final message", resume, roster mentions) so they don't fight the injected `workflow_result` framing; keep "write findings to file + return paragraph/path" idioms (they become the `workflow_result` value) |
| `config/custom/pi/agent/pi-extensible-workflows/roles/*.md` | Parity audit vs deleted agents: notably `tests` role grants `{{pi_tools_edit}}` while agents/tests.md **denied** edit/write — decide intended capability; confirm reviewer stays read-only (it does); researcher/comms skills already match |
| `plans/osmani-cleanup.md`-style leftovers | None blocking; `plans/agent-skills-pi.md` is historical, leave |

> [!NOTE]
> `pi-extensible-workflows/settings.json` needs no change (`concurrency: 8`, alias `cheap-model` already set). Optionally flip `extensionSettings.herdr.enableFullyInspectableMode: true` later if live watching is missed — leave `false` for now.

## Steps

- [x] Parity audit — role side equal/richer everywhere; ported `source_check` into researcher role; kept `tests` role's edit tools (agent-side deny contradicted its own test-writing description)
- [x] Prompt audit — one fix: `prompts/reviewer.md` "lead may resume you" → "caller may steer you"
- [x] Removed pi-subagents packages from `settings.json`
- [x] Removed `subagent`/`subagent_kill`/`subagent_resume` from `tools.json`
- [x] Deleted `config/custom/pi/agent/agents/` (git rm, 8 files; `lead.md` in history)
- [x] `.dotter/global.toml`: agents mapping + stale comments removed
- [x] Delegation section rewritten in `config/custom/pi/agent/AGENTS.md` (roles, mechanics, no-resume, concurrency)
- [x] Root `AGENTS.md` sync section → single-surface; `docs/reference/piewf-role-config.md` updated (5.8.0 selector semantics, `disabledAgentResources`/`thinking` removal)
- [x] `dotter -v -d` then deploy — clean (two pre-existing unrelated skips: ccline symlink, gitconfig drift)
- [x] Removed empty `~/.config/pi/agent/agents/` + cached `~/.config/pi/agent/git/github.com/edxeth/` clone

## Verification

- [x] Fresh `pi -p` session: `subagent*` gone, `subagents_*` + `workflow*` present, no startup warnings
- [x] `piewf doctor` (local 5.8.0 CLI — published npm build is broken, `ERR_MODULE_NOT_FOUND` in dist): all 7 roles 0 errors / 0 warnings
- [x] `recon` background run: completion steer arrived, `subagents_inspect` returned value, correct model+tools
- [x] `reviewer` (fable-5:high, live toolset had no write/replace — read-only enforced) + `impl` (file created on disk) — `workflow_result` contract works with our prompts
- [x] Steer accepted mid-run → stop persisted `stopped` → retry gave fresh id → stopped again; durable records under `~/.config/pi/agent/subagents/`
- [x] Parent idle-with-running-children is now the intended state (steers wake it; pi-subagents batch-barrier machinery uninstalled). Widget/Trajectory: user-observable

## Follow-ups (out of scope, upstream contribution candidates)

- Port `lead` as a piewf **workflow script** (native `agent()` nesting, approvals, budgets)
- Upstream: ambient role roster injection option; resume-with-follow-up; docs fix — `docs/subagents.html`/`roles.html` advertise per-call `thinking` that the closed schema rejects (`contracts.ts:26-38`, test asserts throw)
- Evaluate `enableFullyInspectableMode` for Herdr live panes once its lifecycle churn settles
