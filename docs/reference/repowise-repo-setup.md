# Repowise repo setup — runbook

Full setup of one repo: opus prose wiki, gemini embeddings, decision extraction from ADRs +
git + comments, review, and the checks that prove our pi tooling sees the result. Done on
dotfiles 2026-09-17 (E9 in `docs/otel_retro/2026-09-16-experiments-ledger.md`); written for
redoing it on the swapc repos on the mac.

## Prereqs

- `repowise` 0.50.x (`uv tool`), `claude` CLI logged in (claude_cli bills the subscription;
  `llm_costs` stays empty and the init summary says `$0.00` — expected).
- `GEMINI_API_KEY` in the shell for the run. `--save-key` does **not** persist it (only the
  provider key, and claude_cli has none). Write it yourself, or `repowise mcp`/`update` embed
  with nothing:
  ```sh
  (umask 077; printf 'GEMINI_API_KEY=%s\n' "$GEMINI_API_KEY" > .repowise/.env)
  ```
  `.repowise/` is gitignored; check with `git check-ignore -v .repowise/.env`.

## Run

1. Dry run — free, ~7s on dotfiles (476 files), minutes on big repos (builds the full graph):
   ```sh
   repowise init --dry-run --provider claude_cli --model claude-opus-5 --prose --no-editor-setup
   ```
   Read the Generation Plan table: "N by model" is the opus spend. Ignore the decisions line in
   dry-run — it reads the *existing* config, so a repo with no provider still prints
   "Not run: git history (No LLM provider is configured)".
2. Real run:
   ```sh
   repowise init --provider claude_cli --model claude-opus-5 --embedder gemini --prose \
     --no-editor-setup --no-claude-md --no-agents --concurrency 4
   ```
   `--concurrency 4` fine for claude_cli (warning at 10 is about timeouts; `--resume` picks up
   where it stopped). `--no-claude-md --no-agents` when the repo owns its AGENTS.md — persists as
   `editor_files: {claude_md: false, agents_md: false}` in `.repowise/config.yaml`.
   dotfiles: 4m07s, 135 pages (11 model), 23.6k tokens, 31 decision candidates.
3. Check what ran: `repowise decision status` — every source should say `enabled` with
   `Records > 0` for adr/git_archaeology/comment. `skipped_no_provider` means the provider never
   reached the analysis phase (the swapc "0 decisions" symptom — re-run init with `--provider`).

## Review decisions

```sh
repowise decision candidates          # Acceptable column says why one is blocked
repowise decision confirm ID ID ...   # the ready ones
repowise decision confirm ID --scope path/to/file --scope path/to/dir   # "no scope" ones
repowise decision confirm ID --scope ... --reason '...'                 # "no rationale" ones
repowise decision health              # ungoverned hotspots, stale
```

ADR-derived candidates are usually blocked on scope (the ADR names the choice, not the files).
Scope them to the governed files, not the ADR — `get_why docs/adr/0001…` stays archaeology,
`get_why config/omarchy/hypr/bindings.lua` answers from the decisions.

**Then backfill links (upstream bug, 0.50.0):** `confirm --scope` stores `affected_files` but
writes no `decision_node_links`, and the augment hook scores decisions by links → the ones you
scoped never reach the SessionStart block or the edit-time notice. Fix:

```sh
~/.local/share/uv/tools/repowise/bin/python - <<'EOF'
import sqlite3, json, uuid, datetime, os
c=sqlite3.connect('.repowise/wiki.db')
rows=c.execute("select id, repository_id, affected_files_json, affected_modules_json from decision_records where status='active'").fetchall()
have={r[0] for r in c.execute("select distinct decision_id from decision_node_links")}
n=0
for did, rid, fj, mj in rows:
    if did in have: continue
    files=json.loads(fj or '[]'); mods=json.loads(mj or '[]') or sorted({os.path.dirname(f) for f in files if os.path.dirname(f)})
    for node, lt in [(f,'file') for f in files]+[(m,'module') for m in mods]:
        c.execute("insert into decision_node_links(id,repository_id,decision_id,node_id,link_type,created_at) values(?,?,?,?,?,?)",
                  (uuid.uuid4().hex, rid, did, node, lt, datetime.datetime.now(datetime.UTC).isoformat(' ')))
        n+=1
c.commit(); print('inserted',n,'links for',len(rows)-len(have),'decisions')
EOF
```

