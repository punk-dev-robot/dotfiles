1. **Dotfiles deployment and environment setup** — Uses dotter to synchronize configuration across multiple machines with platform-specific profiles. Configuration templates are processed and deployed during setup.
Key files: `.dotter/global.toml`, `.dotter/kubas-mac.toml`, `.dotter/pre_deploy.sh`

2. **Neovim editor configuration** — Complete editor setup with lazy.nvim package manager, language servers, and organized plugin configuration across lua modules. Supports TypeScript, Rust, Ansible, and debugging.
Key files: `config/nvim/init.lua`, `config/nvim/lua/config/lazy.lua`, `config/nvim/lua/plugins/`

3. **Structured task planning system** — Multi-phase workflow framework (specification, planning, testing, implementation) using IIKit with dashboard generation and phase discipline enforcement.
Key files: `.tessl/RULES.md`, `.tessl/tiles/tessl-labs/intent-integrity-kit/SKILL.md`, `.specify/feature.json`

4. **Claude Code integration and hooks** — Custom hooks for spec-kit planning, caveman mode toggling, task observation, and modern CLI warnings. Manages AI-assisted code generation workflows.
Key files: `config/claude/hooks/`, `config/claude/CLAUDE.md`, `.specify/integrations/claude.manifest.json`