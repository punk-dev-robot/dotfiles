---
name: codebase-memory
description: Use codebase-memory-mcp through Pi's mcp gateway for repository indexing, architecture discovery, symbol search, call tracing, source snippets, change detection, and graph queries. Use before grep/find/read/ls when exploring source code.
---

# Codebase Memory

Use Pi's generic `mcp` tool. CBM remains proxy-only to avoid loading fourteen schemas into every prompt.

## Start of code work

1. List CBM projects with `codebase_memory_mcp_list_projects`.
2. Check the current repository with `codebase_memory_mcp_index_status`.
3. If absent, call `codebase_memory_mcp_index_repository` with the repository path.
4. If indexed, call `codebase_memory_mcp_detect_changes` when freshness matters.

Discover or inspect a schema before guessing arguments:

```text
mcp({ server: "codebase-memory-mcp" })
mcp({ describe: "codebase_memory_mcp_search_graph" })
```

## Discovery order

1. `codebase_memory_mcp_search_graph` — functions, classes, routes, and variables.
2. `codebase_memory_mcp_trace_path` — callers, callees, data flow, or cross-service paths.
3. `codebase_memory_mcp_get_code_snippet` — exact source for a qualified symbol.
4. `codebase_memory_mcp_query_graph` — complex Cypher queries.
5. `codebase_memory_mcp_get_architecture` — high-level project structure.
6. `codebase_memory_mcp_search_code` — graph-augmented text search.

Example call shape:

```text
mcp({
  tool: "codebase_memory_mcp_search_graph",
  args: { name_pattern: ".*OrderHandler.*" }
})
```

Use Pi's lowercase `grep`, `find`, `read`, and `ls` for configuration, documentation, literal text, a known file needed before editing, or fallback when the graph is insufficient. Always read a file before editing it.

A repository can disable Pi's one-time discovery gate with `.pi/.no-cbm-enforce`. Claude-specific opt-out markers do not affect Pi.
