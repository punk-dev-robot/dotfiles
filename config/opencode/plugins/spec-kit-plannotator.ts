import type { Plugin } from "@opencode-ai/plugin"
import path from "node:path"

const TARGET_FILES = new Set(["spec.md", "plan.md", "tasks.md"])
const COOLDOWN_MS = 5000

const lastTriggeredAt = new Map<string, number>()
const activeProcesses = new Map<string, Promise<void>>()

function toAbsolutePath(projectDir: string, file: string): string {
  return path.isAbsolute(file) ? file : path.join(projectDir, file)
}

function isSpecKitArtifact(projectDir: string, file: string): boolean {
  const absolutePath = toAbsolutePath(projectDir, file)
  const relativePath = path.relative(projectDir, absolutePath)

  if (relativePath.startsWith("..") || path.isAbsolute(relativePath)) {
    return false
  }

  if (!TARGET_FILES.has(path.basename(relativePath))) {
    return false
  }

  const normalizedPath = relativePath.split(path.sep).join("/")
  return normalizedPath.startsWith("specs/")
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
          message: "Skipping Spec Kit annotation because `plannotator` is not installed",
          extra: { file: absolutePath },
        },
      })
      return
    }

    const process = Bun.spawn([plannotator, "annotate", absolutePath], {
      stdin: "ignore",
      stdout: "pipe",
      stderr: "pipe",
    })

    const run = (async () => {
      // Standalone `plannotator annotate` returns the submitted annotations on stdout.
      const stdoutPromise = readProcessStream(process.stdout)
      const stderrPromise = readProcessStream(process.stderr)
      const exitCode = await process.exited
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
                text: `# Markdown Annotations\n\nFile: ${absolutePath}\n\n${stdout}\n\nPlease address the annotation feedback above.`,
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
        message: "Opening Plannotator for Spec Kit artifact",
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
        if (isSpecKitArtifact(directory, event.properties.file)) {
          await launchAnnotator(event.properties.file, targetSessionID)
        }
        return
      }

      if (event.type === "file.watcher.updated") {
        if (event.properties.event === "unlink") {
          return
        }

        if (isSpecKitArtifact(directory, event.properties.file)) {
          await launchAnnotator(event.properties.file, targetSessionID)
        }
      }
    },
  }
}

export default SpecKitPlannotatorPlugin
