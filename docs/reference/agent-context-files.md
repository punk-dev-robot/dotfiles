# Agent context files

How harnesses load `AGENTS.md`/`CLAUDE.md`, where ours live, and what goes where.
Vocabulary (harness, context file, global/project context, steering, enforcement):
`CONTEXT.md` → Agent context. Tracker: KUB-159 (phase 1), KUB-164 (steering, phase 2).

## Load order per harness

| Harness | Global slot | Project walk | Notes |
|---|---|---|---|
| pi 0.85 | `$PI_CODING_AGENT_DIR/AGENTS.md` (`~/.config/pi/agent/`) | walk up from cwd to `/`, then cwd. Per dir: `AGENTS.override.md` > `AGENTS.md` > `CLAUDE.md` — exclusive per dir | all matches concatenated, global first. Loaded before project-trust prompt. `--no-context-files` disables; `/reload` re-reads |
| Claude Code | `$CLAUDE_CONFIG_DIR/CLAUDE.md` (`~/.config/claude/`) | walk up; `CLAUDE.md` + `CLAUDE.local.md`; `.claude/rules/*.md`; subdir `CLAUDE.md` lazy | never reads `AGENTS.md`; native `@include`. Injects "may or may not be relevant" reminder around each file |
| codex | `$CODEX_HOME/AGENTS.md` (`~/.config/codex/`) | git-root → cwd, top-down | ~32KB cap; `AGENTS.override.md`; `@include` believed unsupported. Not validated by us |
| opencode | `~/.config/opencode/AGENTS.md` | walk up, falls back to `CLAUDE.md`; plus `instructions` in `opencode.json` | not validated by us |

No spec defines a harness-neutral global slot (agents.md covers project walk-up only).
`~/AGENTS.md` would work for walk-up harnesses but pollutes home and double-loads with pi's global — rejected.

### pi specifics

- `@path` includes are **not core**. Extension `@d3ara1n/pi-context-include`: line-start only, `.md` only,
  recursive (10 levels / 500KB), realpath dedup + cycle detection, path fence, re-injected every turn.
  Relative paths resolve against the *including file's path* — a relative `@./x.md` breaks when the file
  is reached via a symlink from another dir. Avoid relative includes in anything symlinked.
- `APPEND_SYSTEM.md` (`~/.config/pi/agent/` or `.pi/`) appends to the system prompt. Plain text; the include
  extension does not process it. `SYSTEM.md` replaces the prompt entirely.

## Our layout

```
config/shared/punk/AGENTS.md          global context (SSOT) → ~/.config/punk/AGENTS.md
config/custom/pi/agent/AGENTS.md   ─┐
config/shared/claude/CLAUDE.md      ├─ git symlinks → ../punk/AGENTS.md; dotter deploys them as-is
config/shared/codex/AGENTS.md       │  (2-hop readlink, verified fine for pi)
config/shared/opencode/AGENTS.md   ─┘
config/custom/pi/agent/APPEND_SYSTEM.md   pi-only, TEMPORARY: tool/workflow routing until steering ext (KUB-164)
config/custom/agents/skills/punk-resume/manager-mode.md   manager mode, loads with the skill
<repo>/AGENTS.md                      project context; <repo>/CLAUDE.md = `@AGENTS.md` shim
```

## Placement rule

| Content | Goes to |
|---|---|
| Applies to every harness, every session, names no tool (coding standards) | global context, bare markdown |
| Names a tool, MCP server, skill, or workflow (delegation, routing, MCP-first, tracker conventions) | `APPEND_SYSTEM.md` (interim) → steering extension |
| Conditional on a mode the user triggers (manager mode) | the skill that triggers it |
| Repo facts: identity, layout, commands, repo-specific rules | project `AGENTS.md`; rules under narrow `**When …**` headers |
| Harness-specific tooling prose (context-mode quickref, RTK) | nowhere — the tool's own hook/skill ships it |

## Format

- Markdown headers, <200 lines, one concrete verifiable rule per line. Bare for 90%+-relevant content;
  `**When <specific trigger>**` headers for the rest.
- `<important if="…">` (improve-claude-md skill): the Claude Code system-reminder it targets is real, the fix
  is unmeasured, and no other harness/model has evidence for it. Not used. Research: KUB-159 comments.
- Persona preambles ("senior architect, 20 years", `BE CRITICAL`): no measured gain, small negative in the
  largest study; Anthropic says role prompting steers tone only. Dropped; slogans rewritten as rules.

## Footprint (KUB-163, 2026-09-16)

Always-loaded bytes, pi in dotfiles root: before 15.5KB (shared 3.8 + manager-mode 3.7 + pi 4.6 + project
+ docs/README include 3.5) → after 12.0KB (punk 1.4 + APPEND_SYSTEM 7.6 + project 3.0). APPEND_SYSTEM.md is the
remaining bulk — that is the steering extension's target (KUB-164).

## Known dead / gotchas

- Tessl writes `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` (`@../.tessl/RULES.md`) — hardcoded default
  dirs, ignores `CLAUDE_CONFIG_DIR`/`CODEX_HOME`. Harnesses never read them. `~/.claude`, `~/.codex` are
  runtime state, not context files: left alone. `RULES.md` aggregates plugin *rules*; we have none → boilerplate.
- Tessl skills land in `~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills`; Claude reads
  `~/.config/claude/skills` (doesn't exist) → tessl skills invisible to Claude. Claude out of scope.
- Double-load: pi core does **not** realpath-dedup. cwd under `config/shared/punk/` loaded the SSOT twice (walk-up +
  global symlink). Fixed by `config/shared/punk/AGENTS.override.md` (pi loads it instead of `AGENTS.md` there).
- Running pi inside `config/shared/punk/` makes repowise create a `.repowise/` there (gitignored; delete it).
- Deployed symlinks that were hand-repointed make `dotter` refuse to update ("target exists and doesn't
  point at source"). Remove the stale link and redeploy; no `--force`.
