# Prefix Matt Pocock skills with `cock-`

## Context

Matt Pocock skills installed **globally via tessl**:

- Manifest: `~/.tessl/tessl.json` → dep `mattpocock/skills` pinned to commit `8b36d4f`, 20 skills included (`grilling`, `tdd`, `implement`, `research`, `wizard`, `prototype`, `triage`, …)
- Store: `~/.tessl/plugins/mattpocock/skills/skills/{engineering,productivity}/<skill>/SKILL.md`
- Exposed via symlinks: `~/.agents/skills/tessl__<skill>`, `~/.claude/skills/tessl__<skill>`, `~/.codex/skills/tessl__<skill>` — all point into the plugin store, so patching the store fixes every agent at once.

Problem: agents surface the **frontmatter `name:`**, which is bare (`grilling`, `wizard`, `implement`, `research`…). No namespace → generic trigger words fire constantly, feels invasive. The `tessl__` dir prefix doesn't help because the name comes from frontmatter.

Safe precedent: name/dir mismatch already exists today (`tessl__grilling` dir, `name: grilling`) and works — frontmatter-only rename is fine, no dir renames needed.

**User decisions:** prefix = `cock-` (colon invalid in skill names), approach = patch-in-place script, scope = mattpocock skills only.

## Approach

tessl has no alias/prefix feature (checked `tessl --help`, `tessl install --help`), so: idempotent patch script in dotfiles that rewrites `name:` in the plugin store. tessl keeps owning updates; after `tessl update` the script is re-run once (updates overwrite SKILL.md → names revert to bare → re-patch).

Script sketch (~10 lines, POSIX sh):

```sh
#!/bin/sh
# Re-run after `tessl update` — updates overwrite SKILL.md names.
set -eu
for f in "$HOME"/.tessl/plugins/mattpocock/skills/skills/*/*/SKILL.md; do
  sed -i '' 's/^name: \(cock-\)\{0,1\}/name: cock-/' "$f"
done
grep -h '^name:' "$HOME"/.tessl/plugins/mattpocock/skills/skills/*/*/SKILL.md
```

(The `\(cock-\)\{0,1\}` makes it idempotent — strips an existing prefix before re-adding. Only line 2 of each file starts with `name: `, and frontmatter `name:` is always first-match; if any body line starts with `name: ` we anchor to the frontmatter block instead — verify during implementation.)

Note: skill *names* become `cock-grilling` etc.; symlink dirs stay `tessl__*`. Descriptions untouched — the name prefix alone gives the namespace.

## Files to modify

| File | Change |
|---|---|
| `local/bin/tessl-cock-prefix` (new) | Idempotent patcher script, executable. Deploys to `~/.local/bin/tessl-cock-prefix` via existing dotter mapping `"local" = "~/.local"` (`.dotter/global.toml:13`) — no dotter config change needed |
| `AGENTS.md` or `docs/` | One-line note: after `tessl update`, run `tessl-cock-prefix` |

## Reuse

- Dotter mapping `"local" = "~/.local"` already deploys everything in `local/bin/` — drop the script in, `dotter deploy`, done.
- Existing `local/bin/` scripts (e.g. `cymbal-prune-index`) as style reference.

## Steps

- [ ] Write `local/bin/tessl-cock-prefix`, `chmod +x`
- [ ] Verify sed only touches the frontmatter `name:` line (check a body-`name:` false positive doesn't exist across the 20 files)
- [ ] `dotter deploy` (preview with `dotter -v -d` first)
- [ ] Run `tessl-cock-prefix` once
- [ ] Add re-run note to docs
- [ ] Commit

## Verification

- `grep -h '^name:' ~/.tessl/plugins/mattpocock/skills/skills/*/*/SKILL.md` → all 20 lines read `name: cock-…`
- Run script twice → second run is a no-op (no `cock-cock-`)
- Fresh pi/claude session: skills list shows `cock-grilling`, `cock-tdd`, …; `notion`, `gh-stack`, `learning-*` unchanged
