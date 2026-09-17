# dotfiles

Personal config for two hosts — Omarchy (Arch + Hyprland) mini-pc and a work macOS
laptop — deployed by dotter. Vocabulary: `CONTEXT.md`. Decisions: `docs/adr/`.

## Project map

- `config/shared/` — plain `~/.config/*` dirs, one recursive dotter map; drop a dir in, no edit needed
- `config/custom/` — needs templating, single-dir symlink, or non-`~/.config` target; listed per entry in `.dotter/global.toml`
- `config/omarchy/` — Omarchy override-point files (Keep/Tweak verdicts)
- `config/mac/` — mac-only `~/.config/*`
- `config/.disabled/` — parked, not deployed
- `config/shared/punk/AGENTS.md` — global context (every harness's global slot symlinks here)
- `config/custom/pi/agent/` — pi settings, `steering/*.md` (punk-steering rules), extensions
- `config/custom/agents/skills/` — own skills (`punk-*`, `swap-linear`, `swap-project`, `multi-repo-ticket`) → `~/.agents/skills`
- `config/custom/pi/agent/pi-extensible-workflows/roles/` — piewf agent roles
- `etc/`, `system/` — root-owned templates (`omarchy-system` package)
- `local/bin/` — scripts → `~/.local/bin`
- `docs/` — `reference/`, `troubleshooting/`, `workflow/` (tracker ops, team rules, wayfinding), `adr/`, `otel_retro/` (Logfire-driven workflow retros + experiments ledger); index in `docs/README.md`
- `.dotter/` — `global.toml` (mappings), `<hostname>.toml` (host profile), `cache.toml` (deployed state)

**When deploying or changing what a config maps to**

- Always `dotter` — never hand-link. Dry run first: `dotter -v -d` (`-vv` more).
- Deployed = symlink into the repo; edits to repo files are live, no redeploy. Redeploy only for new mappings or templates.
- `[base.files]` = all hosts; `[macos.files]` / `[omarchy.files]` / `[omarchy-system.files]` per host. Hosts pick packages in `.dotter/<hostname>.toml`.
- Apps that rewrite their own config (codex, claude `settings.json`) are `type = "template"` so the repo copy stays clean.

**When touching tessl skills**

- After `tessl update`, run `tessl-cock-prefix` (`local/bin/`) — re-applies the `cock-` prefix that updates revert.
- Global manifest: `config/custom/tessl/tessl.json` → `~/.tessl/tessl.json`.

**When editing agent roles for `subagents_run` or workflow `agent(...)`**

- One file per role in `config/custom/pi/agent/pi-extensible-workflows/roles/<name>.md`: YAML frontmatter (model `provider/model:thinking`, tool/skill/extension selectors) + prompt body. Live via symlink. Details: `docs/reference/piewf-role-config.md`.

**When creating or updating tracker issues**

- Linear, team `Kuba` (`KUB-n`), via Linear MCP tools. GitHub Issues only for public repo bugs. Ops: `docs/workflow/issue-tracker.md`. Labels: `docs/workflow/triage-labels.md`.

**When adding or changing docs**

- Value bar and layout rules: `docs/README.md`. kebab-case filenames; session notes → `docs/.scratch/` (gitignored), promote later.

**When changing vocabulary or recording a decision**

- Glossary `CONTEXT.md`, ADRs `docs/adr/`. Method: `docs/workflow/domain.md`.


# Agent Rules <!-- tessl-managed -->

@.tessl/RULES.md follow the [instructions](.tessl/RULES.md)
