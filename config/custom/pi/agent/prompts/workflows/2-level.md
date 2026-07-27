WORKFLOW: 2-level (manager → specialists). The light path.

- Decompose the epic into tasks; delegate directly via the `task` tool.
- Cheap groundwork first: `task(agent_type: recon)` per unfamiliar area — findings go to a file, never into your context.
- Implementation: `task(agent_type: <specialist>, isolation: worktree)`.
- Gate before ship: `task(agent_type: reviewer)` with an explicit risk threshold + stop condition, then `task_control verify → review → ship`.
- No principal/advisor unless you hit a genuinely consequential design fork — then one `/advisor` call.
- Report progress to the user as a short board update after each phase.
