WORKFLOW: debate (two models discuss a question for N turns, then report to the user).

Given a question/design decision to debate:

1. Split a Herdr pane; start the counterpart agent (cross-family preferred: `piqa` for critique, `pip` for architecture) via `herdr_agent start`.
2. State the question + your opening position. Exchange turns via `herdr_agent prompt` — each turn must engage the other side's strongest point, not restate.
3. Default 4 turns each; honor N from the user's prompt. Track convergence: agreed points, open points.
4. Stop at consensus OR N turns — whichever first. NEVER loop past N.
5. Notify the user (pi-ask-herdr / Herdr notification) with: the question, consensus reached (if any), remaining disagreement with both positions attributed by model, and a recommendation with confidence.
