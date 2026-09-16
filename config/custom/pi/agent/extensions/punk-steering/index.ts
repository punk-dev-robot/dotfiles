/**
 * punk-steering — tool-aware steering rules for pi (KUB-164, specs/punk-steering-v1.md).
 *
 * Rules: <agentDir>/steering/*.md (global) + <cwd>/.pi/steering/*.md (project, trusted only).
 * Settings: <agentDir>/punk-steering.json  { "level": "off" | "observe" | "advise" | "rewrite" }  (default advise).
 * Everything decision-shaped lives in resolver.ts; this file is discovery + side effects + /steering.
 */
import { appendFileSync, existsSync, readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { LEVELS, type Level, mergeRules, parseRules, renderBriefings, resolve, type Resolution, type Rule, type ProbeResult } from "./resolver.ts";

const AGENT_DIR = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");

function readDir(dir: string, source: Rule["source"]) {
	if (!existsSync(dir)) return [];
	return readdirSync(dir)
		.filter((f) => f.endsWith(".md"))
		.sort()
		.map((f) => ({ name: basename(f, ".md"), text: readFileSync(join(dir, f), "utf8"), source }));
}

function readLevel(): Level {
	try {
		const lvl = JSON.parse(readFileSync(join(AGENT_DIR, "punk-steering.json"), "utf8")).level;
		if (LEVELS.includes(lvl)) return lvl;
	} catch {}
	return "advise";
}

export default function (pi: ExtensionAPI) {
	let rules: Rule[] = [];
	let loadErrors: Resolution["errors"] = [];
	let level: Level = "advise";
	let probes: Record<string, ProbeResult> = {};
	const timedOut = new Set<string>(); // inconclusive probes: never trigger on_fail
	let last: Resolution | undefined;
	let stopPending = false;

	const load = (cwd: string, trusted: boolean) => {
		level = readLevel();
		const g = parseRules(readDir(join(AGENT_DIR, "steering"), "global"));
		const p = trusted ? parseRules(readDir(join(cwd, ".pi", "steering"), "project")) : { rules: [], errors: [] };
		rules = mergeRules(g.rules, p.rules);
		loadErrors = [...g.errors, ...p.errors];
		probes = {};
		timedOut.clear();
	};

	// `cwd` is not in the documented pi.exec options but is honoured (verified pi 0.85.1: probe `pwd` == ctx.cwd).
	const sh = (cmd: string, cwd: string, timeoutSec: number) => pi.exec("sh", ["-c", cmd], { cwd, timeout: timeoutSec * 1000 } as any);

	pi.on("session_start", (_e, ctx) => {
		if (process.env.PUNK_STEERING_DEBUG) appendFileSync(process.env.PUNK_STEERING_DEBUG, `load agentDir=${AGENT_DIR}\n`);
		load(ctx.cwd, ctx.isProjectTrusted());
		if (loadErrors.length && ctx.hasUI) ctx.ui.notify(`steering: ${loadErrors.length} rule(s) skipped — /steering`, "warning");
	});

	pi.on("before_agent_start", async (event, ctx) => {
		const tools = event.systemPromptOptions?.selectedTools ?? pi.getActiveTools();
		let res = resolve(rules, tools, level, probes);

		// Probe each pending precondition once (across the whole session — `probes` only resets on load).
		const newlyProbed = new Set<string>();
		for (const p of res.pending) {
			const r = await sh(p.probe, ctx.cwd, p.timeout);
			probes[p.name] = { ok: r.code === 0 && !r.killed, stdout: r.killed ? "probe timed out" : r.stdout || r.stderr };
			newlyProbed.add(p.name);
			if (r.killed) timedOut.add(p.name);
		}
		if (newlyProbed.size) res = resolve(rules, tools, level, probes);

		// `stop` holds every turn until fixed, but we only re-notify / re-message the turn it was newly probed.
		const failLines: string[] = [];
		for (const pc of res.preconditions) {
			if (pc.action === "stop" && !timedOut.has(pc.name)) stopPending = true; // ctx.abort() is a no-op before the run exists; agent_start aborts it
			if (!newlyProbed.has(pc.name)) continue;

			if (timedOut.has(pc.name)) {
				if (ctx.hasUI) ctx.ui.notify(`steering/${pc.name}: probe timed out`, "warning");
				failLines.push(`steering/${pc.name}: probe timed out`);
				continue;
			}
			if (pc.action === "stop") {
				if (ctx.hasUI) ctx.ui.notify(`steering/${pc.name}: ${pc.message}`, "error");
				failLines.push(`steering/${pc.name}: ${pc.message}`);
				continue;
			}
			if (pc.action === "run" && pc.fix) {
				const r = await sh(pc.fix, ctx.cwd, 120);
				if (ctx.hasUI) ctx.ui.notify(`steering/${pc.name}: ${pc.message} → fix ${r.code === 0 ? "ok" : `failed (${r.code})`}`, r.code === 0 ? "info" : "warning");
				if (r.code !== 0) failLines.push(`steering/${pc.name}: ${pc.message}`);
				continue;
			}
			if (pc.action === "ask" && pc.fix && ctx.hasUI) {
				if (await ctx.ui.confirm(`steering/${pc.name}`, `${pc.message}\n\nRun: ${pc.fix}`)) {
					const r = await sh(pc.fix, ctx.cwd, 300);
					ctx.ui.notify(`steering/${pc.name}: fix ${r.code === 0 ? "ok" : `failed (${r.code})`}`, r.code === 0 ? "info" : "warning");
					if (r.code !== 0) failLines.push(`steering/${pc.name}: ${pc.message}`);
				} else {
					failLines.push(`steering/${pc.name}: ${pc.message}`);
				}
				continue;
			}
			// notify, or ask with no UI
			if (ctx.hasUI) ctx.ui.notify(`steering/${pc.name}: ${pc.message}`, "warning");
			failLines.push(`steering/${pc.name}: ${pc.message}`);
		}
		last = res;

		const block = renderBriefings(res.briefings);
		if (process.env.PUNK_STEERING_DEBUG) appendFileSync(process.env.PUNK_STEERING_DEBUG, `bas rules=${rules.length} tools=${tools.length} briefings=${res.briefings.map(b=>b.name)} pending=${res.pending.length} pre=${JSON.stringify(res.preconditions)} probes=${JSON.stringify(probes)} block=${block.length}\n`);
		const ret: { systemPrompt?: string; message?: { customType: string; content: string } } = {};
		if (block) ret.systemPrompt = `${event.systemPrompt}\n\n${block}`;
		if (failLines.length) ret.message = { customType: "punk-steering", content: failLines.join("\n") };
		if (ret.systemPrompt || ret.message) return ret;
	});

	pi.on("agent_start", (_e, ctx) => {
		if (!stopPending) return;
		stopPending = false;
		ctx.abort();
	});

	pi.registerCommand("steering", {
		description: "List steering rules, gate result and effective level for this session",
		handler: async (_args, ctx) => {
			const res = last ?? resolve(rules, pi.getActiveTools(), level, probes);
			const lines = [`level: ${level}   rules: ${rules.length}   (${join(AGENT_DIR, "steering")}, .pi/steering)`];
			for (const r of res.report) {
				const probe = probes[r.name];
				const state = r.kind === "precondition" && probe ? (probe.ok ? " probe=ok" : ` probe=FAIL`) : "";
				lines.push(`${r.applies ? "✓" : "·"} ${r.name} [${r.kind}/${r.level}/${r.source}] ${r.matched.length ? r.matched.join(",") : r.applies ? "always" : "no tool match"}${state}`);
			}
			for (const o of res.observed) lines.push(`~ observed ${o.name}: ${o.reason}`);
			for (const e of loadErrors) lines.push(`✗ ${e.name}: ${e.error}`);
			ctx.ui.notify(lines.join("\n"), loadErrors.length ? "warning" : "info");
		},
	});
}
