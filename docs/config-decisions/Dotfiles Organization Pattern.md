---
title: Dotfiles Organization Pattern
type: pattern
permalink: guides/dotfiles-organization-pattern
tags:
- '["dotfiles"'
- '"organization"'
- '"patterns"]'
---

# Dotfiles Organization Pattern

## Key Rules
- **Single file configs**: Keep in dotfiles root directory with dot prefix (e.g., `.toolhive.yaml`)
- **Multiple files for a tool**: Create a directory (e.g., `hypr/`, `nvim/`, `alacritty/`)

## Examples
- Single file: `.dotter/global.toml` → Would be `.dotter.toml` in root
- Directory: `hypr/` contains multiple config files for Hyprland
- Directory: `nvim/` contains multiple Neovim configuration files

## Rationale
This keeps the dotfiles root clean while making it easy to find single-file configs and organizing complex tool configurations in their own directories.