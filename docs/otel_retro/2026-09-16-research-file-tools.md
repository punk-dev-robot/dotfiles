# Research: file-operation tools for pi, by tokens returned to the model

Date: 2026-09-16 · Scope: pi 0.85.1, pi-readseek 0.9.16 (`readseek.overrideTools`) · All local
evidence re-verified on this machine; sources at the end.

## Answer (short)

Only `read`/`digest` and `write` actually *echo* file bytes at the model in pi-readseek: `digest`
returns the native JSON envelope (measured **1.94× raw**), and `write` returns the whole file as
`LINE:HASH|text` (~1.23× raw) on top of the content the model already typed in the call. `edit`
does **not** read the file back into the model channel — its model-facing text is one summary line
(`Edited <path> (N changes, +a -b lines)`); the diff/patch live in `details`, which pi documents as
UI/state, not LLM context. There is **no** setting in 0.9.16 that shrinks model-facing output
(`readseek.display.{edit,write,grep}` only drives TUI rendering), and 0.9.16 is the newest published
version. pi's own built-ins are already minimal (read = raw text, write/edit = one line), so the
cheapest fix is config: drop `write` (and optionally `read`) from `readseek.overrideTools`, or swap
the read/edit pair for an extension that uses a plain anchored line format.

## 1. pi-readseek 0.9.16 — what controls model-facing size

| Knob | Effect | Evidence |
|---|---|---|
| `readseek.overrideTools` (`read`,`edit`,`write`,`grep`) | Maps built-ins → `readSeek_digest`/`_edit`/`_write`/`_grep`. Removing an entry restores pi's built-in. | README; `READSEEK_TOOL_REPLACEMENTS` in `dist/index.ts` |
| `readseek.display.{grep,edit,write}` = `compact`\|`expanded` | **TUI only** — consumed inside `renderResult()` via `resolveReadSeekToolDisplayMode`. No effect on tokens. | `dist/index.ts` L2265–2467, L3484, L5267 |
| `readseek.grep.{maxLines,maxBytes}` | Caps grep output only (default 2000 lines / 50 KB). | README; `dist/index.ts` L3562–3574 |
| `readSeek_digest` `select`/`at`/`end`/`limit`/`depth` | Per-call scoping — `select: map,metadata` or `limit` is the only real size lever for reads. | `prompts/digest.md`; `readseek digest --help` |
| `postEditVerify: true` | Opt-in extra read-back + compact diff. Leave it off. | `prompts/edit.md` |
| Write cap | Echo truncated at pi's `DEFAULT_MAX_LINES` / 50 KB with "full anchors in readSeekValue". | `dist/index.ts` L5150–5165 |

