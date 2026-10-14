---
name: simplification-audit
description: Run an occasional, read-only, evidence-gated audit for removable code, meaningful duplication, and unjustified dependencies, tooling, or configuration. Use only when explicitly requested.
disable-model-invocation: true
---

# Simplification audit

Find improvements worth making, not diagnostics worth silencing. Follow the repository's `AGENTS.md`, product philosophy, and relevant ADRs. Apply Ponytail Ultra if that skill is available.

Out of scope: bugs, security, performance, architecture, and agent-system coherence — those belong to `ponytail-audit` or `agentic-system-audit`.

## Scope

- Use a clean worktree at the head of the default remote branch; record the commit.
- Read a prior audit report if supplied. Compare only findings from comparable tool versions, configuration, and scope. Otherwise establish a new baseline.
- Treat the repository — source, tests, dependencies, scripts, hooks, CI configuration — as read-only. Temporary tool configs and the report go in a gitignored location (the repo's scratch dir if it has one, else a temp dir). No implementation, commits, issues, PRs, or permanent dependencies.
- Focus on production code; investigate tests or tooling only when a finding makes them relevant.

## Map

Before scanning, identify:

- Languages and their share of production code.
- Entry points: binaries, `main`s, package exports, CLI commands, handlers, jobs, plugin/extension manifests, scripts invoked by CI or hooks.
- Dynamic consumers that static tools cannot see: reflection, string-based loading, config-registered handlers, externally invoked scripts, public API used by other repos.

Tools only know the graph you give them. These entry points are what make unused-code results interpretable.

## Scan

Run current tool versions on demand via the ecosystem's ephemeral runner (`npx`, `uvx`, `go run …@latest`, `cargo install` into a temp root). Record actual versions, commands, configuration, scope, and failures. Ensure the project's dependencies are installed first.

**Unused code and dependencies** — pick the tool for each language present:

| Language | Unused code | Unused dependencies |
|---|---|---|
| JS/TS | `knip --production` | knip (same run) |
| Python | `vulture` | `deptry` |
| Go | `deadcode` (`golang.org/x/tools/cmd/deadcode`) | `go mod tidy -diff` |
| Rust | compiler `dead_code` warnings | `cargo-machete` |
| Other | compiler/linter unused warnings | the package manager's own check, if any |

If a tool needs entry-point configuration, write it to the temporary location from the map, not to tracked files, and record it. No tool for a language: fall back to grep-based reachability on the entry-point map, and say so.

**Duplication** — `jscpd` covers most languages. Look for substantial production duplication, not similar syntax:

```sh
npx --yes jscpd <source dirs> --ignore '<test globs>' \
  --min-tokens 100 --min-lines 15 --mode mild --threshold 100 \
  --reporters console --no-colors
```

**Only when warranted:** a strict linter or type check for a specific correctness question. Broad lint and type scans are noisy; do not run them by default or propose them as gates.

## Triage

Compare against prior verified or rejected findings when available. Do not re-investigate unchanged noise. For each promising candidate:

1. Trace actual callers, entry points, runtime reachability, consumers, and the authoritative contract. Grep the whole tree, including tests, config, and string/dynamic references.
2. Group cascading diagnostics. Distinguish a reachable defect, dead complexity, genuinely duplicated semantics, a justified boundary, and a false positive.
3. Prefer deletion, existing code, native/stdlib facilities, or a root-cause correction. Propose consolidation only when ownership, authorization, lifecycle, validation, and failure semantics really match.
4. State the independent benefit, approximate net code/configuration change, risks, and smallest discriminating check. A lower diagnostic count or line count alone is not a benefit.
5. Reject speculative changes, cosmetic cleanup, generated or vendored code, and abstractions that cost more than they save.

Hold tooling and configuration to the same standard: identify an obsolete or duplicated responsibility before proposing removal. Do not discard validation, durability, security, recovery, or portability guarantees.

## Output

Write one report, `simplification-audit.md`, in the temporary location:

- Baseline commit, prior audit if any, languages, entry-point map, tool versions/commands/configuration.
- Counts for context, clearly separated from **at most five independently verified, actionable findings**.
- For each finding: source location, root cause, consumer/reachability evidence, minimal change, benefit, risks, and validation.
- Material rejected/unchanged findings and limitations (languages without a tool, dynamic consumers not traced).
- Recommended order, or **No action** if nothing justifies a change.

Remove temporary configs, verify `git status --short` is clean and `git diff --check` passes, and report the report path plus any tracked changes or blockers. **Stop after the audit; implementation requires a separate request.**
