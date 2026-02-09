# Claude Plugins Per Project Type

Recommended plugin configurations for per-project `.claude/settings.json`.

## Python Projects (AI/ML)

```json
{
  "enabledPlugins": {
    "astral@astral-sh": true,
    "pyright-lsp@claude-plugins-official": true,
    "hugging-face-cli@huggingface-skills": true,
    "hugging-face-datasets@huggingface-skills": true,
    "hugging-face-jobs@huggingface-skills": true
  }
}
```

## Python Projects (General)

```json
{
  "enabledPlugins": {
    "astral@astral-sh": true,
    "pyright-lsp@claude-plugins-official": true
  }
}
```

## TypeScript/Node.js Projects

```json
{
  "enabledPlugins": {
    "typescript-lsp@claude-plugins-official": true
  }
}
```

## Neovim/Lua Config

```json
{
  "enabledPlugins": {
    "lua-lsp@claude-plugins-official": true
  }
}
```

## Dotfiles

```json
{
  "enabledPlugins": {
    "pyright-lsp@claude-plugins-official": true
  }
}
```

Pyright enabled for Python hooks in `config/claude/hooks/`.

## Global Plugins (user-level)

These are enabled in `~/.config/claude/settings.json` and available to all projects:

context7, commit-commands, security-guidance, pr-review-toolkit, explanatory-output-style, learning-output-style, hookify, code-simplifier, claude-md-management, exa-mcp-server, taches-cc-resources, document-skills
