# Documentation

Curated reference for this dotfiles repo. Audience: future Kuba and Claude equally.

## Value Bar

A doc earns its place if it **teaches something** OR **would be referenced again**. Either criterion is sufficient. One-shot fixes are kept when they reveal a pattern worth remembering.

## Structure

### `reference/`

Technical reference material. How things work, configuration details, architecture docs. Topics with multiple files get a subfolder containing `index.md` that summarizes and links to subtopic files.

### `troubleshooting/`

Problem-solution pairs. Fixes, workarounds, hardware-specific issues. Written so the next person (or agent) hitting the same error can find and apply the fix without re-debugging.

### `.scratch/`

Gitignored. Transient session notes written by Claude during work sessions. Reviewed periodically and either promoted to a curated directory or deleted.

## Naming Rules

- All filenames: **kebab-case** (e.g., `network-stack.md`, not `Network Stack.md`)
- Topic subfolders: contain `index.md` when subject spans multiple files

## Adding New Docs

1. **Audit against codebase** before committing -- verify referenced configs, paths, and commands actually exist
2. **Choose category** based on content type, not origin
3. **Session scratch notes** go in `.scratch/`, not directly into curated directories

## Current Inventory

```
docs/
  reference/       5 standalone + btrfs/ (3) + tmux/ (3)
  troubleshooting/ 6 docs
  .scratch/        gitignored, transient
```
