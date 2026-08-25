// Principal-level PR review: two top models review independently,
// debate to consensus (bounded rounds), neutral arbiter writes the report.
//
// args:
//   pr     — PR number (uses `gh pr diff/view`)  — pass this OR base
//   base   — git base ref (uses `git diff <base>...HEAD`)
//   rounds — max debate rounds after initial review (default 1)
//   repo   — absolute path to the repo checkout (default: cwd)

// args may arrive as a JSON string depending on the caller — normalize
const a = typeof args === "string" ? JSON.parse(args) : (args ?? {});
const pr = a.pr ?? null;
const base = a.base ?? null;
if (!pr && !base) throw new Error("Pass args.pr (PR number) or args.base (git base ref)");
const rounds = a.rounds ?? 1;
const repoNote = a.repo
  ? `The repo is at ${a.repo} — cd there for all git/gh/file commands.`
  : `The repo is checked out at cwd.`;

const target = pr
  ? `PR #${pr}. Get the change set with \`gh pr view ${pr}\` and \`gh pr diff ${pr}\`. ${repoNote} Read surrounding source for context, never judge the diff in isolation.`
  : `the local branch. Get the change set with \`git diff ${base}...HEAD\` (and \`git log ${base}..HEAD --oneline\`). ${repoNote} Read surrounding source for context, never judge the diff in isolation.`;

const criteria = `You are doing a principal-engineer review. Report ONLY high-priority findings:
- correctness bugs, data loss/corruption, broken invariants
- security issues, auth/trust-boundary gaps
- breaking API/contract/schema changes, unsafe migrations
- concurrency/race/idempotency hazards
- significant performance or cost regressions
- architectural violations with system-wide blast radius

Explicitly SKIP: style, naming, nits, minor test gaps, subjective preferences.

For each finding: severity (blocker/major), file:line, what breaks and why it matters,
concrete evidence from the actual code (quote it), and a suggested fix direction.
Verify each claim by reading the relevant source before reporting it.
Output markdown. End with a line: FINDINGS: <n>.`;

const reviewBrief = `Review ${target}\n\n${criteria}`;

// reviewer role = fable-5:high, read-only+cymbal tools; sol overrides model inside the role object
const solRole = { name: "reviewer", model: "openai-codex/gpt-5.6-sol", thinking: "high" };

const initial = await parallel("review", {
  fable: () => agent(reviewBrief, { role: "reviewer", label: "fable-review" }),
  sol: () => agent(reviewBrief, { role: solRole, label: "sol-review" }),
});

let fablePos = initial.fable;
let solPos = initial.sol;

const debateTemplate = `You previously reviewed ${pr ? `PR #${pr}` : `branch diff vs ${base}`} (same repo access as before: ${repoNote}). Another principal reviewer did too.

YOUR PRIOR FINDINGS:
{own}

THE OTHER REVIEWER'S FINDINGS:
{other}

For each of the other reviewer's findings: mark AGREE (with refinement if any) or CONTEST — contesting requires quoting code evidence, not opinion. For each of your own: MAINTAIN or WITHDRAW (say why). You may add a new finding only if it is high-priority and evidenced. Re-read source where the two of you disagree.

Output your full updated position as markdown. End with exactly one line:
CONSENSUS: yes   (if nothing remains contested)
CONSENSUS: no    (if contested items remain)`;

for (let i = 1; i <= rounds; i++) {
  // operation name must be a static string literal (preflight AST check); loop occurrences get their own identity
  const debate = await parallel("debate", {
    fable: () =>
      agent(prompt(debateTemplate, { own: fablePos, other: solPos }), {
        role: "reviewer", label: `fable-debate-${i}`,
      }),
    sol: () =>
      agent(prompt(debateTemplate, { own: solPos, other: fablePos }), {
        role: solRole, label: `sol-debate-${i}`,
      }),
  });
  fablePos = debate.fable;
  solPos = debate.sol;
  const done = /CONSENSUS:\s*yes/i.test(fablePos) && /CONSENSUS:\s*yes/i.test(solPos);
  log(`debate round ${i}/${rounds} done, consensus: ${done}`);
  if (done) break;
}

const reportPath =
  (a.repo ? `${a.repo}/` : "") +
  (pr ? `reviews/PR-${pr}-review.md` : `reviews/branch-review-vs-${String(base).replace(/[^\w.-]/g, "_")}.md`);

const arbiterBrief = prompt(
  `You are the neutral arbiter of a two-reviewer principal-level review of ${pr ? `PR #${pr}` : `the branch diff vs ${base}`}. ${repoNote} You may read source and the diff to spot-check.

REVIEWER A (fable) FINAL POSITION:
{fable}

REVIEWER B (sol) FINAL POSITION:
{sol}

Produce the consensus report, severity-ordered, with sections:
1. Agreed findings — deduped, each with file:line, impact, fix direction.
2. Contested findings — both positions in two lines each, plus your ruling with code evidence.
3. Withdrawn/dropped — one line each, why.
4. Verdict — approve / approve-with-fixes / request-changes, one paragraph.

Spot-check any finding whose evidence looks thin before including it as agreed.
Write the full report to {reportPath} (create the directory if needed).
Return a short summary: verdict + top 3 findings + the report path.`,
  { fable: fablePos, sol: solPos, reportPath },
);

return await agent(arbiterBrief, { model: "anthropic/claude-opus-5", thinking: "high", label: "arbiter" });
