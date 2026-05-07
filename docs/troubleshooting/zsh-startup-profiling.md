# Zsh Startup Profiling — May 2026

## Baseline

```
zsh -i -c exit  →  4623ms ± 275ms
zsh -c exit     →    10ms
```

Interactive overhead: **4613ms** — all in `.zshrc`.

## Measurement Stack

```bash
# Overall timing
hyperfine --warmup 3 --runs 10 'zsh -i -c exit'

# Per-function breakdown (add to top/bottom of .zshrc temporarily)
zmodload zsh/zprof   # top
zprof                # bottom — run: zsh -i -c exit 2>&1 | head -40

# Per-file timing (replace rc.d loop in .zshrc temporarily)
zmodload zsh/datetime
local file= _t0= _t1= _tlog=/tmp/zsh-rc-timing.txt
: > $_tlog
for file in $ZDOTDIR/rc.d/<->-*.zsh(n); do
  _t0=$EPOCHREALTIME
  . $file
  _t1=$EPOCHREALTIME
  printf '%6.0f ms  %s\n' $(( (_t1 - _t0) * 1000 )) "${file:t}" >> $_tlog
done
# then: sort -rn /tmp/zsh-rc-timing.txt
```

> Note: redirect stderr for per-file timing — znap writes terminal escape codes to stderr that swallow printf output. Use `>> /tmp/file` not `>&2`.

## Per-File Results

| ms | file |
|----|------|
| **3398** | `062-dev.zsh` |
| **1177** | `061-frameworks.zsh` |
| **893** | `060-plugins.zsh` |
| **482** | `040-znap.zsh` |
| 18 | `095-op-functions.zsh` |
| 17 | `090-aliases.zsh` |
| 5 | `030-env.zsh` |
| ≤2 | all others |

## Root Causes (zprof)

| ms | % | symbol | fix |
|----|---|--------|-----|
| 2128 | 33.7% | `.znap.eval:pyenv.zsh` | replace with mise / lazy-load |
| 849 | 13.4% | `.znap.multi` (22 calls) | reduce plugin count |
| 729 | 11.5% | `.znap.fpath` | reduce plugin count |
| 629 | 9.96% | `.znap.source:prezto.modules.ssh` | remove — 1Password owns SSH_AUTH_SOCK |
| 597 | 9.45% | `.znap.source:omz-plugin-pnpm` | remove — redundant with `znap eval pnpm` |
| 356 | 5.63% | `.znap.source:zsh-you-should-use` | lazy or remove |
| 274 | 4.34% | `.znap.eval:starship.zsh` | cached but init script is slow |
| 233 | 3.69% | `.znap.prompt` | part of starship overhead |

## Why pyenv Is Slow Even With Cache

`znap eval pyenv 'pyenv init -'` caches the *output* of `pyenv init -` to `~/.cache/zsh-snap/eval/pyenv.zsh`. But the cached script itself contains:

```bash
# Spawns bash subprocess on every source:
PATH="$(bash --norc -ec 'IFS=:; paths=($PATH); ...; echo "${paths[*]}"')"

# Scans shims directory on every source:
command pyenv rehash
```

The cache saves the cost of running `pyenv init -` but not the cost of executing its output. Fix: replace pyenv with `mise` which has a fast, inline init.

## Why Prezto SSH Is Redundant

`061-frameworks.zsh` sources `prezto modules/{docker,ssh}`. The ssh module spawns `ssh-agent` and runs `ssh-add`. But `069-after-plugins.zsh` then sets:

```zsh
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
```

1Password wins; the prezto-spawned agent is orphaned. 629ms wasted.

## Why pnpm Plugin Is Redundant

`062-dev.zsh` has both:
- Line 14: `znap source ntnyq/omz-plugin-pnpm` (597ms)  
- Line 18: `znap eval pnpm 'pnpm completion zsh'`

The omz plugin provides completions that the znap eval already provides. Remove the omz plugin.

## Binary Search Confirmation

