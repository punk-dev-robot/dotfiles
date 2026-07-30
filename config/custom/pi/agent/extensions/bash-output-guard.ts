import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Ports the context-mode PreToolUse bash nudge that the Pi adapter dropped.
 *
 * The Claude Code adapter (hooks/core/routing.mjs) warns on every bash command
 * whose output is not structurally bounded. The Pi adapter inlined only the two
 * helpers its HTTP-blocking branch needed and never reached the general nudge —
 * its only stated rationale (extension.js:574) covers the 7KB *prompt block*,
 * which is a per-turn context cost, not this hook, which costs nothing until it
 * fires.
 *
 * Two differences from the reference, both deliberate:
 *
 *  - Fires on `tool_result`, not `tool_call`. Pi's tool_call can only block or
 *    allow, and a hard wall on `cat` is unusable. tool_result can append to the
 *    result, so the nudge is advisory and no data is lost.
 *  - Gated on ACTUAL result size, not just the command shape. The reference
 *    notes (#463) that nudging every unbounded command trains the agent to
 *    ignore the warning; requiring both signals keeps it rare and truthful.
 */

// ponytail: bash only — measured 349 bash calls vs 52 read / 4 grep.
const NUDGE_OVER_CHARS = 8_000;

const ROUTING_CANDIDATES = [
	join(
		homedir(),
		".pi/agent/npm/node_modules/context-mode/hooks/core/routing.mjs",
	),
	join(
		homedir(),
		".config/pi/agent/npm/node_modules/context-mode/hooks/core/routing.mjs",
	),
];

type BoundedCheck = (command: string) => boolean;

export async function loadIsStructurallyBounded(
	candidates: string[] = ROUTING_CANDIDATES,
): Promise<BoundedCheck | undefined> {
	for (const path of candidates) {
		if (!existsSync(path)) continue;
		try {
			const mod = await import(pathToFileURL(path).href);
			if (typeof mod.isStructurallyBounded === "function") {
				return mod.isStructurallyBounded as BoundedCheck;
			}
		} catch {
			// Try the next candidate; a missing reference must never break the session.
		}
	}
	return undefined;
}

function textLength(content: unknown): number {
	if (!Array.isArray(content)) return 0;
	let total = 0;
	for (const block of content) {
		const text = (block as { text?: unknown } | null)?.text;
		if (typeof text === "string") total += text.length;
	}
	return total;
}

export function buildNudge(chars: number): string {
	const tokens = Math.round(chars / 3.7);
	return (
		`⚠ ${chars.toLocaleString()} chars (~${tokens.toLocaleString()} tokens) of raw output just entered context, ` +
		`and every later turn re-reads it. If you only needed to derive something from this, ` +
		`re-run it through ctx_execute and print just the answer — the bytes stay in the sandbox. ` +
		`Multiple related commands: ctx_batch_execute. One large file: ctx_execute_file.`
	);
}

export default async function bashOutputGuard(pi: ExtensionAPI): Promise<void> {
	const isStructurallyBounded = await loadIsStructurallyBounded();
	if (!isStructurallyBounded) {
		console.error(
			"bash-output-guard: context-mode hooks/core/routing.mjs not found — bash nudge disabled.",
		);
		return;
	}

	const unbounded = new Set<string>();

	pi.on("session_start", () => {
		unbounded.clear();
	});

	pi.on("tool_call", (event) => {
		if (String(event?.toolName ?? "").toLowerCase() !== "bash") return;
		const command = (event as { input?: { command?: unknown } }).input?.command;
		if (typeof command !== "string" || command.length === 0) return;
		const id = String(event?.toolCallId ?? "");
		if (id && !isStructurallyBounded(command)) unbounded.add(id);
	});

	pi.on("tool_result", (event) => {
		const id = String(event?.toolCallId ?? "");
		if (!id || !unbounded.delete(id)) return;
		if (event?.isError === true) return;

		const chars = textLength(event?.content);
		if (chars < NUDGE_OVER_CHARS) return;

		return {
			content: [
				...(event.content as unknown[]),
				{ type: "text", text: buildNudge(chars) },
			],
		};
	});
}
