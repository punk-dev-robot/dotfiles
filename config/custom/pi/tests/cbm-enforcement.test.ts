import { afterEach, describe, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import cbmEnforcement, {
	findGitRoot,
	isCbmProxyCall,
	isDiscoveryCall,
	isSuccessfulCbmResult,
} from "../agent/extensions/cbm-enforcement";

const temporaryDirectories: string[] = [];

afterEach(() => {
	for (const directory of temporaryDirectories.splice(0)) {
		rmSync(directory, { recursive: true, force: true });
	}
});

describe("CBM proxy recognition", () => {
	test("recognizes Pi MCP adapter prefixed tools", () => {
		expect(isCbmProxyCall({
			toolName: "mcp",
			input: { tool: "codebase_memory_mcp_search_graph" },
		})).toBe(true);
	});

	test("recognizes an original CBM tool when the server is explicit", () => {
		expect(isCbmProxyCall({
			toolName: "mcp",
			input: { server: "codebase-memory-mcp", tool: "trace_path" },
		})).toBe(true);
	});

	test("marks only successful CBM results", () => {
		const event = {
			toolName: "mcp",
			input: { tool: "codebase_memory_mcp_get_architecture" },
		};
		expect(isSuccessfulCbmResult(event)).toBe(true);
		expect(isSuccessfulCbmResult({ ...event, isError: true })).toBe(false);
	});
});

describe("Pi-native discovery classification", () => {
	test("gates source discovery tools", () => {
		expect(isDiscoveryCall({ toolName: "grep", input: { pattern: "Handler", path: "src" } })).toBe(true);
		expect(isDiscoveryCall({ toolName: "grep", input: { pattern: "settings.json", path: "src" } })).toBe(true);
		expect(isDiscoveryCall({ toolName: "find", input: { pattern: "**/*.ts" } })).toBe(true);
		expect(isDiscoveryCall({ toolName: "read", input: { path: "src/index.ts" } })).toBe(true);
		expect(isDiscoveryCall({ toolName: "ls", input: { path: "src" } })).toBe(true);
		expect(isDiscoveryCall({ toolName: "bash", input: { command: "rg Handler src" } })).toBe(true);
	});

	test("allows directives, config searches, and non-discovery commands", () => {
		expect(isDiscoveryCall({ toolName: "read", input: { path: "AGENTS.md" } })).toBe(false);
		expect(isDiscoveryCall({ toolName: "read", input: { path: "config/settings.json" } })).toBe(false);
		expect(isDiscoveryCall({ toolName: "grep", input: { pattern: "reserveTokens", glob: "*.json" } })).toBe(false);
		expect(isDiscoveryCall({ toolName: "find", input: { pattern: "**/*.md" } })).toBe(false);
		expect(isDiscoveryCall({ toolName: "bash", input: { command: "npm test" } })).toBe(false);
	});
});

describe("repository detection", () => {
	test("finds a parent .git directory", () => {
		const root = mkdtempSync(join(tmpdir(), "cbm-enforcement-"));
		temporaryDirectories.push(root);
		mkdirSync(join(root, ".git"));
		const nested = join(root, "src", "feature");
		mkdirSync(nested, { recursive: true });
		expect(findGitRoot(nested)).toBe(root);
	});

	test("accepts worktree .git files", () => {
		const root = mkdtempSync(join(tmpdir(), "cbm-enforcement-worktree-"));
		temporaryDirectories.push(root);
		writeFileSync(join(root, ".git"), "gitdir: /tmp/example\n");
		expect(findGitRoot(root)).toBe(root);
	});
});

describe("one-time enforcement state", () => {
	function setup(root: string) {
		const handlers = new Map<string, Array<(event: any, ctx: any) => any>>();
		const pi = {
			on(name: string, handler: (event: any, ctx: any) => any) {
				const registered = handlers.get(name) ?? [];
				registered.push(handler);
				handlers.set(name, registered);
			},
			exec: async () => ({ code: 0, stdout: '{"projects":[]}', stderr: "", killed: false }),
		};
		cbmEnforcement(pi as any);
		const emit = (name: string, event: any = {}, ctx: any = { cwd: root }) => {
			let result;
			for (const handler of handlers.get(name) ?? []) result = handler(event, ctx) ?? result;
			return result;
		};
		return { emit };
	}

	test("blocks one discovery call and then opens", () => {
		const root = mkdtempSync(join(tmpdir(), "cbm-enforcement-state-"));
		temporaryDirectories.push(root);
		mkdirSync(join(root, ".git"));
		const { emit } = setup(root);
		emit("session_start");

		expect(emit("before_agent_start").message.customType).toBe("cbm-discovery-protocol");
		expect(emit("tool_call", { toolName: "grep", input: { pattern: "Handler" } }).block).toBe(true);
		expect(emit("tool_call", { toolName: "find", input: { pattern: "**/*.ts" } })).toBeUndefined();
	});

	test("a successful CBM result disarms the gate", () => {
		const root = mkdtempSync(join(tmpdir(), "cbm-enforcement-result-"));
		temporaryDirectories.push(root);
		mkdirSync(join(root, ".git"));
		const { emit } = setup(root);
		emit("session_start");
		emit("tool_result", {
			toolName: "mcp",
			input: { tool: "codebase_memory_mcp_search_graph" },
			isError: false,
		});

		expect(emit("tool_call", { toolName: "grep", input: { pattern: "Handler" } })).toBeUndefined();
	});

	test("a Pi opt-out marker suppresses reminder and gate", () => {
		const root = mkdtempSync(join(tmpdir(), "cbm-enforcement-optout-"));
		temporaryDirectories.push(root);
		mkdirSync(join(root, ".git"));
		mkdirSync(join(root, ".pi"));
		writeFileSync(join(root, ".pi", ".no-cbm-enforce"), "");
		const { emit } = setup(root);
		emit("session_start");

		expect(emit("before_agent_start")).toBeUndefined();
		expect(emit("tool_call", { toolName: "grep", input: { pattern: "Handler" } })).toBeUndefined();
	});

	test("a Claude opt-out marker does not disable Pi enforcement", () => {
		const root = mkdtempSync(join(tmpdir(), "cbm-enforcement-claude-marker-"));
		temporaryDirectories.push(root);
		mkdirSync(join(root, ".git"));
		mkdirSync(join(root, ".claude"));
		writeFileSync(join(root, ".claude", ".no-cbm-enforce"), "");
		const { emit } = setup(root);
		emit("session_start");

		expect(emit("before_agent_start").message.customType).toBe("cbm-discovery-protocol");
		expect(emit("tool_call", { toolName: "grep", input: { pattern: "Handler" } }).block).toBe(true);
	});
});
