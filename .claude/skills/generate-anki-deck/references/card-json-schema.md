# Card JSON Schema

Each chapter produces one JSON file: an array of card objects.

## Common Fields (all card types)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `chapter` | string | yes | Chapter label, e.g., "Chapter 3: Design a URL Shortener" |
| `chapter_number` | integer | yes | Chapter number (1-indexed) |
| `topic` | string | yes | Section or topic name within the chapter |
| `card_type` | string | yes | One of: `qa`, `cloze`, `scenario`, `tradeoff` |

## Type-Specific Fields

### `qa`

| Field | Type | Required |
|-------|------|----------|
| `question` | string | yes |
| `answer` | string | yes |

### `cloze`

| Field | Type | Required |
|-------|------|----------|
| `text` | string | yes (must contain `{{c1::...}}`) |
| `extra` | string | no (additional context shown after answer) |

### `scenario`

| Field | Type | Required |
|-------|------|----------|
| `scenario` | string | yes |
| `response` | string | yes |

### `tradeoff`

| Field | Type | Required |
|-------|------|----------|
| `option_a` | string | yes |
| `option_b` | string | yes |
| `comparison` | string | yes |

## Example

See `examples/sample-cards.json` for a working example with all four card types: qa, cloze, scenario, and tradeoff.

## Tags

The build script automatically generates tags from card data:
- `chapter::{NN}::{topic-slug}` — e.g., `chapter::01::load-balancing`
- `topic::{topic-slug}` — e.g., `topic::load-balancing`
- `card-type::{type}` — e.g., `card-type::qa`
