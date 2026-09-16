# punk-steering v1 — tool-aware steering extension for pi

Tracker: KUB-164. Vocabulary: `CONTEXT.md` → Agent context (harness, context file, global/project
context, steering, enforcement). Research: `docs/.scratch/research-pi-steering-extensions.md`,
`docs/.scratch/research-context-file-format.md`. Phase 1 (context-file cleanup): KUB-159.

## Problem Statement

Tool and workflow guidance (delegate to subagents, prefer repowise, MCP-first, tracker
conventions, web-research routing) is loaded into every pi session as one flat block
(`APPEND_SYSTEM.md`, 7.6KB — 63% of always-loaded context). It is sent to subagents that
lack the tools it talks about, it cannot be tuned per session, and it says nothing when a tool
the guidance depends on is missing or unhealthy (MCP server down, repowise index absent or
stale). The owner cannot roll out a new rule cautiously — it is either in the prompt or not.

## Solution

A small pi extension, `punk-steering`, that reads steering **rules** (markdown files with
YAML frontmatter) and, at agent start, applies only the rules whose required tools are
present in the session. Each rule is one of three kinds: a **briefing** (prose appended to the
system prompt), a **precondition** (a probe that runs before work starts and can notify, ask,
run a fix, or stop the session), or — reserved for v2 — a **reminder** (mid-session nudge on an
observation). A global level dial (`off / observe / advise / rewrite`) lets the owner watch what
a rule *would* do before letting it speak. `APPEND_SYSTEM.md` is migrated into rules and
deleted.

## User Stories

1. As the owner, I want tool guidance injected only when the session actually has that tool, so that subagents with restricted tool sets don't read irrelevant rules.
2. As the owner, I want to match tools by glob (`repowise_*`, `*linear_*`), so that one rule covers an MCP server's whole tool family without listing every tool.
3. As the owner, I want each rule in its own markdown file with frontmatter, so that I can grep, edit, and review rules like roles and skills.
4. As the owner, I want a global `level` dial, so that I can switch all steering off, observe, advise, or rewrite without editing rules.
5. As the owner, I want `observe` to log which rules would have fired and why, without changing the prompt, so that I can roll out a rule and check the log before trusting it.
6. As the owner, I want a per-rule `level` override capped by the global dial, so that one experimental rule can sit at observe while the rest advise.
7. As the owner, I want a briefing rule's body appended to the system prompt at agent start, so that long workflow explanations arrive once, up front.
8. As the owner, I want briefings to survive compaction, so that a long session does not silently lose its workflow rules.
9. As the owner, I want a precondition rule to run a probe command before the first turn, so that missing or unhealthy dependencies surface before work begins.
10. As the owner, I want a failed probe to `notify` me, so that I know a tool is degraded but can continue.
11. As the owner, I want a failed probe to `ask` me a yes/no question and run a fix command on yes, so that "repowise index missing — init now?" is one prompt, not a debugging session.
12. As the owner, I want a failed probe to `run` a fix command silently, so that "repowise index stale → reindex" happens without asking.
13. As the owner, I want a failed probe to `stop` the session with a clear reason, so that an essential MCP server being down does not produce a session that quietly works around it.
14. As the owner, I want a precondition to declare `required_tools` and treat their absence as probe failure, so that "MCP didn't start" is caught by the same mechanism as "index stale".
15. As the owner, I want precondition probes to run once per session, not every turn, so that steering adds no per-turn latency.
16. As the owner, I want rules from the global rules directory and the project's `.pi/` rules directory merged, project winning on name collision, so that a repo can override a global rule.
17. As the owner, I want the extension to append to the chained system prompt and never rewrite or remove text other extensions added, so that steering cannot break caveman, ponytail, advisor, or readseek.
18. As the owner, I want every injected block tagged with its rule name, so that when I dump the system prompt I can see which rule said what.
19. As the owner, I want a `/steering` command that lists loaded rules, their kind, their gate result for this session, and their effective level, so that "why did/didn't X fire" is one command.
20. As the owner, I want rule files hot-reloaded on `/reload`, so that editing a rule does not require restarting pi.
21. As the owner, I want a malformed rule file to be reported and skipped rather than aborting all steering, so that one typo does not silence every rule.
22. As the owner, I want `APPEND_SYSTEM.md` split into one rule per section and then deleted, so that phase 1's TEMPORARY block is gone.
23. As the owner, I want the repowise prompt text in `repowise-augment.ts` replaced by a steering rule, so that repowise guidance has one author and one home.
24. As a subagent (piewf role), I want to receive only the briefings for tools I have, so that my context budget goes to the task.
25. As a subagent, I want preconditions to run in my session too, so that a child launched while an MCP server is down fails fast instead of improvising.
26. As a piewf role author, I want to opt a role out of steering with the existing `extensions: ["!…"]` selector, so that no new role syntax is needed in v1.
27. As the owner, I want the resolver (rules + tool list + probe results → actions) to be a pure function with fixture tests, so that the logic is verifiable without launching pi.
28. As the owner, I want to see in the doc (`docs/reference/agent-context-files.md`) that tool guidance now lives in steering rules, so that the placement rule stays accurate.

