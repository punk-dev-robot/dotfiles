1. **IIKit Phase Workflow System** — Multi-skill orchestration framework managing constitution → specify → plan → checklist → testify → analyze → implement → tasks-to-issues phases. Key files: `.tessl/tiles/tessl-labs/intent-integrity-kit/SKILL.md`, `.tessl/RULES.md`, `.tessl/tiles/tessl-labs/intent-integrity-kit/skills/iikit-core/SKILL.md`.

2. **Constitution-Driven Governance** — Foundation layer defining project principles, phase separation rules, and assertion integrity constraints enforced across all downstream skills. Key files: `.tessl/tiles/tessl-labs/intent-integrity-kit/skills/iikit-00-constitution/SKILL.md`, `.tessl/tiles/tessl-labs/intent-integrity-kit/rules/`.

3. **Bash Scripting Foundation** — Shared utilities, prerequisite checking, dashboard generation, and test execution helpers used across all phases. Key files: `.tessl/tiles/tessl-labs/intent-integrity-kit/skills/iikit-core/scripts/bash/common.sh`, `check-prerequisites.sh`, `generate-dashboard-safe.sh`.

4. **Dashboard Generation Pipeline** — JavaScript-based real-time visualization system parsing markdown artifacts and rendering phase state, board view, checklist coverage, and test status. Key files: `.tessl/tiles/tessl-labs/intent-integrity-kit/skills/iikit-core/scripts/dashboard/src/generate-dashboard.js`, `parser.js`, `pipeline.js`.

5. **Specification & Planning Templates** — Structured markdown templates for features, specifications, plans, tasks, and checklists with cross-linking and traceability. Key files: `.specify/templates/spec-template.md`, `.specify/templates/plan-template.md`, `.specify/templates/tasks-template.md`.

6. **BDD/Gherkin Test Framework Integration** — Step verification, feature file parsing, and test execution coordination with Cucumber/Gherkin syntax support. Key files: `.tessl/tiles/tessl-labs/intent-integrity-kit/skills/iikit-04-testify/references/gherkin-reference.md`, `verify-steps.sh`, `verify-bdd.sh`.

7. **Dotter Configuration Management** — Multi-machine dotfiles deployment with profile-based targeting (kubas-mac, arch, etc.) and pre/post-deploy hooks. Key files: `.dotter/global.toml`, `.dotter/kubas-mac.toml`, `.dotter/pre_deploy.sh`, `.dotter/post_deploy.sh`.

8. **Neovim Lazy-loader Plugin Architecture** — Lua-based modular plugin system with 40+ plugins covering LSP, debugging, UI, and development tools. Key files: `config/nvim/init.lua`, `config/nvim/lua/config/lazy.lua`, `config/nvim/lua/plugins/`.

9. **ZSH Shell Environment** — Modular RC configuration with znap plugin manager, framework integration, aliases, and environment setup across rc.d/ fragments. Key files: `config/zsh/rc.d/`, `config/zsh/lib/core.sh`, `config/zsh/lib/logging.sh`.

10. **Git Hook Assertion Layer** — Pre/post-commit hooks enforcing test execution, assertion integrity, and constitution compliance validation. Key files: `.tessl/tiles/tessl-labs/intent-integrity-kit/skills/iikit-core/scripts/bash/pre-commit-hook.sh`, `post-commit-hook.sh`.

11. **Claude Code Integration** — Local plugins, hooks, and commands for AI-assisted development including caveman mode and spec-kit integration. Key files: `config/claude/hooks/`, `config/claude/skills/`, `config/claude/commands/scr.md`.

12. **Task Observer Skill** — Cross-session improvement tracking system capturing observations on skill execution for continuous enhancement. Key files: `config/claude/skills/task-observer/SKILL.md`.

13. **Feature Lifecycle Management** — Integrated system for creating, tracking, and converting feature specifications through phases with git-based artifact storage. Key files: `.specify/scripts/bash/create-new-feature.sh`, `update-agent-context.sh`.

14. **Terminal Multiplexing & Window Management** — Tmux/Alacritty integration with environment syncing, session persistence, and race condition handling. Key files: `config/tmux/`, `local/bin/tmux-sync-env.sh`, `docs/reference/tmux/`.

15. **Integration & Manifest System** — Multi-tool orchestration (speckit, claude, opencode) via JSON manifests coordinating workflows across specification, planning, and implementation tools. Key files: `.specify/integrations/`, `config/codex/AGENTS.md`, `.mcp.json`.