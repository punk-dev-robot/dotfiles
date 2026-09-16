// Run: node --test config/custom/pi/agent/extensions/punk-steering/test/resolver.test.ts
// External behaviour only: rule files + tool list + level + probe outcomes → actions.
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";
import { guard, guardAction, mergeRules, normalise, parseRule, parseRules, renderBriefings, resolve, type Rule } from "../resolver.ts";

const FIX = join(import.meta.dirname, "fixtures");
const load = (dir: "global" | "project") =>
	parseRules(readdirSync(join(FIX, dir)).sort().map((f) => ({ name: f.replace(/\.md$/, ""), text: readFileSync(join(FIX, dir, f), "utf8"), source: dir })));

const g = load("global");
const p = load("project");
const rules: Rule[] = mergeRules(g.rules, p.rules);
const names = (xs: { name: string }[]) => xs.map((x) => x.name).sort();

test("malformed rules are reported and skipped, good ones still load", () => {
	assert.deepEqual(names(g.errors), ["bad-ask-no-fix", "bad-kind", "bad-probe-list", "bad-reminder"]);
	assert.match(g.errors.find((e) => e.name === "bad-reminder")!.error, /not implemented in v1/);
	assert.match(g.errors.find((e) => e.name === "bad-ask-no-fix")!.error, /requires fix/);
	assert.ok(rules.length >= 9);
});

test("array-valued probe is a rule error, not a mis-parsed scalar", () => {
	assert.match(g.errors.find((e) => e.name === "bad-probe-list")!.error, /probe must be a scalar/);
});

test("project rule wins over global on name collision", () => {
	const r = resolve(rules, [], "advise");
	assert.equal(r.briefings.find((b) => b.name === "shared")!.body, "PROJECT version");
});

test("any-match: glob hits one tool of the family; no match → not applied", () => {
	const hit = resolve(rules, ["read", "repowise_get_answer"], "advise");
	assert.ok(names(hit.briefings).includes("any-match"));
	const miss = resolve(rules, ["read", "bash"], "advise");
	assert.ok(!names(miss.briefings).includes("any-match"));
	assert.equal(miss.report.find((x) => x.name === "any-match")!.applies, false);
});

test("tools_all requires every pattern to match", () => {
	assert.ok(!names(resolve(rules, ["web_search"], "advise").briefings).includes("all-match"));
	assert.ok(names(resolve(rules, ["web_search", "fetch_content"], "advise").briefings).includes("all-match"));
});

test("empty when → always applies; briefing block tags each body with its rule name", () => {
	const r = resolve(rules, [], "advise");
	assert.ok(names(r.briefings).includes("always"));
	const block = renderBriefings(r.briefings);
	assert.match(block, /<!-- steering: always -->\nTool economy/);
});

test("global level: off injects nothing; observe logs would-fire and injects nothing", () => {
	assert.equal(resolve(rules, ["repowise_x"], "off").briefings.length, 0);
	const obs = resolve(rules, ["repowise_x"], "observe");
	assert.equal(obs.briefings.length, 0);
	assert.ok(names(obs.observed).includes("any-match"));
	assert.match(obs.observed.find((o) => o.name === "any-match")!.reason, /repowise_x/);
});

test("per-rule level lowers but never raises the global level", () => {
	const r = resolve(rules, [], "advise");
	assert.ok(!names(r.briefings).includes("capped"));
	assert.ok(names(r.observed).includes("capped"));
	assert.equal(r.report.find((x) => x.name === "capped")!.level, "observe");
	// global off beats rule observe
	assert.equal(resolve(rules, [], "off").observed.length, 0);
});

test("preconditions without probe results are pending (gated by tools), each runs once", () => {
	const r = resolve(rules, ["repowise_x", "linear_a"], "advise");
	assert.deepEqual(names(r.pending), ["pre-ask", "pre-notify", "pre-run"]);
	assert.equal(r.pending.find((x) => x.name === "pre-run")!.timeout, 30);
	assert.equal(r.pending.find((x) => x.name === "pre-ask")!.timeout, 10);
	// pre-notify is gated on repowise_*: absent tools → not pending
	assert.ok(!names(resolve(rules, ["linear_a"], "advise").pending).includes("pre-notify"));
});

