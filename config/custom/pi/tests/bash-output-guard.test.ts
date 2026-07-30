import { describe, expect, test } from "bun:test";
import bashOutputGuard, {
	buildNudge,
	loadIsStructurallyBounded,
} from "../agent/extensions/bash-output-guard";

type Handler = (event: unknown) => unknown;

/** Minimal ExtensionAPI stand-in that just records handlers. */
function fakePi() {
	const handlers = new Map<string, Handler[]>();
	return {
		// biome-ignore lint/suspicious/noExplicitAny: test double
		api: {
			on: (name: string, fn: Handler) => {
				handlers.set(name, [...(handlers.get(name) ?? []), fn]);
			},
		} as any,
		fire(name: string, event: unknown) {
			let last: unknown;
			for (const fn of handlers.get(name) ?? []) last = fn(event);
			return last;
		},
		has: (name: string) => handlers.has(name),
	};
}

const big = (n: number) => [{ type: "text", text: "x".repeat(n) }];

async function guarded() {
	const pi = fakePi();
	await bashOutputGuard(pi.api);
	return pi;
}

describe("reference helper import", () => {
	test("resolves isStructurallyBounded from the installed context-mode package", async () => {
		const fn = await loadIsStructurallyBounded();
		expect(typeof fn).toBe("function");
		expect(fn?.("git status")).toBe(true);
		expect(fn?.("cat huge.log")).toBe(false);
	});

	test("returns undefined when no candidate path exists", async () => {
		expect(
			await loadIsStructurallyBounded(["/nonexistent/routing.mjs"]),
		).toBeUndefined();
	});
});

describe("nudge decision", () => {
	test("unbounded command with large output gets the nudge appended", async () => {
		const pi = await guarded();
		pi.fire("tool_call", {
			toolName: "bash",
			toolCallId: "a",
			input: { command: "cat huge.log" },
		});
		const patch = pi.fire("tool_result", {
			toolCallId: "a",
			content: big(20_000),
		}) as { content: { text: string }[] } | undefined;

		expect(patch?.content).toHaveLength(2);
		expect(patch?.content[1].text).toContain("ctx_execute");
	});

	test("structurally bounded command is never nudged, however large", async () => {
		const pi = await guarded();
		pi.fire("tool_call", {
			toolName: "bash",
			toolCallId: "b",
			input: { command: "git status" },
		});
		expect(
			pi.fire("tool_result", { toolCallId: "b", content: big(500_000) }),
		).toBeUndefined();
	});

	test("small output stays quiet so the warning keeps its meaning", async () => {
		const pi = await guarded();
		pi.fire("tool_call", {
			toolName: "bash",
			toolCallId: "c",
			input: { command: "cat small.txt" },
		});
		expect(
			pi.fire("tool_result", { toolCallId: "c", content: big(200) }),
		).toBeUndefined();
	});

	test("failed commands are not nudged", async () => {
		const pi = await guarded();
		pi.fire("tool_call", {
			toolName: "bash",
			toolCallId: "d",
			input: { command: "cat nope" },
		});
		expect(
			pi.fire("tool_result", {
				toolCallId: "d",
				content: big(20_000),
				isError: true,
			}),
		).toBeUndefined();
	});

	test("non-bash tools are ignored", async () => {
		const pi = await guarded();
		pi.fire("tool_call", {
			toolName: "read",
			toolCallId: "e",
			input: { command: "cat huge.log" },
		});
		expect(
			pi.fire("tool_result", { toolCallId: "e", content: big(20_000) }),
		).toBeUndefined();
	});

	test("each tool call is nudged at most once", async () => {
		const pi = await guarded();
		pi.fire("tool_call", {
			toolName: "bash",
			toolCallId: "f",
			input: { command: "cat huge.log" },
		});
		expect(
			pi.fire("tool_result", { toolCallId: "f", content: big(20_000) }),
		).toBeDefined();
		expect(
			pi.fire("tool_result", { toolCallId: "f", content: big(20_000) }),
		).toBeUndefined();
	});
});

describe("nudge text", () => {
	test("reports size in both chars and tokens", () => {
		const text = buildNudge(37_000);
		expect(text).toContain("37,000");
		expect(text).toContain("10,000");
	});
});
