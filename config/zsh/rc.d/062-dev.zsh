# node
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NPM_TOKEN=$(cat $NPM_CONFIG_USERCONFIG | grep _authToken | sed 's/.*=//')
# Set Node.js memory limit to 8GB for 64GB system
export NODE_OPTIONS="--max-old-space-size=8192"
path+=("./node_modules/.bin")
path+=("$HOME/.node_modules/bin")
path+=("$HOME/.yarn/bin")
path+=("$HOME/.npm-global/bin")
znap eval fnm 'fnm env --use-on-cd'
# pnpm aliases
znap source ntnyq/omz-plugin-pnpm 
# use either this (installed with yay pnpm-shell-completion)
# source /usr/share/zsh/plugins/pnpm-shell-completion/pnpm-shell-completion.zsh
# or
znap eval pnpm 'pnpm completion zsh'

# docker
export DOCKER_HIDE_LEGACY_COMMANDS=true
# rust
path+=("$HOME/.cargo/bin")

# go
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
path+=("$GOBIN")

# python
# vitualenvwrapper
# export WORKON_HOME=$HOME/.virtualenvs
# source '/usr/bin/virtualenvwrapper.sh'
# export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
znap eval hf 'hf --show-completion'

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && path=("$PYENV_ROOT/bin" $path)
znap eval pyenv 'pyenv init -'
znap eval pipx-argcomplete 'register-python-argcomplete pipx'

# lua5.1 is in /usr/local/bin
export LUAROCKS_CONFIG="$XDG_CONFIG_HOME/luarocks/config-5.4.lua"
# TODO: this unsets some PATH like the one for fnm
# znap eval luarocks 'luarocks path'

# git
znap eval scmpuff 'scmpuff init -s --aliases=false'
alias gs='scmpuff status'
znap fpath '_glab' 'glab completion -s zsh'

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
