# BROWSER env var broken for macOS .app bundles

## Symptom

Tools that respect `$BROWSER` (e.g. plannotator, `b` alias) silently fail to open URLs on macOS. The `open` command itself works fine.

## Cause

`BROWSER="zen-browser"` was set unconditionally. On macOS, Zen Browser (and most GUI browsers) are `.app` bundles — there is no `zen-browser` binary in `$PATH`. Any tool exec'ing `$BROWSER` silently fails.

The `open` command works regardless because it talks directly to `launchservicesd`, bypassing the `$BROWSER` variable.

## Fix

Make `$BROWSER` conditional on binary availability (`config/zsh/rc.d/030-env.zsh`):

```zsh
if (( $+commands[zen-browser] )); then
  export BROWSER="zen-browser"
elif [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER="open"
elif (( $+commands[xdg-open] )); then
  export BROWSER="xdg-open"
fi
```

- macOS: `open` delegates to the system default browser (Zen Browser in this case)
- Linux: `xdg-open` as fallback if `zen-browser` binary isn't in PATH

## Note on tmux

`open` works correctly inside tmux on modern macOS (Sequoia+) without `reattach-to-user-namespace` — it communicates with `launchservicesd` at the OS level.
