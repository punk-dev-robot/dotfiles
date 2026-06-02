# Generate Anki Cards from Chapters

Read `card-types.md` and `card-json-schema.md` before generating any cards.

## Steps

1. **List available sources** — scan `./anki-output/` for source directories containing a `chapters/` subdirectory
2. **Ask which source** to generate cards for (or confirm if only one exists)
3. **Select chapters** — if `--chapters` was provided, use that selection directly. Otherwise, ask which chapters: all, or a specific range/selection.
4. **Create cards directory**: `./anki-output/{source-slug}/cards/`
5. **For each chapter**:
   a. Read the chapter markdown from `./anki-output/{source-slug}/chapters/`
   b. Generate a mix of card types appropriate to the content
   c. Follow the card quality principles from SKILL.md
   d. Apply the card type guidelines from `card-types.md`
   e. Output JSON matching the schema in `card-json-schema.md`
   f. Write to `./anki-output/{source-slug}/cards/chapter-{NN}.json`
6. **Report** card counts by type and chapter

## Guidelines

- Aim for 5-15 cards per chapter section (more for dense content, fewer for light)
- Use Q&A for concepts, definitions, benefits, principles
- Use cloze for formulas, specific terms, numerical values (max 2-3 per section)
- Use scenario for design problems and decision-making
- Use tradeoff for comparing options or approaches
- Ensure `chapter`, `chapter_number`, and `topic` fields match the source material
- Extract the chapter number from the filename pattern `{NN}-{slug}.md`
