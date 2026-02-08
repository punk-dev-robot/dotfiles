#!/bin/zsh

##
# Commands, funtions and aliases
#
# Always set aliases _last,_ so they don't get used in function definitions.
#

# This lets you change to any dir without having to type `cd`, that is, by just
# typing its name. Be warned, though: This can misfire if there exists an alias,
# function, builtin or command with the same name.
# In general, I would recommend you use only the following without `cd`:
#   ..  to go one dir up
#   ~   to go to your home dir
#   ~-2 to go to the 2nd mostly recently visited dir
#   /   to go to the root dir
setopt auto_cd

# Type '-' to return to your previous dir.
alias -- -='cd -'
# '--' signifies the end of options. Otherwise, '-=...' would be interpreted as
# a flag.

# These aliases enable us to paste example code into the terminal without the
# shell complaining about the pasted prompt symbol.
alias %= \$=

# zmv lets you batch rename (or copy or link) files by using pattern matching.
# https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#index-zmv
autoload -Uz zmv
alias zmv='zmv -Mv'
alias zcp='zmv -Cv'
alias zln='zmv -Lv'
# Note that, unlike with Bash, you do not need to inform Zsh's completion system
# of your aliases. It will figure them out automatically.

# Set $PAGER if it hasn't been set yet. We need it below.
# `:` is a builtin command that does nothing. We use it here to stop Zsh from
# evaluating the value of our $expansion as a command.
: ${PAGER:=less}

# Use `< file` to quickly view the contents of any text file.
READNULLCMD=$PAGER  # Set the program to use for this.

# Define general aliases.
alias _='sudo '
alias b='${(z)BROWSER}'

# alias diffu="diff --unified"
alias e='${(z)VISUAL:-${(z)EDITOR}}'
alias mkdir="${aliases[mkdir]:-mkdir} -p"
alias p='${(z)PAGER}'
alias po='popd'
alias pu='pushd'
alias sa='alias | grep -i'
alias type='type -a'

# Safe ops. Ask the user before doing anything destructive.
alias cpi="${aliases[cp]:-cp} -i"
alias lni="${aliases[ln]:-ln} -i"
alias mvi="${aliases[mv]:-mv} -i"
alias rmi="${aliases[rm]:-rm} -i"
if zstyle -T ':prezto:module:utility' safe-ops; then
  alias cp="${aliases[cp]:-cp} -i"
  alias ln="${aliases[ln]:-ln} -i"
  alias mv="${aliases[mv]:-mv} -i"
  alias rm="${aliases[rm]:-rm} -i"
fi

# ls
alias ls='eza --icons=auto'
alias l='ls -1A'         # Lists in one column, hidden files.
alias ll='ls -lh'        # Lists human readable sizes.
alias lr='ls -lh -R'     # Lists human readable sizes, recursively.
alias la='ls -lh -A'     # Lists human readable sizes, hidden files.
alias lm='ls -lh -A | "$PAGER"' # Lists human readable sizes, hidden files through pager.
alias lk='ls -lh -Sr'        # Lists sorted by size, largest last.
alias lt='ls -lh -tr'        # Lists sorted by date, most recent last.
alias lc='ls -lh -c'         # Lists sorted by date, most recent last, shows change time.
alias lu='ls -lh -tr -u'     # Lists sorted by date, most recent last, shows access time.
alias lx='ll -XB'      # Lists sorted by extension (GNU only).

alias o='xdg-open'

alias pbc='wl-copy'
alias pbp='wl-paste'

# Command line head / tail shortcuts
alias H='| head'
alias T='| tail'
alias G='| rg'
alias L="| { $PAGER }"
alias M="| most"
alias LL="2>&1 | { $PAGER }"
alias CA="2>&1 | cat -A"
alias NE="2> /dev/null"
alias NUL="> /dev/null 2>&1"
alias P="2>&1| pygmentize -l pytb"

# Resource Usage
alias df='df -kh'
alias du='du -kh'

# vim
alias vi='nvim'
alias vim='nvim'
alias nv='neovide --multigrid'

