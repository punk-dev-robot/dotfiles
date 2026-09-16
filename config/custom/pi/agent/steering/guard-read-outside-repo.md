---
kind: guard
level: observe
when:
  tools: [read]
tool: read
field: path
deny:
  - '(node_modules|site-packages|\.local/share|/tmp)/'
strikes: 3
---
Installed-package / other-repo source goes to `recon`.
