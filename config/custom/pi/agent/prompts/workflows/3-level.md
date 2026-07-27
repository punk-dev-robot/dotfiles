WORKFLOW: 3-level (manager ⇄ principal → specialists). The heavy path.

- BEFORE decomposing: consult the principal on architecture and task/tier allocation — `/advisor` (fable) or discuss with the `pip` pane if the user opened one.
- Decompose per the agreed plan; note which tasks the principal flagged as consequential.
- Delegate: recon (cheap) → specialists in worktrees; consequential tasks get a mid-flight `/advisor` design check before implementation starts.
- Gate before ship: independent reviewer (cross-family `piqa` pane preferred; else `task(agent_type: reviewer)`) with risk threshold + stop condition, then `task_control verify → review → ship`.
- Specialist disagreement → principal adjudicates; still unresolved after 3 exchanges → notify the user with both positions + attribution.
- Report a board update after each phase.
