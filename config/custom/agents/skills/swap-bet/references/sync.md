# sync

Turn the PO sync into decisions, and the decisions into a spec the owner signs.

Reads `brief.md` + the owner's sync notes (pasted, or a Slack thread link). Writes `spec.md`
from [templates/spec.md](../templates/spec.md).

## Preflight

| Tool | Probe (read-only) |
|---|---|
| Slack MCP | `mcp({ connect: "slack" })`, read the given thread (only when notes are a Slack link) |
| Plannotator | `plannotator_inbox` tool listed, or `plannotator inbox --help` exits 0 |

## Steps

1. **Map notes to the agenda.** Each agenda item in `brief.md` gets its outcome: decided
   (what, by whom), deferred, or unanswered. Write the outcomes into `brief.md` under the
   agenda so the one-pager records them once.
2. **Pick the outcome** with the owner:
   - `go` → step 3.
   - `park` → one line in `brief.md` (why, what would reopen it); stop.
   - `research again` → name the new questions in `brief.md`; next is `swap-bet brief <KEY>`.
   Unanswered items that block the spec go to the owner now as one numbered round with
   recommendations (`cock-grilling` style).
3. **Write `spec.md`**: what we build, decisions (linking back to the agenda), acceptance
   criteria each with a verifier, metrics plan, walking skeleton, out of scope. A decision
   still open may stay `OPEN` naming the slice it blocks; only that slice's ticket waits.
4. **Hard gate — owner sign-off.** Owner reviews `spec.md` through Plannotator (SKILL.md
   Gates). Apply edits, then record the sign-off line. Without it, stop here: `tickets` and
   `build` will refuse.

Done when `spec.md` carries the sign-off line. Commit; next: `swap-bet tickets <KEY>`.

## After sign-off

The process is still being found, so a change needs no re-sign: edit `spec.md`, draft the
change in the bet thread as in `publish.md` step 4 (the owner sends it), move on once the PO
acks (e.g. an `:ok:` reaction), and add one bullet under `## Changes since sign-off` linking
that Slack message. Resolving an `OPEN` decision takes the same path; its slice is then
unblocked.
