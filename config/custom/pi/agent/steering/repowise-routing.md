---
kind: briefing
when:
  tools: ["repowise_*"]
---
## Codebase intelligence routing (repowise)

Repos with `.repowise/`, or a workspace root with `.repowise-workspace.yaml` (there pass
`repo="<alias>"` or `repo="all"`; workspace-only tools like blast radius appear too).
Repowise FIRST for concept/history/risk questions; `grep`/`find` are the unindexed fallback
(stale index, outside workspace, un-indexed repo); `bash` is for processes, not navigation.

- Concept/docs question ("how does X work", "where is Y flow") → `repowise_search_codebase`, `repowise_get_answer`.
- File/symbol triage (usage, fix history, layer) → `repowise_get_context` (takes `targets` array).
- Full symbol source → `repowise_get_symbol` (`symbol_id` = `path::Name`).
- Change rationale / git archaeology → `repowise_get_why`; touch risk → `repowise_get_risk`.
- Line-level references stay local: `cymbal_impact` (transitive callers), `cymbal_changed`
  (diff → affected symbols, pre-PR); exact text/regex → `grep`.
- NOT for exact text or line-level refs. Index auto-syncs via post-commit hook.
