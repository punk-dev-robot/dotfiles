# Structurizr C4 DSL Support for Neovim

This plugin adds support for the [Structurizr C4 DSL](https://github.com/structurizr/dsl) to Neovim.

## Features

- Filetype detection for `.c4` and `.dsl` files
- TreeSitter syntax highlighting
- LSP support with diagnostics and code features

## Installation Requirements

- Neovim with LazyVim
- Java installed (used by the C4 DSL Language Server)
- C4 DSL Language Server installed at `~/.local/share/lsp-servers/c4-dsl-language-server/`

## Commands

The following commands are available:

- `:StructurizrLsp` - Start the LSP for structurizr files
- `:StructurizrStatus` - Check LSP client status and attached buffers
- `:StructurizrAttach` - Force attach the current buffer to the LSP
- `:StructurizrLogs` - View LSP wrapper logs
- `:StructurizrOutput` - View server stdout for debugging
- `:StructurizrErrors` - View server stderr for debugging

## Automatic Features

- Filetype detection for `.c4` and `.dsl` files
- TreeSitter syntax highlighting
- LSP auto-start when a structurizr file is opened

## Debugging

If you encounter issues, logs are available in `~/.cache/c4-lsp-logs/`. Use the provided commands to view these logs:

- `simple-wrapper.log` - Logs from the wrapper script
- `server-output.log` - Raw stdout from the LSP server
- `server-error.log` - Raw stderr from the LSP server

## How It Works

The Structurizr C4 DSL Language Server is a Java application that needs special handling for its output to work with Neovim's LSP client. This plugin uses a wrapper script to handle the server's output and ensure proper LSP communication.

The wrapper script:
1. Handles LSP server startup
2. Manages logging configuration
3. Ensures proper LSP protocol communication

## Troubleshooting

If the LSP isn't working correctly:

1. Check if the language server is installed at `~/.local/share/lsp-servers/c4-dsl-language-server/`
2. Ensure Java is installed and working correctly
3. View the logs with `:StructurizrLogs` and `:StructurizrErrors`
4. Try manually starting the LSP with `:StructurizrLsp`
5. Force attach the buffer with `:StructurizrAttach`