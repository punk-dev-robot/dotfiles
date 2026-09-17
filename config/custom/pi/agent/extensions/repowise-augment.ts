import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Pi port of the repowise Claude Code hook layer (prototype).
 *
 * All analysis lives in the `repowise-augment` binary (crash-proof, budgeted);
 * this extension is stdin/stdout plumbing speaking the Claude hook envelope
 * (`hook_event_name` / `hookSpecificOutput.additionalContext`), since no
 * `--client pi` contract exists upstream yet.
 *
 *  - tool_result        -> PostToolUse / PostToolUseFailure, append notice to result
 *  - before_agent_start -> SessionStart, standing-decisions block into the system prompt
 *
 * SessionStart: only the standing-decisions half is kept — punk-steering's
 * repowise-index-* rules own freshness and act rather than narrate (KUB-164).
 * Telemetry: every call emits `pi-otel:log` `pi.augment.fired` (hit=false too,
 * so hit rate is computable).
 *
 * Deliberately NOT ported: the PreToolUse rewrite hook (pi-rtk-optimizer owns
 * command rewriting here) and `updatedToolOutput` replacement (additionalContext
 * only — replacement shapes are Claude-typed).
 */

// pi tool name -> Claude tool name the augment handlers dispatch on.
const TOOL_MAP: Record<string, string> = {
	grep: "Grep",
	find: "Glob",
	read: "Read",
	edit: "Edit",
	write: "Write",
	bash: "Bash",
};

// Matches upstream hooks.json timeout: 10. Common PostToolUse path measured ~0.5s;
// the zero-match semantic rescue (embedding lookup) legitimately takes ~10s.
const SEARCH_TIMEOUT_MS = 10_000; // zero-match semantic rescue legitimately ~10s
const FAST_TIMEOUT_MS = 3_000; // staleness / decision notices; common path ~0.5-1.4s
const MAX_OUTPUT_CHARS = 20_000; // cap tool output forwarded to augment

// decision_inject.py:437 header — the separable half of the SessionStart block
const DECISIONS_MARKER = "[repowise] Standing decisions";

type SessionManager = { getSessionId(): string; getSessionFile?(): string | undefined };

/** Same key format as pi-otel: session file basename, falls back to bare id. */
const sessionId = (sm: SessionManager) => {
	const f = sm.getSessionFile?.();
	return f ? basename(f, ".jsonl") : sm.getSessionId();
};

import { appendFileSync } from "node:fs";
const DEBUG_LOG = process.env.REPOWISE_AUGMENT_DEBUG; // path to a log file enables debug
function dbg(msg: string) {
	if (!DEBUG_LOG) return;
	try {
		appendFileSync(DEBUG_LOG, `${new Date().toISOString()} ${msg}\n`);
	} catch {}
}

function repoWithIndex(cwd: string): string | null {
	let dir = cwd;
	for (;;) {
		if (existsSync(join(dir, ".repowise"))) return dir;
		const parent = dirname(dir);
		if (parent === dir) return null;
		dir = parent;
	}
}

/** Claude tool_input shapes use file_path; pi uses path. */
function mapInput(piTool: string, input: Record<string, unknown>): Record<string, unknown> {
	if (piTool === "read" || piTool === "edit" || piTool === "write") {
		return { ...input, file_path: input.path ?? input.file_path };
	}
	return input;
}

function textOf(content: unknown): string {
	if (!Array.isArray(content)) return "";
	return content
		.filter((b): b is { type: string; text: string } => !!b && (b as any).type === "text")
		.map((b) => b.text)
		.join("\n")
		.slice(0, MAX_OUTPUT_CHARS);
}

type AugmentResult = { context: string | null; timedOut: boolean };

/**
 * Claude's PostToolUse tool_response shapes. Read needs the file block
 * (`replacement.py:_as_read_output`, `read_state.py:_read_output_line_count`);
 * every other tool is read through `_extract_output_text`, which takes `output`.
 */
function toolResponse(piTool: string, cwd: string, input: Record<string, unknown>, text: string) {
	if (piTool !== "read") return { output: text };
	const filePath = resolve(cwd, String(input.path ?? input.file_path ?? ""));
	// same count as replacement.py:_as_read_output; describes the forwarded slice,
	// which MAX_OUTPUT_CHARS may have truncated
	const numLines = text ? text.split("\n").length - (text.endsWith("\n") ? 1 : 0) : 0;
	return { type: "text", file: { filePath, content: text, numLines } };
}

