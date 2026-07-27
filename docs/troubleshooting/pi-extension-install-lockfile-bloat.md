# pi extension install/uninstall takes minutes

## Symptom

Installing or uninstalling any pi extension hangs for minutes. Reproducible outside pi — `cd ~/.config/pi/agent/npm && npm u <package>` is equally slow. Network is not the bottleneck: the time is user CPU inside npm's arborist.

Measured 2026-07-27: `npm install --dry-run` took **480 s** (405 s user CPU).

## Cause

`~/.config/pi/agent/npm/package-lock.json` had grown to **27.3 MB / 38,252 entries** for only 41 declared dependencies. 37,328 of them (97.6%) were `extraneous` entries under paths that do not exist:

```
../../../.config/.config/.config/… ×N …/pi/agent/npm/node_modules/bl
```

61 distinct prefixes, one per nesting depth, ~700 entries each.

### Why it compounds

Every npm run resolves each lock key against the tree root, then re-relativizes it. With root `~/.config/pi/agent/npm`:

- `../../../` lands on `~/.config`
- writing it back yields `../../../.config/…` — exactly **one more `.config/` level**

So each install adds ~700 entries. 61 levels ≈ 60 installs since the first bad write.

### Where the seed comes from

pi spawns npm as `npm install <spec> --prefix <installRoot> --legacy-peer-deps` but passes no `cwd` (`dist/core/package-manager.js:1475` builds the args; `:919` / `:1480` call it, and `spawnCommand` uses `cwd: options?.cwd` → `undefined`). npm therefore inherits pi's cwd — your project directory — while `--prefix` points elsewhere.

Some npm/pi version wrote lock keys relative to **cwd** instead of the prefix root. The `../../../` depth means that cwd was 3 levels below `$HOME`. One such write is enough; the loop above does the rest forever.

npm 11.17.0 does not reproduce the seeding, so the accumulated garbage is historical — but it never self-heals.

## Detection

```bash
ls -la ~/.config/pi/agent/npm/package-lock.json          # healthy: ~300 KB
grep -c '"\.\./' ~/.config/pi/agent/npm/package-lock.json # healthy: 0
grep -c extraneous ~/.config/pi/agent/npm/package-lock.json # healthy: 0
```

Lock creeping past ~1 MB with `../` keys present means the seed is back.

## Fix

Strip the relative-path entries, keeping every real entry so versions are preserved (no re-resolution, no surprise upgrades):

```bash
cd ~/.config/pi/agent/npm
cp package-lock.json package-lock.json.bloated.bak

node -e '
const fs=require("fs");
const l=JSON.parse(fs.readFileSync("package-lock.json","utf8"));
const out={};
for (const [k,v] of Object.entries(l.packages)) if (!k.startsWith("../")) out[k]=v;
l.packages=out;
fs.writeFileSync("package-lock.json", JSON.stringify(l,null,2));
'

npm install --legacy-peer-deps   # prunes stale dirs, ~6 s
```

Result: 27.3 MB → 305 KB, dry-run 480 s → **1.17 s**.

`npm install` also prunes ~48 top-level dirs (`openai`, `google-auth-library`, `gaxios`, `chalk`, …) — stale transitive deps of the `@earendil-works/pi-coding-agent` peer. Expected: `--legacy-peer-deps` skips peers by design, and pi provides those APIs from its own install. All 41 declared extensions stay.

Deleting the lock outright also works but re-resolves every version range. Prefer the strip.

## Upstream

Worth reporting on pi: pass `cwd: installRoot` to the spawn instead of relying on `--prefix` with an inherited cwd. That removes the cwd/prefix split that seeds the relative keys.