## Implementation Decisions

**Kinds.** A rule is `kind: briefing | precondition | reminder`. v1 implements briefing and
precondition. `reminder` is parsed and rejected with a clear "not implemented in v1" report so
the schema is stable from day one.

**Gate.** Every rule has `when.tools`: a list of glob patterns (minimatch-style `*`, `?`)
matched against the session's active tool names (`event.systemPromptOptions.selectedTools` in
`before_agent_start`). Default semantics: rule applies if **any** pattern matches at least one
tool. `when.tools_all: true` switches to all-patterns-must-match. Empty/absent `when` = always
applies. No other predicates in v1 (no cwd, model, or role conditions — cwd-shaped guidance
stays in project `AGENTS.md`).

**Levels.** Global `level` in the extension's settings block: `off | observe | advise |
rewrite`. Per-rule `level` may lower but never raise the effective level. Semantics for a
briefing: `off` = nothing; `observe` = log the would-fire decision (rule name, matched tools)
to the extension's log and `/steering` output, inject nothing; `advise` = append body to the
system prompt; `rewrite` = reserved for rules that carry a `rewrite` block mutating a tool
call's input (v1 parses, does not execute — no rule needs it yet). `block` is deliberately
absent; v2 may add it with semantics *terminate session + flag for review*, never
deny-and-retry.

**Briefing injection.** In `before_agent_start`, return
`{ systemPrompt: event.systemPrompt + "\n\n" + block }` where `block` is the bodies of all
applicable briefings, each wrapped in a one-line header naming the rule. Append only; never
inspect, strip, or reorder text from other handlers. Because `before_agent_start` fires every
turn, briefings are present after compaction without extra handling. Position in the chain is
load order and is not controlled.

**Precondition probes.** Frontmatter: `required_tools` (globs; absence = failure),
`probe` (shell command; non-zero exit = failure; stdout captured for the message), `on_fail:
notify | ask | run | stop`, `fix` (shell command; required for `ask` and `run`), `message`
(shown to the user; `{stdout}` placeholder). Probes run once per session on the first
`before_agent_start`, sequentially, with a timeout (default 10s, per-rule override). `ask` uses
the extension UI confirm; yes → run `fix`; no → continue. `stop` → `ctx.ui.notify` the reason
and abort the turn via the documented abort path; the session stays open for the user. In
`observe`, probes still run but every `on_fail` degrades to a log entry. Preconditions are
gated by `when.tools` like every rule, so a repowise check only runs when repowise tools exist.

**Rule discovery and merge.** Global: `<agentDir>/steering/*.md` (deployed by dotter from the
dotfiles repo). Project: `.pi/steering/*.md` (only after project trust, via pi's resource
discovery). Rule name = filename without extension; project wins on collision. Loaded on
session start and `/reload`. Parse errors are collected and shown once via notify plus in
`/steering`; the bad file is skipped.

**Overlap with other extensions' prose.** Not handled mechanically. Rules steer *gaps*: tools
whose shipped guidance is absent or wrong. Where another extension's guidance should be
replaced, disable it via that extension's own switch (mode flag, or piewf role `extensions`
exclusion). Reserved for v2 if a real case appears: per-rule `posture: defer | augment |
replace`.

**Architecture.** Two modules. `resolver`: pure — `(rules, selectedTools, globalLevel,
probeResults?) → { briefings: [{name, body}], preconditions: [{name, action, message}],
observed: [{name, reason}], errors }`. No pi imports. `adapter`: the extension entry —
discovers files, calls resolver, executes probes/fixes via the exec API, appends prompt,
registers `/steering`, subscribes to reload. Everything decision-shaped lives in the resolver.

**Migration.** `APPEND_SYSTEM.md` sections → rules: delegation (`when.tools:
[subagents_run]`), tool economy (always), web research routing (`web_search`,
`fetch_content`), repowise routing (`repowise_*`), multi-repo coordinator (`repowise_*`),
external services / MCP-first (`*linear_*`, `*notion_*`, `*logfire_*`), Linear conventions
(`*linear_*`). Delete `APPEND_SYSTEM.md`. `repowise-augment.ts` loses its
`before_agent_start` prompt text (keeps its `tool_result` observer); two precondition rules
replace the repowise checks: index absent → `ask` init; index stale → `run` reindex.
`context-nudge.ts` stays until reminders exist. Doc `docs/reference/agent-context-files.md`
placement table updated: "names a tool → steering rule".

**Packaging.** Lives in the dotfiles repo under the pi agent extensions dir first (same as
`repowise-augment.ts`), deployed by the existing dotter map. Extraction to its own package
only if it grows tests/deps that don't belong in dotfiles.

## Testing Decisions

Good test = external behaviour of the resolver: given these rule files, this tool list, this
level, and these probe outcomes, these are the actions. No assertions on internal parsing
steps or on pi's prompt string layout beyond "contains rule body with header".

Tested module: `resolver` only, via fixture rule files in a `fixtures/` dir next to the tests
(one per scenario: any-match, all-match, no-match, level capping, observe degrading,
precondition fail → each `on_fail`, malformed frontmatter skipped, project-overrides-global).
Runner: whatever piewf uses (`packages/core/test/*.test.ts` — node test runner style); keep
it dependency-free so it runs from the dotfiles checkout.

Adapter: one manual smoke per milestone — `pi -p -e <extension> "print the rule headers in
your system prompt"` from the dotfiles root and from a subagent-like restricted tool set;
recorded in the ticket, not automated. Prior art: KUB-163 verification probes.

## Out of Scope

Other harnesses (Claude Code, codex, opencode). Bash argv / destructive-command guarding —
`@cad0p/pi-steering`, `guardme` territory, installable alongside. Everything below.

## Deferred — v2+ backlog

Every decision that moved something out of v1, with the trigger that brings it back. Mirrored
as a checklist on KUB-164; keep both in sync.

| # | Item | Why deferred | Bring back when |
|---|---|---|---|
| D1 | `reminder` kind — observation-triggered nudges (turn count, tool seen, N turns since X) via `sendMessage(deliverAs: steer)` | predicate surface is open-ended; one existing case covered by `context-nudge.ts` | second reminder is wanted, or `context-nudge.ts` needs a condition |
| D2 | `block` level — semantics *terminate session + flag for review*, never deny-and-retry (pix-nudge: forced retries waste turns) | no v1 rule needs it; needs tracker-write path | a rule exists whose violation should end the session |
| D3 | `rewrite` execution (mutate `tool_call` input) | schema parsed, no rule needs it | first routing rule that is better as a rewrite than as prose (rtk-style) |
| D4 | `posture: defer \| augment \| replace` per tool toward other extensions' shipped guidance | overlap is content, fixed at source or via the other extension's own switch | owner wants more/less aggressive guidance than a tool ships and its switch is insufficient |
| D5 | Role-contributed rules: (a) match on piewf role name, (b) `steering:` frontmatter key in `AgentDefinition` | v1 opts roles out via existing `extensions: ["!…"]` | a role needs its own rule; verify unknown-key survival in piewf decoders before (b) |
| D6 | Conditions beyond tools: cwd / repo shape, model, MCP server health as a predicate | cwd-shaped guidance lives in project `AGENTS.md`; model = premature | a rule cannot be expressed with tool globs alone |
| D7 | Precondition probes as tool calls (not shell) | shell probe covers repowise/MCP cases | a probe needs an MCP tool result, not a CLI |
| D8 | Extract to standalone package | lives in dotfiles extensions dir | tests/deps outgrow dotfiles, or a second machine/user wants it |
| D9 | Mechanical dedup of other extensions' prompt text (marker-based strip) | fragile; rejected | never, unless D4 proves insufficient |
| D10 | Enforcement via `tool_call` hooks generally (advise→block ladder end) | pi-steering/guardme cover safety rails | D2 or D3 lands |

## Further Notes

- pi chains `before_agent_start` handlers; all installed extensions append (`caveman`,
  `ponytail`, `pi-advisor-flow`, `repowise-augment`). Overwriting would drop earlier handlers'
  text — never do it.
- `pi-rules` was removed (07761a9) to avoid double injection; `.pi/rules/` is not read.
- pix-nudge's field note: blocking early wastes a turn on forced retry — reason `block` is
  deferred and, when added, means stop-and-review.
- Per-turn cost target: briefings for a typical main session ≤ current APPEND_SYSTEM.md
  (7.6KB); a recon subagent should receive only tool-economy + repowise briefings.