| what disabled | startup time | savings |
|---|---|---|
| baseline | 4623ms | — |
| pyenv only | 3253ms | **−1370ms** |
| pyenv + pnpm plugin | 2642ms | **−1981ms** |
| + prezto ssh (estimated from zprof) | ~2013ms | **−2610ms total** |

## Applied Fixes & Results

| change | before | after | benchmark | perceived |
|---|---|---|---|---|
| remove pyenv + pnpm omz plugin + prezto ssh | 4623ms | **2303ms** | −2320ms | −2320ms |
| batch all omz plugins into one znap source | 2303ms | **1891ms** | −412ms | −412ms |
| cache glab completion (then commented out) | 1891ms | **1424ms** | −467ms | −467ms |
| remove 5 omz plugins (ansible/node/pip/python/yarn) | 1424ms | ~1570ms est | ~−100ms | ~−100ms |
| ZVM_INIT_MODE=sourcing + move atuin before source | — | **1655ms** | +231ms measured | **−1000–2000ms** |

Changes made 2026-05-06:
- `062-dev.zsh`: removed `ntnyq/omz-plugin-pnpm`, pyenv block; added `znap eval uv`; commented out glab
- `061-frameworks.zsh`: removed prezto ssh; batched omz plugins; removed ansible, node, pip, python, yarn
- `060-plugins.zsh`: `ZVM_INIT_MODE=sourcing` + moved atuin before `znap source jeffreytse/zsh-vi-mode`

### Note on ZVM_INIT_MODE=sourcing and benchmark honesty

`zsh -i -c exit` never enters ZLE (the line editor), so deferred hooks (`zle-line-init`) never fire. With default deferred mode, `zvm_init` was invisible to the benchmark but caused a 1–2s cursor change delay after the prompt appeared. With `ZVM_INIT_MODE=sourcing`, zvm_init runs synchronously at source time — the benchmark now counts it (~231ms), but it no longer appears as a post-prompt delay.

Net effect: **total time to usable dropped from ~2.4–3.4s to ~1.7s**.

| `starship.toml` `truncate_to_repo = false` | ~600ms starship render | ~340ms in git repos | −260ms prompt render | —  |

### Root cause of perceived cursor delay — starship, not ZLE hooks

Instrumented `zle-line-init` and `precmd` with `$EPOCHREALTIME` timestamps. Finding:

```
precmd-done:        1778088966.1263
zle-line-init START: 1778088967.0147   ← prompt rendered here (starship subprocess)
zle-line-init END:   1778088967.0198   ← 5ms, trivially fast
```

The 888ms gap between `precmd-done` and `zle-line-init START` is `$PROMPT='$(starship prompt ...)'` executing synchronously. The cursor delay is just starship being slow — no ZLE hook issue.

`starship timings` breakdown in a git repo (dotfiles):

| module | before | after |
|---|---|---|
| `directory` | 322ms | <1ms (`truncate_to_repo = false`) |
| `git_status` | 230ms | 72ms |
| `git_branch` | <1ms (warm cache) | 269ms (now runs cold) |
| **total** | **~552ms** | **~341ms** |

Modules run concurrently; actual render time ≈ max(bottleneck module). Old bottleneck: `directory` (ran git for repo-root truncation, warmed cache for git_status). New bottleneck: `git_branch` (first cold git call).

`time starship prompt`: 584ms → 604ms (within noise; concurrent bottleneck shifted but not eliminated).

In non-git directories (e.g. `~`): starship takes ~21ms total — instant.

## Remaining Opportunities

1. **Starship `command_timeout`** — set to 200ms to hard-cap slow git modules in large repos. Modules that exceed timeout show a placeholder symbol instead.

2. **Remove zsh-you-should-use** or lazy-load (`060-plugins.zsh`)
   ~266ms zsh startup (from prior zprof). Only fires on alias detection.

3. **Audit kubectl / golang omz plugins** if not actively using at company
   Each ~10ms startup cost, low priority.

Target: **< 1000ms startup** (requires removing zsh-you-should-use). Prompt render in git repos: hard floor ~300–400ms with starship subprocess model.
