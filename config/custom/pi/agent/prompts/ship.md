---
description: Pre-launch gate — parallel fan-out to reviewer and tests, then a merged go/no-go
argument-hint: "[scope]"
---

Invoke the `/skill:shipping-and-launch` skill.

`/ship` is a **fan-out orchestrator**. It runs two specialist personas against the current change
in parallel, then merges their reports into a single go/no-go decision with a rollback plan. The
personas operate independently — no shared state, no ordering — which is what makes parallel
execution safe here.

Scope: ${@:-the staged changes, or the most recent commit if nothing is staged}.

## Phase A — Parallel fan-out

Establish the exact scope first (`git diff --cached`, `git diff`, `git show`), then issue **one**
`subagent` call with both children in the `children` array so they launch together. Each child
starts with a clean context and cannot see this chat — the brief must carry the scope, the intent
of the change, and any constraint they need.

1. **`reviewer`** — five-axis review (correctness, readability, architecture, security,
   performance) on the named diff. Brief it to go deep on the security axis for this gate:
   OWASP Top 10, secrets handling, auth/authz, dependency risk. Findings graded
   blocker / should-fix / nit with `file:line`.
2. **`tests`** — coverage analysis for the change: gaps in happy path, edge cases, error
   paths, concurrency. Standard coverage analysis.

Constraints:

- Children do not spawn children. If one wants a deeper pass from another persona, it says so in
  its report and this session decides.
- `reviewer` opens in a pane; `tests` runs headless. Both report back here.
- Neither can edit. Fixes happen in this session or via `impl` / `dev`.

## Phase B — Merge in this session

Once both reports are back, synthesize them here (not in a child):

1. **Code quality** — aggregate Critical/Important findings from `reviewer` plus any failing
   tests, lint, or build output. Resolve duplicates between reports.
2. **Security** — promote Critical/High findings from `reviewer`'s security axis to launch
   blockers.
3. **Performance** — pull from `reviewer`'s performance axis.
4. **Accessibility** — keyboard nav, screen reader support, contrast. Not covered by the two
   personas — verify directly.
5. **Infrastructure** — env vars, migrations, monitoring, feature flags. Verify directly.
6. **Documentation** — README, ADRs, changelog. Verify directly.

## Phase C — Decision and rollback

```markdown
## Ship Decision: GO | NO-GO

### Blockers (must fix before ship)
- [source persona: Critical finding + file:line]

### Recommended fixes (should fix before ship)
- [source persona: Important finding + file:line]

### Acknowledged risks (shipping anyway)
- [risk + mitigation]

### Rollback plan
- Trigger conditions: [what signals would prompt rollback]
- Rollback procedure: [exact steps]
- Recovery time objective: [target]

### Specialist reports (full)
- [reviewer report]
- [tests report]
```

## Rules

1. The two Phase A personas run in parallel — one `subagent` call, never two sequential ones.
2. Personas do not call each other. The merge happens in Phase B, here.
3. The rollback plan is mandatory before any GO decision.
4. Any Critical finding means NO-GO by default, unless the user explicitly accepts the risk.
5. **Skip the fan-out only if all of these hold:** the change touches 2 files or fewer, the diff is
   under 50 lines, and it does not touch auth, payments, data access, or config/env. Otherwise fan
   out even when the diff looks small — `/ship` is for production-bound changes.
6. A child's summary is a claim. Check the diff before you believe it.
