# Plannotator Agent Integrations

How Plannotator is wired into OpenCode and Claude Code for Spec Kit artifacts in this repo.

## Scope

Both integrations target the same artifact set under `specs/`:

- `spec.md`
- `plan.md`
- `tasks.md`

Anything outside `specs/` or outside that filename set is ignored.

## OpenCode

OpenCode uses a local plugin defined in `config/opencode/plugins/spec-kit-plannotator.ts` and enabled from `config/opencode/opencode.jsonc`.

### Trigger model

- listens to `file.edited`
- listens to `file.watcher.updated`
- launches `plannotator annotate <absolute-path>` for matching files

### Return path

The plugin reads submitted annotations from `plannotator annotate` stdout and sends them back into the active OpenCode session with `client.session.prompt(...)`.

File-related OpenCode events do not always include a session ID, so the plugin caches the most recent session ID seen for the current project and reuses it for watcher-triggered callbacks.

### Practical result

This gives OpenCode real async callback behavior: edit the file, annotate in the browser, submit, and the annotation text returns to the live session.

## Claude Code

Claude Code uses a command hook defined in `config/claude/hooks/spec-kit-plannotator.py` and registered in `config/claude/settings.json` under `PostToolUse` for `Edit|Write`.

### Trigger model

- runs after Claude successfully uses `Edit`
- runs after Claude successfully uses `Write`
- resolves `tool_input.file_path`
- launches `plannotator annotate <absolute-path>` for matching files

### Return path

The reliable path in practice is top-level `PostToolUse` feedback:

```json
{
  "decision": "block",
  "reason": "# Markdown Annotations\n..."
}
```

Claude's hook schema also documents `hookSpecificOutput.additionalContext` for `PostToolUse`, but in this workflow that path did not reliably surface the annotation text back to Claude. Using `decision: "block"` with the annotation payload in `reason` did work consistently.

### Practical result

Claude does not get the same async session callback behavior as OpenCode here. The best reliable equivalent is a post-tool interruption: Claude edits the file, Plannotator opens, you submit feedback, and Claude receives that feedback as post-tool hook output.

## Behavior Difference

| Client | Trigger | Return path | Observed behavior |
|--------|---------|-------------|-------------------|
| OpenCode | file events | session prompt | returns annotations directly into the live session |
| Claude Code | `PostToolUse` on `Edit|Write` | hook `decision` + `reason` | surfaces annotations as post-tool feedback |

OpenCode is closer to a true watcher-driven callback. Claude Code is closer to a hook-driven interruption after its own file edit tools run.

## Deployment Notes

### OpenCode

`config/opencode` is deployed to `~/.config/opencode` through Dotter. If the running `opencode serve` process does not seem to pick up plugin changes, restart OpenCode so it reloads the updated plugin module.

### Claude Code

`config/claude` is also managed under `~/.config/claude`, but newly added hook files are not usable until the live path exists.

Expected live path:

```text
~/.config/claude/hooks/spec-kit-plannotator.py
```

If that path is missing, redeploy the `claude` package with Dotter or create the symlink manually before testing.

## Validation

### OpenCode

1. Edit `specs/.../spec.md`, `plan.md`, or `tasks.md`.
2. Confirm the browser annotation UI opens.
3. Submit annotation feedback.
4. Confirm the annotation text returns to the active OpenCode session.

### Claude Code

1. Have Claude edit `specs/.../spec.md`, `plan.md`, or `tasks.md`.
2. Confirm the browser annotation UI opens.
3. Submit annotation feedback.
4. Confirm Claude receives the annotation text as post-tool feedback.

## Troubleshooting

### OpenCode opens Plannotator but no feedback returns

- confirm the running OpenCode process was restarted after plugin changes
- check that the edited file matches `specs/**/{spec.md,plan.md,tasks.md}`
- check OpenCode logs for `spec-kit-plannotator` messages
- verify the plugin observed or cached a valid session ID before the watcher callback fired

### Claude opens Plannotator but Claude never reacts

- confirm `~/.config/claude/hooks/spec-kit-plannotator.py` exists and is executable
- confirm `config/claude/settings.json` still registers the hook on `PostToolUse` for `Edit|Write`
- prefer `decision: "block"` plus `reason` over `additionalContext` for this workflow
- restart the Claude session if hook changes were made mid-session and behavior still looks stale
