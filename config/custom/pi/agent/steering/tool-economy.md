---
kind: briefing
---
## Tool economy

Navigate with `read` / `grep` / `find` / `ls` — their output is compacted and cheap.
`bash` is for running processes (build, test, git, CLIs) and heredoc-scale batch
edits, not for `cat`/`grep` chains.

Own skills live in `~/dotfiles/config/custom/agents/skills/`. `~/.agents/skills` and most of
`~/.config/pi` are symlinks that `grep`/`find` skip: search the dotfiles path, or `rg -L`.