test("failed probe → on_fail action with {stdout} substituted; ok probe → nothing", () => {
	const r = resolve(rules, ["repowise_x", "linear_a"], "advise", {
		"pre-notify": { ok: false, stdout: "no .repowise\n" },
		"pre-ask": { ok: false, stdout: "" },
		"pre-run": { ok: true, stdout: "" },
	});
	assert.equal(r.pending.length, 0);
	const byName = Object.fromEntries(r.preconditions.map((x) => [x.name, x]));
	assert.deepEqual(byName["pre-notify"], { name: "pre-notify", action: "notify", message: "index missing: no .repowise", fix: undefined });
	assert.deepEqual(byName["pre-ask"], { name: "pre-ask", action: "ask", message: "init now?", fix: "repowise init" });
	assert.equal(byName["pre-run"], undefined);
});

test("required_tools absence is a probe failure → stop; presence → no action", () => {
	const down = resolve(rules, ["read"], "advise");
	const stop = down.preconditions.find((x) => x.name === "pre-stop")!;
	assert.equal(stop.action, "stop");
	assert.equal(stop.message, "Linear MCP down");
	assert.equal(resolve(rules, ["gateway_linear_get_issue"], "advise").preconditions.find((x) => x.name === "pre-stop"), undefined);
});

test("observe degrades every on_fail to a log entry", () => {
	const r = resolve(rules, ["read"], "observe", { "pre-ask": { ok: false, stdout: "" } });
	assert.equal(r.preconditions.length, 0);
	assert.match(r.observed.find((o) => o.name === "pre-stop")!.reason, /would stop: Linear MCP down/);
	assert.match(r.observed.find((o) => o.name === "pre-ask")!.reason, /would ask/);
});

// ─── guard (v2)

const GUARD_DIR = join(import.meta.dirname, "..", "..", "..", "steering");
const guardRule = (file: string) => parseRule(file.replace(/\.md$/, ""), readFileSync(join(GUARD_DIR, file), "utf8"), "global");
const bash = guardRule("guard-bash.md");
const reader = guardRule("guard-read-outside-repo.md");
const OTHER = "/home/kuba/other"; // table cwd: no rule row cd's here

test("guard rule files parse with the tiny frontmatter parser", () => {
	assert.equal(bash.kind, "guard");
	assert.deepEqual(bash.when.tools, ["bash"]);
	assert.equal(bash.guard!.field, "command");
	assert.equal(bash.guard!.strikes, 3);
	assert.ok(bash.guard!.allow.some((a) => a.startsWith("override:")));
	assert.equal(reader.guard!.tool, "read");
	assert.equal(reader.guard!.field, "path");
	assert.equal(reader.level, "observe");
});

test("fixture table: 50 labelled bash commands", () => {
	const rows = readFileSync(join(FIX, "guard-bash.jsonl"), "utf8").trim().split("\n").map((l) => JSON.parse(l) as { cmd: string; expect: string });
	assert.equal(rows.length, 50);
	for (const row of rows) {
		const want = row.expect.split("#")[0].trim();
		const v = guard(bash, row.cmd, OTHER);
		const got = v.verdict === "violation" ? `violation:${v.match}` : v.verdict;
		assert.equal(got, want, `${row.cmd}\n  got ${got} (segment: ${v.segment})`);
	}
});

test("`cd <cwd> && …` is a violation only when the path is the session cwd", () => {
	const cmd = "cd /home/kuba/dotfiles && git status";
	assert.equal(guard(bash, cmd, OTHER).verdict, "pass");
	const v = guard(bash, cmd, "/home/kuba/dotfiles");
	assert.equal(v.verdict, "violation");
	assert.equal(v.match, "cd /home/kuba/dotfiles");
});

test("read guard fires on installed-package / tmp paths only", () => {
	assert.equal(guard(reader, "/home/kuba/dotfiles/AGENTS.md", OTHER).verdict, "pass");
	assert.equal(guard(reader, "/x/node_modules/foo/index.js", OTHER).verdict, "violation");
	assert.equal(guard(reader, "/tmp/scratch.md", OTHER).verdict, "violation");
});

