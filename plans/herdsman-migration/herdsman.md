# pi-herdsman — architecture & philosophy brief

Repo: `/home/kuba/dev/oss/pi-herdsman` (github `boadij/pi-herdsman`, npm `pi-herdsman`, Apache-2.0).
Snapshot: HEAD `0dc62d3` (2026-10-13), `package.json` version **0.26.0**. Local clone has no
`node_modules/` or `dist/`, so nothing was built or run. Every claim below comes from reading the
source and docs.

---

## 0. TL;DR

- It is a **Pi extension plus skill** that turns Pi sessions running in Herdr panes into an
  **asynchronous, ownership-tracked agent tree**. Each subagent is a **full `pi` process in its own
  Herdr pane**, launched with `herdr agent start --kind pi`. Tasks and results move through a
  **durable file mailbox** under `<agentDir>/pi-herdsman/`.
- Herdr is **required**. Outside Herdr the extension is inert and only prints a diagnostic
  (`extension/index.ts:792`).
- Roles are defined as Markdown with YAML frontmatter (similar to piewf), with overlay layers
  `bundled < project < global`.
- **There is no workflow/scripting layer**, i.e. nothing like piewf's JS workflows. There is also
  **no blocking "run and wait"**. The design forbids polling: results and attention events
  re-trigger the owner's turn.
- On top of plain delegation it adds a **Manager** (branch/worktree-scoped project leads), a
  **Chief** (supervisor across the whole runtime) and **Peers** (Lead↔Lead messaging).
- The project is **very opinionated** and heavy on contracts: fail-closed identity checks,
  "one executor per unit of work", 20 ADRs, a large model-facing prose contract.
- Velocity is very high: about 55 tags and 290 commits in about 5 weeks. Breaking changes landed
  at 0.2, 0.5, 0.13, 0.16, 0.17, 0.19 and 0.22.

---

## 1. Philosophy / design goals

Primary sources: `docs/development/product-philosophy.md`,
`docs/development/instruction-interface-design.md`, `AGENTS.md`, `docs/adr/*`.

- **Thin orchestration layer.** "Pi owns each coding-agent conversation; herdr owns processes, panes,
  workspaces, and worktree placement; Herdsman connects them through delegation, ownership,
  supervision, and project orchestration" (`README.md`).
- **Own orchestration, not ecosystems.** Herdsman owns delegation, ownership, supervision,
  lifecycle, assignment delivery and continuation. It explicitly does not own memory, provider,
  tool or service features. "Delegation does not imply shared memory"
  (`product-philosophy.md`; ADR 0014 integration-agnostic primitives).
- **Prefer composition, keep optional capabilities optional, generalize only from evidence.**
  The decision test in `product-philosophy.md` asks: "Is this fundamentally an orchestration
  problem Herdsman owns?"
- **Native contracts over wrappers** (ADR 0008). It uses Herdr's CLI and socket API, the official
  `herdr integration install pi` state extension, and Pi's `getAgentDir()`, session files and
  event hooks.
- **Persist intent, derive runtime state** (ADR 0002). Assignments, ownership and session identity
  are durable. Pane, process and liveness are observations, re-derived each time. Ambiguous state
  **fails closed** (states `unknown` / `lost`, never guessed).
- **Durable ownership graph = authority** (ADR 0003). Seeing a pane does not mean owning it.
- **Delegation framing:** "Each unresolved unit of work has one executor." Delegating a scope
  transfers execution ownership. The delegator must not do overlapping work and must not poll.
  It either ends its turn or continues with genuinely independent work. Results and attention
  wake it automatically (`SKILL.md` runtime contract; `docs/concepts/lifecycle.md`
  §Asynchronous orchestration).
- **Context management framing:**
  - Recipients never inherit the sender's conversation. Evidence moves explicitly through a single
    `files` channel: inline UTF-8 when it fits, otherwise canonical path refs (ADR 0005).
  - Agent results become reusable refs (`result:<agent>#<n>`) that can be forwarded without being
    re-summarized (ADR 0001).
  - Temporary plans and specs go under project-local `.pi-herdsman/`.
  - **Prompt-cache continuity** is a first-class constraint: context is append-only and prefixes
    are never rewritten (ADR 0009).
  - **Context retirement replaces compaction** for managed agents (ADR 0010; details in §4).
