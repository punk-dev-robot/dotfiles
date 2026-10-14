// Principal-level PR review: two top models review independently,
// debate to consensus (bounded rounds), neutral arbiter writes the report.
//
// args:
//   pr     — PR number (uses `gh pr diff/view`)  — pass this OR base
//   base   — git base ref (uses `git diff <base>...HEAD`)
//   rounds — max debate rounds after initial review (default 1)
//   repo   — absolute path to the repo checkout (default: cwd)
//   sota   — true: fable vs astra; default: opus vs sol. Arbiter is fable in both.

// args may arrive as a JSON string depending on the caller — normalize
const a = typeof args === "string" ? JSON.parse(args) : (args ?? {});
const pr = a.pr ?? null;
const base = a.base ?? null;
if (!pr && !base) throw new Error("Pass args.pr (PR number) or args.base (git base ref)");
const rounds = a.rounds ?? 1;
// reviewer pair by tier; models pinned explicitly so role resolution can't swap them
const [A, B] = a.sota
  ? [{ name: "fable", model: "sota" }, { name: "astra", model: "sota-openai" }]
  : [{ name: "opus", model: "strong" }, { name: "sol", model: "review-openai" }];
const revA = { role: "reviewer", model: A.model };
const revB = { role: "reviewer", model: B.model };
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


const initial = await parallel("review", {
  a: () => agent(reviewBrief, { ...revA, label: `${A.name}-review` }),
  b: () => agent(reviewBrief, { ...revB, label: `${B.name}-review` }),
});

let posA = initial.a;
let posB = initial.b;

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
    a: () =>
      agent(prompt(debateTemplate, { own: posA, other: posB }), {
        ...revA, label: `${A.name}-debate-${i}`,
      }),
    b: () =>
      agent(prompt(debateTemplate, { own: posB, other: posA }), {
        ...revB, label: `${B.name}-debate-${i}`,
      }),
  });
  posA = debate.a;
  posB = debate.b;
  const done = /CONSENSUS:\s*yes/i.test(posA) && /CONSENSUS:\s*yes/i.test(posB);
  log(`debate round ${i}/${rounds} done, consensus: ${done}`);
  if (done) break;
}

const tag = `${A.name}-vs-${B.name}`;
const reportPath =
  (a.repo ? `${a.repo}/` : "") +
  (pr ? `reviews/PR-${pr}-review-${tag}.md` : `reviews/branch-review-vs-${String(base).replace(/[^\w.-]/g, "_")}-${tag}.md`);

const arbiterBrief = prompt(
  `You are the neutral arbiter of a two-reviewer principal-level review of ${pr ? `PR #${pr}` : `the branch diff vs ${base}`}. ${repoNote} You may read source and the diff to spot-check.

REVIEWER A (${A.name}) FINAL POSITION:
{posA}

REVIEWER B (${B.name}) FINAL POSITION:
{posB}

Produce the consensus report, severity-ordered, with sections:
1. Agreed findings — deduped, each with file:line, impact, fix direction.
2. Contested findings — both positions in two lines each, plus your ruling with code evidence.
3. Withdrawn/dropped — one line each, why.
4. Verdict — approve / approve-with-fixes / request-changes, one paragraph.

Spot-check any finding whose evidence looks thin before including it as agreed.
Write the full report to {reportPath} (create the directory if needed).
Return a short summary: verdict + top 3 findings + the report path.`,
  { posA, posB, reportPath },
);

return await agent(arbiterBrief, { model: "sota", label: "fable-arbiter" });