# docked mode
alias lap='_ systemctl start udevmon; light -S 30'
alias desk='_ systemctl stop udevmon; light -S 100'

# bat
alias cat='bat --paging=never'

# trash-cli
# alias rm='echo "This is not the command you are looking for."; false'
alias rm='trash-put'
alias trp='trash-put'
alias tre='trash-empty'
alias trl='trash-list'
alias trr='trash-restore'
alias trrm='trash-remove'

# ai
alias cb='chatblade -c 4 -s'
alias cb3='chatblade -c 3 -s'

# docker
alias gwa='git worktree add'
alias gwls='git worktree list'
alias gwlck='git worktree lock'
alias gwmv='git worktree move'
alias gwp='git worktree prune'
alias gwdel='git worktree remove'
alias gwr='git worktree repair'
alias gwulck='git worktree unlock'
alias lg='lazygit'

# kubernetes
# alias kdhm='kubectl describe HelmChart'
# alias kdelhm='kubectl delete HelmChart'
# alias kedhm='kubectl edit HelmChart'
# alias kghm='kubectl get HelmChart'
# alias kdssec='kubectl describe SealedSecret'
# alias kdelssec='kubectl delete SealedSecret'
# alias kessec='kubectl edit SealedSecret'
# alias kgssec='kubectl get SealedSecret'

# Functions
#

# Makes a directory and changes to it.
function mkdcd {
  [[ -n "$1" ]] && mkdir -p "$1" && builtin cd "$1"
}

# Changes to a directory and lists its contents.
function cdls {
  builtin cd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

# Pushes an entry onto the directory stack and lists its contents.
function pushdls {
  builtin pushd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

# Pops an entry off the directory stack and lists its contents.
function popdls {
  builtin popd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

# Prints columns 1 2 3 ... n.
function slit {
  awk "{ print ${(j:,:):-\$${^@}} }"
}

# Finds files and executes a command on them.
function find-exec {
  find . -type f -iname "*${1:-}*" -exec "${2:-file}" '{}' \;
}

# Displays user owned processes status.
function psu {
  ps -U "${1:-$LOGNAME}" -o 'pid,%cpu,%mem,command' "${(@)argv[2,-1]}"
}

# run with nushell
nu() {
  local args\="$@"
  command nu -c "$args"
}

# terraform() {
#   local args="$@"
#   AWS_PROFILE="" command terraform "$args"
# }

function upd {
  source "$HOME/.local/bin/update-system.zsh"
}

alias psc='ps xawf -eo pid,user,cgroup,args'

# journalctl
alias jc='sudo journalctl'
alias jcj='sudo journalctl -o json --output-fields=MESSAGE,PRIORITY,_PID,SYSLOG_IDENTIFIER,_SYSTEMD_UNIT'
alias jcu='journalctl --user'
alias jcuj='journalctl --user -o json --output-fields=MESSAGE,PRIORITY,_PID,SYSLOG_IDENTIFIER,_SYSTEMD_UNIT'

# npx
alias nx='npx nx'
alias nxa='npx nx affected'
alias nxm='npx nx run-many'
alias nxsp='nx show project'

# ansible
alias apl='ansible-playbook'
alias aplc='ansible-playbook --check'

alias tlsc='tailscale'
# Claude Code with 1Password secret injection for MCP servers
# Unset service account to use desktop app auth (biometric)
# script creates PTY to workaround: https://github.com/anthropics/claude-code/issues/6820
cld() {
    OP_SERVICE_ACCOUNT_TOKEN= op run --env-file="$XDG_CONFIG_HOME/claude/secrets.env" -- script -q /dev/null -c "claude $*"
}

alias hf='op run -- hf'
alias cdx='codex'
oc() {
    OP_SERVICE_ACCOUNT_TOKEN= op run --env-file="$XDG_CONFIG_HOME/claude/secrets.env" -- script -q /dev/null -c "opencode $*"
}
alias mem='basic-memory'
alias task-master="npx -y --package task-master-ai@latest -- task-master"

