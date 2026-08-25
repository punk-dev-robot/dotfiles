import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Bridge "waiting for human" signals to herdr's pi integration.
 *
 * Herdr's herdr-agent-state.ts (lifecycle authority for pi panes) only knows
 * blocked via the in-process, ref-counted `herdr:blocked` event
 * ({ active: boolean, label?: string }). Two installed packages block on
 * human input without emitting it, so their panes show "working":
 *
 *  - @juicesharp/rpiv-ask-user-question emits package-owned
 *    `rpiv:ask-user:blocked` ({ active }) — mapping is deliberately left to
 *    consumers (juicesharp/rpiv-mono#128).
 *  - @plannotator/pi-extension blocks inside its `plannotator_submit_plan`
 *    tool call until the browser review decides; no herdr signal at all.
 *
 * Every `active: true` emit is paired with exactly one `active: false`.
 */

/** Tools that spend their whole execution waiting on a human. */
const BLOCKING_TOOLS: Record<string, string> = {
	plannotator_submit_plan: "plan review",
};

export default function herdrBlockedBridge(pi: ExtensionAPI): void {
	if (process.env.HERDR_ENV !== "1") {
		return;
	}

	const emit = (active: boolean, label?: string) => {
		try {
			pi.events.emit("herdr:blocked", active ? { active, label } : { active });
		} catch {
			/* Herdr is optional. */
		}
	};

	// rpiv guarantees paired { active: false } in a finally upstream.
	pi.events.on("rpiv:ask-user:blocked", (data: { active?: boolean }) => {
		emit(!!data?.active, "question");
	});

	// ponytail: marks the whole tool execution blocked, not just the human
	// wait inside it; split when plannotator emits its own herdr signal.
	const activeToolCalls = new Set<string>();
	pi.on("tool_execution_start", (event) => {
		const label = BLOCKING_TOOLS[event.toolName];
		if (!label || activeToolCalls.has(event.toolCallId)) {
			return;
		}
		activeToolCalls.add(event.toolCallId);
		emit(true, label);
	});
	pi.on("tool_execution_end", (event) => {
		if (activeToolCalls.delete(event.toolCallId)) {
			emit(false);
		}
	});
}
