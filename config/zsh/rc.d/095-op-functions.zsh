# Shell completions for CLI tools wrapped with op run
# These tools use 1Password for secret injection but completion doesn't need auth

# opencode completion - bind to 'oc' function defined in 090-aliases.zsh
znap eval opencode 'opencode completion'
compdef _opencode_yargs_completions oc

# claude completion - auto-updated community plugin
# https://github.com/wbingli/zsh-claudecode-completion
znap source wbingli/zsh-claudecode-completion
compdef _claude cld
