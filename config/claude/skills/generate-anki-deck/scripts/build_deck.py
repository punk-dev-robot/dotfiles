#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["genanki"]
# ///
"""Build Anki .apkg decks from card JSON files.

Usage:
    scripts/build_deck.py --source-dir ./anki-output/my-book
    scripts/build_deck.py --source-dir ./anki-output/my-book --deck-name "My Book"
"""

import argparse
import hashlib
import html
import json
import re
import sys
from pathlib import Path

import genanki

# Stable model IDs — shared across all decks so card types have consistent formatting
QA_MODEL_ID = 1407392319
CLOZE_MODEL_ID = 1498127456
SCENARIO_MODEL_ID = 1582736891
TRADEOFF_MODEL_ID = 1673451234

COMMON_CSS = """\
.card {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    font-size: 16px;
    text-align: left;
    color: #333;
    background-color: #fafafa;
    padding: 20px;
}
.chapter {
    font-size: 12px;
    color: #888;
    margin-bottom: 10px;
}
.front, .back {
    margin: 10px 0;
}
pre, code {
    font-family: 'Courier New', Courier, monospace;
    background-color: #f4f4f4;
    padding: 5px;
    border-radius: 3px;
}
"""

QA_MODEL = genanki.Model(
    QA_MODEL_ID,
    "Anki Generator Q&A",
    fields=[{"name": "Chapter"}, {"name": "Question"}, {"name": "Answer"}],
    templates=[
        {
            "name": "Card 1",
            "qfmt": '<div class="chapter">{{Chapter}}</div>'
            '<div class="front">{{Question}}</div>',
            "afmt": "{{FrontSide}}"
            '<hr id="answer"><div class="back">{{Answer}}</div>',
        }
    ],
    css=COMMON_CSS,
)

CLOZE_MODEL = genanki.Model(
    CLOZE_MODEL_ID,
    "Anki Generator Cloze",
    fields=[{"name": "Text"}, {"name": "Extra"}],
    templates=[
        {
            "name": "Cloze",
            "qfmt": '<div class="front">{{cloze:Text}}</div>',
            "afmt": '<div class="back">{{cloze:Text}}</div>'
            '<div class="extra">{{Extra}}</div>',
        }
    ],
    css=COMMON_CSS,
    model_type=genanki.Model.CLOZE,
)

SCENARIO_MODEL = genanki.Model(
    SCENARIO_MODEL_ID,
    "Anki Generator Scenario",
    fields=[{"name": "Chapter"}, {"name": "Scenario"}, {"name": "Response"}],
    templates=[
        {
            "name": "Card 1",
            "qfmt": '<div class="chapter">{{Chapter}}</div>'
            '<div class="front">{{Scenario}}</div>',
            "afmt": "{{FrontSide}}"
            '<hr id="answer"><div class="back">{{Response}}</div>',
        }
    ],
    css=COMMON_CSS,
)

TRADEOFF_MODEL = genanki.Model(
    TRADEOFF_MODEL_ID,
    "Anki Generator Tradeoff",
    fields=[
        {"name": "Chapter"},
        {"name": "OptionA"},
        {"name": "OptionB"},
        {"name": "Comparison"},
    ],
    templates=[
        {
            "name": "Card 1",
            "qfmt": '<div class="chapter">{{Chapter}}</div>'
            '<div class="front">Compare: {{OptionA}} vs {{OptionB}}</div>',
            "afmt": "{{FrontSide}}"
            '<hr id="answer"><div class="back">{{Comparison}}</div>',
        }
    ],
    css=COMMON_CSS,
)

MODELS = {
    "qa": QA_MODEL,
    "cloze": CLOZE_MODEL,
    "scenario": SCENARIO_MODEL,
    "tradeoff": TRADEOFF_MODEL,
}

TYPE_FIELDS = {
    "qa": ["question", "answer"],
    "cloze": ["text"],
    "scenario": ["scenario", "response"],
    "tradeoff": ["option_a", "option_b", "comparison"],
}


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def build_tags(card: dict) -> list[str]:
    chapter_padded = str(card["chapter_number"]).zfill(2)
    topic_slug = slugify(card.get("topic", "general"))
    return [
        f"chapter::{chapter_padded}::{topic_slug}",
        f"topic::{topic_slug}",
        f"card-type::{card['card_type']}",
    ]


