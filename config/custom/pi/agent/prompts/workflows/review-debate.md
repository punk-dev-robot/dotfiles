WORKFLOW: review-debate (two models discuss a diff, then converge or escalate).

Given a diff/worktree/branch to review:

1. Split a Herdr pane; start a cross-family critic (`piqa`, GPT-5.6-Sol) via `herdr_agent start`. You (or a `pid` pane) act as the defender.
2. Round loop (default 3 rounds, honor N from the user's prompt):
   - Critic reviews the diff: findings by severity, concrete file:line.
   - Defender responds per finding: accept (fix it), rebut (evidence), or defer (name the ceiling).
   - Pass responses back to the critic via `herdr_agent prompt`; a finding is CLOSED when both sides agree.
3. Stop conditions (whichever first): all blocker/major findings closed → apply accepted fixes, summarize; N rounds exhausted with open disagreements → STOP, do not loop further.
4. On stop, notify the user (pi-ask-herdr / Herdr notification) with: closed findings, open disagreements with BOTH positions attributed by model, and your recommendation.
5. Never let the critic grind lower-severity edge cases past the agreed risk threshold.
