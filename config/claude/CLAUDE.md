@about_me.md

# Core Rules

## General Principles

- If something is unclear or too complex, ask for clarification
- Do not make assumptions
- Be thorough
- Always try to get documentation for external tools, services and APIs using tools available to you

## Memory System (basic-memory)

- Query memory for existing knowledge before starting new research, planning session or task
- Always pass the `project` parameter to every basic-memory tool call
- Available projects:
  - `dotfiles` → `~/dotfiles/docs` — Arch Linux, Hyprland, Neovim, CLI tools, dotter config
  - `homelab` → `~/lab/docs` — infrastructure, networking, Proxmox, NAS, services
  - `notes` → `~/Documents/notes` — personal knowledge, web clippings, Obsidian vault (default)
- Determine project from working directory:
  - `~/dotfiles/*` → dotfiles
  - `~/lab/*` → homelab
  - Otherwise → notes (default)
- Cross-reference: when working in one project, check other projects for related knowledge if relevant
- Markdown files are the source of truth — the DB is a rebuildable search index

## Code Implementation Rules

- Do not leave redundant comments or comments more fitting for a changelog
- Write succinct production-ready code
- Avoid use of `any` type in typescript files
- Follow best coding and engineering practices
- Figure out the root cause of the issue before attempting to fix it

## Tools Usage

- Use `Tool search tool` to discover and be aware of useful tooling installed to make our work better
