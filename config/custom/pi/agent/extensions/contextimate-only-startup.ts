/**
 * contextimate-only-startup — header, then the Contextimate panel, nothing between.
 *
 * Contextimate (pine-of-glass) anchors its panel after Pi's loaded-resource listing, so
 * `quietStartup: "header"` leaves it nowhere to attach. Keep `quietStartup: false` and,
 * once Contextimate has found that container, render only its panel from it.
 * Pi creates the container once and refills it, so one patch per process holds.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Container = { children: unknown[]; render: (width: number) => string[] };
const g = globalThis as {
	__piContextimateChat?: Container;
	__piContextimateTui?: { requestRender?: (force?: boolean) => void };
};
const PATCHED = Symbol.for("contextimate-only-startup");

const isPanel = (c: unknown) => (c as { __piContextimateBlock?: boolean })?.__piContextimateBlock === true;

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		let tries = 0;
		const attempt = () => {
			const chat = g.__piContextimateChat;
			if (!chat) {
				if (++tries < 40) setTimeout(attempt, 50);
				return;
			}
			const tagged = chat as Container & { [PATCHED]?: true };
			if (tagged[PATCHED]) return;
			tagged[PATCHED] = true;
			const render = chat.render.bind(chat);
			chat.render = (width) => {
				const all = chat.children;
				chat.children = all.filter(isPanel);
				try {
					return render(width);
				} finally {
					chat.children = all;
				}
			};
			g.__piContextimateTui?.requestRender?.(true);
		};
		setTimeout(attempt, 0);
	});
}