No compact/plain read mode, no no-echo write mode, no hunk-only edit mode exists: the CLI has no
output-format flag at all (`readseek digest --help` lists only facet/location/limit options), and
`registerWriteTool` unconditionally builds `LINE:HASH|` display lines for every line written.
Versions on npm stop at **0.9.16** (`npm view pi-readseek versions`). Upstream issue
[readseek#2 "agent started to consume more tokens"](https://gitlab.com/jarkkojs/readseek/-/work_items/2)
(opened 2026-08-23, closed 2026-08-31) asks exactly this ("Is there a way to limit tool output?");
the discussion notes require auth → **UNVERIFIED** what the resolution was, but 0.9.16 ships no such
setting.

Measured on a real 5 927-byte / 132-line JS file (`pi-otel/dist/attrs.js`):

| Format | Bytes | vs raw |
|---|---|---|
| `readseek digest --select content` (JSON `{line,hash,text}` per line) | 11 480 | **1.94×** |
| `LINE:HASH|text` plain (what `readSeek_write` echoes) | 7 272 | 1.23× |
| `3-char-hash│text` (pi-better-edit style) | 6 456 | 1.09× |
| `N:text` (pi-kaush) / `N→text` (Claude Code) | 6 348 | 1.07× |
| raw file (pi built-in `read`) | 5 927 | 1.00× |

## 2. pi 0.85.1 built-ins (strings extracted from the shipped binary)

| Tool | Model-facing return |
|---|---|
| `read` | **Raw file text, no line numbers** (`allLines.slice(start,end).join("\n")`), truncated to `DEFAULT_MAX_LINES`/`DEFAULT_MAX_BYTES` with a trailing notice; images become attachments |
| `write` | `Successfully wrote to <path>` — one line |
| `edit` | `Successfully replaced N block(s) in <path>.` — one line; params are `edits[].oldText`/`newText`, exact unique match |
| `grep` | matching lines + paths/line numbers, capped by match count / KB |

Caveat on the 14-day Logfire numbers: since `edit` returns ~1 line and `details` is not sent to the
LLM (`docs/extensions.md`: `content:` "Sent to LLM"; `details` for rendering/state), the 3.4k avg
for `edit` and much of `write`'s 11k must be **call arguments** (`new_text` / whole-file `content`),
i.e. model output tokens, not echo. Re-check which OTel attribute was summed
(`gen_ai.tool.call.arguments` vs `.result`) before attributing savings — pi-otel itself computes no
per-tool token counts.

## 3. Alternatives (npm, keyword `pi-package`)

**Premise of the hashline family.** pi's built-in `edit` is `str_replace`: the model must reproduce
the exact `oldText` it wants replaced. That fails in three ways — the model mis-copies (whitespace,
quotes, a line it hallucinated), the snippet is not unique, or the file changed since it was read
(stale read). Each failure costs a retry turn, and copying the old text into the call doubles
output tokens for large edits. Hashline tools attach a short content hash to every line on `read`;
the model addresses lines by `LINE:HASH` instead of quoting them, and the hash proves the line is
unchanged since the read. So the trade is: **+read overhead (hash per line, 1.07–1.94×) and a
mandatory read-before-edit, against −old-text quoting, −ambiguity failures, −stale-edit bugs**.
The many forks exist because the idea is trivial (~200 lines) and each author tuned a different
knob: hash length (token cost), read format, whether write/edit auto-read, description size.

Our own data on the trade: 188 `edit` calls, **33 rejected with `You must get fresh anchors`**
(18%) — the staleness guard doing its job, but each is a wasted turn (~$0.20 on fable). pi
built-in `edit` failure rate before the override: no data in this window.
| Package | ver / last pub | read format | write | edit result | Notes |
|---|---|---|---|---|---|
| `@pi-kaush/pi-better-read-edit` | 0.2.2 / 2026-09-12 | `[path#TAG]` header + `N:text` (~1.07×) | **not overridden** → built-in one-liner | "fresh tag + small changed windows"; diffs/patches in details | Explicitly "read/edit only … search and write do not mint tags"; seen-range authorization, model avoidlist |
| `pi-better-edit` | 1.7.0 / 2026-09-09 | `HASH│content`, 3-char hash (~1.09×) | auto-read block **always on** after write (50 KB budget) → same echo problem; "No config" | post-edit diff with fresh anchors | Claims −24…−50 % envelope vs str_replace on a 12-edit corpus; 23/23 eval, served-row staleness guard |
| `pi-hashline-edit-pro` | 4.3.4 / 2026-09-16 | `anchor│content`, tokenizer-tuned 4-char anchors (2 tokens/anchor) | auto-read block after write | diff rows carry fresh anchors (chained edits, no re-read) | Most actively maintained; anchors verified against served rows |
| `pi-hashline-edit-pro-lean` | 3.0.4-lean.1 / 2026-09-06 | as pro | as pro | as pro | Trims **tool descriptions/schemas** only: 423 vs 1 503 prompt tokens (−71.9 %). Orthogonal to result size |
| `pi-lean-edit` | 0.3.6 / 2026-08-28 | built-in read + harness-side read tracking | built-in | error path snapshots ±5 lines | "verifying prior reads in the harness instead of the prompt" |
| `pi-hashline-readmap` | 0.14.0 / 2026-08-18 | hash-anchored read + code maps | — | — | grep `summary: true` = counts only; least recently updated |
| `@danypops/pi-lector`, `hashline-pi`, `@d3ara1n/pi-hashline-edit`, `@oh-my-pi/hashline` | various | daemon / patch-language variants | — | — | `@oh-my-pi/hashline` is the upstream patch language most forks vendor |

## 4. Benchmark: "minimum viable echo"

- Claude Code `Read` prefixes each line with `N→` (community-documented, not in Anthropic docs →
  **UNVERIFIED as primary**): ≈1.07× raw.
- Anthropic's own reference editor (`str_replace_based_edit_tool`, computer-use-demo `edit.py`) is
  primary and shows the intended envelope: `view` → `f"{i+init_line:6}\t{line}"` under "Here's the
  result of running `cat -n` on …"; `create` → `File created successfully at: <path>` (one line);
  `str_replace` → `The file <path> has been edited.` + a **±4-line snippet** (`SNIPPET_LINES = 4`)
  around the change. So: write = one line, edit = tiny hunk, read = numbered lines. pi's built-ins
  already match this; pi-readseek's `digest`/`write` do not.

## 5. Recommendation

| Goal | Cheapest path | Cost |
|---|---|---|
| (b) edit returns hunk/one-line | **Already true** — keep `edit` overridden, never set `postEditVerify`. Verify the Logfire metric counts arguments, not results. | config/none |
| (a) write returns path + count | Remove `"write"` from `readseek.overrideTools` → built-in `Successfully wrote to <path>`. Loses post-write anchors: follow with `readSeek_grep`/`digest --select map` only when the next step is an anchored edit, or use `edit`'s `replace` variant. | 1-line settings change |
| (c) read ≤1.2× raw with reliable anchors | Not achievable with `readSeek_digest` (1.94×, no format flag). Two options: **(i)** drop `read` too → built-in raw read (1.00×) and mint anchors on demand via `readSeek_grep`/`_def`/`_search` (all already anchored); **(ii)** hand read+edit to `@pi-kaush/pi-better-read-edit` (1.07×, tag-based, write untouched) or `pi-hashline-edit-pro` (1.09×, tokenizer-tuned anchors) and keep pi-readseek only for `search`/`def`/`refs`/`view`. Do not stack two read/edit overrides (kaush README §"tool override order must not decide which contract is active"). | (i) config; (ii) swap extension |
| Prompt-side savings | `pi-hashline-edit-pro-lean` shows ~1 080 tokens/session recoverable from tool descriptions alone — independent of result size, and a fork-free precedent if you want a lean-description wrapper around pi-readseek. | optional |

### Decision (owner, 2026-09-16): uninstall pi-readseek, go vanilla

Usage of the non-override readSeek tools in 14d: `readSeek_grep` 111 (built-in `grep` 140 covers
it), `readSeek_def` 2, `_refs` 1, `_search` 0, `_view` 0, `_rename` 0. Nothing here that grep,
repowise, cymbal and the code-intelligence tools in the pipeline don't cover. Keeping an extension
whose main override is 1.94× raw and whose edit guard rejected 18% of calls, for two tools nobody
calls, is not worth the preamble or the risk. Vanilla first; if str_replace edit failures turn out
worse than the 18% stale-guard baseline, `pi-hashline-edit-pro-lean` (below) is the fallback.

### Head-to-head: vanilla pi vs `pi-hashline-edit-pro-lean` (vs current readSeek)

| | vanilla pi built-ins | pi-hashline-edit-pro-lean 3.0.4-lean.1 | current: pi-readseek (read/edit/write overridden) |
|---|---|---|---|
| read format | raw text, 1.00×, **no line numbers** (model must count or use start/end) | `anchor│text`, 4-char anchors, ~1.09× | JSON hashlines, 1.94× |
| edit contract | `str_replace` exact unique match; failures = ambiguity/mis-copy/stale, all silent until applied | `replace`/`insert` by anchor range + `replacement_lines[]`; anchors validated against last served read; per-file `undo_last_change` | `LINE:HASH` anchors or `replace`; fresh-anchor guard |
| write | `Successfully wrote to <path>` | built-in write kept; **auto-read after write** (`/toggle-auto-read`, config-persisted) → off = one line | `LINE:HASH` echo of whole file |
| edit result | one line | post-edit diff with fresh anchors when auto-read on; one line when off | one line |
| selective override | n/a | **yes, by construction**: registers `read`, `replace`, `insert`, `undo_last_change`; hides built-in `edit` via `setActiveTools`; `grep` untouched (`anchor_grep` separate, off by default, `/toggle-anchor-grep`); `write` untouched | `overrideTools` list (read/edit/write/grep individually) |
| coexistence with readSeek structural tools | fine | fine if readSeek `overrideTools: []` (README: "do not load another Hashline wrapper" — readSeek with no overrides is not a wrapper, but **UNVERIFIED** until tried) | — |
| preamble | 0 extra | 423 tok (4 tools) | ~9 tool schemas, est. 2–3k tok |
| maintenance | pi core | wrapper pins upstream `pi-hashline-edit-pro` 3.0.4 (upstream now 4.3.4 → lag), last pub 2026-09-06, single author | 0.9.16, single author, gitlab |
| risk | edit reliability regression (unknown baseline; 18% stale-guard rate suggests staleness is real in our sessions) | new contract for the model to learn; steering/skills that say `edit`/`LINE:HASH` need updating | known |

Read-side both options are ~equal (1.00× vs 1.09×); the decision is purely **str_replace vs
anchored edit**. Cheapest honest experiment: run **vanilla for one week** (`overrideTools: []`,
keep readSeek structural tools), measure `edit` error rate + edits-per-file-per-session + output
tokens per edit against this fortnight's 18% stale-guard baseline; if str_replace failures exceed
that, switch to hashline-edit-pro-lean with auto-read off. Either way `read` drops to ~1×.
A fork of pi-readseek is **not** needed for (a)/(b) and would be the only route to a compact
`digest` text mode; the upstream-friendly move is an issue on gitlab.com/jarkkojs/readseek asking for
`readseek.output.{read,write}: "compact"|"summary"` (issue #2 shows the maintainer has seen the
demand). Expected saving from config alone: remove the write echo (~1.2× file per write) and the
0.94× digest overhead per read — i.e. most of the 65 % tool-token share, without touching edit
reliability, since anchors remain available from grep/def/search.

## Sources

- Local: `~/.config/pi/agent/npm/node_modules/pi-readseek@0.9.16` — `README.md`, `prompts/{write,edit,digest}.md`, `dist/index.ts` (L2052 `formatAnchoredFileBlocks`, L2162 `buildEditOutput`, L2265–2467 settings, L3484/L5267 display modes, L5150–5165 write echo/truncation)
- `@jarkkojs/readseek-api@0.9.16` + `@jarkkojs/readseek-linux-x64` — `readseek --help`, `readseek digest --help`, measured `digest --select content` output
- pi 0.85.1 — `docs/extensions.md` (tool `content` "Sent to LLM" vs `details`), `docs/settings.md`; built-in tool implementations extracted from the `pi` binary (`strings`): read/write/edit result strings
- npm: `npm view pi-readseek versions|homepage`; `npm search keywords:pi-package`; READMEs of `@pi-kaush/pi-better-read-edit` 0.2.2, `pi-better-edit` 1.7.0, `pi-hashline-edit-pro` 4.3.4, `pi-hashline-edit-pro-lean` 3.0.4-lean.1, `pi-lean-edit` 0.3.6, `pi-hashline-readmap` 0.14.0
- Upstream: https://gitlab.com/jarkkojs/readseek/-/work_items/2 (issue #2, closed; notes require auth → UNVERIFIED)
- Anthropic: https://platform.claude.com/docs/en/agents-and-tools/tool-use/text-editor-tool (spec leaves result strings to the integrator); https://github.com/anthropics/anthropic-quickstarts/blob/main/computer-use-demo/computer_use_demo/tools/edit.py (`_make_output`, `SNIPPET_LINES = 4`, `create`/`str_replace` returns)
- Claude Code Read `N→` format (secondary, UNVERIFIED): https://dev.to/_94be737e156beb4d74df2/claude-code-tools-deep-dive-5-read-2ba6 , https://cc.bruniaux.com/guide/tools-reference/
