/**
 * context-nudge — once per session, when context passes 150K tokens,
 * suggest a handoff at the next semantic boundary (KUB-149).
 * OM compaction fires at ~180K source tokens; a /punk-handoff beats a
 * summary when the goal is changing anyway.
 */
import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const THRESHOLD = 150_000;

export default function (pi: ExtensionAPI) {
	let nudged = false;

	pi.on("session_start", () => {
		nudged = false;
	});

	pi.on("turn_end", (_event, ctx) => {
		if (nudged) return;
		const usage = ctx.getContextUsage();
		if (!usage || usage.tokens < THRESHOLD) return;
		nudged = true;
		pi.events.emit("pi-otel:log", {
			eventName: "pi.context.nudge",
			severity: "info",
			body: "handoff nudge",
			attributes: { "pi.session.id": basename(ctx.sessionManager.getSessionFile() ?? ctx.sessionManager.getSessionId(), ".jsonl"), "pi.context.tokens": usage.tokens },
		});
		ctx.ui.notify(
			`Context ${Math.round(usage.tokens / 1000)}K — semantic boundary? /punk-handoff (OM compacts at ~180K)`,
			"warning",
		);
	});
}
