#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["pymupdf4llm"]
# ///
"""Extract PDF content as LLM-optimized markdown using pymupdf4llm.

Usage:
    scripts/extract_pdf.py <pdf-path>
    scripts/extract_pdf.py <pdf-path> --pages 1-20,25-30
    scripts/extract_pdf.py <pdf-path> --output extracted.md
    scripts/extract_pdf.py <pdf-path> --images ./images
"""

import argparse
import sys
from pathlib import Path

import pymupdf4llm


def parse_page_ranges(spec: str, max_pages: int) -> list[int]:
    """Parse page range spec like '1-20,25-30' into 0-indexed page numbers."""
    pages: list[int] = []
    for part in spec.split(","):
        part = part.strip()
        if "-" in part:
            start, end = part.split("-", 1)
            start_i = max(int(start) - 1, 0)
            end_i = min(int(end), max_pages)
            pages.extend(range(start_i, end_i))
        else:
            page_i = int(part) - 1
            if 0 <= page_i < max_pages:
                pages.append(page_i)
    return sorted(set(pages))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract PDF to LLM-optimized markdown"
    )
    parser.add_argument("pdf_path", type=Path, help="Path to PDF file")
    parser.add_argument(
        "--pages",
        type=str,
        default=None,
        help="Page ranges to extract (1-indexed), e.g. '1-20,25-30'",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output file path (defaults to stdout)",
    )
    parser.add_argument(
        "--page-breaks",
        action="store_true",
        help="Insert page break markers between pages",
    )
    parser.add_argument(
        "--images",
        type=Path,
        default=None,
        help="Extract images to this directory (adds ![](path) refs in markdown)",
    )
    parser.add_argument(
        "--image-size-limit",
        type=float,
        default=0.05,
        help="Ignore images smaller than this fraction of page area (default: 0.05)",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=150,
        help="Image resolution in DPI (default: 150)",
    )
    args = parser.parse_args()

    if not args.pdf_path.exists():
        print(f"Error: file not found: {args.pdf_path}", file=sys.stderr)
        sys.exit(1)

    kwargs: dict = {"show_progress": False}

    if args.pages:
        import pymupdf

        doc = pymupdf.open(str(args.pdf_path))
        page_numbers = parse_page_ranges(args.pages, len(doc))
        doc.close()
        kwargs["pages"] = page_numbers

    if args.page_breaks:
        kwargs["page_chunks"] = True

    if args.images:
        args.images.mkdir(parents=True, exist_ok=True)
        kwargs["write_images"] = True
        kwargs["image_path"] = str(args.images)
        kwargs["image_size_limit"] = args.image_size_limit
        kwargs["dpi"] = args.dpi

    result = pymupdf4llm.to_markdown(str(args.pdf_path), **kwargs)

    if args.page_breaks and isinstance(result, list):
        text = "\n\n---\n\n".join(chunk["text"] for chunk in result)
    elif isinstance(result, list):
        text = "\n\n".join(chunk["text"] for chunk in result)
    else:
        text = result

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text)
        print(f"Extracted to {args.output}", file=sys.stderr)
    else:
        print(text)

    if args.images:
        image_count = len(list(args.images.glob("*")))
        print(f"Extracted {image_count} images to {args.images}", file=sys.stderr)


if __name__ == "__main__":
    main()
