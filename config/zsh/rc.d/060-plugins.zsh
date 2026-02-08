##
# Plugins
#

# Add the plugins you want to use here.
# For more info on each plugin, visit its repo at github.com/<plugin>
# -a sets the variable's type to array.
# local -a plugins=(
    # TODO: check them out
    # marlonrichert/zsh-autocomplete      # Real-time type-ahead completion
    # marlonrichert/zsh-edit              # Better keyboard shortcuts
    # marlonrichert/zsh-hist              # Edit history from the command line.
    # marlonrichert/zcolors               # Colors for completions and Git
    # zsh-users/zsh-autosuggestions       # Inline suggestions
    # zdharma-continuum/fast-syntax-highlighting   # Command-line syntax highlighting
#     zsh-users/zsh-syntax-highlighting   # Command-line syntax highlighting
# )

# Speed up the first startup by cloning all plugins in parallel.
# This won't clone plugins that we already have.
# znap clone $plugins

# Load each plugin, one at a time.
# local p=
# for p in $plugins; do
#   znap source $p
# done

znap source jeffreytse/zsh-vi-mode

# `znap eval <name> '<command>'` is like `eval "$( <command> )"` but with
# caching and compilation of <command>'s output, making it ~10 times faster.

export YSU_MODE=ALL
export YSU_MESSAGE_POSITION=after
# export YSU_HARDCORE=1
znap source MichaelAquilina/zsh-you-should-use

# fzf-tab
# apply to all command
zstyle ':fzf-tab:*' popup-min-size 80 12
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
# use tmux-popup
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
znap source Aloxaf/fzf-tab

znap source zsh-users/zsh-autosuggestions       # Inline suggestions
znap source zsh-users/zsh-syntax-highlighting   # Command-line syntax highlighting
znap source catppuccin/zsh-syntax-highlighting themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
# znap source grigorii-zander/zsh-npm-scripts-autocomplete zsh-npm-scripts-autocomplete.plugin.zsh # auto-complete for package.json scripts


znap eval zoxide 'zoxide init zsh'
znap eval direnv 'direnv hook zsh'
znap eval copilot 'gh copilot alias -- zsh'


#
# start atuin (can't be deferred in plugins)
# zsh vi-mode/atuin temp fix https://github.com/atuinsh/atuin/issues/977
zvm_after_init_commands+=(eval "$(atuin init zsh --disable-up-arrow)")

# enable smooth scrolling, blured backgrounds and window animations
# may be causing some bugs
# export NEOVIDE_MULTIGRID=true
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep

# FZF respect version control ignore files excluding hidden files
export FZF_DEFAULT_COMMAND='fd --type file --hidden --exclude .git --color always --follow'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# catppuccin mocha
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

# source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
source /home/kuba/.config/broot/launcher/bash/br