def card_to_note(card: dict) -> genanki.Note:
    card_type = card["card_type"]
    model = MODELS[card_type]
    tags = build_tags(card)

    if card_type == "qa":
        fields = [
            html.escape(card["chapter"]),
            html.escape(card["question"]),
            html.escape(card["answer"]),
        ]
        guid = genanki.guid_for(fields[0], fields[1])
    elif card_type == "cloze":
        fields = [
            html.escape(card["text"]),
            html.escape(card.get("extra", "")),
        ]
        guid = genanki.guid_for(fields[0])
    elif card_type == "scenario":
        fields = [
            html.escape(card["chapter"]),
            html.escape(card["scenario"]),
            html.escape(card["response"]),
        ]
        guid = genanki.guid_for(fields[0], fields[1])
    elif card_type == "tradeoff":
        fields = [
            html.escape(card["chapter"]),
            html.escape(card["option_a"]),
            html.escape(card["option_b"]),
            html.escape(card["comparison"]),
        ]
        guid = genanki.guid_for(fields[0], fields[1], fields[2])
    else:
        raise ValueError(f"Unknown card type: {card_type}")

    return genanki.Note(model=model, fields=fields, tags=tags, guid=guid)


def validate_card(card: dict, file_name: str, index: int) -> list[str]:
    errors = []
    prefix = f"{file_name}[{index}]"

    for field in ("chapter", "chapter_number", "topic", "card_type"):
        if field not in card:
            errors.append(f"{prefix}: missing required field '{field}'")

    card_type = card.get("card_type")
    if card_type not in TYPE_FIELDS:
        errors.append(f"{prefix}: unknown card_type '{card_type}'")
        return errors

    for field in TYPE_FIELDS[card_type]:
        if field not in card:
            errors.append(f"{prefix}: missing field '{field}' for type '{card_type}'")

    if card_type == "cloze" and "text" in card:
        if "{{c1::" not in card["text"]:
            errors.append(f"{prefix}: cloze text missing {{{{c1::}}}} pattern")

    return errors


def build_deck(source_dir: Path, deck_name: str) -> Path:
    cards_dir = source_dir / "cards"
    if not cards_dir.exists():
        print(f"Error: cards directory not found: {cards_dir}", file=sys.stderr)
        sys.exit(1)

    card_files = sorted(cards_dir.glob("*.json"))
    if not card_files:
        print(f"Error: no JSON files found in {cards_dir}", file=sys.stderr)
        sys.exit(1)

    # Deck ID derived from name for stability across rebuilds
    deck_id = int(hashlib.sha256(deck_name.encode()).hexdigest(), 16) % (2**31)
    deck = genanki.Deck(deck_id, deck_name)

    all_errors: list[str] = []
    total_cards = 0

    for card_file in card_files:
        with open(card_file) as f:
            cards = json.load(f)

        for i, card in enumerate(cards):
            errors = validate_card(card, card_file.name, i)
            if errors:
                all_errors.extend(errors)
                continue

            note = card_to_note(card)
            deck.add_note(note)
            total_cards += 1

    if all_errors:
        print(f"Validation errors ({len(all_errors)}):", file=sys.stderr)
        for error in all_errors:
            print(f"  {error}", file=sys.stderr)
        if total_cards == 0:
            sys.exit(1)
        print(f"Continuing with {total_cards} valid cards...", file=sys.stderr)

    slug = source_dir.name
    output_path = source_dir / f"{slug}.apkg"

    package = genanki.Package(deck)
    package.write_to_file(str(output_path))

    print(f"Built deck '{deck_name}' with {total_cards} cards")
    print(f"Output: {output_path}")
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build Anki .apkg from card JSON files"
    )
    parser.add_argument(
        "--source-dir",
        type=Path,
        required=True,
        help="Source directory containing cards/ subdirectory",
    )
    parser.add_argument(
        "--deck-name",
        type=str,
        default=None,
        help="Deck name (defaults to source directory name, title-cased)",
    )
    args = parser.parse_args()

    if not args.source_dir.exists():
        print(
            f"Error: source directory not found: {args.source_dir}", file=sys.stderr
        )
        sys.exit(1)

    deck_name = args.deck_name or args.source_dir.name.replace("-", " ").title()
    build_deck(args.source_dir, deck_name)


if __name__ == "__main__":
    main()
