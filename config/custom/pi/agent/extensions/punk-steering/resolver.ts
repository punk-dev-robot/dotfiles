/**
 * punk-steering resolver — pure. No pi imports.
 * (rules, selectedTools, globalLevel, probeResults?) → actions. Spec: specs/punk-steering-v1.md (KUB-164).
 */

export const LEVELS = ["off", "observe", "advise", "rewrite"] as const;
export type Level = (typeof LEVELS)[number];
export type Kind = "briefing" | "precondition" | "reminder" | "guard";
export type OnFail = "notify" | "ask" | "run" | "stop";

/** kind: guard — tool_call inspector (specs/punk-steering-v2.md). Patterns stay strings; `<cwd>` is substituted at match time. */
export interface GuardSpec {
	tool: string;
	field: string;
	/** an entry prefixed `override:` passes *and* is logged as an override instead of a silent pass */
	allow: string[];
	deny: string[];
	strikes: number;
}

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
	guard?: GuardSpec;
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
	/** active guard rules with their effective level (adapter runs them on tool_call) */
	guards: { rule: Rule; level: Level }[];
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
	if (!["briefing", "precondition", "reminder", "guard"].includes(kind)) throw new Error(`kind must be briefing|precondition|reminder|guard, got ${String(fm.kind)}`);
	if (kind === "reminder") throw new Error("kind: reminder not implemented in v1");
	if (fm.level !== undefined && !LEVELS.includes(fm.level as Level)) throw new Error(`level must be one of ${LEVELS.join("|")}`);
	const when = (fm.when ?? {}) as Fm;
	const on_fail = (fm.on_fail ?? "notify") as OnFail;
	if (kind === "precondition") {
		if (!["notify", "ask", "run", "stop"].includes(on_fail)) throw new Error(`on_fail must be notify|ask|run|stop`);
		if ((on_fail === "ask" || on_fail === "run") && fm.fix === undefined) throw new Error(`on_fail: ${on_fail} requires fix`);
		if (fm.probe === undefined && fm.required_tools === undefined) throw new Error("precondition needs probe or required_tools");
	}
	let guard: GuardSpec | undefined;
	if (kind === "guard") {
		const tool = str(fm.tool, "tool") ?? "bash";
		const deny = strList(fm.deny, "deny");
		if (deny.length === 0) throw new Error("guard needs at least one deny pattern");
		guard = {
			tool,
			field: str(fm.field, "field") ?? (tool === "read" ? "path" : "command"),
			allow: strList(fm.allow, "allow"),
			deny,
			strikes: typeof fm.strikes === "number" ? fm.strikes : 3,
		};
		for (const p of [...guard.allow, ...guard.deny]) compile(p, ""); // fail the rule, not the tool call, on a bad regex
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
		guard,
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
	const res: Resolution = { briefings: [], pending: [], preconditions: [], observed: [], guards: [], report: [], errors: [] };
	for (const rule of rules) {
		const { applies, matched } = gate(rule, selectedTools);
		const level = effectiveLevel(rule, globalLevel);
		res.report.push({ name: rule.name, kind: rule.kind, level, matched, applies, source: rule.source });
		if (!applies || level === "off") continue;

		if (rule.kind === "guard") {
			res.guards.push({ rule, level }); // observe included: the adapter counts and logs, enforces only at advise+
			continue;
		}

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

// ─── guard: normalise + verdict (specs/punk-steering-v2.md)

export interface Segment {
	text: string;
	head: string;
	/** segment is the target of a `|` (not `||`) — pipe filters trim process output, which is sanctioned bash */
	isPipeTarget: boolean;
}

export interface Verdict {
	verdict: "pass" | "override" | "violation";
	segment?: string;
	pattern?: string;
	/** the text the deny pattern matched (`sed -n`, `python3 -c`) — what the reason line names */
	match?: string;
	head?: string;
}

/** trimming process output is what bash is for; the same heads as a *first* segment read files and are denied */
const PIPE_FILTERS = new Set(["grep", "rg", "head", "tail", "wc", "sort", "uniq", "cut", "jq", "awk"]);
const SELF_CD = new Set(["$PWD", "${PWD}", ".", "./"]);
const ENV_PREFIX = /^(?:[A-Za-z_]\w*=(?:"[^"]*"|'[^']*'|\S*)\s+)+(?=\S)/;

const escapeRe = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/** `<cwd>` → the session cwd, regex-escaped; unmatchable when no cwd is known. */
function compile(pattern: string, cwd: string): RegExp {
	return new RegExp(pattern.replace(/<cwd>/g, cwd ? escapeRe(cwd) : "(?!)"));
}

const unq = (s: string) => ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'")) ? s.slice(1, -1) : s);

/** Split on `|`/`||`/`;`/`&&`/newline outside quotes; `$( )` and backtick bodies become their own segments; heredoc bodies are dropped. */
function split(src: string): { text: string; pipe: boolean }[] {
	const out: { text: string; pipe: boolean }[] = [];
	const nested: string[] = [];
	let buf = "";
	let pipe = false;
	let heredoc: string | null = null;
	const push = (nextPipe: boolean) => {
		const t = buf.trim();
		if (t) out.push({ text: t, pipe });
		buf = "";
		pipe = nextPipe;
	};
	for (let i = 0; i < src.length; i++) {
		const c = src[i];
		if (c === "\\" && i + 1 < src.length) {
			buf += c + src[++i];
			continue;
		}
		if (c === "'" || c === '"') {
			// quoted runs are opaque: a denied head inside quotes is a false positive we accept (spec)
			const j = src.indexOf(c, i + 1);
			const end = j < 0 ? src.length - 1 : j;
			buf += src.slice(i, end + 1);
			i = end;
			continue;
		}
		if (c === "`" || (c === "$" && src[i + 1] === "(")) {
			const open = c === "`" ? 1 : 2;
			let depth = 1;
			let j = i + open;
			for (; j < src.length && depth > 0; j++) {
				if (c === "`") {
					if (src[j] === "`") depth = 0;
				} else if (src[j] === "(") depth++;
				else if (src[j] === ")") depth--;
			}
			nested.push(src.slice(i + open, depth === 0 ? j - 1 : src.length));
			i = j - 1;
			continue;
		}
		if (c === "<" && src[i + 1] === "<") {
			const m = /^<<-?\s*(['"]?)(\w+)\1/.exec(src.slice(i));
			if (m) {
				heredoc = m[2];
				buf += m[0];
				i += m[0].length - 1;
				continue;
			}
		}
		if (c === "\n" && heredoc) {
			// heredoc body is not shell: skip it, the command line before `<<` is the segment
			let j = i + 1;
			while (j < src.length) {
				const eol = src.indexOf("\n", j);
				const line = src.slice(j, eol < 0 ? src.length : eol);
				j = eol < 0 ? src.length : eol + 1;
				if (line.trim() === heredoc) break;
			}
			heredoc = null;
			i = j - 1;
			push(false);
			continue;
		}
		if (c === "|") {
			const or = src[i + 1] === "|";
			if (or) i++;
			push(!or);
			continue;
		}
		if (c === "&" && src[i + 1] === "&") {
			i++;
			push(false);
			continue;
		}
		if (c === ";" || c === "\n") {
			push(false);
			continue;
		}
		buf += c;
	}
	push(false);
	for (const n of nested) out.push(...split(n));
	return out;
}

/** Command text → segments. Strips one leading `cd <path> (&&|;)` unless that cd is itself a denied self-cd. */
export function normalise(cmd: string, cwd = ""): Segment[] {
	let s = cmd.trim();
	const m = /^cd\s+("[^"]*"|'[^']*'|[^\s;&|]+)\s*(&&|;)\s*/.exec(s);
	if (m && !SELF_CD.has(m[1]) && unq(m[1]) !== cwd) s = s.slice(m[0].length);
	return split(s).map(({ text, pipe }) => {
		const t = text.replace(ENV_PREFIX, ""); // `FOO=1 grep x` is a grep
		return { text: t, head: (/^\S+/.exec(t)?.[0] ?? ""), isPipeTarget: pipe };
	});
}

/** allow (override-flagged first) then deny, per segment; first violation wins. */
export function guard(rule: Rule, input: string, cwd = ""): Verdict {
	const g = rule.guard;
	if (!g) return { verdict: "pass" };
	const allow = g.allow.map((p) => {
		const override = p.startsWith("override:");
		const src = override ? p.slice("override:".length).trim() : p;
		return { src, override, re: compile(src, cwd) };
	});
	const deny = g.deny.map((p) => ({ src: p, re: compile(p, cwd) }));
	for (const seg of normalise(input, cwd)) {
		let allowed = false;
		for (const a of allow) {
			if (!a.re.test(seg.text)) continue;
			if (a.override) return { verdict: "override", segment: seg.text, pattern: a.src, head: seg.head };
			allowed = true;
		}
		if (allowed) continue;
		for (const d of deny) {
			const hit = d.re.exec(seg.text);
			if (!hit) continue;
			if (seg.isPipeTarget && PIPE_FILTERS.has(seg.head)) break;
			return { verdict: "violation", segment: seg.text, pattern: d.src, match: hit[0].trim(), head: seg.head };
		}
	}
	return { verdict: "pass" };
}

export interface GuardAction {
	/** level is advise+ : the call is rejected. observe counts and logs only. */
	enforced: boolean;
	/** 3rd strike in a main session: reduce tools to HANDOFF_TOOLS and notify. Never true for subagents. */
	handoff: boolean;
	reason?: string;
}

/**
 * What the adapter does with a violation. Subagents (piewf roles) are rejected on every
 * violation but never blocked — the parent reruns them, a handoff would strand the brief.
 */
export function guardAction(rule: Rule, v: Verdict, strikes: number, level: Level, subagent: boolean): GuardAction {
	const max = rule.guard?.strikes ?? 3;
	const enforced = level === "advise" || level === "rewrite";
	if (v.verdict !== "violation" || !enforced) return { enforced, handoff: false };
	if (!subagent && strikes >= max) {
		return {
			enforced,
			handoff: true,
			reason: `steering/${rule.name} — strike ${max} of ${max}. Session blocked. Invoke the punk-handoff skill now (read ~/.agents/skills/punk-handoff/SKILL.md and follow it; argument: 'blocked by steering/${rule.name} after ${max} violations — continue the task in a fresh session'), then stop.`,
		};
	}
	const budget = subagent ? `strike ${strikes}` : `strike ${strikes} of ${max}; at ${max} this session is blocked and must hand off`;
	return { enforced, handoff: false, reason: `steering/${rule.name} — ${budget}. Denied: ${v.segment}. ${rule.body}` };
}

/** System-prompt block for applicable briefings; empty string when none. */
export function renderBriefings(briefings: Resolution["briefings"]): string {
	return briefings.map((b) => `<!-- steering: ${b.name} -->\n${b.body}`).join("\n\n");
}
