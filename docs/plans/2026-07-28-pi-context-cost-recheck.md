# Pi context-cost recheck

**Created:** 2026-07-28 · **Recheck after:** ~3–5 days of real work (target 2026-08-01)

Changes below were made on a brand-new pi harness with almost no usage history. Every
threshold is a guess made from two days of data, most of which was the audit itself.
This doc records the baselines and the exact commands to re-derive them, so the recheck
is a measurement, not a re-investigation.

## What changed on 2026-07-28

| # | Change | Rationale |
| --- | --- | --- |
| 1 | `config/custom/pi/agent/mcp.json` — removed `context-mode` server entry | `npm:context-mode` *extension* already registers all 11 native `ctx_*` via its own bridge. The MCP entry only added 5 prefixed duplicates. |
| 2 | `config/custom/pi/agent/settings.json` — removed `npm:pi-perf`, `npm:pi-markdown-preview` | Unused; 4 tool schemas. |
| 3 | `npm uninstall` + `npm prune` in `~/.pi/agent/npm` | Housekeeping. Side effect: tree re-resolved 910M → 1.1G. |
| 4 | **New** `config/custom/pi/agent/extensions/bash-output-guard.ts` | Ports the bash nudge context-mode's Pi adapter never received. See below. |

### Why #4 exists

context-mode's Claude Code adapter (`hooks/core/routing.mjs`) nudges on every bash
command failing `isStructurallyBounded()` — a conservative allowlist, fail-safe by
default. The Pi adapter inlined only `stripQuotedContent` (:196–209) and
`isSafeCurlWget` (:672–701) — exactly the two helpers its HTTP-blocking branch needs —
and never ported the general nudge. Its only stated rationale
(`build/adapters/pi/extension.js:574`) covers dropping the 7KB *prompt block*, which is
a per-turn context cost; it says nothing about the hook, which costs nothing until it
fires. Looks like a partial port, not a design decision.

