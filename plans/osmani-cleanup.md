# Purge addyosmani/agent-skills leftovers

## Context

`352de4d` ("pi: adopt addyosmani/agent-skills — 24 skills, 4 personas, 8 commands") brought in skills clone, 4 personas, 8 command prompts. Cleanup commit `5c1b54a` removed the 4 personas, `webperf.md`, and `plans/agent-skills-pi.md` — but left 7 command prompts behind. They still deploy as pi prompt templates today (`/plan`, `/build`, `/ship`, ...).

The osmani skills clone (`~/.pi/agent/git/github.com/addyosmani/agent-skills`) is already gone, so 6 of the 7 prompts invoke `/skill:...` skills that **no longer exist** — dead commands:

All 7 get deleted. Reference of what each was:

| Prompt | Invokes | State |
|---|---|---|
| `config/custom/pi/agent/prompts/plan.md` | `/skill:planning-and-task-breakdown` | dead — delete |
| `config/custom/pi/agent/prompts/build.md` | `/skill:incremental-implementation` + 3 more | dead — delete |
| `config/custom/pi/agent/prompts/spec.md` | `/skill:spec-driven-development` | dead — delete |
| `config/custom/pi/agent/prompts/test.md` | `/skill:test-driven-development` | dead — delete |
| `config/custom/pi/agent/prompts/code-simplify.md` | `/skill:code-simplification` | dead — delete |
| `config/custom/pi/agent/prompts/ship.md` | `/skill:shipping-and-launch` + reviewer/tests fan-out | delete |
| `config/custom/pi/agent/prompts/review.md` | `reviewer` subagent | delete |

Other stragglers found:

- Dead doc link `~/.pi/agent/git/github.com/addyosmani/agent-skills/docs/agents.md` in `config/custom/pi/prompts/reviewer.md:102` and `config/custom/pi/prompts/tests.md:95` (prompt sources → sync to agents + piewf roles per AGENTS.md sync rule)
- Whole `## Skills` section in `config/custom/pi/agent/AGENTS.md:48-53` (deploys to `~/.config/pi/agent/AGENTS.md`). Audited `git show 352de4d -- …AGENTS.md`: this section is the **exact and only** text that commit added to AGENTS.md, so removing it = removing everything addy-skills added there. It cites `addyosmani/agent-skills#423, #433` and warns against `using-agent-skills` — a router skill that no longer exists.

Rest of 352de4d already reverted, verified against current tree:

- 4 osmani personas + `webperf.md` + `plans/agent-skills-pi.md` — deleted in `5c1b54a`
- `reviewer` → `code-reviewer` renames in AGENTS.md / `dev.md` / `lead.md` — current files say `reviewer` again
- `settings.json` `git:github.com/addyosmani/agent-skills@…` skill source — gone; no clone under `~/.pi/agent/git` or `~/.config/pi/agent/git`

## Approach

Delete the leftover prompt files from the repo, run `dotter deploy` so the per-file symlinks under `~/.config/pi/agent/prompts/` are removed. Strip the dead doc links from the two persona prompt sources (they deploy to agents + roles via dotter templates — edit sources only).

**Decision (user):** delete all 7 prompts.

## Files to modify

- Delete all 7: `config/custom/pi/agent/prompts/{plan,build,spec,test,code-simplify,review,ship}.md`
- Edit: `config/custom/pi/prompts/reviewer.md` (drop dead `docs/agents.md` link, line 102)
- Edit: `config/custom/pi/prompts/tests.md` (drop dead link, line 95)
- Edit: `config/custom/pi/agent/AGENTS.md` — remove `## Skills` section (lines 48–53)

## Steps

- [ ] `git rm` all 7 prompt files under `config/custom/pi/agent/prompts/`
- [ ] Edit `reviewer.md` / `tests.md` prompt sources — remove dead `See [docs/agents.md](...)` link, keep the rule sentence
- [ ] Remove `## Skills` section from `config/custom/pi/agent/AGENTS.md`
- [ ] `dotter deploy` (preview with `dotter -v -d` first)
- [ ] Verify `~/.config/pi/agent/prompts/` has no dangling symlinks
- [ ] Commit

## Verification

- `ls ~/.config/pi/agent/prompts/` — deleted templates gone, no broken symlinks
- New pi session: type `/pla` — no `plan [u]` entry
- `grep -rn addyosmani config/ .dotter/` — only intended hits remain (AGENTS.md citation if kept; `.dotter/cache/` regenerates on deploy)
