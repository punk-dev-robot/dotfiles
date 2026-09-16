// Run: node --test config/custom/pi/agent/extensions/punk-steering/test/resolver.test.ts
// External behaviour only: rule files + tool list + level + probe outcomes → actions.
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";
import { mergeRules, parseRules, renderBriefings, resolve, type Rule } from "../resolver.ts";

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
