# Agent Epic Runbook

How to drive an epic with the multi-agent orchestration stack.
Design: [2026-07-27-pi-multi-agent-orchestration-design.md](../plans/2026-07-27-pi-multi-agent-orchestration-design.md)
Launchers: `config/custom/zsh/rc.d/092-pi-aliases.zsh`

## TL;DR

Start the manager, point it at the epic, it delegates the rest:

```bash
# Herdr tab 1, in the platform repo
pim "Epic AGI-5099: <one-line goal or Linear link>. Decompose into phases, delegate, keep me posted."
```

## Flow

1. **Manager** (`pim`, opus-4-8, Ctrl+P → gpt-5.6-sol) decomposes the epic and
   delegates via the `task` tool. Available profiles: `recon`, `ai-eng`, `be-eng`,
   `fe-eng`, `devops`, `observability`, `reviewer`.
2. **Per phase:**
   - `task(agent_type: recon)` → findings file, cheap groundwork
   - `task(agent_type: <specialist>, isolation: worktree)` → implementation
   - `task_control verify` → `review` → `ship` gate
3. **Deep decisions:** manager runs `/advisor` (fable-5, 5-call budget, opt-in
   per session), or you open a `pip` pane and discuss directly.
4. **Review gate (cross-family, recommended):** split a Herdr pane, launch
   `piqa` (gpt-5.6-sol), feed it the diff/worktree path.
   **Brief MUST include a risk threshold + stop condition** or Sol loops on
   edge cases and burns budget.
5. **You:** live in tab 1; one tab per work item; jump into panes as needed.
   Unresolved disagreement → manager escalates with both positions + attribution.

## Launchers

| Cmd | Role | Model (Ctrl+P alt) |
| ----- | ------ | -------------------- |
| `pim` | manager / orchestrator | opus-4-8 (gpt-5.6-sol) |
| `pip` | principal / architect | fable-5 |
| `pid` | implementer | opus-4-8 (gpt-5.6-terra) |
| `piqa` | reviewer / QA | gpt-5.6-sol |
| `pir` | recon, read-only | haiku-4-5 (gpt-5.6-luna) |
| `pif` | full default session | settings default |

## Gotchas

- `task` children **inherit the parent's model** — no per-profile tiering.
  Cheap recon = launch a Herdr pane with `pir` instead of `task(recon)`;
  say so in the epic prompt.
- New/edited `agents/*.md` are discovered at `session_start` only — restart
  the session after changes.
- `doctor` `runtime-wrapper-missing` / `packaged-runtime-drift` = harmless
  package-author advisories; delegation works.
- punkfl0w/Linear per-phase SDD is **opt-in** — heavy phases only,
  worktree per phase.
- Reviewer never reviews own work; nobody ships unreviewed.
