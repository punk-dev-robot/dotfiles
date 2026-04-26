import type { Plugin } from "@opencode-ai/plugin"
import path from "node:path"

const COOLDOWN_MS = 5000

const lastTriggeredAt = new Map<string, number>()
const activeProcesses = new Map<string, Promise<void>>()

function toAbsolutePath(projectDir: string, file: string): string {
  return path.isAbsolute(file) ? file : path.join(projectDir, file)
}

type HookResult = {
  decision?: "allow" | "block"
  reason?: string
}

function isMarkdownFile(projectDir: string, file: string): boolean {
  const absolutePath = toAbsolutePath(projectDir, file)
  const relativePath = path.relative(projectDir, absolutePath)

  if (relativePath.startsWith("..") || path.isAbsolute(relativePath)) {
    return false
  }

  return path.extname(relativePath).toLowerCase() === ".md"
}

function parseHookResult(stdout: string): HookResult | undefined {
  try {
    const parsed = JSON.parse(stdout) as HookResult
    if (parsed.decision === "allow" || parsed.decision === "block") {
      return parsed
    }
  } catch {
    return undefined
  }

  return undefined
}

function shouldTrigger(file: string): boolean {
  const now = Date.now()
  const lastRun = lastTriggeredAt.get(file) ?? 0

  if (now - lastRun < COOLDOWN_MS) {
    return false
  }

  lastTriggeredAt.set(file, now)
  return true
}

function getEventSessionID(event: {
  properties?: Record<string, unknown>
  sessionID?: unknown
  sessionId?: unknown
}): string | undefined {
  const candidates = [
    event.properties?.sessionID,
    event.properties?.sessionId,
    event.sessionID,
    event.sessionId,
  ]

  return candidates.find(
    (value): value is string => typeof value === "string" && value.length > 0,
  )
}

async function readProcessStream(
  stream: ReadableStream<Uint8Array> | null | undefined,
): Promise<string> {
  if (!stream) {
    return ""
  }

  return (await new Response(stream).text()).trim()
}

export const SpecKitPlannotatorPlugin: Plugin = async ({ client, directory }) => {
  let lastSessionID: string | undefined

  async function launchAnnotator(file: string, sessionID?: string) {
    const absolutePath = toAbsolutePath(directory, file)

    if (activeProcesses.has(absolutePath) || !shouldTrigger(absolutePath)) {
      return
    }

    const plannotator = Bun.which("plannotator")
    if (!plannotator) {
      await client.app.log({
        body: {
          service: "spec-kit-plannotator",
          level: "warn",
          message: "Skipping markdown annotation because `plannotator` is not installed",
          extra: { file: absolutePath },
        },
      })
      return
    }

    const proc = Bun.spawn([plannotator, "annotate", absolutePath, "--hook"], {
      stdin: "ignore",
      stdout: "pipe",
      stderr: "pipe",
      env: { ...globalThis.process.env, NO_COLOR: "1" },
    })

    const run = (async () => {
      const stdoutPromise = readProcessStream(proc.stdout)
      const stderrPromise = readProcessStream(proc.stderr)
      const exitCode = await proc.exited
      const [stdout, stderr] = await Promise.all([stdoutPromise, stderrPromise])

      if (exitCode !== 0) {
        await client.app.log({
          body: {
            service: "spec-kit-plannotator",
            level: "error",
            message: "Plannotator annotate command failed",
            extra: {
              file: absolutePath,
              exitCode,
              stderr,
              stdout,
            },
          },
        })
        return
      }

      if (!stdout) {
        return
      }

      const hookResult = parseHookResult(stdout)
      if (!hookResult) {
        await client.app.log({
          body: {
            service: "spec-kit-plannotator",
            level: "error",
            message: "Plannotator returned non-JSON hook output",
            extra: { file: absolutePath, stdout },
          },
        })
        return
      }

      if (hookResult.decision !== "block" || !hookResult.reason) {
        return
      }

      if (!sessionID) {
        await client.app.log({
          body: {
            service: "spec-kit-plannotator",
            level: "warn",
            message:
              "Received Plannotator annotations but could not route them back to OpenCode because no session ID was available",
            extra: { file: absolutePath },
          },
        })
        return
      }

      try {
        await client.session.prompt({
          path: { id: sessionID },
          body: {
            parts: [
              {
                type: "text",
                text: hookResult.reason,
              },
            ],
          },
        })
      } catch (error) {
        await client.app.log({
          body: {
            service: "spec-kit-plannotator",
            level: "error",
            message: "Failed to send Plannotator annotations back to OpenCode",
            extra: {
              file: absolutePath,
              sessionID,
              error: error instanceof Error ? error.message : String(error),
            },
          },
        })
      }
    })()

    activeProcesses.set(absolutePath, run)

    await client.app.log({
      body: {
        service: "spec-kit-plannotator",
        level: "info",
        message: "Opening Plannotator for markdown file",
        extra: { file: absolutePath, sessionID },
      },
    })

    void run.finally(() => {
      activeProcesses.delete(absolutePath)
    })
  }

  return {
    event: async ({ event }) => {
      const sessionID = getEventSessionID(event)
      if (sessionID) {
        lastSessionID = sessionID
      }

      const targetSessionID = sessionID ?? lastSessionID

      if (event.type === "file.edited") {
        if (isMarkdownFile(directory, event.properties.file)) {
          await launchAnnotator(event.properties.file, targetSessionID)
        }
        return
      }

      if (event.type === "file.watcher.updated") {
        if (event.properties.event === "unlink") {
          return
        }

        if (isMarkdownFile(directory, event.properties.file)) {
          await launchAnnotator(event.properties.file, targetSessionID)
        }
      }
    },
  }
}

export default SpecKitPlannotatorPlugin
