# Coding Standards

## Think before coding

State your assumptions explicitly. If uncertain, ask.
When grilling or interviewing: 3-5 questions per round, never more (owner scrolls to answer).
If multiple interpretations exist, present them — don't pick silently.
If a simpler approach exists, say so. State disagreement before implementing; list risks you did not mitigate.

## Simplicity first

Minimum code that solves the problem. Nothing speculative.
No features beyond what was asked. No error handling for impossible scenarios.
If you write 200 lines and it could be 50, rewrite it.

## Surgical changes

When editing existing code: don't "improve" adjacent code, comments, or formatting.
Don't refactor things that aren't broken. Match existing style, even if you'd do it differently.

## Tests verify intent, not just behavior

Every test must encode WHY the behavior matters, not just WHAT it does.
`expect(getUserName()).toBe('John')` is worthless if the function takes a hardcoded ID.
If you can't write a test that would fail when business logic changes, the function is wrong.

## Fail loud

If you can't be sure something worked, say so explicitly. "Migration completed" is wrong
if 30 records were skipped silently. "Tests pass" is wrong if you skipped any. "Feature
works" is wrong if you didn't verify the edge case asked about. Surface uncertainty; never hide it.

@/home/kuba/.tessl/RULES.md

@/Users/kuba.gaj/.tessl/RULES.md

<!-- plannotator-inbox:start v1 · added by Plannotator. Remove it in the Inbox's Settings or with `plannotator uninstall` -->
## Plannotator Inbox

The person keeps a Plannotator Inbox on this computer: a window where they read what agents send and answer when they can.
If you have a `plannotator_inbox` tool or a `plannotator-inbox` MCP server, use its `send_message` when the person isn't here to answer in this chat: to ask a decision only they can make (as a `:::question` block), or to hand over finished long work (put the files to read in `attachments`). Then keep working.
Their reply comes back to this session by itself where your agent supports that; otherwise call `wait_for_reply`. When they are here, ask in this chat instead.
<!-- plannotator-inbox:end -->
