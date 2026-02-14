@about_me.md

# Core Rules

## General Principles

- If something is unclear or too complex, ask for clarification
- Do not make assumptions
- Be thorough
- Always try to get documentation for external tools, services and APIs using tools available to you

## Memory System

- Query memory for existing knowledge before starting new research, planning session or task
- Always pass the `project` parameter to every basic-memory tool call
- Determine project from working directory:
  - `dotfiles` → dotfiles project
  - `lab/*` → homelab project
  - Otherwise → project with same name as working directory
- If no matching project exists, propose creating one (project directory should be `/docs` inside project root)

## Code Implementation Rules

- Do not leave redundant comments or comments more fitting for a changelog
- Write succinct production-ready code
- Avoid use of `any` type in typescript files
- Follow best coding and engineering practices
- Figure out the root cause of the issue before attempting to fix it

## Tools Usage

- Use `Tool search tool` to discover and be aware of useful tooling installed to make our work better
