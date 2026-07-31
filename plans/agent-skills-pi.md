# Adopt addyosmani/agent-skills in pi (dotfiles)

## Context

Adopt the 24-skill `addyosmani/agent-skills` repo into this dotfiles-managed pi setup, plus its
4 specialist personas and all 8 phase commands (`/spec /plan /build /test /review /ship
/code-simplify /webperf`). Existing setup: 26 skills in `~/.agents/skills`, 7 subagents in
`config/custom/pi/agent/agents/`, skill-gate visibility control, delegation policy in global
`AGENTS.md`.

Decided: all 24 skills enabled, installed as a `pi install git:` package; all 4 personas ported as
pi subagents with the duplicate `reviewer` removed; all 8 commands ported as pi prompt templates.

## Verified facts (pi 0.82.1 docs + local config + upstream repo)

- **Nested skill dirs load.** `docs/skills.md`: "In all skill locations, directories containing
  `SKILL.md` are discovered **recursively**." `docs/packages.md`: package convention dir
  "`skills/` recursively finds `SKILL.md` folders". Repo has exactly 24 `SKILL.md`, all at
  `skills/<name>/` — no strays, no name collisions with the 26 already installed.
- **Package install works without `package.json`.** Git packages run `npm install` only
  "if `package.json` exists"; otherwise convention dirs apply. Repo has none → clone + discover.
  Only `skills/` is a pi convention dir — the repo's `agents/`, `commands/`, `hooks/`, `.claude/`
  are ignored by pi, so personas and commands must be ported by hand.
- **skill-gate defaults unknown skills to `disabled`** (`pi-skill-gate/index.ts:71`).
  "All 24, no gating" therefore requires 24 explicit `"enabled"` entries in `skill-gate.json`.
- **Context cost**: 24 descriptions ≈ 6.3 KB ≈ 1.6k tokens in every system prompt. Prompt
  templates cost **zero** until typed, personas cost zero until launched.
- **Prompt templates** = `~/.pi/agent/prompts/*.md` → `/name`; frontmatter `description`,
  `argument-hint`; args via `$1`, `$@`, `$ARGUMENTS`, `${1:-default}`. Discovery is
  non-recursive. Directory does not exist yet; no name collisions with installed packages
  (only `pi-hashline-edit-pro` ships templates: read/replace/undo).
- **Agent frontmatter wins over launch-time `mode`/`tools`/`cwd`** (pi-subagents README) — a
  persona meant for background fan-out must declare `mode: background` in its own file.
- **Per-agent `skills:` frontmatter** scopes which skills a child sees (`lead.md` already does this).
- Paths: `~/.pi` → `~/.config/pi`; dotter maps `config/custom/pi/agent` → `~/.config/pi/agent`
  recursively, so new files/dirs deploy on `dotter deploy`.
- `mcp.json` currently has one server (`logfire`) — no `chrome-devtools`, so
  `browser-testing-with-devtools` and the perf persona's deep mode have no runtime eyes yet.

### How the Claude plugin actually wires routing — and why we won't copy it

`.claude-plugin/plugin.json` declares `skills`, `commands`, and the 4 `agents/`. Routing is done
by a **`SessionStart` hook** (`hooks/hooks.json` → `hooks/session-start.sh`) that runs
`jq -cn --arg message "agent-skills loaded… $(cat skills/using-agent-skills/SKILL.md)"` and injects
the **entire 9.7 KB meta-skill as an `IMPORTANT` message into every single session** — before the
agent knows whether the task is even engineering work.

Pi can do the same (`before_agent_start` "can inject message, modify system prompt"), and it would
be the wrong trade: ~2.4k tokens per session, permanently, to say what one sentence says. Confirms
the suspicion — the Claude side is the less ideal implementation, not the model to follow.

The upstream setup docs agree with the cheap version:

- **Codex** (closest analogue to pi: native plugin + skill discovery) adds **zero** rules-file
  content. Install, then `@skill-name` or let the model route.
- **OpenCode's** heavy intent-map + anti-rationalization AGENTS.md exists because that harness had
  no automatic skill routing at the time — pi injects descriptions natively.
- **Cursor** caps the always-on layer at "one routing rule + 1–2 non-negotiables" and lists
  "paste all skills into one rule" and "many alwaysApply rules" as anti-patterns.
