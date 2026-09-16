/**
 * punk-steering resolver — pure. No pi imports.
 * (rules, selectedTools, globalLevel, probeResults?) → actions. Spec: specs/punk-steering-v1.md (KUB-164).
 */

export const LEVELS = ["off", "observe", "advise", "rewrite"] as const;
export type Level = (typeof LEVELS)[number];
export type Kind = "briefing" | "precondition" | "reminder";
export type OnFail = "notify" | "ask" | "run" | "stop";

export interface Rule {
	name: string;
	kind: Kind;
	level?: Level;
	when: { tools: string[]; tools_all: boolean };
	body: string;
	// precondition
	required_tools: string[];
	probe?: string;
	on_fail: OnFail;
	fix?: string;
	message?: string;
	timeout: number; // seconds
	source: "global" | "project";
}

export interface ProbeResult {
	ok: boolean;
	stdout: string;
}

export interface Resolution {
	briefings: { name: string; body: string }[];
	/** gated preconditions whose probe result is not yet known */
	pending: { name: string; probe: string; timeout: number }[];
	/** failed preconditions → what to do */
	preconditions: { name: string; action: OnFail; message: string; fix?: string }[];
	observed: { name: string; reason: string }[];
	/** every loaded rule with its gate verdict (for /steering) */
	report: { name: string; kind: Kind; level: Level; matched: string[]; applies: boolean; source: string }[];
	errors: { name: string; error: string }[];
}

// ─── frontmatter (tiny, dep-free: scalars, inline [a, b] lists, "- item" lists, one nested map)

type Fm = Record<string, unknown>;

function scalar(raw: string): unknown {
	const s = raw.trim();
	if (s === "") return "";
	if (s === "true") return true;
	if (s === "false") return false;
	if (/^-?\d+(\.\d+)?$/.test(s)) return Number(s);
	if (s.startsWith("[") && s.endsWith("]")) {
		const inner = s.slice(1, -1).trim();
		return inner === "" ? [] : inner.split(",").map((x) => unquote(x.trim()));
	}
	return unquote(s);
}

function unquote(s: string): string {
	return (s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'")) ? s.slice(1, -1) : s;
}

export function parseFrontmatter(text: string): { fm: Fm; body: string } {
	if (!text.startsWith("---")) return { fm: {}, body: text };
	const end = text.indexOf("\n---", 3);
	if (end < 0) throw new Error("unterminated frontmatter");
	const lines = text.slice(3, end).split("\n");
	const body = text.slice(end + 4).replace(/^\r?\n/, "");
	const fm: Fm = {};
	let key: string | null = null; // current top-level key awaiting nested/list content
	let sub: string | null = null; // current nested key awaiting list items
	for (const line of lines) {
		if (!line.trim() || line.trim().startsWith("#")) continue;
		const indented = /^\s/.test(line);
		if (!indented) {
			const m = /^([\w-]+):\s*(.*)$/.exec(line);
			if (!m) throw new Error(`bad line: ${line}`);
			key = m[1];
			sub = null;
			fm[key] = m[2] === "" ? undefined : scalar(m[2]);
			continue;
		}
		if (!key) throw new Error(`indented line without key: ${line}`);
		const t = line.trim();
		if (t.startsWith("- ")) {
			const container = sub ? (fm[key] as Fm) : fm;
			const k = sub ?? key;
			if (container[k] === undefined) container[k] = [];
			if (!Array.isArray(container[k])) throw new Error(`list item under non-list ${k}`);
			(container[k] as unknown[]).push(scalar(t.slice(2)));
			continue;
		}
		const m = /^([\w-]+):\s*(.*)$/.exec(t);
		if (!m) throw new Error(`bad nested line: ${line}`);
		if (fm[key] === undefined) fm[key] = {};
		if (typeof fm[key] !== "object" || Array.isArray(fm[key])) throw new Error(`nested key under non-map ${key}`);
		sub = m[1];
		(fm[key] as Fm)[sub] = m[2] === "" ? undefined : scalar(m[2]);
	}
	return { fm, body };
}

// ─── rule parsing

/** shell commands / messages stay text even when YAML would read them as bool/number (`probe: false`) */
function str(v: unknown, field: string): string | undefined {
	if (v === undefined) return undefined;
	if (Array.isArray(v)) throw new Error(`${field} must be a scalar, not a list`);
	return String(v);
}

function strList(v: unknown, field: string): string[] {
	if (v === undefined) return [];
	if (typeof v === "string") return [v];
	if (Array.isArray(v) && v.every((x) => typeof x === "string")) return v as string[];
	throw new Error(`${field} must be a string or list of strings`);
}

export function parseRule(name: string, text: string, source: Rule["source"] = "global"): Rule {
	const { fm, body } = parseFrontmatter(text);
	const kind = fm.kind as Kind;
	if (!["briefing", "precondition", "reminder"].includes(kind)) throw new Error(`kind must be briefing|precondition|reminder, got ${String(fm.kind)}`);
	if (kind === "reminder") throw new Error("kind: reminder not implemented in v1");
	if (fm.level !== undefined && !LEVELS.includes(fm.level as Level)) throw new Error(`level must be one of ${LEVELS.join("|")}`);
	const when = (fm.when ?? {}) as Fm;
	const on_fail = (fm.on_fail ?? "notify") as OnFail;
	if (kind === "precondition") {
		if (!["notify", "ask", "run", "stop"].includes(on_fail)) throw new Error(`on_fail must be notify|ask|run|stop`);
		if ((on_fail === "ask" || on_fail === "run") && fm.fix === undefined) throw new Error(`on_fail: ${on_fail} requires fix`);
		if (fm.probe === undefined && fm.required_tools === undefined) throw new Error("precondition needs probe or required_tools");
	}
	return {
		name,
		kind,
		level: fm.level as Level | undefined,
		when: { tools: strList(when.tools, "when.tools"), tools_all: when.tools_all === true },
		body: body.trim(),
		required_tools: strList(fm.required_tools, "required_tools"),
		probe: str(fm.probe, "probe"),
		on_fail,
		fix: str(fm.fix, "fix"),
		message: str(fm.message, "message"),
		timeout: typeof fm.timeout === "number" ? fm.timeout : 10,
		source,
	};
}

/** Parse many files; malformed ones become errors, not aborts. */
export function parseRules(files: { name: string; text: string; source: Rule["source"] }[]): { rules: Rule[]; errors: Resolution["errors"] } {
	const rules: Rule[] = [];
	const errors: Resolution["errors"] = [];
	for (const f of files) {
		try {
			rules.push(parseRule(f.name, f.text, f.source));
		} catch (e) {
			errors.push({ name: f.name, error: (e as Error).message });
		}
	}
	return { rules, errors };
}

/** Project wins on name collision. */
export function mergeRules(global: Rule[], project: Rule[]): Rule[] {
	const byName = new Map(global.map((r) => [r.name, r]));
	for (const r of project) byName.set(r.name, r);
	return [...byName.values()];
}

// ─── gating

export function globToRegExp(glob: string): RegExp {
	const re = glob.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".");
	return new RegExp(`^${re}$`);
}

