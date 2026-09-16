/**
 * context-events — emit compaction / observational-memory / handoff lifecycle
 * as OTel log records via pi-otel's `pi-otel:log` channel, so KUB-149-style
 * changes can be scored in Logfire instead of guessed from peak context.
 *
 * Query: records WHERE attributes->>'event.name' LIKE 'pi.context.%'
 * Join key: attributes->>'pi.session.id' (same as chat/execute_tool spans).
 */
import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const OM_TYPES = [
	"om.observations.recorded",
	"om.reflections.recorded",
	"om.observations.dropped",
	"om.folded",
];

const sessionId = (sm: { getSessionId(): string; getSessionFile?(): string | undefined }) => {
	const f = sm.getSessionFile?.();
	return f ? basename(f, ".jsonl") : sm.getSessionId();
};

export default function (pi: ExtensionAPI) {
	let seenOm = 0;

	const log = (
		ctx: { sessionManager: { getSessionId(): string; getSessionFile?(): string | undefined }; getContextUsage(): { tokens: number; contextWindow: number } | undefined; model?: { id?: string } },
		eventName: string,
		body: string,
		attributes: Record<string, string | number | boolean> = {},
	) => {
		const usage = ctx.getContextUsage();
		pi.events.emit("pi-otel:log", {
			eventName,
			severity: "info",
			body,
			attributes: {
				// same key format as pi-otel: session file basename, falls back to bare id
				"pi.session.id": sessionId(ctx.sessionManager),
				"pi.context.tokens": usage?.tokens ?? -1,
				"pi.context.window": usage?.contextWindow ?? -1,
				"gen_ai.request.model": ctx.model?.id ?? "",
				...attributes,
			},
		});
	};

	pi.on("session_start", () => {
		seenOm = 0;
	});

	pi.on("session_compact", (event, ctx) => {
		const e = event.compactionEntry;
		log(ctx, "pi.context.compaction", `compaction (${event.reason})`, {
			"pi.compaction.reason": event.reason,
			"pi.compaction.from_extension": Boolean(event.fromExtension),
			"pi.compaction.will_retry": Boolean(event.willRetry),
			"pi.compaction.tokens_before": e.tokensBefore ?? -1,
			"pi.compaction.summary_chars": e.summary?.length ?? 0,
			"pi.compaction.summary_cost_out_tokens": e.usage?.output ?? -1,
		});
	});

	pi.on("session_compact_failed", (event, ctx) => {
		log(ctx, "pi.context.compaction_failed", event.errorMessage ?? "aborted", {
			"pi.compaction.reason": event.reason,
			"pi.compaction.aborted": Boolean(event.aborted),
		});
	});

	// OM only leaves custom session entries; surface new ones once per turn.
	pi.on("turn_end", (_event, ctx) => {
		const entries = ctx.sessionManager.getEntries();
		const om = entries.filter(
			(e) => e.type === "custom" && OM_TYPES.includes((e as { customType?: string }).customType ?? ""),
		);
		for (const e of om.slice(seenOm)) {
			const d = (e as { data?: Record<string, unknown> }).data ?? {};
			const items = (d.observations ?? d.reflections) as unknown[] | undefined;
			log(ctx, `pi.context.${(e as { customType: string }).customType}`, "observational-memory", {
				"pi.om.items": Array.isArray(items) ? items.length : -1,
			});
		}
		seenOm = om.length;
	});
}
