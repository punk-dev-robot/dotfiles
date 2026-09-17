# Research: repowise Claude Code plugin — what it does, what ports to pi

**Q:** what does the repowise Claude Code plugin do, and what is portable to pi?
**A:** a thin packaging shell (19 slash commands, 6 skills, `.mcp.json`, a 1.1 kB `hooks.json`); all hook intelligence lives in the `repowise-augment` CLI binary. It never blocks — it nudges (skills + a SessionStart line), augments (`additionalContext`, after the tool ran), and optionally replaces (`updatedToolOutput`, opt-in). We already run the augment path in pi.
**Sources:** upstream `plugins/claude-code/` @ `plugin.json` **0.51.0**, repo pinned at commit `9241f3bbe0db91d56e7eebc1c60c25921fd33e13` (2026-09-17) (<https://github.com/repowise-dev/repowise/tree/main/plugins/claude-code>); hook logic read from the installed CLI **0.50.0** at `~/.local/share/uv/tools/repowise/lib/python3.14/site-packages/repowise/cli/commands/augment_cmd/` (python **3.14** — the briefed 3.13 path does not exist) and cross-checked against upstream `packages/cli/src/repowise/cli/commands/augment_cmd/`. **0.50.0 is the binary pi actually invokes**, so the recommendations below target the code that runs; version skew is measured, not assumed (see unknowns).

## 1. Inventory

`hooks/hooks.json` is the entire hook surface — **no scripts**. All three entries are the same one-liner `if command -v repowise-augment >/dev/null 2>&1; then exec repowise-augment; fi`, `timeout: 10`. Logic = `augment_hook.py:main` → `augment_cmd/` (~5.5k LoC, 18 modules). No LLM, no network.

| Event | Matcher | Handler → emits |
|---|---|---|
| SessionStart | `startup\|resume\|clear` | `session_start.py`: freshness line + standing-decisions block |
| PostToolUse | `Grep\|Glob\|Read\|Edit\|Write\|mcp__.*[Rr]epowise.*__.*` | `command.py:353` → sub-surfaces below |
| PostToolUseFailure | `Read\|Edit\|Write\|Grep\|Glob\|NotebookEdit` | `wrong_path.py` "…is not in this tree. The only indexed X is…" (63 c); `glob_rescue.py` answers a ripgrep-timed-out glob from the index (245 c + paths) |

Sub-surfaces, each silent unless it has something asymmetric to add (chars = measured literal length):

| Surface | File:line | Gate | Emits (chars) |
|---|---|---|---|
| zero-match + widened rescue | `search.py:784,980` | grep 0 results / best hit in a file grep missed | `No literal match for \`{p}\`. Closest indexed symbol: {k} \`{n}\` in {f}` (85/89) |
| triage / flood digest | `search.py:941,280` | ≥15 lines (`_TRIAGE_THRESHOLD`) / ≥50 (`_DIGEST_THRESHOLD`) | 116 header + top-3 ranked files / 60 header + per-file rows |
| **replacements** (digest, read skeleton) | `search_digest.py:103`, `read_skeleton.py:159` | opt-in flag; skeleton also needs ≥100 lines, ≥1500 tok saved, ≤0.5 ratio | 258 / 627 preamble, then replace the tool result outright |
| stale read / skeleton-only warn | `read_state.py:327,270` | Read after this session's Edit / edit after a skeleton-only read | `{f} changed (Edit/Write) after your previous read of it — excerpts from before that edit are stale.` (110) / 233 |
| unchanged re-read / changed-outside | `reread.py:145,180` | identical digest / mtime moved with no Edit of ours | 248 (collapses the re-read) / 218 |
| edit decision + bug-history | `decision_inject.py:561,651` | governed file (`_MAX_EDIT_NOTICES=3`/session); ≥3 fixes ≤180 d, 1/file/session | `{f} is governed by a standing decision: {t}` (54+) / 69+ |
| bash staleness / served-reads KPI | `bash_staleness.py:114`, `served_reads.py` | after `git commit` / Read after MCP served the bytes | 136 / **nothing** (measurement only) |

**Skills** (6, `user-invocable: false`, gated on `.repowise/`): `codebase-exploration` 3932 B, `change-review` 6145 B, `code-health` 3253 B, `pre-modification` 3002 B, `architectural-decisions` 2927 B, `dead-code-cleanup` 2091 B. **Commands**: 19 (`init` 11.7 kB, `status`, `update`, `search`, `ask`, `context`, `symbol`, `reindex`, `health`, `coverage`, `impacted-tests`, `risk`, `security`, `dead-code`, `export`, `decision`, `why`, `doctor`). **MCP**: `.mcp.json` = `repowise mcp`.

## 2. Mechanism — nothing blocks

**No `PreToolUse` entry at all**: no `permissionDecision: "deny"`, no grep denial. Three levers: *nudge* (skills + `session_start.py:90`: `"This repository has a local codebase index. Prefer the repowise MCP tools ({_CORE_TOOLS}) over raw file reads for locating and understanding code before you edit."`); *augment* (`hookSpecificOutput.additionalContext`, appended to a result already paid for); *replace* (`hookSpecificOutput.updatedToolOutput`, `command.py:260-295`, opt-in per repo via `hooks.<flag>` / `REPOWISE_HOOK_<FLAG>`; Claude validates the shape and silently falls back on mismatch).

Dedup: `_claim_emission` uses a content-keyed temp lock, `_EMIT_DEDUP_TTL_SECONDS = 8.0`, so the plugin hook and the `~/.claude/settings.json` hook that `repowise init` writes cannot double-emit.

## 3. Overlap with what we have

| Theirs | Ours | Gap |
|---|---|---|
| SessionStart freshness | `steering/repowise-index-{absent,stale}.md` — preconditions on `repowise_*`, `ask`→`repowise init`, `run`→`repowise update` | ours *acts* rather than narrates, and is lazier. Missing: the standing-decisions block |
| PostToolUse + Failure | `extensions/repowise-augment.ts` (`tool_result` → Claude envelope, appends to `content`) | **already ported**; skips success-path Read, `updatedToolOutput`, PreToolUse (pi-rtk-optimizer owns rewrites) |
| `codebase-exploration` / `pre-modification` | `skills/repowise-exploration` 4150 B / `repowise-pre-modification` 3263 B | ours ahead: native `repowise_*` names, workspace support, proxy calls, trust-signal + error sections |
| `change-review`, `code-health` | — | **real gap**: `repowise-routing.md` gives `get_change_risk`/`get_health` no guidance |
| `architectural-decisions`, `dead-code-cleanup` | one line each in `repowise-routing.md` | acceptable at our usage rate |
| 19 slash commands | — | not ported (thin CLI wrappers) |

## 4. Portability to pi

| Hook | pi event | Effort | Claude-specific risk |
|---|---|---|---|
| PostToolUse / PostToolUseFailure | `tool_result` | **done** | none |
| Read success path | `tool_result` on `read`; must synthesize `{type,file:{filePath,content,numLines}}` (`replacement.py:107`) | S | that shape is Claude-typed |
| SessionStart | `session_start` / `before_agent_start` | S | `startup\|resume\|clear` matcher has no pi analogue |
| `updatedToolOutput` | `tool_result` **can already replace `content`** — pi is more capable here than the comment in `repowise-augment.ts` implies | M | replacement objects Claude-typed; unwrap to text blocks |
| PreToolUse | `tool_call` (can block/mutate input) | n/a | upstream registers none |

Non-portable as-is: the stdout JSON protocol (`{"hookSpecificOutput":{"hookEventName","additionalContext","updatedToolOutput"}}`), `matcher` regexes over Claude tool names, `statusMessage`, and the two-gutter explainer in `read_skeleton.py:159` (it describes Claude Code renumbering served content — actively misleading in pi). Permission decisions are unused anywhere, so that whole incompatibility class is moot.

## 5. Cost

~4 chars/token. Fixed: SessionStart 40-60 tok + decisions 50-150 tok. Per firing: rescue 25-40, triage ~100, flood digest 250-750, stale/changed 28-55, decision + bug-history ~30 each, bash staleness ~35, wrong-path 20, glob rescue 80-150 — most capped once-per-file-per-session.

Whole session ≈ **150-250 tok fixed + 30-100 tok per firing**. Against our data (`repowise_search_codebase` averages **1.6k tok/result**; tools fired **10× in 14 days**) a full session of hook injections costs about **one third of a single MCP search call**, and the replacement surfaces are net-negative by construction (`_READ_NUDGE_MIN_SAVINGS = 1500` tokens). Cost is not the constraint here; latency is (`SEARCH_TIMEOUT_MS = 10_000` on the semantic-rescue path).

## 6. Recommendation

- **Adopt — done.** PostToolUse/Failure via `repowise-augment.ts`. No action.
- **Adapt, best value/diff ratio.** Enable the **Read success path**: unlocks stale-read, unchanged-re-read, changed-outside and skeleton (4 of the surfaces) for ~20 lines — drop `if (event.toolName === "read" && !event.isError) return;` and build `tool_response` as `{file:{filePath: rel, content: textOf(...), numLines: n}}`.
- **Adapt.** SessionStart **decisions block only** — ~15 lines on `before_agent_start`, one augment call with `hook_event_name:"SessionStart"`, prepend as context. Skip its freshness line: our two preconditions already own that and act rather than narrate.
- **Adapt, partial.** `updatedToolOutput` for `search_digest` (pure text); **skip** `read_skeleton` replacement (Claude-renderer-specific preamble). **Adopt as skills:** `change-review` + `code-health`.
- **Skip.** The 19 slash commands, `.mcp.json`/`plugin.json` packaging, the `architectural-decisions` and `dead-code-cleanup` skills, and PreToolUse.

## Contradictions / unknowns

- README says the plugin "registers two hooks"; `hooks.json` registers **three**. The JSON is authoritative.
- Plugin 0.51.0 vs installed CLI 0.50.0: **drift checked, not hand-waved** — `diff -rq` over the whole `augment_cmd/` tree shows exactly one differing file, `search.py`, and the change is a new quality gate on the zero-result FTS rescue (`_RESCUE_FTS_MIN_TERMS = 2`, upstream #2092) that makes that one surface *quieter*. Every threshold (`_TRIAGE_THRESHOLD=15`, `_DIGEST_THRESHOLD=50`, `_TRIAGE_TOP_N=3`, `_RESCUE_TOP_N=2`, `_MAX_EDIT_NOTICES=3`, `_EMIT_DEDUP_TTL_SECONDS=8.0`) and every quoted literal is unchanged on main. No cited claim or recommendation is affected. Re-verify `replacement.py`'s expected tool-response shape on the next CLI upgrade.
- `PostToolUseFailure` is not in the official Claude Code hooks reference; upstream registers it anyway. Whether Claude Code dispatches it is `UNVERIFIED` from primary docs (only corroborated by repowise's own code).
- Latency figures (~0.5 s common, ~10 s rescue) are comments in `repowise-augment.ts`, not measured here (`UNVERIFIED`). `~/.claude/settings.json` contains the string `repowise`; whether it duplicates the plugin hooks on this machine was not checked.
