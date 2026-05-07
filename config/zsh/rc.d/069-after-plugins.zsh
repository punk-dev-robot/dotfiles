# 1Password setup
znap eval op 'op completion zsh'
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Only call zle reset-prompt when crossing vicmd↔viins boundary (visual change).
# Prevents unnecessary starship subprocess spawns on spurious keymap-select events.
starship_zle-keymap-select() {
  case $KEYMAP in
    vicmd) [[ $_starship_kmap != vicmd ]] && zle reset-prompt ;;
    *)     [[ $_starship_kmap == vicmd ]] && zle reset-prompt ;;
  esac
  _starship_kmap=$KEYMAP
}
zle -N zle-keymap-select starship_zle-keymap-select
