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
export PNPM_HOME="$HOME/.local/share/pnpm"  # pnpm reads this for global installs
path=("$PNPM_HOME/bin" $path)               # prepend: must win over per-version npm bins
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
# CLAUDE_CONFIG_DIR and CODEX_HOME moved to .zshenv — must apply to non-interactive shells too
znap eval basic-memory 'basic-memory --show-completion'  
# znap eval thv 'thv completion zsh' 

# Composio CLI
export COMPOSIO_INSTALL_DIR="/Users/kuba.gaj/.composio"
export PATH="$COMPOSIO_INSTALL_DIR:$PATH"


# Added by Cupcake installer
export PATH="/Users/kuba.gaj/.cupcake/bin:$PATH"


# repowise: never write editor-wiring files (.mcp.json, .claude/, .vscode/) — pi MCP config owns integration
export REPOWISE_SKIP_EDITOR_SETUP=1
