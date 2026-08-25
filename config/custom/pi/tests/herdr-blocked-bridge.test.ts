import { beforeEach, describe, expect, test } from "bun:test";
import herdrBlockedBridge from "../agent/extensions/herdr-blocked-bridge";

type Handler = (event: unknown) => unknown;

/** Records herdr:blocked emissions and lets tests fire bus + lifecycle events. */
function fakePi() {
	const busHandlers = new Map<string, Handler[]>();
	const lifecycleHandlers = new Map<string, Handler[]>();
	const blocked: Array<{ active: boolean; label?: string }> = [];
	return {
		blocked,
		// biome-ignore lint/suspicious/noExplicitAny: test double
		api: {
			events: {
				on: (name: string, fn: Handler) => {
					busHandlers.set(name, [...(busHandlers.get(name) ?? []), fn]);
				},
				emit: (name: string, payload: unknown) => {
					if (name === "herdr:blocked") {
						blocked.push(payload as { active: boolean; label?: string });
					}
					for (const fn of busHandlers.get(name) ?? []) fn(payload);
				},
			},
			on: (name: string, fn: Handler) => {
				lifecycleHandlers.set(name, [...(lifecycleHandlers.get(name) ?? []), fn]);
			},
		} as any,
		emitBus(name: string, payload: unknown) {
			for (const fn of busHandlers.get(name) ?? []) fn(payload);
		},
		fire(name: string, event: unknown) {
			for (const fn of lifecycleHandlers.get(name) ?? []) fn(event);
		},
	};
}

describe("herdr-blocked-bridge", () => {
	beforeEach(() => {
		process.env.HERDR_ENV = "1";
	});

	test("inert outside herdr", () => {
		delete process.env.HERDR_ENV;
		const pi = fakePi();
		herdrBlockedBridge(pi.api);
		pi.emitBus("rpiv:ask-user:blocked", { active: true });
		expect(pi.blocked).toEqual([]);
	});

	test("maps rpiv ask-user blocked, paired", () => {
		const pi = fakePi();
		herdrBlockedBridge(pi.api);
		pi.emitBus("rpiv:ask-user:blocked", { active: true });
		pi.emitBus("rpiv:ask-user:blocked", { active: false });
		expect(pi.blocked).toEqual([
			{ active: true, label: "question" },
			{ active: false },
		]);
	});

	test("marks plannotator submit_plan blocked for the tool interval", () => {
		const pi = fakePi();
		herdrBlockedBridge(pi.api);
		pi.fire("tool_execution_start", { toolCallId: "t1", toolName: "plannotator_submit_plan" });
		pi.fire("tool_execution_end", { toolCallId: "t1", toolName: "plannotator_submit_plan" });
		expect(pi.blocked).toEqual([
			{ active: true, label: "plan review" },
			{ active: false },
		]);
	});

	test("ignores other tools and unmatched ends", () => {
		const pi = fakePi();
		herdrBlockedBridge(pi.api);
		pi.fire("tool_execution_start", { toolCallId: "t2", toolName: "bash" });
		pi.fire("tool_execution_end", { toolCallId: "t2", toolName: "bash" });
		pi.fire("tool_execution_end", { toolCallId: "never-started", toolName: "plannotator_submit_plan" });
		expect(pi.blocked).toEqual([]);
	});
});
