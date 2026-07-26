# Convert Source to Markdown Chapters

## Steps

1. **Ask for source path** — file path to PDF or document
2. **Ask for source name** (optional) — defaults to kebab-case slug of filename without extension
3. **Create output directory**: `./anki-output/{source-slug}/chapters/`
4. **Extract the source content**:
   - For PDF: Run from the skill directory:
     ```bash
     scripts/extract_pdf.py <pdf-path> \
       --output ./anki-output/{source-slug}/raw.md \
       --images ./anki-output/{source-slug}/images
     ```
     The `--images` flag extracts diagrams/figures as PNGs (filtered by `--image-size-limit 0.05` to skip small icons). The markdown will contain `![](path)` references to these images.

     For large PDFs, extract in ranges of up to 50 pages:
     ```bash
     scripts/extract_pdf.py <pdf-path> --pages 1-50 \
       --output ./anki-output/{source-slug}/raw-001.md \
       --images ./anki-output/{source-slug}/images
     ```
   - For other formats: Read the full file with the Read tool
5. **Detect chapter boundaries** from table of contents, heading patterns, or clear section breaks
6. **Write one markdown file per chapter** to `./anki-output/{source-slug}/chapters/`:
   - Filename: `{NN}-{chapter-slug}.md` (e.g., `01-scale-from-zero.md`)
   - Format: `# Chapter N: Title` followed by `## Section` headings with clean body text
   - Strip headers, footers, page numbers, and formatting artefacts
   - Preserve tables, lists, and code blocks
7. **Report** the chapter list and total page count

## Notes

- If chapter boundaries are unclear, ask for guidance
- For very large PDFs (200+ pages), extract in 50-page batches and confirm progress between batches
- Skip front matter, index, and appendices unless explicitly requested
- If the PDF has a table of contents, extract just the TOC pages first to plan chapter splits before reading content
