---
name: block-planning-commits
enabled: true
event: bash
pattern: git\s+(add|commit).*\.planning
action: block
---

**Do not add or commit .planning files.**

The `.planning/` directory is gitignored and managed by GSD workflows internally.
Use `gsd-tools.js commit` for GSD-managed commits that need planning files.
