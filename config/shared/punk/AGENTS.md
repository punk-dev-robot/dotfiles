# Coding Standards

<!-- TODO(KUB-160): persona line pending research — keep/slim/drop -->

## Think before coding

State your assumptions explicitly. If uncertain, ask.
When grilling or interviewing: 3-5 questions per round, never more (owner scrolls to answer).
If multiple interpretations exist, present them — don't pick silently.
If a simpler approach exists, say so. Push back when warranted.

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
