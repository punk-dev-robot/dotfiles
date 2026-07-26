import { existsSync, realpathSync } from "node:fs";
import { dirname, join, parse, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CBM_SERVER = "codebase-memory-mcp";
const CBM_PREFIX = "codebase_memory_mcp_";
const CBM_TOOLS = new Set([
	"index_repository",
	"search_graph",
	"query_graph",
	"trace_path",
	"get_code_snippet",
	"get_graph_schema",
	"get_architecture",
	"search_code",
	"list_projects",
	"delete_project",
	"index_status",
	"detect_changes",
	"manage_adr",
	"ingest_traces",
]);

const SOURCE_EXTENSIONS = new Set([
	".c",
	".cc",
	".cpp",
	".cs",
	".dart",
	".ex",
	".exs",
	".go",
	".h",
	".hpp",
	".java",
	".js",
	".jsx",
	".kt",
	".kts",
	".lua",
	".php",
	".py",
	".rb",
	".rs",
	".scala",
	".swift",
	".ts",
	".tsx",
	".vue",
]);

const DIRECTIVE_FILES = new Set([
	"AGENTS.md",
	"CLAUDE.md",
	"CONTRIBUTING.md",
	"GEMINI.md",
	"SOP.md",
	".cursorrules",
	".windsurfrules",
]);

const REMINDER = `Code discovery protocol: use codebase-memory-mcp through the Pi \`mcp\` gateway before source exploration. Start with \`list_projects\`/\`index_status\`, then \`search_graph\`, \`trace_path\`, \`get_code_snippet\`, \`query_graph\`, or \`get_architecture\`. Use Pi's lowercase \`grep\`, \`find\`, \`read\`, and \`ls\` only for configs/text, known-file reads, or fallback after CBM.`;

interface ToolEvent {
	toolName: string;
	input?: unknown;
	isError?: boolean;
}

interface State {
	cbmUsed: boolean;
	gateOpened: boolean;
	optedOut: boolean;
	reminderPending: boolean;
	repoRoot?: string;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
	return typeof value === "object" && value !== null
		? value as Record<string, unknown>
		: undefined;
}

function stringField(input: unknown, key: string): string | undefined {
	const value = asRecord(input)?.[key];
	return typeof value === "string" ? value : undefined;
}

function normalizedToolName(input: unknown): string | undefined {
	return stringField(input, "tool")?.replaceAll("-", "_");
}

export function isCbmProxyCall(event: ToolEvent): boolean {
	if (event.toolName !== "mcp") return false;

	const tool = normalizedToolName(event.input);
	if (!tool) return false;
	if (tool.startsWith(CBM_PREFIX)) return true;

	const server = stringField(event.input, "server");
	return server === CBM_SERVER && CBM_TOOLS.has(tool);
}

export function isSuccessfulCbmResult(event: ToolEvent): boolean {
	return event.isError !== true && isCbmProxyCall(event);
}

function isDirectivePath(path: string): boolean {
	const base = path.split(/[\\/]/).at(-1);
	return base !== undefined && DIRECTIVE_FILES.has(base);
}

function hasSourceExtension(path: string): boolean {
	const match = path.toLowerCase().match(/\.[a-z0-9]+$/);
	return match !== null && SOURCE_EXTENSIONS.has(match[0]);
}

function explicitlyTargetsNonCode(input: unknown, keys: string[]): boolean {
	const record = asRecord(input);
	if (!record) return false;

	for (const key of keys) {
		const value = record[key];
		if (typeof value !== "string" || value.length === 0) continue;
		if (isDirectivePath(value)) return true;
		if (/\.(md|mdx|txt|jsonc?|ya?ml|toml|ini|conf|lock)$/i.test(value)) return true;
	}
	return false;
}

function isDiscoveryShellCommand(command: string): boolean {
	return /(?:^|[;&|]\s*)(?:command\s+)?(?:rg|grep|find|fd|tree|ls|ag)\b/i.test(command)
		|| /(?:^|[;&|]\s*)git\s+grep\b/i.test(command);
}

export function isDiscoveryCall(event: ToolEvent): boolean {
	if (event.toolName === "grep") {
		return !explicitlyTargetsNonCode(event.input, ["path", "glob"]);
	}

	if (event.toolName === "find") {
		return !explicitlyTargetsNonCode(event.input, ["path", "pattern"]);
	}

	if (event.toolName === "ls") return true;

	if (event.toolName === "read") {
		const path = stringField(event.input, "path");
		return path !== undefined && !isDirectivePath(path) && hasSourceExtension(path);
	}

	if (event.toolName === "bash") {
		const command = stringField(event.input, "command");
		return command !== undefined && isDiscoveryShellCommand(command);
	}

	return false;
}

export function findGitRoot(start: string): string | undefined {
	let current = resolve(start);
	const filesystemRoot = parse(current).root;

	while (true) {
		if (existsSync(join(current, ".git"))) return current;
		if (current === filesystemRoot) return undefined;
		const parent = dirname(current);
		if (parent === current) return undefined;
		current = parent;
	}
}

function isOptedOut(repoRoot: string): boolean {
	return existsSync(join(repoRoot, ".pi", ".no-cbm-enforce"));
}

function parseJsonOutput(stdout: string): Record<string, unknown> | undefined {
	const start = stdout.indexOf("{");
	if (start < 0) return undefined;
	try {
		return asRecord(JSON.parse(stdout.slice(start)));
	} catch {
		return undefined;
	}
}

function sameExistingPath(left: string, right: string): boolean {
	try {
		return realpathSync(left) === realpathSync(right);
	} catch {
		return resolve(left) === resolve(right);
	}
}

async function refreshIndexedRepository(pi: ExtensionAPI, repoRoot: string): Promise<void> {
	try {
		const listed = await pi.exec(
			"codebase-memory-mcp",
			["cli", "list_projects", "{}"],
			{ timeout: 10_000 },
		);
		if (listed.code !== 0) return;

		const projects = parseJsonOutput(listed.stdout)?.projects;
		if (!Array.isArray(projects)) return;
		const indexed = projects.some((project) => {
			const rootPath = asRecord(project)?.root_path;
			return typeof rootPath === "string" && sameExistingPath(rootPath, repoRoot);
		});
		if (!indexed) return;

		await pi.exec(
			"codebase-memory-mcp",
			[
				"cli",
				"index_repository",
				JSON.stringify({ repo_path: repoRoot, mode: "fast" }),
			],
			{ timeout: 120_000 },
		);
	} catch {
		// Freshness is best-effort and must never delay or break the session.
	}
}

export default function cbmEnforcement(pi: ExtensionAPI): void {
	const state: State = {
		cbmUsed: false,
		gateOpened: false,
		optedOut: false,
		reminderPending: true,
	};

	pi.on("session_start", (_event, ctx) => {
		state.cbmUsed = false;
		state.gateOpened = false;
		state.reminderPending = true;
		state.repoRoot = findGitRoot(ctx.cwd);
		state.optedOut = state.repoRoot === undefined || isOptedOut(state.repoRoot);

		if (state.repoRoot && ctx.hasUI) {
			void refreshIndexedRepository(pi, state.repoRoot);
		}
	});

	pi.on("session_compact", () => {
		if (!state.optedOut) state.reminderPending = true;
	});

	pi.on("before_agent_start", () => {
		if (state.optedOut || !state.reminderPending) return;
		state.reminderPending = false;
		return {
			message: {
				customType: "cbm-discovery-protocol",
				content: REMINDER,
				display: false,
			},
		};
	});

	pi.on("tool_result", (event) => {
		if (isSuccessfulCbmResult(event)) state.cbmUsed = true;
	});

	pi.on("tool_call", (event) => {
		if (state.optedOut || state.cbmUsed || state.gateOpened) return;
		if (isCbmProxyCall(event)) return;
		if (!isDiscoveryCall(event)) return;

		state.gateOpened = true;
		return {
			block: true,
			reason: "Use codebase-memory-mcp first through Pi's mcp gateway: list_projects/index_status, then search_graph, trace_path, get_code_snippet, query_graph, or get_architecture. If the repository is unindexed, call index_repository. The gate is now open, so retry this Pi tool if CBM is unsuitable.",
		};
	});
}