- The **dev.to write-up** (hidden use #1) reduces it to one line in the rules file: *"On session
  start, ALWAYS read `skills/using-agent-skills/SKILL.md` first and follow its decision tree."*

**Correction from upstream issues #423 / #433** (found mid-implementation): that forced-router line
is only right for hosts with no native routing. On GPT-5.6 and Claude Code — both of which route
skills themselves — stacking `using-agent-skills` gives "two routers doing the same job", reported
as a severe slowdown; maintainer's stated fix is a documented *"don't load our meta-skill where the
host already routes skills itself."* **Pi routes natively.** So the AGENTS.md line became a guard
*against* the extra hop, not a mandate for it, and `using-agent-skills` is best left disabled in
skill-gate. #433 also confirms the always-on cost is descriptions only — bodies load one at a time.

### "Don't load all 24 at once" — what that means in pi

Upstream's quickstart says *"Don't load all 24 skills at once — it wastes context"*, while its own
step 1 is *"one command drops all 24 skills into your agent… the meta-skill routes work to the
right one."* Both are true because they describe different layers, and the warning is aimed at
harnesses where "load" means pasting `SKILL.md` bodies into a rules file (`GEMINI.md`,
`.windsurfrules`) — that is the 100 KB mistake.

In pi the layers are separate and the costs are known:

| Layer | Cost | Our setting |
|---|---|---|
| 24 names + descriptions in system prompt | ~1.6k tokens, always | enabled (all 24) |
| Full `SKILL.md` body | 3–16 KB, only when the agent reads it | on demand |
| 4 personas | 0 until launched, then in the child's context | on demand |
| 8 prompt templates | 0 until typed | on demand |

So "all 24 enabled" here means all 24 *descriptions* — which is exactly the routing surface the
meta-skill needs. Nothing is pre-loaded. Fallback if the 1.6k ever bites: skill-gate's `projects`
key narrows the set per project without touching the install.

### Errors in the pasted guide (do not copy into our setup)

1. `settings.json` `skills` array is an **additive location list**, not a whitelist. Real
   cherry-pick = package object form `{"source": …, "skills": ["skills/x", "!skills/y"]}`.
2. "Pi has no subagent system" — false here: `edxeth/pi-subagents` is installed, 7 agents exist,
   parallel fan-out works, so `/ship` is implementable.
3. "No native slash commands for `/spec`, `/plan`" — false: pi prompt templates give all 8.
4. Git packages clone to `~/.config/pi/agent/git/…` on this box (`~/.pi` is a symlink).

## Approach

1. **Install** as a global git package pinned by sha in dotfiles-tracked `settings.json`.
2. **Enable all 24** via explicit skill-gate entries.
3. **Route via the meta-skill on demand**: one line in global `AGENTS.md`. No session-start
   injection hook, no copied flowchart, no intent table.
4. **Personas as subagents**: port the 4 persona bodies into pi agent files with pi frontmatter,
   scoped `skills:`, `mode: background`, cross-family models. `reviewer` is the duplicate of
   `code-reviewer` → merged into it (keeping reviewer's stop-condition + `deny-tools`), file deleted.
5. **All 8 commands as prompt templates** — one file each, near-verbatim from
   `.claude/commands/*.md`, with three mechanical substitutions:
   `agent-skills:<skill>` → `/skill:<skill>`; Claude Agent tool → pi `subagent`;
   `$ARGUMENTS` kept as-is (pi supports it, so `/build auto` works unchanged).
   `/ship` fans out 3 children in one call; `/review` and `/webperf` each launch one persona.

## Files to modify

- `config/custom/pi/agent/settings.json` — add `"git:github.com/addyosmani/agent-skills@<sha>"`
- `config/custom/pi/agent/config/skill-gate.json` — +24 `"enabled"` entries
- `config/custom/pi/agent/AGENTS.md` — one-line skills routing pointer
- `config/custom/pi/agent/agents/reviewer.md` — **deleted**, replaced by:
- `config/custom/pi/agent/agents/{code-reviewer,security-auditor,test-engineer,web-performance-auditor}.md` — new
- `config/custom/pi/agent/agents/lead.md` — `reviewer` refs at L30/83/88/90 → `code-reviewer`
- `config/custom/pi/agent/agents/dev.md` — ref at L16
- `config/custom/pi/agent/prompts/{spec,plan,build,test,review,ship,code-simplify,webperf}.md` — new

## Reuse

- `agents/reviewer.md` frontmatter — cross-family model, `deny-tools: edit,write,replace,…`,
  `env: PI_SUBAGENT_HERDR_PLACEMENT=tab`, plus its "Stop condition — mandatory" section. Kept
  verbatim in `code-reviewer.md`; the upstream persona supplies the five-axis framework + template.
- `agents/recon.md` background/read-only frontmatter — template for the 3 fan-out personas.
- `agents/lead.md` `skills:` frontmatter — same mechanism scopes each persona's skill access.
- `skills/using-agent-skills/SKILL.md` — the routing flowchart, loaded on demand instead of restated.
- Upstream `.claude/commands/*.md` — bodies reused near-verbatim (0.6–4 KB each); only the skill
  invocation syntax and `/ship` Phase A change.
- skill-gate `projects` key — per-project narrowing later if the 1.6k tokens proves heavy.

## Steps

- [ ] `pi install git:github.com/addyosmani/agent-skills@<pinned-sha>`; confirm 24 skills discovered
- [ ] Add 24 `"enabled"` entries to `config/custom/pi/agent/config/skill-gate.json`
- [ ] Confirm the dotfiles `settings.json` diff is only the package entry
- [ ] `agents/code-reviewer.md` = upstream persona body + `reviewer.md` frontmatter and stop
      condition; `skills: code-review-and-quality`; then delete `agents/reviewer.md`
- [ ] `agents/security-auditor.md` — `skills: security-and-hardening`, `mode: background`,
      read/grep/find/ls/bash, `deny-tools: edit,write,replace`
- [ ] `agents/test-engineer.md` — `skills: test-driven-development`, background, bash for test runs
- [ ] `agents/web-performance-auditor.md` — `skills: performance-optimization,
      frontend-ui-engineering, browser-testing-with-devtools`, background
- [ ] Rename refs `reviewer` → `code-reviewer` in `AGENTS.md`, `lead.md`, `dev.md`
- [ ] Add to `config/custom/pi/agent/AGENTS.md`: load a skill when its description matches; do
      **not** route through `using-agent-skills` first (pi routes natively — #423/#433)
- [ ] Port the 8 templates into `config/custom/pi/agent/prompts/`:
  - [ ] `spec.md`, `plan.md`, `test.md`, `code-simplify.md` — body verbatim, `/skill:` substitution
  - [ ] `build.md` — keep both modes; `$ARGUMENTS` = `auto`/`all` → autonomous pass
  - [ ] `review.md` — five-axis review delegated to the `code-reviewer` subagent (matches the
        existing delegation policy) instead of running inline
  - [ ] `ship.md` — Phase A: one `subagent` call with
        `children: [code-reviewer, security-auditor, test-engineer]`; Phases B/C merge, go/no-go,
        mandatory rollback plan
  - [ ] `webperf.md` — single `web-performance-auditor` launch; keep the quick/deep mode gate
- [ ] `dotter deploy`

## Verification

- [ ] pi startup lists the 24 new skills; `/skill-gate` shows them enabled
- [ ] `/skill:debugging-and-error-recovery` loads the SKILL.md body (proves package discovery)
- [ ] `/` autocomplete lists all 8 new commands with their descriptions
- [ ] `/build auto` and `/build` expand differently (proves `$ARGUMENTS` handling)
- [ ] Roster shows `code-reviewer`, `security-auditor`, `test-engineer`,
      `web-performance-auditor`, and no `reviewer`
- [ ] `/review` on a small real diff → five-axis report from the child, zero edits made
- [ ] `/ship` on a scratch commit with a planted flaw (hardcoded secret + untested branch) →
      three children run concurrently, merged verdict is NO-GO naming the secret
- [ ] `grep -rn "\breviewer\b" config/custom/pi/agent` → only `code-reviewer` hits
- [ ] Session token count before/after adoption differs by ~1.6k (descriptions only), not ~4k
- [ ] Upstream "first 10 minutes" lifecycle runs end to end on a throwaway feature:
      `/spec` → `/plan` → `/build` → `/test` → `/review` → `/ship`, each step loading its skill
      on demand and none of them pasting a SKILL.md body into the transcript

## Not doing (upstream features deliberately skipped)

- **`SessionStart` meta-skill injection** — the Claude plugin's approach; ~2.4k tokens every
  session. The one-line AGENTS.md pointer covers it. Revisit only if routing measurably fails.
- **`sdd-cache` hook** (ETag-revalidating WebFetch cache for `source-driven-development`) — a pi
  port would be a new extension; `context-mode`'s fetch cache already covers most of it.
- **`simplify-ignore` hook** (redacts `simplify-ignore-start/end` blocks from the model) — clever,
  but no protected hot paths in these repos yet. YAGNI.
- **`chrome-devtools-mcp` in `mcp.json`** — needed for `browser-testing-with-devtools` and the perf
  persona's deep mode. Add when there is actual browser work; both degrade to quick mode without it.

## Open questions (defaults chosen, annotate to override)

0. **`using-agent-skills` stays disabled** in skill-gate — its router duplicates pi's own.
1. **Skill twins.** New pack overlaps installed tessl skills. Default: keep all 24 enabled,
   disable the 4 clear twins on the tessl side — `tessl__to-spec`, `tessl__to-tickets`,
   `tessl__api-design-patterns`, `tessl__devops-essentials`. Kept on both sides because they are
   genuinely different: `ponytail` vs `code-simplification`, `context-mode` vs
   `context-engineering`, `tessl__grill-with-docs` vs `interview-me`/`idea-refine`.
2. **Persona models.** code-reviewer `openai-codex/gpt-5.6-sol:high` (inherited from reviewer),
   security-auditor `anthropic/claude-opus-5:high`, test-engineer `anthropic/claude-sonnet-5:medium`,
   web-performance-auditor `anthropic/claude-sonnet-5:medium`.
3. **`/plan` naming.** Upstream `/plan` writes `tasks/plan.md`; you already plan via plannotator +
   the `planner` subagent. Default: install it as `/plan` (no collision found) and let it delegate
   to `planner`. Alternative: name it `/plan-tasks` to keep the two workflows visibly separate.
