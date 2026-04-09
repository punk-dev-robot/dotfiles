##
# Plugins from frameworks

# Prezto
(( $+commands[yay] )) && zstyle ':prezto:module:pacman' frontend 'yay'
if [[ "$OSTYPE" == linux* ]]; then
  znap source sorin-ionescu/prezto modules/{docker,pacman,ssh}
else
  znap source sorin-ionescu/prezto modules/{docker,ssh}
fi

# oh-my-zsh lib
znap source ohmyzsh/ohmyzsh lib/{functions,git}.zsh

# oh-my-zsh plugins
local -a zsh_plugins=(
  ansible
  aliases
  eza
  git
  golang
  kubectl
  node
  pip
  python
  # rust
  terraform
  tmux
  yarn
)
# Linux-only OMZ plugins
if [[ "$OSTYPE" == linux* ]]; then
  zsh_plugins+=(archlinux podman systemadmin systemd)
fi

# Load each plugin, one at a time.
local p=
for p in $zsh_plugins; do
  znap source ohmyzsh/ohmyzsh plugins/$p
done

