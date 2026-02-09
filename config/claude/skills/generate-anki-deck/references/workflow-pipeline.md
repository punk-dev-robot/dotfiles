# Full Pipeline: Source → Deck

Orchestrates the complete workflow: convert → generate → build.

## Steps

1. **Ask for source path** and optional source name
2. **Convert** — read `workflow-convert.md` and follow its steps
3. **Select chapters** — if `--chapters` was provided, use that selection directly. Otherwise, show the chapter list and ask which to generate cards for (all or selection).
4. **Generate** — read `workflow-generate.md` and follow its steps
5. **Build** — read `workflow-build.md` and follow its steps
6. **Report** final summary: source, chapter count, card count, output .apkg path

## Notes

- The source slug established during convert flows through all subsequent steps
- If any step fails, stop and report the issue rather than continuing
- For large sources, offer to process chapters in batches (e.g., 5 at a time)
