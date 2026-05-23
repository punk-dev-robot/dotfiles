# node
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
if [[ -f "$NPM_CONFIG_USERCONFIG" ]]; then
  export NPM_TOKEN=$(grep _authToken "$NPM_CONFIG_USERCONFIG" | sed 's/.*=//')
fi
# Set Node.js memory limit to 8GB for 64GB system
export NODE_OPTIONS="--max-old-space-size=8192"
path+=("./node_modules/.bin")
path+=("$HOME/.node_modules/bin")
path+=("$HOME/.yarn/bin")
path+=("$HOME/.npm-global/bin")
znap eval fnm 'fnm env --use-on-cd'
znap eval pnpm 'pnpm completion zsh'

# docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
[[ -S "$XDG_CONFIG_HOME/colima/default/docker.sock" ]] && export DOCKER_HOST="unix://$XDG_CONFIG_HOME/colima/default/docker.sock"
export DOCKER_HIDE_LEGACY_COMMANDS=true
# rust
path+=("$HOME/.cargo/bin")

# go
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
path+=("$GOBIN")

# python
znap eval hf 'command hf --show-completion'
znap eval uv 'uv generate-shell-completion zsh'

# lua5.1 is in /usr/local/bin
export LUAROCKS_CONFIG="$XDG_CONFIG_HOME/luarocks/config-5.4.lua"
# TODO: this unsets some PATH like the one for fnm
# znap eval luarocks 'luarocks path'

# git
znap eval scmpuff 'scmpuff init -s --aliases=false'
alias gs='scmpuff status'
# znap fpath '_glab' 'glab completion -s zsh'  # not used at current company

# aws
export AWS_PAGER=""
complete -C aws_completer aws

# localstack
# throws errors
# znap fpath '_localstack' 'localstack completion zsh'
# znap eval localstack 'localstack completion zsh'

# ai
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"
export CODEX_HOME="$XDG_CONFIG_HOME/codex"
znap eval basic-memory 'basic-memory --show-completion'  
# znap eval thv 'thv completion zsh' 

# Composio CLI
export COMPOSIO_INSTALL_DIR="/Users/kuba.gaj/.composio"
export PATH="$COMPOSIO_INSTALL_DIR:$PATH"

export LINEAR_TEAM_ID=62f87de9-2d7b-401d-8bbd-749477d7a773