Our version differs deliberately: it fires on `tool_result` (pi's `tool_call` can only
block or allow, and a hard wall on `cat` is unusable) and requires **both** an unbounded
command **and** an actual result ≥ `NUDGE_OVER_CHARS`, because the reference itself
notes (#463) that nudging every unbounded command trains the agent to ignore it.

## Baselines to compare against

### Startup request (print mode, `PI_OFFLINE=1`, cwd `~/dotfiles`)

| | before | after |
| --- | --- | --- |
| total body | 105,357 B | 79,490 B |
| tools | 77,767 B / 43 | 53,061 B / 34 |
| system+messages | 26,420 B | ~26,300 B |
| ≈ tokens | 28.5k | 21.5k |

Removed exactly: `context_mode_ctx_{execute,execute_file,search,fetch_and_index,batch_execute}`,
`perf_{profile,bench,report}`, `preview_export`.

### Spend and session shape (2 days, pre-change)

```
MODEL            turns  sess  avgTurns  avgCacheRead/turn  avgCacheWrite/turn   $total  cache%
claude-opus-4-8    287     3      95.7            316,905              53,726  $152.79    93%
claude-opus-5      416    10      41.6            114,634               7,577   $56.08    90%
claude-fable-5     162    12      13.5             56,811              13,939   $41.11    91%
```

**91% of spend was re-reading context.** The startup block is only ~7% of a long opus
session's per-turn read — accumulated transcript dominates. That is the number the guard
is meant to move.

### Tool call mix (pre-change)

```
bash 349 | herdr_pane 80 | ctx_execute 77 | edit 76 | read 52 | ask_user 34 | write 33
ctx_batch_execute 26 | mcp 6 | ctx_search 6 | grep 4 | ctx_fetch_and_index 3 | ls 2 | find 1
```

Direct read/exec 408 vs context-mode 116 → **context-mode routed ~22%**.

## Recheck procedure

### 1. Cost and session shape

```sh
sqlite3 -json ~/.pi/agent/observability.db \
  "select session_id,ts,payload_json from events where type='turn_end';"
```

Each payload has `message.usage` with `input`, `output`, `cacheRead`, `cacheWrite`,
and a `cost` breakdown. Aggregate by `message.model`. Compare `avgCacheRead/turn`
against the table above — **this is the primary metric**.

### 2. Tool mix

```sh
sqlite3 ~/.pi/agent/observability.db \
  "select json_extract(payload_json,'\$.toolName') n, count(*) c
   from events where type='tool_call' group by n order by c desc;"
```

Target: bash:ctx_execute ratio moving off 4.5:1.

### 3. Startup request size

The `/tmp/pi-ctx-capture/` harness from the original session is gone by now. Recreate:

```js
// capture.js — run with: node capture.js
const http=require('http'),fs=require('fs'),{spawn}=require('child_process');
const PORT=8912, DIR='/tmp/pi-ctx-capture';
fs.mkdirSync(DIR,{recursive:true});
fs.writeFileSync(`${DIR}/ext.ts`,
`import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
export default function (pi: ExtensionAPI) { pi.registerProvider("anthropic", { baseUrl: "http://127.0.0.1:${PORT}" }); }`);
const srv=http.createServer((req,res)=>{let b=[];req.on('data',c=>b.push(c));req.on('end',()=>{
  fs.writeFileSync(`${DIR}/body.json`,Buffer.concat(b));
  res.writeHead(400,{'content-type':'application/json'});
  res.end(JSON.stringify({type:'error',error:{type:'invalid_request_error',message:'probe'}}));});});
srv.listen(PORT,'127.0.0.1',()=>{
  const pi=spawn('pi',['-e',`${DIR}/ext.ts`,'--provider','anthropic','--model','claude-opus-5','-p','hi'],
    {cwd:process.env.HOME+'/dotfiles',env:{...process.env,PI_OFFLINE:'1'},stdio:['ignore','pipe','pipe']});
  const fin=()=>{try{pi.kill('SIGKILL')}catch{}srv.close();
    const b=JSON.parse(fs.readFileSync(`${DIR}/body.json`,'utf8')),B=x=>JSON.stringify(x).length;
    console.log('total',B(b),'tools',b.tools.length,B(b.tools),'system',B(b.system),'messages',B(b.messages));
    b.tools.map(t=>({n:t.name,b:B(t)})).sort((x,y)=>y.b-x.b).forEach(t=>console.log(' ',t.n,t.b));
    process.exit(0);};
  pi.on('exit',()=>setTimeout(fin,500)); setTimeout(fin,100000);});
```

Note: pi-cc-header relocates the 25KB pi prompt from `system` into `messages[0]` when the
keychain read succeeds, so **measure `messages` too, not just `system`** — otherwise it
looks like the prompt vanished.

### 4. Did the guard ever fire?

No counter is recorded. Cheapest check is grepping session transcripts for the nudge text:

```sh
grep -rl "of raw output just entered context" ~/.pi/agent/sessions/ | wc -l
```

## Decisions to make at recheck

| Question | Data needed | Action if… |
| --- | --- | --- |
| Is `NUDGE_OVER_CHARS = 8000` right? | Distribution of bash result sizes | Fires on >~1 in 5 bash calls → raise. Never fires → lower. |
| Is the nudge working? | bash:ctx_execute ratio | Unmoved after ~200 bash calls → advisory is too weak; consider rewriting `event.input` (append `\| head -N`) instead. |
| Did per-turn cacheRead drop? | §1 vs baseline | No movement on long opus sessions → the transcript is dominated by `read`/`edit`, not `bash`; extend the guard to `read`. |
| Gate `read` too? | read call count + result sizes | read climbs above ~150/2 days → extend. Currently 52 vs bash 349, hence bash-only. |
| Manager/worker split worth building? | avgTurns + cacheRead on manager sessions | Long sessions still >250k cacheRead/turn → yes, this is the real lever, not startup trim. |

## Open items not yet investigated

- **Observability runs in summary mode** — tool *result* payloads are redacted, so per-tool
  result bytes are unknowable. Run one real session with `--observability-detail detailed`
  before the recheck; without it, questions 1 and 3 above cannot be answered properly.
- **pi-cc-header moves the pi prompt into `messages[0]`.** Unknown effect on cache
  breakpoints — 53,726 cacheWrite/turn on opus-4-8 is high and unexplained.
- **Duplicate tool families still shipping** (~13k tok): pi-lens code-nav vs
  codebase-memory-mcp (and `AGENTS.md` mandates CBM first anyway); `subagent*` vs
  `workflow*` vs `herdr_agent`; `web_search`/`source_check`/`fetch_content` vs
  `ctx_fetch_and_index`; builtin file tools vs `ctx_execute*`.
- **`cbm-enforcement.ts` gate is one-shot** — `state.gateOpened = true` is never reset, and
  any successful CBM call sets `cbmUsed` permanently. Max one block per session. Verb list
  (`rg|grep|find|fd|tree|ls|ag`) also misses the commands that actually flood
  (`cat`, `sed`, `awk`, `jq`, `sqlite3`, `du`).
- **Upstream issue not filed** for context-mode's dropped Pi nudge.

## Reproducing the analysis

Tests: `cd config/custom/pi && bun test tests/bash-output-guard.test.ts` (9 tests; one
imports the real `isStructurallyBounded` from the installed package, so it fails loudly if
a context-mode upgrade moves or renames it).