- **Interface design opinions** (`instruction-interface-design.md`):
  - Prefer structure over instruction: tool availability, schemas, `available_tools`.
  - Prefer positive steering; no defensive guidance creep.
  - One invariant, one meaning.
  - Shared instructions must be **roster-agnostic**: they never assume that `scout`, `reviewer` or
    any other bundled agent exists. Agents are selected by capability from the effective roster;
    if nothing fits, the model works locally or reports the gap. Added in #384 (HEAD).
- **Operation-specific, verb-first tools** (ADR 0006) instead of one multiplexed `agent` tool.
  That multiplexed form was removed in the 0.22 breaking change.
- **The runtime contract is authoritative and the skill is optional.** The runtime injects the
  contract; `SKILL.md` only reinforces it (`AGENTS.md` §Runtime instruction authority).
- **"Internal review" (#384).** A Lead plus its recursively owned agents form a *herd*, which is an
  "internal team". Reviews inside the herd are internal feedback, not user or supervisor approval.
  The bundled `reviewer` must preserve the origin of external feedback and must not pass its own
  findings off as sign-off (`extension/agent-definitions/reviewer.md`,
  `docs/concepts/coordination.md`).

---

## 2. Surfaces exposed

### Slash commands (human): `extension/index.ts:799-2005`, `docs/reference/commands.md`

| Command | Purpose |
|---|---|
| `/herdsman` (alias `/agents`) | Native menu: Execution, Agents (Running / Layout / Stop all), Project manager, Session stats, Definitions, Settings, Advanced… (Chief). Outside Herdr it is only a diagnostic. |
| `/herdsman stats` | Pi-native token and cost totals for this session plus transitively owned agent sessions. In Manager mode it also includes assigned Leads' trees. |
| `/herdsman definitions` | Lists effective definitions with their sources. Edits `model` / `thinking` / `enabled` by writing **global override** files only. |
| `/herdsman placement [tab\|subtree\|split]` | Where new direct agents spawn (default `subtree` = one tab per direct agent). |
| `/herdsman stop` | Emergency: abort the Lead turn and close the proven-owned agent tree. |
| `/lead [flexible\|orchestrate]` | Ordinary Lead mode. `orchestrate` = `tools: []`: Lead keeps only coordination tools and must delegate. |
| `/manager`, `/manager leave`, `/manager remove <branch>` | Claim the exclusive project Manager lease from a Herdr **primary** workspace. Remove a clean worktree after a typed `remove` confirmation. |
| `/chief`, `/chief leave` | Supervisor role spanning the whole runtime. |
| `/takeover` | An assigned managed Lead releases Manager authority and becomes an ordinary Orchestrate Lead. |

### Model tools

Registration: `agent-controller.ts:6401-6595`, `index.ts:1773-2225`,
`managed-agent-runtime.ts:968`. Reference: `docs/reference/{agent,staff,supervisor,peer,ask-owner}.md`.

**Agent ownership tools** (nine; Lead, and delegating agents only when allowlisted):

| Tool | Purpose |
|---|---|
| `delegate_agent {definition, task, label?, files?}` | Fresh pane and Pi session, one assignment. Returns once the request is durably recorded, not when the work completes. |
| `continue_agent {session, task, files?}` | New generation on an exact saved session (cwd, label and definition are inherited). |
| `list_agents {}` | Roster (`agent_definitions` capability summary) plus live records with `available_tools` and state. |
| `steer_agent` | Cooperative and queued. |
| `interrupt_agent` | Preemptive: cancels the current op and continues with a replacement message. |
| `reply_agent` | Answers a pending `ask_owner` question. |
| `close_agent` | Teardown; cascades to children first. |
| `inspect_agent` | Bounded live terminal/process read. |
| `read_agent_transcript` | Bounded read of the persisted Pi session. |

**Other tools:**

- `ask_owner`: given to every managed agent. It must be the only and final tool call of its turn,
  and the agent blocks until the owner replies. This is agent→owner. **It is not an ask-user UI.**
- Staff tools (Chief/Manager): `list_staff`, `inspect_staff`, `read_staff_transcript`,
  `message_staff`.
- Manager-only: `delegate_project {task, branch?}`, `resume_project {branch}`, `stop_lead`,
  `remove_worktree`.
- `message_supervisor` (Lead→Manager/Chief, Manager→Chief; nonblocking).
- `list_peers`, `message_peer` (Lead↔Lead, Manager↔Manager; user-global, including across Herdr
  sockets).

### Hooks used

`pi.on`: `before_agent_start`, `context`, `tool_call`, `session_before_compact`, `session_start`,
`turn_*`, `agent_settled`, `session_before_fork/switch`, `model_select`, `input`, and others.

Effects:
- Widgets `pi-herdsman` and `pi-herdsman-staff`.
- `setSessionName` for managed Leads, named after the branch (`presentation.ts:291`).
- Custom message and entry renderers.

---

## 3. Agent / role model

### Definitions

Markdown files with YAML frontmatter. Full schema: `docs/reference/agent-definition-schema.md`.

**Sources and precedence:**
- Bundled: `dist/agent-definitions/` (source: `extension/agent-definitions/*.md`).
- Project: `<cwd>/.pi/agents/`, used only when Pi trusts the project.
- Global: `getAgentDir()/agents/` (`agent-definitions.ts:456-459`). On this machine that resolves
  to `~/.config/pi/agent/agents/`, which does not exist yet.
- Precedence `bundled < project < global`. A same-name file overlays; a new name is standalone.
- Validation is strict:
  - Unknown frontmatter keys are rejected.
  - A malformed file fails discovery of the **whole roster**, not just that file.
  - Every name in `agents:` must resolve.

**Fields:**

| Group | Fields |
|---|---|
| Identity | `name`, `description`, `enabled` |
| Model | `model`, `thinking` (`off` … `max`) |
| Prompt | `systemPromptMode` (`append` / `replace`), `bodyMode` (overlay only) |
| Tools | `tools` (closed allowlist, `*` globs), `excludeTools`, `noTools`, `noBuiltinTools` |
| Skills | `skills`, `noSkills`, `inheritSkills` |
| Extensions | `extensions`, `noExtensions` |
| Delegation | `agents` (allowed children) |
| Context | `inheritProjectContext`, `inheritGlobalContext` |
| Other | `permission` (opaque passthrough for permission extensions) |

**Body and prompt composition:**
- Body lines of the form `@./path` include files once at launch, without recursion.
- Prompt order (bottom of the schema doc): Pi base → body → context files → shared guidance →
  `<active_agent name=…/>` → `<pi_herdsman_agent>` (identity, direct owner).

### Model selection

Omitted `model` / `thinking` fields are inherited:

| Launch | Inherits from |
|---|---|
| Fresh delegate | Spawning controller's current model |
| Nested delegate | Parent agent |
| `continue` | Saved session |
| Managed lead | Manager |

There is no per-task model override at call time. Models are set per definition or through the
`/herdsman definitions` UI.

One special case: when an inherited model's provider comes from an extension, extension discovery
is forced on so the child can resolve the model.

### Tool / skill restrictions

- An explicit `tools` list is closed across all Pi tool sources: built-ins, extension tools and MCP
  tools (matched by name).
- Role-mandatory coordination tools are always re-added and cannot be excluded. A wildcard
  exclusion that would hit one is a launch error.
- `agent` in a tools list is a sentinel that enables delegation, not a callable tool.
- The docs say tool filtering is **not extension sandboxing**: loaded extensions still run their
  hooks.
- `noExtensions: true` still injects the Herdsman agent extension and Herdr's state extension.

### Bundled roster (`extension/agent-definitions/`)

**Agents:**

| Agent | Tools | Delegates to | Notes |
|---|---|---|---|
| `scout` | `read, ls, find, grep` | — | read-only recon |
| `researcher` | `read, ls, find, grep, web_search, fetch_content, get_search_content, source_check` | — | assumes a pi-web-access-style extension; `noSkills`, extensions not disabled |
| `implementer` | `read, bash, edit, write` | `scout` | |
| `reviewer` | `read, ls, find, grep` | `scout, researcher` | read-only internal reviewer |
| `generalist` | `read, bash, edit, write` | `scout, researcher` | |

Common defaults across all bundled agents:
- `noSkills: true`.
- `noExtensions: true`, except `researcher`.
- `inheritGlobalContext: false`, so the user's global `AGENTS.md` is **not** loaded in children.
- `inheritProjectContext: true`.

**Reserved role profiles** (not delegatable): `flexible-lead`, `orchestrator-lead` (`tools: []`),
`managed-lead` (`tools: []`, append-only prompt), `manager`, `chief` (`tools: []`, global
overlay only).

### Delegation depth

- Lead → delegating agent → leaf. Agents started by agents are always leaves.
- Delegation requires a non-empty `agents:` list and must not be disabled by tool policy
  (`docs/concepts/delegation.md`).

### Runtime capability discovery

- At session start, the system prompt gets an `agent_definitions` section. It covers enabled
  definitions only: name, description, normalized tool/skill summary and permitted children
  (`lead-runtime.ts:1351-1369`, `managed-agent-runtime.ts:1961`).
- `list_agents` refreshes it.
- Children receive their allowlist via `PI_HERDSMAN_ALLOWED_AGENT_DEFINITIONS`
  (`agent-controller.ts:5777`).
- Per-record `available_tools` tells the model which controls are legal right now. This is
  "structure over instruction".
- Configured tool policy is **not** proof that a tool is installed (`docs/reference/agent.md`).

### Internal review

See §1 (#384). It is purely semantic framing in prompts and the reviewer definition. There is no
review workflow engine.

---

## 4. Execution model

### Process model

Every agent is a separate interactive `pi` process in its own Herdr pane:

```
herdr agent start <alias> --kind pi --pane <id> --timeout … -- \
  --extension <herdsman agent ext> --extension <agentDir>/extensions/herdr-agent-state.ts <definition args>
```

- Source: `extension/herdr.ts:1520-1545`.
- Resume uses `--session <path>` (`agent-controller.ts:5419`).
- It is **not in-process** and **not headless/RPC**.
- Visible, focusable panes; tab and split placement is configurable.
- Contains a "ponytail" workaround for Herdr #3208 (pane busy on a fresh shell) (`herdr.ts:1513`).

### Context isolation

- Each child is a fresh Pi session with its own system prompt (private temp prompt snapshots).
- Nothing from the parent conversation is inherited. Only `task` plus `files` cross the boundary
  (ADR 0005).
- Environment passed to the child: `PI_HERDSMAN_*`, `PI_SUBAGENT_CHILD=1`,
  `PI_SUBAGENT_PARENT_SESSION` (the latter two are an interoperability convention;
  `herdr.ts:587-625`).

### Transport

File mailbox under `<agentDir>/pi-herdsman/runtime/mailboxes-v5/` (`mailbox.ts:162`).

- `state.json`, `ask.json` and request/result records; atomic writes, `fs.watch`, process locks
  (`lock.ts`), build-hash compatibility checks (`compatibility.ts`).
- Herdr state comes from the socket `events.subscribe` (`herdr.ts:833-912`) plus a **30 s fallback
  reconciliation scan**.

### How results come back

1. The child completes its turn.
2. The result is persisted to `<agentDir>/pi-herdsman/results/<requestId>`.
3. It is delivered exactly once to the owner via `pi.sendMessage(..., {triggerTurn: true})`
   (`agent-controller.ts:6862+`). This **wakes the owner's turn**.
4. The agent pane is then cleaned up. The Pi session file survives, so `continue_agent` works.

Result text is prefixed with provenance (`Agent result source: {...}`) and is available as a ref
`result:<label>#<n>` (`docs/guides/handoffs.md` §Result handoff).

### Concurrency

- Unlimited parallel `delegate_agent` calls. There is no cap in config.
- Discipline is enforced by prompt: "one writer per worktree", no overlapping scopes.
- Delegating agents cannot finish while their children are unresolved (completion gate).

### Health

Event-driven, owner-directed attention messages:

| Condition | Timing |
|---|---|
| `stale` advisory | first after 10 min without progress, then every ~5 min |
| other persistent conditions | `5m → 2m30 → 1m15 → 1m` |

There is no auto-kill or auto-retry. Managed agents' `bash` / `powershell` calls without an explicit
timeout are **capped at 600 s** (`managed-agent-runtime.ts:1785`).

### Context retirement (default on)

- On threshold auto-compaction, a managed agent **cancels compaction** and is told to finalize a
  handoff.
- A retired session cannot be continued; follow-up needs a fresh agent
  (`managed-agent-runtime.ts:2604`, ADR 0010, `config.json:contextRetirement`).
- Manual compaction is untouched.

### Worktrees

- Plain Lead → Agent delegation runs in the caller's cwd. There is no per-agent worktree; the
  `cwd` override was removed in 0.5.
- Worktrees exist only at the **Manager → Lead** level:
  - `delegate_project` creates or reuses a Herdr linked worktree for a branch and launches a
    `managed-lead` Pi there.
  - Assignments are durable per branch and survive Manager restarts.
  - An assignment is retired only on Herdr `worktree.removed` or verified absence of the checkout
    (ADR 0013/0019/0020).

### Persistence and recovery

- Durable intent lives in the mailbox, project assignments, peer registry and results.
- After a controller restart, live agents are re-bound only when Herdr and Pi identity still
  match exactly. Otherwise the state is `unknown` (fail-closed) or `lost`, both requiring explicit
  `close_agent` (`docs/concepts/lifecycle.md` §Restart and recovery; `docs/guides/recovery.md`).
- Health reminder timers are process-local and reset on restart.
- No power-loss durability claim.

### State machine

Public lifecycle: `working | blocked | settling | unknown | lost`, plus `starting` / `idle` /
`done` in the UI.

### Compared with piewf

| Aspect | piewf | Herdsman |
|---|---|---|
| Run style | sync/async `subagents_run`, JS workflows | async only, no wait/poll tool, no programmatic composition |
| Waking the parent | caller decides | **parent turn re-triggers on results** |
| Child process | headless / in-process (presumably) | pane-based full TUI Pi |
| Cost per agent | lighter | heavier: full Pi startup each time, but visible and focusable |

---

## 5. Herdr integration

- **Hard requirement.**
  - Lead must run inside a Herdr pane (`HERDR_ENV=1`); otherwise inactive (`index.ts:433,792`).
  - Requires `herdr integration install pi` (Herdr's official `herdr-agent-state.ts` extension in
    `<agentDir>/extensions/`) for session identity reporting (`agent-controller.ts:2905`).
  - Tested baselines: Herdr 0.9.3 (sha256-pinned in `package.json`), Pi 1.1.0.
  - This machine has herdr 0.9.4, pi 1.2.0 and `herdr-agent-state.ts` already present.
- **Herdr commands used:**
  - `agent start/get/list/send-keys`
  - `pane split/get/list/layout/close/run/process-info`
  - `tab list/close`
  - `worktree list`
  - the event socket
- **Does it replace `@ogulcancelik/pi-herdr` / `@piewf/herdr`?** **No.**
  - Herdsman registers **no generic Herdr tools** (no pane/layout/run-arbitrary-command tools). It
    controls only the agents it owns.
  - Herdr tools for arbitrary panes, servers and tests would still need pi-herdr.
  - It overlaps with them only on "spawn an agent in a pane and talk to it".
  - Current `settings.json` loads `@ogulcancelik/pi-herdr`, `@henryqw/pi-herdr-rename`,
    `pi-extensible-workflows`, `@piewf/herdr` and `@henryqw/pi-herdr-btw`.
- **Tab naming overlap.**
  - Herdsman best-effort renames the Lead's Herdr **tab** to
    `Lead` / `Managed Lead` / `Manager` / `Chief`. It touches only tabs named with their numeric
    position or a canonical role label (`commands.md` end).
  - Managed Leads get a Pi session name from their branch.
  - This can **fight `@henryqw/pi-herdr-rename`** if that extension writes tab names.

---

## 6. Overlap with common pi extensions

| Capability | Herdsman built-in? | Notes / evidence |
|---|---|---|
| Steering / context injection | **Partial** | Injects its own runtime contract and `agent_definitions` into the system prompt (`before_agent_start`). Adds hidden persisted `<supervision_state>` context for Chief/Manager (`presentation.ts:1277`). `steer_agent` / `interrupt_agent` steer *child agents*. No user-defined steering rules: it would coexist with punk-steering, not replace it. |
| Memory | **No** | Explicitly out of scope ("Delegation does not imply shared memory"). `.pi-herdsman/` holds ad-hoc coordination files only. |
| Advisor | **No** | Closest is the bundled `reviewer` agent. |
| Plan review | **No** | Plans are `.pi-herdsman/*.md` artifacts passed via `files`. No approval UI; `/manager remove` is the only confirmation UI. |
| Ask-user | **No** | `ask_owner` is child→owner; a Lead never gets an ask-user UI. |
| Web search | **No** | The `researcher` definition *expects* `web_search`, `fetch_content`, `get_search_content`, `source_check` from another extension. `source_check` is disabled in this setup and missing tools are silently unavailable. |
| MCP | **No** | Tool policy name-matches MCP tools. Children with `noExtensions: true` (all bundled except researcher) will **not** load the MCP gateway extension unless the definition adds it. |
| Task-models | **Partial** | Per-definition `model` / `thinking` with inheritance; UI editor in `/herdsman definitions`. No per-call or per-task routing. |
| Observability / OTel | **No OTel** | No telemetry code (grep: none). Has a status widget, `/herdsman stats` (tokens and cost across the owned tree) and `inspect_agent` / `read_agent_transcript`. |
| btw / side questions | **No** | Peers (`message_peer`) and supervisor messaging are cross-session coordination, not ephemeral side questions. |
| Renaming panes/tabs | **Yes (tabs)** | Role-based Herdr tab labels plus session names for managed Leads. Possible conflict with pi-herdr-rename. |
| Compaction | **Yes (agents only)** | `contextRetirement` cancels threshold auto-compaction in managed agents. Could interact with custom compaction extensions loaded into children. |
| Bash timeouts | **Yes (agents only)** | 600 s default cap injected into built-in `bash` / `powershell` calls. |
| Subagents | **Core** | Direct replacement for piewf `subagents_run` / `inspect` / `steer` semantics, without workflows. |
| Optional integration | Codex context sharing | `extension/integrations/pi-codex-context-sharing.ts` is an adapter for `@howaboua/pi-codex-conversion` (Remote storage only) via the generic `pi-herdsman:managed-agent-bootstrap` event-bus protocol v1 (`docs/reference/agent.md`). That protocol is the general extension hook for passing state into fresh children (≤64 KiB). |

---

## 7. Docker / Tailscale angle

Purpose: a **portable, SSH-reachable remote agent box** that you attach to from local Herdr as a
remote machine (`herdr machine add ssh://herdsman@host:2222`). Source:
`docs/guides/container-deployment.md`.

**Image** (`Dockerfile`, 148 lines):
- Multi-stage: build and pack the package, then `node:26.10-trixie-slim` with mise, gh, git,
  python3, build-essential, rg, fd, fzf, jq, sqlite3, openssh-server, etc.
- Exact, checksum-verified Pi and Herdr releases from the package metadata.
- User `herdsman`, keys only, no root or password SSH.

**Compose files:**
- `compose.yaml`: image `ghcr.io/boadij/pi-herdsman:latest`, port 2222→22, volumes
  `herdsman-home` (all Pi/Herdr state, repos, credentials, mise tools) and `herdsman-ssh` (host
  keys). Uses `SSH_AUTHORIZED_KEYS` (first start only), `PUID` and `PGID`.
- `compose.tailscale.yaml`: a `tailscale/tailscale:v1.102.4` sidecar with
  `network_mode: service:tailscale`, ports reset, hostname `pi-herdsman`, `TS_AUTHKEY`.
  Tailscale is networking only; SSH is still OpenSSH.

**Other files:**
- `docker/AGENTS.md` is mounted at `/AGENTS.md` and gives Pi sessions the container context
  (persistence rules, prefer mise).
- `docker/entrypoint.sh` validates home permissions.
- `scripts/container-smoke.sh` tests the container.

Processes do not survive container restart. Only state does.

---

## 8. Config surface & install

### Herdsman config

`<getAgentDir()>/pi-herdsman/config.json` (`docs/reference/configuration.md`). Flat, strict schema;
unknown keys are an error.

| Key | Default |
|---|---|
| `defaultLeadExecution` | `flexible` (or `orchestrate`) |
| `spawnPlacement` | `subtree` (or `tab`, `split`) |
| `contextRetirement` | `true` |
| `autoActivateManager` | `false` |
| `inlineAttachmentLimitBytes` | 128 KiB (range 1 KiB–1 MiB) |
| `mailboxPayloadLimitBytes` | 128 KiB (range 1 KiB–1 MiB) |

All keys are editable via `/herdsman` → Settings. Project settings and trust do not affect this
file.

### Data root `<agentDir>/pi-herdsman/` (ADR 0007)

- `config.json`
- `results/<requestId>`
- `runtime/mailboxes-v5/`
- `runtime/peers-v2/peers/`
- supervision and project-assignment state

Reset: stop all processes, then `rm -rf` the directory. Temporary prompt snapshots go to OS tmp.

### Definitions

- Global: `<agentDir>/agents/*.md`.
- Project: `<repo>/.pi/agents/*.md`, trusted projects only.
- Project-local scratch: `.pi-herdsman/`, untracked.

### Env vars

- **User-facing:** `PI_CODING_AGENT_DIR` only. It relocates everything.
- **Internal:** `PI_HERDSMAN_*` (owner session, label, mailbox, run id, allowed definitions,
  workspace), `PI_SUBAGENT_CHILD`, `PI_SUBAGENT_PARENT_SESSION`, and Herdr's
  `HERDR_ENV/SOCKET_PATH/PANE_ID/TAB_ID/WORKSPACE_ID`.

### Install

- **Full stack:** `curl …/install.sh | sh` (193 lines, POSIX sh):
  1. Resolves `pi-herdsman@latest` from npm.
  2. Installs or upgrades Pi via the official `pi.dev/install.sh` when it is missing or older than
     the baseline.
  3. Downloads the pinned Herdr with sha256 verification when missing or older; never downgrades.
  4. Runs `pi install npm:pi-herdsman --no-approve`, `herdr integration install pi` and
     `herdr integration status`.
- **Manual:** `pi install npm:pi-herdsman && herdr integration install pi`.
- **Package manifest:**
  - `pi.extensions: ./dist/index.js`
  - `pi.skills: ./SKILL.md` (skill name **`agents`**) plus `./skills` (`agent-definitions` skill)
  - Peer deps on `@earendil-works/pi-*`; optional peer `@howaboua/pi-codex-conversion`
  - Node ≥ 22.19

---

## 9. Maturity

### Version and cadence

- **0.26.0**, 55 tags. First public release on 2026-09-07; HEAD on 2026-10-13.
- 290 commits (Sep: 180, Oct: 110). Often several releases per day (e.g. 4 tags on 2026-10-06 and
  3 on 2026-10-10).
- Uses release-please and conventional commits.
- **Seven releases with breaking changes**: 0.2.0 (`worker`→`agent` rename), 0.5.0 (config moved,
  cwd override removed), 0.13, 0.16, 0.17 (delegate/continue split), 0.19 (Manager), 0.22
  (verb-first tools).
- Effectively a **single author** (Jeffrey Boadi), heavily agent-assisted (`.agents/skills/*`
  audit skills; `.pi-herdsman/` used for repo work).

### Size

| Part | LOC |
|---|---|
| Extension source (non-test TS) | ~40.1k |
| Largest source files | `lead-runtime.ts` 11.2k, `agent-controller.ts` 7.8k, `presentation.ts` 3.9k, `support.ts` 3.1k, `managed-agent-runtime.ts` 3.0k, `herdr.ts` 2.7k, `supervision.ts` 2.7k |
| Tests | ~69.5k across 18 `*.test.ts` plus `scripts/worktree-hook.test.mjs` |
| Docs + skills + changelog | ~9.8k lines of Markdown |

### Tests

- `node --test`, about **963 `test()` / `it()` cases** (grep count).
- CI `validate.yml` runs on ubuntu, macOS and Windows.
- Smoke harness (`scripts/smoke.mjs`) runs real Pi and Herdr with scripted ("simulated") or live
  model decisions; scenarios are core, continuation, chief-tree, terminal-failure and
  manager-recovery (live only).
- **No coverage tooling** (no c8/istanbul). The policy is "do not optimize for coverage
  percentages" (`AGENTS.md`).
- Tests were **not run** for this report (no `node_modules`).

### Sharp edges and risks

- **Heavy per-agent cost.** Every agent is a full Pi TUI process in a pane, with startup latency
  and Herdr pane churn. The `subtree` default opens a tab per direct agent.
- **Strict fail-closed behavior** can leave `unknown` or `lost` agents that need manual
  `close_agent`. A malformed definition anywhere kills the whole roster. A build-hash mismatch
  after an update forces restarting every running session (`compatibility.ts`).
- **Very large model-facing contract.** `SKILL.md` is 510 lines, and the runtime contract is
  injected into every Lead and agent. The token overhead per session is non-trivial and dense with
  legalistic prose.
- **Async-only, no-poll doctrine.** No equivalent of "run these 3 and give me results in this
  turn". The Lead must end its turn. A good fit for interactive use, awkward for scripted
  pipelines (piewf workflows).
- **Bundled agents deliberately strip context.**
  - `noExtensions` and `noSkills` mean children lose repowise, steering, MCP gateway, lsp and
    output-guard extensions, and global `AGENTS.md`.
  - This needs custom global overlays to keep the current setup's guarantees.
  - `researcher` depends on external web tool names.
- **Same-name tool collisions** across sources have no defined winner (schema doc). Tool filtering
  is not sandboxing.
- **Tab rename may conflict** with pi-herdr-rename.
- **Peer discovery is user-global**, across projects and Herdr sockets.
- **Contains a Herdr #3208 workaround** ("temporary"), so it depends on Herdr behavior.
- **Churn:** ADRs supersede quickly (e.g. ADR 0012 says Manager removes assignments; 0013/0019
  changed that to worktree-removal-driven retirement).

### Open TODOs

- No `TODO`/`FIXME` in non-test source.
- The issue backlog lives in an ignored `.backlog/` (not present in this clone) plus GitHub issues
  and discussions.
- The only explicit "temporary" marker is the Herdr #3208 retry (`herdr.ts:1513`).

---

## 10. Fit notes vs current piewf setup (for decision)

**What it would replace:**
- The core of `pi-extensible-workflows` (roles as md+frontmatter, run/inspect/steer).
- Parts of `@piewf/herdr` for agent spawning.

**What it would not replace:**
- JS workflows.
- Generic Herdr pane tools (keep `@ogulcancelik/pi-herdr`).
- btw, advisor, memory, steering, MCP, web search.

**Migration work:**
- Rewrite roles into Herdsman's schema. Different field names; unknown keys are rejected.
- Decide `noExtensions` / `inheritGlobalContext` per role so children keep the tooling they need.
- Check the tab-rename interplay with `@henryqw/pi-herdr-rename`.
- Check whether piewf and Herdsman can coexist. No tool-name clash was observed: piewf uses
  `subagents_*`, Herdsman uses `*_agent`, `ask_owner`, `*_staff`, `*_peer`. But two delegation
  systems will confuse the model's prompt contract.

**Unique value:**
- Visible, focusable agent panes with durable ownership and recovery.
- Turn re-triggering on results.
- Branch/worktree-scoped Manager→Lead project orchestration.
- Token and cost stats across the tree.
- Cross-Lead peer messaging.
- SSH/Tailscale container for remote Herdr machines.
