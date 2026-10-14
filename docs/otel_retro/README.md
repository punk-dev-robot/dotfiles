# otel_retro

Periodic retrospectives on the agentic workflow, driven by pi's OTel data in Logfire.
One review per session (`<date>-logfire-review.md`); one running ledger of deliberate changes
scored against expectations (`<date>-experiments-ledger.md` — append rows, start a new file only
when the standard queries change).

| date | file | what |
|---|---|---|
| 2026-09-16 | [logfire-review](2026-09-16-logfire-review.md) | 14d baseline: cost, context, tool/skill usage, telemetry gaps, hypotheses H0–H5 |
| 2026-09-16 | [experiments-ledger](2026-09-16-experiments-ledger.md) | E1 KUB-149 compaction/OM; E2 context-events telemetry; E3 KUB-164 punk-steering; E4–E8 readseek/guards/otel/augment; E9 repowise full setup (→ `reference/repowise-repo-setup.md`) |
| 2026-09-16 | [logfire-queries](2026-09-16-logfire-queries.md) | every SQL used, copy-paste ready |
| 2026-09-19 | [logfire-review](2026-09-19-logfire-review.md) | weekly last-week-vs-this-week comparison; experiment verdicts E1/E3/E6/E9 scored against expectations |
| 2026-10-14 | [herdsman-baseline](2026-10-14-herdsman-baseline.md) | pre-trial numbers for the pi-herdsman switch (KUB-171): child vs main cost, first-turn input; rerunnable SQL for the go decision |

Query gotchas: 14d max window, pass `start_timestamp` + `end_timestamp` explicitly; cost from
`chat *` spans only; `event.name` lands as `span_name`; never `SELECT attributes` raw (30KB/row).
Role attribution recipe: `docs/reference/logfire-pi-role-attribution.md`.
