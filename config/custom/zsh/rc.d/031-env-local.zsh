## Local environment overrides (no secrets in repo)
# Intentionally left empty. Put any sensitive exports in a private file
# outside of version control (already sourced by zsh/.zshenv):
#   - Use: zsh/.zshenv.priv (gitignored) for secrets like tokens/passwords
#   - Or use 1Password: `op run --env-file=... -- zsh` for ephemeral env

# Example (uncomment and set via private file only):
# export NEO4J_PASSWORD="${NEO4J_PASSWORD:-}"
# export OP_SERVICE_ACCOUNT_TOKEN="${OP_SERVICE_ACCOUNT_TOKEN:-}"

HF_TOKEN="op://AI/HF_CLI_TOKEN/password"
