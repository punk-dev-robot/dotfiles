# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

## Summary

[Summarize the change, the affected repo boundaries, and the technical approach]

## Technical Context

**Project Type**: Dotter-managed configuration monorepo  
**Primary Technologies**: TOML, `.conf`, Lua, shell/Zsh, JSON/JSONC, Markdown  
**Deployment Layer**: Dotter via `.dotter/global.toml`  
**Validation**: `dotter -v -d` for Dotter-managed changes; targeted syntax/runtime checks for touched scripts or tooling  
**Platform Scope**: [common/linux/arch/macos/host-specific]  
**Risk Level**: [low/medium/high] based on whether work touches `config/`, `local/`, `etc/`, `.dotter/`, `docs/`, or optional auxiliary `.specify/` tooling

## Constitution Check

*GATE: Must pass before implementation and again before completion.*

- Does the plan keep work inside the correct repo boundary or clearly justify cross-boundary changes?
- If deployable files move or package membership changes, does the plan include `.dotter/` updates?
- Are validation steps appropriate to the touched area instead of generic app commands?
- If `.specify/` is touched, does the plan keep that work clearly auxiliary to the main dotfiles purpose?
- If `.specify/extensions/*` is touched, does the plan preserve the local test conventions already present there?
- If docs, commands, or paths change, does the plan include documentation updates?

## Project Structure

### Feature Documentation

```text
specs/[###-feature]/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

### Repository Boundaries

```text
.dotter/   package selection, target mappings, template variables, deploy hooks
config/    user-level application configs
etc/       system-level templates and OS configuration
local/     local scripts and desktop assets
docs/      curated reference, troubleshooting, plans, archive
```

Optional auxiliary workspace, only if the feature explicitly targets it:

```text
.specify/  spec-kit workspace for SDD practice, templates, and extensions
```

### Structure Decision

[List the exact paths this feature touches and explain why those paths are the right home for the work. If `.specify/` is included, explain why that auxiliary workspace is in scope and why it does not change the main dotfiles purpose of the repository.]

## Implementation Phases

### Phase 0: Verify Scope

- Confirm the exact affected paths.
- Confirm package/platform scope.
- Confirm whether `.dotter/` changes are required.

### Phase 1: Implement In Boundary Order

Apply changes in the owning boundary, keeping support changes adjacent to the main change:

1. `.dotter/` when package membership, variables, or targets change
2. `config/`, `etc/`, or `local/` depending on the primary feature location
3. `docs/` for behavior, command, or path updates
4. `.specify/` only when the feature is explicitly about SDD tooling or practice

### Phase 2: Validate

- Run `dotter -v -d` for Dotter-managed changes.
- Run the narrowest useful script/config validation for touched files.
- Record any environment-specific validation limitations.

## Complexity Tracking

| Complexity | Why Needed | Simpler Alternative Rejected Because |
|------------|------------|--------------------------------------|
| [Cross-boundary change] | [reason] | [why a smaller boundary was insufficient] |
| [Platform split] | [reason] | [why a shared change would be incorrect] |
