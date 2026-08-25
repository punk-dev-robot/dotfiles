# zsh startup: process substitution failed + malloc double-free

## Context

Every new terminal session prints (above the first prompt):

```
(anon):2: process substitution failed: no such file or directory
zsh(...) malloc: *** error for object ...: pointer being freed was not allocated
direnv: unloading
```

## Root cause (verified by xtrace)

Traced with `echo exit | PS4='+%N:%i> ' zsh -i -x`; the error unpacks to:

```
+(anon):1> local TMPPREFIX=/completions/_kubectl
(anon):2: process substitution failed: no such file or directory
```

Chain:

1. omz kubectl plugin got commit `830a5bc` "fix: load completion files atomically (#14000)"
   — pulled in by `update-system.zsh` → `znap pull` ("multiple recent changes"). New code:

   ```zsh
   () {
     local TMPPREFIX="$ZSH_CACHE_DIR/completions/_kubectl"
     zf_mv -f -- =( kubectl completion zsh 2> /dev/null ) "$TMPPREFIX"
   } &|
   ```

2. Plugin is loaded via znap (`config/custom/zsh/rc.d/061-frameworks.zsh:22`), not the omz
   framework, so **`$ZSH_CACHE_DIR` is unset** → `TMPPREFIX=/completions/_kubectl`.
3. `=( ... )` creates its temp file at `$TMPPREFIX*` → `/completions/...` doesn't exist
   → ENOENT → `process substitution failed`.
4. The malloc line is a known **zsh 5.9 double-free** on exactly this failure path
   ([zsh-workers 2023 patch](https://zsh.org/mla/workers/2023/msg00854.html), repro:
   `TMPPREFIX=/tmp/xxx/zsh; echo =(<<<"")`); fixed post-5.9, macOS ships 5.9.
   Crash is in the backgrounded `&|` job — main shell unaffected.
5. Error appears *above* the prompt because znap's instant-prompt captures rc-phase
   stderr and replays it at first precmd (`.znap.prompt.precmd`).
6. `direnv: unloading` is unrelated/harmless: inherited direnv state unloading at
   first precmd.

Side effect of the bug: `_kubectl` completion is never generated, so the plugin's
`autoload -Uz _kubectl` binding is dead too.

## Approach

Set the omz cache dir before sourcing omz plugins — the documented requirement for
using omz plugins outside the framework. Fixes kubectl and any other omz plugin
using the same cached-completions pattern.

## Files to modify

`config/custom/zsh/rc.d/061-frameworks.zsh` — before the `znap source ohmyzsh/...` lines:

```zsh
# omz plugins outside the framework need ZSH_CACHE_DIR (kubectl etc. write completions there)
export ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/ohmyzsh
mkdir -p $ZSH_CACHE_DIR/completions
fpath+=( $ZSH_CACHE_DIR/completions )
```

`fpath` entry needed so the plugin's `autoload -Uz _kubectl` can resolve the generated file.

## Reuse

- `znap source` calls stay as-is; no plugin changes, no fork patches.
- zsh-snap fork (`punk-dev-robot/zsh-snap`) untouched — its `=(<<<'')` in `.znap.prompt`
  is fine with default `TMPPREFIX=/tmp/zsh`.

## Steps

- [x] Add ZSH_CACHE_DIR block to `config/custom/zsh/rc.d/061-frameworks.zsh` above omz sources
- [x] `dotter -v -d` to confirm, then `dotter deploy` (file is symlinked, but keep workflow)

## Verification

- [x] `echo exit | zsh -i 2>&1 | grep -ai 'anon\|malloc\|substitution'` → empty
      (note: must pipe `exit` via stdin — `zsh -ilc` never runs precmd, so znap's
      deferred stderr replay is silently swallowed and hides the error)
- [x] `ls ~/.cache/ohmyzsh/completions/_kubectl` exists after one startup
- [x] Open real new terminal → clean startup, kubectl completion works (`kubectl <TAB>`)

## Optional follow-up

- Doc a short note in `docs/troubleshooting/` (matches repo value bar: omz-plugins-via-znap
  need `ZSH_CACHE_DIR`; zsh 5.9 masks procsub failures with a malloc crash).
