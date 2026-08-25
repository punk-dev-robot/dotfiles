# herdr-automatic-rename: live per-command tab naming (preexec/precmd hooks).
# No-ops outside a herdr pane. Glob (N) = silent when plugin not installed.
for _f in ${HOME}/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
  source $_f; break
done
unset _f
