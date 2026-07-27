/**
 * Removes pi's startup [Context]/[Skills]/[Prompts]/[Extensions]/[Themes] listing while
 * keeping `quietStartup: false`.
 *
 * Why not just set quietStartup: true? pi-contextimate anchors its block on those rows
 * (RESOURCE_HEADER_RE) inside loadedResourcesContainer — with quietStartup on there is no
 * anchor and contextimate never installs. So: let pi render the list, let contextimate
 * anchor, then drop the rows.
 *
 * ponytail: reuse contextimate's own `globalThis.__piContextimateChat` rather than walking
 * the TUI tree. A tree walk has to render-probe every component to find the rows, which
 * perturbs pi's layout caches and broke the listing outright. The global is the exact same
 * container, is only set once contextimate installed (which is our precondition anyway),
 * and costs nothing. If pine-of-glass is absent the global stays undefined and this no-ops.
 *
 * Diagnostics ([Skill conflicts], [Prompt conflicts], ...) are deliberately kept.
 */

const RESOURCE_HEADER_RE =
	/^\s*\[(Context|Skills|Prompts|Extensions|Themes)\]/m;
// biome-ignore lint/suspicious/noControlCharactersInRegex: ANSI SGR stripping
const ANSI_RE = /\x1b\[[0-9;]*m/g;

type Renderable = { render?: (width: number) => string[]; children?: unknown };

const plain = (c: Renderable, width: number): string => {
	try {
		return (c.render?.(width) ?? []).join("\n").replace(ANSI_RE, "");
	} catch {
		return "";
	}
};

const isContextimateBlock = (c: unknown): boolean =>
	!!c &&
	typeof c === "object" &&
	(c as { __piContextimateBlock?: boolean }).__piContextimateBlock === true;

/** A startup resource section: a leaf component whose render carries a [Section] header. */
export const isResourceRow = (c: unknown): boolean => {
	const r = c as Renderable;
	if (!r || typeof r.render !== "function" || Array.isArray(r.children))
		return false;
	if (isContextimateBlock(r)) return false;
	return RESOURCE_HEADER_RE.test(plain(r, 200));
};

const isBlank = (c: unknown): boolean =>
	plain(c as Renderable, 80).trim().length === 0;

/** Drop every resource row plus the Spacer pi appends after each one. */
export function prune(children: unknown[]): unknown[] {
	const out: unknown[] = [];
	for (let i = 0; i < children.length; i++) {
		if (!isResourceRow(children[i])) {
			out.push(children[i]);
			continue;
		}
		if (i + 1 < children.length && isBlank(children[i + 1])) i++;
	}
	return out;
}

export default function (pi: {
	on: (e: string, h: (event: unknown, ctx: any) => unknown) => void;
}) {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		// ponytail: only re-probe when the child count moved. isResourceRow render-probes
		// each child, and doing that every frame forever is what broke the first attempt.
		// pi only touches this container by re-running showLoadedResources(), which always
		// changes the count, so a length watch is a sufficient and much cheaper trigger.
		let lastLen = -1;
		let anchored = false;

		ctx.ui.setWidget("__prune_resource_list", () => ({
			render: () => {
				// Set by pi-contextimate's installContextBlock: the container holding the
				// resource rows. Undefined until it has anchored — pruning before that
				// would remove the anchor and contextimate would never appear.
				const container = (globalThis as any).__piContextimateChat as
					| { children: unknown[] }
					| undefined;
				const kids = container?.children;
				if (!Array.isArray(kids) || kids.length === lastLen)
					return [] as string[];
				lastLen = kids.length;
				if (kids.some(isContextimateBlock) && kids.some(isResourceRow)) {
					container!.children = prune(kids);
					lastLen = container!.children.length;
					anchored = true;
				}
				return [] as string[];
			},
			invalidate: () => {},
		}));

		// Fail loudly instead of silently leaving the full listing on screen: this breaks
		// whenever contextimate can't anchor (pine-of-glass gone, or cc-header's /hrl
		// flipping rsl back to true, which re-forces quietStartup).
		// ponytail: 10s, not 5 — contextimate retries its install every 50ms and a heavy
		// cwd anchors after 5s, which fired this warning while pruning still succeeded.
		setTimeout(() => {
			if (!anchored) {
				ctx.ui.notify(
					"prune-resource-list: contextimate never anchored; check quietStartup is false and pine-of-glass is loaded",
					"warn",
				);
			}
		}, 10000).unref?.();
	});
}

// ponytail: self-check — `node --experimental-strip-types prune-resource-list.ts`
if (process.argv[1]?.endsWith("prune-resource-list.ts")) {
	const eq = (actual: unknown, expected: unknown, msg: string) => {
		if (actual !== expected)
			throw new Error(
				`${msg}: got ${String(actual)}, want ${String(expected)}`,
			);
	};
	const row = (t: string) => ({ render: () => [t] });
	const spacer = { render: () => [""] };
	const block = {
		__piContextimateBlock: true,
		render: () => ["[Contextimate] summary"],
	};
	const chat = row("chat");

	eq(
		isResourceRow(row("\x1b[1m[Skills]\x1b[0m\n  a, b")),
		true,
		"ansi-wrapped header",
	);
	eq(
		isResourceRow(row("[Skill conflicts]\n  dupe")),
		false,
		"diagnostics kept",
	);
	eq(isResourceRow(block), false, "block must never look like an anchor");
	eq(
		isResourceRow({ children: [], render: () => ["[Skills]"] }),
		false,
		"containers skipped",
	);

	const kept = prune([
		row("[Context]"),
		spacer,
		row("[Skills]"),
		spacer,
		block,
		chat,
	]);
	eq(kept.length, 2, "all sections + their spacers dropped");
	eq(kept[0], block, "contextimate block survives");
	eq(kept[1], chat, "chat rows survive");

	eq(
		prune([row("[Themes]"), block]).length,
		1,
		"section with no trailing spacer",
	);
	eq(prune([block, chat]).length, 2, "idempotent once pruned");
	console.log("ok");
}
