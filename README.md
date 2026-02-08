# dotfiles

Personal configuration files for Arch Linux with Hyprland, managed with [dotter](https://github.com/SuperCuber/dotter).

## Key Tools

- **Window Manager:** [Hyprland](https://hyprland.org/) with Hypridle, Hyprlock, Hyprpaper
- **Shell:** ZSH with fzf-tab, modern CLI replacements (eza, bat, ripgrep, fd, zoxide)
- **Editor:** Neovim with lazy.nvim
- **Terminal:** Alacritty
- **Theme:** Catppuccin Mocha

## Structure

```
config/     Application configs (hypr, nvim, zsh, waybar, etc.)
etc/        System-level configs (mkinitcpio, grub, udev rules)
local/      User scripts and binaries
docs/       Configuration decisions, hardware notes, and fix documentation
```

## Usage

These dotfiles use [dotter](https://github.com/SuperCuber/dotter) for deployment. Symlink mappings are defined in `.dotter/global.toml`.

```sh
dotter deploy
```

## License

[MIT](LICENSE)