export function matchTools(patterns: string[], tools: string[]): string[] {
	const out = new Set<string>();
	for (const p of patterns) {
		const re = globToRegExp(p);
		for (const t of tools) if (re.test(t)) out.add(t);
	}
	return [...out];
}

function gate(rule: Rule, tools: string[]): { applies: boolean; matched: string[] } {
	const { tools: patterns, tools_all } = rule.when;
	if (patterns.length === 0) return { applies: true, matched: [] };
	const matched = matchTools(patterns, tools);
	const applies = tools_all ? patterns.every((p) => matchTools([p], tools).length > 0) : matched.length > 0;
	return { applies, matched };
}

export function effectiveLevel(rule: Rule, global: Level): Level {
	if (!rule.level) return global;
	return LEVELS.indexOf(rule.level) < LEVELS.indexOf(global) ? rule.level : global;
}

// ─── resolve

export function resolve(rules: Rule[], selectedTools: string[], globalLevel: Level, probeResults: Record<string, ProbeResult> = {}): Resolution {
	const res: Resolution = { briefings: [], pending: [], preconditions: [], observed: [], report: [], errors: [] };
	for (const rule of rules) {
		const { applies, matched } = gate(rule, selectedTools);
		const level = effectiveLevel(rule, globalLevel);
		res.report.push({ name: rule.name, kind: rule.kind, level, matched, applies, source: rule.source });
		if (!applies || level === "off") continue;

		if (rule.kind === "briefing") {
			if (level === "observe") res.observed.push({ name: rule.name, reason: `briefing would fire (tools: ${matched.join(", ") || "always"})` });
			else res.briefings.push({ name: rule.name, body: rule.body });
			continue;
		}

		// precondition
		const missing = rule.required_tools.filter((p) => matchTools([p], selectedTools).length === 0);
		let result: ProbeResult | undefined = probeResults[rule.name];
		if (missing.length > 0) result = { ok: false, stdout: `missing tools: ${missing.join(", ")}` };
		if (!result) {
			if (rule.probe) res.pending.push({ name: rule.name, probe: rule.probe, timeout: rule.timeout });
			continue;
		}
		if (result.ok) continue;
		const message = (rule.message ?? `${rule.name}: precondition failed {stdout}`).replace("{stdout}", result.stdout.trim());
		if (level === "observe") res.observed.push({ name: rule.name, reason: `would ${rule.on_fail}: ${message}` });
		else res.preconditions.push({ name: rule.name, action: rule.on_fail, message, fix: rule.fix });
	}
	return res;
}

/** System-prompt block for applicable briefings; empty string when none. */
export function renderBriefings(briefings: Resolution["briefings"]): string {
	return briefings.map((b) => `<!-- steering: ${b.name} -->\n${b.body}`).join("\n\n");
}
