## What
<what to do, one or two sentences>

## Intent
<why, only when it adds something the title and What do not; else drop the heading>

## Slice
<the user-visible behaviour this makes work, end to end, across whatever repos and layers it
touches>

## Verification
Written for `verify-window-shop` (see its `features/README.md`):

- **Surface / feature ids:** <api | widget | pilot-web> · <feature>/<sub-feature ids>, or
  "new recipe needed: <what>", or "no recipe for this surface — manual: <steps>"
- **Action:** <what the shopper does>
- **Read-back:** <second user path that shows the result: history GET, widget reload, …>
- **Expected user-visible text:** <words the shopper should see>
- **Flags / env:** <flag = value, env (uat default), store if not the test store>
- **Logfire `--live` needed:** yes — <span/attribute to show> | no

Blocked by: native Linear relation (none = can start now); an `OPEN` spec decision as a
text line `Blocked by: D<n> (OPEN)`.

Skipped defaults: <default — reason> (drop the line when none).