test("normalise: cd strip, VAR= prefix, function def, $( ), backticks, heredoc", () => {
	const t = (cmd: string, cwd = OTHER) => normalise(cmd, cwd).map((s) => [s.text, s.head, s.isPipeTarget] as const);

	assert.deepEqual(t("cd /x && pnpm test | tail -5"), [["pnpm test", "pnpm", false], ["tail -5", "tail", true]]);
	assert.deepEqual(t("cd $PWD && git status"), [["cd $PWD", "cd", false], ["git status", "git", false]]);
	assert.deepEqual(t("cd /home/kuba/dotfiles && git status", "/home/kuba/dotfiles")[0][0], "cd /home/kuba/dotfiles");
	assert.deepEqual(t("D=/x; sed -n 1,5p $D/f"), [["D=/x", "D=/x", false], ["sed -n 1,5p $D/f", "sed", false]]);
	assert.deepEqual(t("FOO=1 grep x f"), [["grep x f", "grep", false]]);
	assert.deepEqual(t("f() { echo hi; }; f"), [["f() { echo hi", "f()", false], ["}", "}", false], ["f", "f", false]]);
	assert.deepEqual(t("echo $(ls /tmp)"), [["echo", "echo", false], ["ls /tmp", "ls", false]]);
	assert.deepEqual(t("echo `cat f`"), [["echo", "echo", false], ["cat f", "cat", false]]);
	// heredoc body is dropped, the command line before `<<` stays
	assert.deepEqual(t("cat <<'EOF' > f\ngrep this is not shell\nEOF\necho done"), [["cat <<'EOF' > f", "cat", false], ["echo done", "echo", false]]);
	// `||` is not a pipe
	assert.equal(t("pnpm test || head -5 log")[1][2], false);
	// quoted separators do not split
	assert.deepEqual(t("ssh mac 'cd /x; python3 - <<EOF\\nprint(1)\\nEOF' | head -3").length, 2);
});

test("pipe filters pass as pipe targets, violate as first segment; cat/ls/find/sed -n violate anywhere", () => {
	assert.equal(guard(bash, "git log | grep x", OTHER).verdict, "pass");
	assert.equal(guard(bash, "pnpm test | tail -15", OTHER).verdict, "pass");
	assert.equal(guard(bash, "head -20 file.md", OTHER).verdict, "violation");
	assert.equal(guard(bash, "pnpm test | cat", OTHER).match, "cat");
	assert.equal(guard(bash, "git log | sed -n 1,2p", OTHER).match, "sed -n");
});

test("one verdict per call even when several segments violate; override short-circuits", () => {
	const v = guard(bash, "cd $PWD && grep x f", OTHER);
	assert.equal(v.verdict, "violation");
	assert.equal(v.match, "cd $PWD");
	assert.equal(guard(bash, "grep x f  # allow: one-off", OTHER).verdict, "override");
});

test("guard rules are gated by when.tools and surface in resolve().guards", () => {
	const rs = [bash, reader];
	assert.deepEqual(resolve(rs, ["bash"], "advise").guards.map((g) => g.rule.name), ["guard-bash"]);
	assert.deepEqual(resolve(rs, ["bash", "read"], "advise").guards.map((g) => g.level), ["observe", "observe"]);
	assert.equal(resolve(rs, ["bash"], "off").guards.length, 0);
	assert.equal(resolve(rs, ["bash"], "advise").briefings.length, 0);
});

test("strike ladder: reject 1–2, block at 3 (main session); observe never enforces", () => {
	const v = guard(bash, "head -5 f", OTHER);
	const s1 = guardAction(bash, v, 1, "advise", false);
	assert.equal(s1.enforced, true);
	assert.equal(s1.handoff, false);
	assert.match(s1.reason!, /strike 1 of 3; at 3 this session is blocked and must hand off/);
	assert.match(s1.reason!, /Denied: head -5 f\. Bash is for processes/);
	assert.equal(guardAction(bash, v, 2, "advise", false).handoff, false);
	const s3 = guardAction(bash, v, 3, "advise", false);
	assert.equal(s3.handoff, true);
	assert.match(s3.reason!, /strike 3 of 3\. Session blocked\. Invoke the punk-handoff skill now/);
	const obs = guardAction(bash, v, 3, "observe", false);
	assert.deepEqual(obs, { enforced: false, handoff: false });
});

test("subagents: rejected on every violation, never blocked, no handoff text", () => {
	const v = guard(bash, "head -5 f", OTHER);
	for (const n of [1, 3, 7]) {
		const a = guardAction(bash, v, n, "advise", true);
		assert.equal(a.handoff, false, `strike ${n} must not hand off in a subagent`);
		assert.match(a.reason!, new RegExp(`strike ${n}\\. Denied:`));
		assert.doesNotMatch(a.reason!, /punk-handoff|Session blocked/);
	}
	assert.equal(guardAction(bash, v, 5, "observe", true).enforced, false);
});
