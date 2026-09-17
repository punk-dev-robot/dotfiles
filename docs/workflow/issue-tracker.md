# Issue tracker: Linear (primary), GitHub Issues (repo bugs)

Planning, wayfinder maps, and manager-mode work live in **Linear**, team `Kuba`
(key `KUB`). GitHub Issues on `punk-dev-robot/dotfiles` remain for public repo
bugs and for `#123` references in commits. When a skill says "the issue
tracker" without qualification, it means Linear.

## Linear

Access: Linear MCP tools (`*linear_*`, via `mcp` / `mcpScript`). No CLI
fallback — if the tools fail, fix the MCP route, don't improvise. Manager-mode
rules and branch/PR naming: `config/shared/agents/manager-mode.md`.

### Conventions

- **Create an issue**: `linear_save_issue` with `team: "Kuba"`, `title`,
  `description` (markdown), `project`, optional `labels`, `parentId`,
  `projectMilestone`.
- **Read an issue**: `linear_get_issue` with `id: "KUB-n"` — returns body,
  status, assignee, labels, `parentId`. Comments: `linear_list_comments`.
- **List issues**: `linear_list_issues` filtered by `project` / `team` /
  `assignee` / `state`. Output is large — use `mcpScript` and emit only the
  fields you need.
- **Comment**: `linear_save_comment` with `issueId`.
- **Update / close**: `linear_save_issue` with `id` plus `state`
  (`Backlog` / `Todo` / `In Progress` / `Done` / `Canceled`), `assignee: "me"`,
  `labels`, etc.
- **Documents**: `linear_save_document` for long-form briefs; attach to an
  issue via `linear_prepare_attachment_upload` + `linear_create_attachment_from_upload`.

### Quirks

- `linear_list_issues` with `parentId` returns `[]` — list by `project` and
  filter on each issue's `parentId` client-side.
- `linear_save_issue` description patches anchor against Linear's *normalised*
  markdown (`* ` bullets, not `- `).
- Blocking relations are **not echoed** by `get_issue` / `list_issues`; verify
  in the UI.
- Result payloads >~20 KB are spilled to a tempfile by the MCP output guard;
  parse the file rather than re-running the call.

### When a skill says "publish to the issue tracker"

Create a Linear issue in team `Kuba`, in the relevant project.

### When a skill says "fetch the relevant ticket"

`linear_get_issue` with the `KUB-n` id, then `linear_list_comments` for the
resolution thread.

### Wayfinding operations

Used by `/cock-wayfinder` and manager mode. The **map** is one issue with
**sub-issues** as tickets.

- **Map**: one issue labelled `wayfinder:map`, holding Destination / Notes /
  Decisions-so-far / Not-yet-specified / Out-of-scope. Assigned to the owner.
- **Child ticket**: a sub-issue of the map (`parentId: <map uuid>`), labelled
  `wayfinder:<type>` (`research` / `prototype` / `grilling` / `task`), placed
  in a project milestone. Body = the question, sized to one session.
- **Blocking**: Linear's native **blocked by** relation — the canonical,
  UI-visible gate. A ticket is unblocked when every blocker is `Done`.
- **Frontier query**: open sub-issues of the map, no assignee, no open
  blocker. First in map / milestone order wins.
- **Claim**: `linear_save_issue { id, assignee: "me", state: "In Progress" }`
  — the session's first write. One ticket per session.
- **Resolve**: `linear_save_comment` with the answer, `state: "Done"`, then
  append a one-line pointer to the map's **Decisions so far** list
  (`[title](<url>): summary`).
- **Annoyances**: plain issues in the project, milestone `Annoyances`, no
  wayfinder label.

## GitHub Issues (repo bugs only)

Use the `gh` CLI; it infers the repo from `git remote -v`.

- **Read**: `gh issue view <n> --comments`
- **Create**: `gh issue create --title "..." --body "..."`
- **Comment / label / close**: `gh issue comment`, `gh issue edit --add-label`
  / `--remove-label`, `gh issue close --comment "..."`

Code-review skills resolving `#123` in commit messages use `gh issue view`
(fall back to `gh pr view` — GitHub shares one number space). Linear refs look
like `KUB-123` and resolve via `linear_get_issue`.

**PRs as a request surface: no.**
