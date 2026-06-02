# dotfiles

Personal configuration files for Arch Linux (Hyprland) and macOS (AeroSpace), managed with [dotter](https://github.com/SuperCuber/dotter).

## Key Tools

- **Window Manager:** [Hyprland](https://hyprland.org/) with Hypridle, Hyprlock, Hyprpaper
- **Shell:** ZSH with fzf-tab, modern CLI replacements (eza, bat, ripgrep, fd, zoxide)
- **Editor:** Neovim with lazy.nvim
- **Terminal:** Alacritty
- **Theme:** Catppuccin Mocha

## Structure

```
config/
  shared/   Cross-platform app configs → ~/.config        (every host)
  linux/    Arch-only configs, Hyprland stack → ~/.config
  mac/      macOS-only configs, AeroSpace stack → ~/.config
  custom/   Configs needing special handling (templating, single-dir
            symlinks, or targets outside ~/.config); listed in global.toml
etc/        System-level configs, Arch only (mkinitcpio, pacman, udev rules)
local/      User scripts and binaries → ~/.local
docs/       Configuration decisions, hardware notes, and fix documentation
```

`shared/`, `linux/`, and `mac/` are each mapped with a single recursive line in
`.dotter/global.toml` (their contents flatten into `~/.config`). **Add a plain
config: just drop the dir into the right one — no `global.toml` edit needed.**
Anything requiring templating, a `recurse = false` directory symlink, or a
target outside `~/.config` goes in `custom/` and is listed explicitly.

## Usage

These dotfiles use [dotter](https://github.com/SuperCuber/dotter) for deployment. Shared mappings live in `.dotter/global.toml`; each machine selects its package and variables via a per-host file (`.dotter/<hostname>.toml`).

```sh
dotter -l .dotter/arch.toml deploy        # Arch  → base + linux + /etc
dotter -l .dotter/kubas-mac.toml deploy   # macOS → base + mac
```

## License

[MIT](LICENSE)
