---
kind: guard
level: observe
when:
  tools: [bash]
tool: bash
field: command
allow:
  - '^git\b'
  - 'override: #\s*allow:'
deny:
  - '^(grep|rg|cat|head|tail|ls|find|wc|tree)\b'
  - '^sed\s+-n\b'
  - '^(sed\s+-i|perl\s+-p?i)\b'
  - '^(python[0-9.]*|node|perl|ruby)\s+(-c\b|-e\b|-(\s|$))'
  - '^python[0-9.]*\s+\S+\.py\b'
  - '^cd\s+(\$PWD|\$\{PWD\}|\.|<cwd>)(\s|$)'
strikes: 3
---
Bash is for processes. Navigate with `read` (start/end for ranges), `grep`, `find`, `ls`.
Edit with `edit`. Scripts go through `ctx_execute`. Source outside this repo (node_modules,
site-packages, ~/.config) → dispatch `recon`.
