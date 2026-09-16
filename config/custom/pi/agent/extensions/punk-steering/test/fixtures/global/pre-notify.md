---
kind: precondition
when:
  tools: [repowise_*]
probe: test -d .repowise
on_fail: notify
message: "index missing: {stdout}"
---
