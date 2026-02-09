# Card Types

Four card types, each suited to different kinds of knowledge. Use the right type for the content.

## Q&A Cards

Test understanding of concepts, definitions, or principles.

**Fields**: `question`, `answer`

**Example:**
- Q: "What is the primary benefit of using a Content Delivery Network (CDN)?"
- A: "A CDN reduces latency by caching static content at edge locations geographically closer to users. Instead of every request hitting the origin server, content is served from the nearest edge server, cutting round-trip time significantly."

**When to use**: Concepts, definitions, benefits, principles, "what/why/how" knowledge.

## Cloze Deletion Cards

Test recall of key technical terms, values, or relationships.

**Fields**: `text`, `extra` (optional context shown after answer)

**Example:**
- Text: "In consistent hashing, when a server is added or removed, only {{c1::k/n}} keys need to be redistributed, where k is the total number of keys and n is the number of servers."

**Guidance:**
- Blank key technical terms, values, or relationships
- Place the blank near the end of the sentence when possible
- Do NOT blank articles (a, an, the), verbs, or connectors
- Use `{{c1::term}}` syntax — one cloze deletion per card
- Max 2-3 cloze cards per section

## Scenario Cards

Test problem-solving and applied thinking.

**Fields**: `scenario`, `response`

**Example:**
- Scenario: "You need to design a URL shortening service. What are the first things you consider?"
- Response: "Start with requirements: read-heavy (100:1 read/write ratio), short URL uniqueness, custom alias support, analytics. Key components: hash function for URL-to-short mapping, database for persistence, cache layer for hot URLs, load balancer for distributing reads."

**When to use**: Design problems, "what would you do" situations, applied decision-making.

## Tradeoff Cards

Test understanding of choices between alternatives.

**Fields**: `option_a`, `option_b`, `comparison`

**Example:**
- Option A: "SQL database"
- Option B: "NoSQL database"
- Comparison: "SQL provides ACID transactions and complex queries via JOIN — ideal for relational data with strict consistency needs. NoSQL offers horizontal scalability and flexible schemas — better for high-volume, simple key-value or document access patterns. Choose SQL when data relationships matter; choose NoSQL when scale and write throughput dominate."

**When to use**: Comparing technologies, approaches, patterns, or design alternatives.

## Anti-Patterns

- **Multi-concept cards**: Testing two ideas in one card. Split them.
- **Trivial facts**: Page numbers, author names, copyright info.
- **Empty cloze**: Blanking articles or verbs. `The {{c1::CDN}} reduces...` is fine; `{{c1::The}} CDN reduces...` is not.
- **Substance-free cards**: Content like "See chapter X for details" has no learning value.
- **Overly long questions**: If the question is a paragraph, it's testing reading comprehension, not knowledge.