`repowise decision candidates` again afterwards — confirming can surface a new candidate
(dotfiles: ADR 0003 appeared only after the first batch).

## Verify the pi tooling sees it

Drive `repowise-augment` directly with the payloads `repowise-augment.ts` sends; no pi
session needed. `SID` is any string; `F` an absolute path to a governed file.

```sh
# SessionStart: needs a dirty/branch-changed governed file, silent on a clean main by design
echo '# tmp' >> "$F"
printf '{"hook_event_name":"SessionStart","source":"startup","cwd":"%s","session_id":"%s"}' "$PWD" $SID | repowise-augment
# expect: freshness line + "[repowise] Standing decisions relevant …" (≤ 400 tok, ≤ 6 items)

# Edit notice (max 3/session)
printf '{"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"x","new_string":"y"},"cwd":"%s","session_id":"%s","tool_response":{"output":"ok"}}' "$F" "$PWD" $SID | repowise-augment
# expect: "[repowise] <file> is governed by a standing decision: …"
git checkout "$F"
```

Read-path stale notice needs a Read payload with `tool_response.file.content` before and after
the edit; see E8/E9 for the shape. In a live pi session: Logfire
`span_name='pi.augment.fired' AND attributes->>'pi.augment.event'='SessionStart'` → `hit`,
`chars`; system prompt tail carries `<!-- repowise:session -->`.

Git hooks: global `core.hooksPath=~/.config/git/hooks` (post-commit/merge/checkout →
`config/custom/git/hooks/post-commit`); commit → `.repowise/.update.log` gets a
`--- post-commit hook fired …` line.

## Gotchas

- `state.json` `docs_mode: deterministic` is stale after a prose run; truth is
  `sqlite3 .repowise/wiki.db "select page_type, coalesce(model_name,'-'), count(*) from wiki_pages group by 1,2"`.
- `repowise update` (every hook fire) rewrites `.vscode/mcp.json` + `extensions.json`. No config
  flag: the VS Code writer only honours CLI `disabled_project_files`, which `update` never passes.
  Gitignore `.vscode/` or accept.
- Decisions on hidden dotfiles (`config/custom/zsh/.zshenv`) show `staleness 1.00` with
  "nothing changed" — cosmetic, not chased.
- Dry-run decisions line and `--prose` cost estimate are both meaningless with claude_cli.
- `repowise update` "Pages to regenerate: 7 … Pages updated 0" after a docs/json-only commit is
  normal: md/json/toml have no pages, the 7 are cascade candidates that get dropped. A code file
  with a page does regenerate (probe: 1 page in 4.5s from the hook). `model_name` on `file_page`
  rows is just the provider tag — those pages are structural (0 tokens). Whether `update` calls
  opus for a *module* page from the hook context is **unverified**; check the first time a
  cascade actually picks one (`input_tokens > 0` on a `module_page` row with a fresh `updated_at`).
- `.repowise/.env` loading under the hook: no embed errors in the log, but no positive proof
  either (lancedb `wiki_pages` stayed at 166 rows across the probe). Verify on swapc with a
  commit that adds a new code file: row count must grow.

## swapc (mac)

State 2026-09-16: shopmr/shopai/merchdash/apollo-monorepo have opus module pages but **0
decisions with provider set** — check `repowise decision status` per repo; `skipped_no_provider`
or `Records 0` on git_archaeology means extraction never ran → rerun step 2 (`--resume` keeps the
wiki). Small repos (admdash, analytics-dbt, shopargo, shopiac, protobuf-registry) same check.
Workspace `~/dev/swapc/.repowise-workspace.yaml`, default repo shopmr. Needs `git pull` +
`dotter` first (hooks, augment extension, guards). Per-repo: `git check-ignore .vscode` before
the first hook fire.
