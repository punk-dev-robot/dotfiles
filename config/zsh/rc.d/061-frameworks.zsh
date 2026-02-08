##
# Plugins from frameworks

# Prezto
zstyle ':prezto:module:pacman' frontend 'yay'
# znap source sorin-ionescu/prezto modules/{docker,pacman}
znap source sorin-ionescu/prezto modules/{docker,pacman,ssh}

# oh-my-zsh lib
znap source ohmyzsh/ohmyzsh lib/{functions,git}.zsh

# oh-my-zsh plugins
local -a zsh_plugins=(
  archlinux
  ansible
  aliases
  eza
  git
  golang
  kubectl
  node
  pip
  podman
  python
  # rust
  systemadmin
  systemd
  terraform
  tmux
  yarn
)

# Load each plugin, one at a time.
local p=
for p in $zsh_plugins; do
  znap source ohmyzsh/ohmyzsh plugins/$p
done

