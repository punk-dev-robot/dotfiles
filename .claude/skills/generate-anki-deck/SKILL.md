---
name: generate-anki-deck
description: >-
  This skill should be used when the user asks to "generate Anki cards",
  "create flashcards from a PDF", "convert a book to Anki deck",
  "build an .apkg file", "make study cards from a document",
  "create an Anki deck", or "extract flashcards from a book".
  Handles the full pipeline from source document through chapter extraction,
  card generation, and .apkg deck building.
version: 0.1.0
---

# Generate Anki Deck

Usage: `generate-anki-deck [convert|generate|build|full <source-path>] [--chapters N,N-N]`

## Step 1: Determine Workflow

Infer the workflow from provided arguments. If none provided, use AskUserQuestion:

**"What would you like to do?"**

Options:
1. **Convert** — source (PDF/document) to markdown chapters
2. **Generate** — Anki cards from existing chapters
3. **Build** — .apkg deck from existing card JSON
4. **Full pipeline** — source → chapters → cards → deck

If `--chapters` is provided (e.g., `--chapters 3`, `--chapters 3,5-7`), pass the selection through to the generate step — skip the "which chapters?" prompt.

## Step 2: Load Workflow

Read the workflow file for the chosen step:

| Choice | File to read |
|--------|-------------|
| Convert | `references/workflow-convert.md` |
| Generate | `references/workflow-generate.md` |
| Build | `references/workflow-build.md` |
| Full pipeline | `references/workflow-pipeline.md` |

Then execute the steps in that workflow file.

## Card Quality Principles

These apply to ALL card generation — non-negotiable.

1. **Atomic concepts**: Each card tests ONE idea. Never combine multiple concepts.
2. **Concise questions**: Clear and direct, 1-2 sentences max.
3. **Detailed answers**: Explain WHY, not just WHAT. Include context and implications.
4. **ASCII diagrams**: For architecture or flow content, include simple ASCII diagrams in answers (box-and-arrow, under 10 lines).
5. **No trivial facts**: Skip page numbers, author names, copyright info, "see chapter X" references.
6. **No multi-concept cards**: If testing two ideas, make two cards.

## Output Structure

All output goes to `./anki-output/` in the current working directory, scoped by source:

```
./anki-output/{source-slug}/
├── chapters/              # 01-chapter-title.md, ...
├── cards/                 # chapter-01.json, ...
└── {source-slug}.apkg     # Final deck
```

The source slug is derived from the filename or title (kebab-case, lowercase).

## Constraints

- **Do not enter plan mode.** Execute workflow steps directly.
- **Scripts are executables.** Run them directly (e.g., `scripts/extract_pdf.py`). Do not read their source code.
- **Load files on demand.** Only read the workflow file for the current step. Do not pre-load all workflows or references.
- **Do not write custom Python.** All PDF extraction and deck building is handled by the provided scripts.