/** Run repowise-augment with a JSON payload; return additionalContext or null. Never throws. */
function augment(payload: object, timeoutMs: number): Promise<AugmentResult> {
	return new Promise((done) => {
		let timedOut = false;
		try {
			const child = spawn("repowise-augment", [], { stdio: ["pipe", "pipe", "ignore"] });
			let out = "";
			const timer = setTimeout(() => {
				timedOut = true;
				child.kill("SIGKILL");
			}, timeoutMs);
			child.stdout.on("data", (d) => (out += d));
			child.on("error", () => {
				clearTimeout(timer);
				done({ context: null, timedOut });
			});
			child.on("close", () => {
				clearTimeout(timer);
				try {
					const c = JSON.parse(out)?.hookSpecificOutput?.additionalContext;
					done({ context: typeof c === "string" && c.trim() ? c : null, timedOut });
				} catch {
					done({ context: null, timedOut });
				}
			});
			child.stdin.end(JSON.stringify(payload));
		} catch {
			done({ context: null, timedOut });
		}
	});
}

export default function (pi: ExtensionAPI) {
	/** Call augment, emit telemetry either way, return additionalContext. */
	async function fire(sm: SessionManager, payload: { hook_event_name: string }, tool: string, timeoutMs: number) {
		const t0 = Date.now();
		const { context, timedOut } = await augment(payload, timeoutMs);
		pi.events.emit("pi-otel:log", {
			eventName: "pi.augment.fired",
			severity: "info",
			body: (context ?? "").split("\n")[0]?.slice(0, 80) || payload.hook_event_name,
			attributes: {
				"pi.session.id": sessionId(sm),
				"pi.augment.tool": tool,
				"pi.augment.event": payload.hook_event_name,
				"pi.augment.chars": context?.length ?? 0,
				"pi.augment.ms": Date.now() - t0,
				"pi.augment.hit": Boolean(context),
				...(timedOut ? { "pi.augment.timeout": true } : {}),
			},
		});
		dbg(`augment ${payload.hook_event_name} tool=${tool} ms=${Date.now() - t0} ctx=${context?.slice(0, 60) ?? null}`);
		return context;
	}

	let sessionStarted = "";
	pi.on("before_agent_start", async (event, ctx) => {
		const sid = sessionId(ctx.sessionManager);
		if (sessionStarted === sid) return;
		sessionStarted = sid;
		const root = repoWithIndex(ctx.cwd);
		if (!root) return;
		const context = await fire(
			ctx.sessionManager,
			{ hook_event_name: "SessionStart", source: "startup", cwd: root, session_id: sid },
			"",
			FAST_TIMEOUT_MS,
		);
		// Keep the standing-decisions half only; the freshness line duplicates
		// steering/repowise-index-{absent,stale}.md (session_start.py joins both with \n).
		const at = context?.indexOf(DECISIONS_MARKER) ?? -1;
		if (at < 0) return;
		return {
			systemPrompt: `${event.systemPrompt}\n\n<!-- repowise:session -->\n${context!.slice(at)}`,
		};
	});

	pi.on("tool_result", async (event, ctx) => {
		dbg(`tool_result tool=${event.toolName} cwd=${ctx?.cwd}`);
		const claudeTool = TOOL_MAP[event.toolName];
		if (!claudeTool) return;
		const root = repoWithIndex(ctx.cwd);
		if (!root) return;

		const input = (event.input ?? {}) as Record<string, unknown>;
		const base = {
			tool_name: claudeTool,
			tool_input: mapInput(event.toolName, input),
			cwd: root,
			session_id: sessionId(ctx.sessionManager),
		};
		const payload = event.isError
			? { hook_event_name: "PostToolUseFailure", ...base, error: textOf(event.content), is_interrupt: false }
			: { hook_event_name: "PostToolUse", ...base, tool_response: toolResponse(event.toolName, ctx.cwd, input, textOf(event.content)) };

		const timeoutMs = claudeTool === "Grep" || claudeTool === "Glob" ? SEARCH_TIMEOUT_MS : FAST_TIMEOUT_MS;
		const context = await fire(ctx.sessionManager, payload, event.toolName, timeoutMs);
		if (!context) return;
		return {
			content: [...(event.content ?? []), { type: "text", text: `\n${context}` }],
		};
	});
}
