# Shell Utility Library

A collection of reusable shell functions for the dotfiles project.

## Credits

This library incorporates code from:
- [labbots/bash-utility](https://github.com/labbots/bash-utility) - Comprehensive bash utility library (MIT License)
- [Nathaniel Landau's bash utilities](https://natelandau.com/bash-scripting-utilities/) - Simple, elegant utility functions

## Usage

```bash
#!/bin/bash
# Source the core library
source "$ZSH_LIB_DIR/core.sh"

# Load additional modules as needed
shell::load "logging"
shell::load "notifications"
shell::load "banners"

# Use the functions
log::info "Starting script..."
notify::success "Operation Complete" "All tasks finished successfully"
banner::rainbow_cow "Hello World!"
```

## Available Modules

### core.sh
- `shell::load` - Load a library module
- `shell::source_if_exists` - Safely source a file
- `shell::load_vendor` - Load vendor libraries

### colors.sh
- Color variables: `$RED`, `$GREEN`, `$BLUE`, etc.
- Functions: `color::red`, `color::bold`, etc.

### logging.sh
- `log::info`, `log::success`, `log::error`, `log::warning`
- `log::header`, `log::section`, `log::separator`
- All functions also log to systemd journal

### notifications.sh
- `notify::critical`, `notify::warning`, `notify::normal`, `notify::low`
- `notify::success`, `notify::info`
- `notify::disk`, `notify::backup`, `notify::system`
- Works correctly from systemd services

### banners.sh
- `banner::cowsay`, `banner::rainbow_cow` 🐄
- `banner::figlet`, `banner::rainbow_figlet` 
- `banner::toilet`, `banner::rainbow_toilet` 🌈
- `banner::celebrate`, `banner::alert`, `banner::section`
- `banner::box` - Text in various box styles
- `banner::fortune_cow` - Fortune cookie wisdom from animals
- `banner::misfortune_tux` - Cynical wisdom from Tux
- `banner::daily_wisdom` - Random fortune or misfortune
- `banner::fortune_topic` - Topic-specific fortunes

## Vendor Libraries

The `vendor/` directory contains:
- `bash-utility/` - Full featured bash library with 100+ functions
- `landau-utils.sh` - Nathaniel Landau's utility functions

Load vendor functions with:
```bash
shell::load_vendor "bash-utility" "string"  # Load string module
shell::load_vendor "landau"                 # Load Landau utilities
```

## Environment

Set `ZSH_LIB_DIR` to the library directory, or it will auto-detect.

## Fun Banner Tools

Install these for maximum fun:
- `cowsay` - ASCII art animals
- `figlet` - ASCII art text
- `toilet` - Fancy ASCII art with filters
- `boxes` - Text in decorative boxes
- `lolcat` - Rainbow colored output
- `fortune` - Random quotes and wisdom
- `misfortune` - Cynical and dark humor quotes

Run `banner::list_styles` to see all available banner functions!

## Daily Wisdom Example

Add to your shell startup for daily inspiration:
```bash
# In .zshrc or .bashrc
if [[ -f "$ZSH_LIB_DIR/core.sh" ]]; then
    source "$ZSH_LIB_DIR/core.sh"
    shell::load "banners"
    banner::daily_wisdom
fi
```