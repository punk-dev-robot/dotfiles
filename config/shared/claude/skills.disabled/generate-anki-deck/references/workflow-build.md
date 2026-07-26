# Build .apkg Deck from Card JSON

## Steps

1. **List available sources** — scan `./anki-output/` for source directories containing a `cards/` subdirectory with JSON files
2. **Ask which source** to build (or confirm if only one exists)
3. **Run the build script** from the skill directory:
   ```bash
   scripts/build_deck.py \
     --source-dir ./anki-output/{source-slug} \
     --deck-name "{Deck Name}"
   ```
   Deck name defaults to the source slug title-cased (e.g., `system-design-interview` → `System Design Interview`)
4. **Verify** the .apkg file was created at `./anki-output/{source-slug}/{source-slug}.apkg`
5. **Report** the output path, card count, and any validation warnings

## Troubleshooting

- If `uv` is not available, fall back to `pip install genanki && python <script>`
- If validation errors appear, list them and offer to fix the card JSON
