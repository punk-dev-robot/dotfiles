##
# Plugins from frameworks

# Prezto
(( $+commands[yay] )) && zstyle ':prezto:module:pacman' frontend 'yay'
if [[ "$OSTYPE" == linux* ]]; then
  znap source sorin-ionescu/prezto modules/{docker,pacman}
else
  znap source sorin-ionescu/prezto modules/docker
fi

# omz plugins outside the framework need ZSH_CACHE_DIR (kubectl etc. write completions there)
export ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/ohmyzsh
mkdir -p $ZSH_CACHE_DIR/completions
fpath+=( $ZSH_CACHE_DIR/completions )

# oh-my-zsh lib
znap source ohmyzsh/ohmyzsh lib/{functions,git}.zsh

# oh-my-zsh plugins — all in one znap source call (one clone-check subshell vs N)
# removed: ansible (unused at company), node (fnm owns it), pip/python (uv ecosystem), yarn (using pnpm)
znap source ohmyzsh/ohmyzsh \
  plugins/aliases \
  plugins/eza \
  plugins/git \
  plugins/golang \
  plugins/kubectl \
  plugins/terraform \
  plugins/tmux

if [[ "$OSTYPE" == linux* ]]; then
  znap source ohmyzsh/ohmyzsh \
    plugins/archlinux \
    plugins/podman \
    plugins/systemadmin \
    plugins/systemd
fi

