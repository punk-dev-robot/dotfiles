# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: User description: "$ARGUMENTS"

## Scope *(mandatory)*

### Affected Boundaries

- [ ] `config/`
- [ ] `etc/`
- [ ] `local/`
- [ ] `.dotter/`
- [ ] `docs/`

Optional, only if the feature explicitly targets SDD/tooling work:

- [ ] `.specify/`

### Affected Paths

- `[exact path or directory]`
- `[exact path or directory]`

### Platform Scope

- [ ] `common`
- [ ] `linux`
- [ ] `arch`
- [ ] `macos`
- [ ] Not package-scoped

## User Scenarios & Testing *(mandatory)*

### User Story 1 - [Brief Title] (Priority: P1)

[Describe the highest-value user-facing or maintainer-facing outcome. In this repo, the “user” is often the machine owner or future maintainer.] 

**Why this priority**: [Explain why this change matters first] 

**Independent Test**: [Describe the smallest realistic check that proves the change works on its own] 

**Acceptance Scenarios**:

1. **Given** [starting environment or config state], **When** [action or deployment], **Then** [observable result]
2. **Given** [starting environment or config state], **When** [action or deployment], **Then** [observable result]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe the next independently valuable outcome]

**Why this priority**: [Explain why it comes after P1]

**Independent Test**: [Describe the focused validation]

**Acceptance Scenarios**:

1. **Given** [state], **When** [action], **Then** [result]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe the final independently valuable outcome]

**Why this priority**: [Explain why it comes after P2]

**Independent Test**: [Describe the focused validation]

**Acceptance Scenarios**:

1. **Given** [state], **When** [action], **Then** [result]

## Edge Cases *(mandatory)*

- What happens when the target platform is different from the default platform assumed by the change?
- What happens if Dotter variables, package membership, or target paths differ between Linux and macOS?
- What happens if the change touches generated, templated, or machine-specific files?
- What happens if the change affects startup/login/session behavior and cannot be safely validated in the current environment?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST identify the exact repo paths and boundaries affected by the change.
- **FR-002**: The feature MUST preserve or intentionally update Dotter mappings when deployable files move or change ownership.
- **FR-003**: The feature MUST define how success is validated for the touched config, script, or tooling area.
- **FR-004**: The feature MUST state any platform-specific behavior or package scoping assumptions.
- **FR-005**: The feature MUST document any required follow-up in `docs/` when behavior, commands, or paths change.

### Boundary-Specific Requirements

Use only the sections that apply.

#### `config/` Changes

- Describe which application config is being changed.
- State whether the behavior is shared, Linux-only, macOS-only, or host-specific.

#### `etc/` Changes

- State why a system-level change is required.
- Call out rollback or recovery expectations for risky OS-level behavior.

#### `local/` Script Changes

- State the entrypoint script name and what triggers it.
- Describe required environment variables, paths, or dependent tools if relevant.

#### `.dotter/` Changes

- State which package, variable, or target mapping is changing.
- State whether the change affects `common`, `linux`, `macos`, or `arch` package composition.

#### `.specify/` Changes

- State whether the work targets spec templates, workflows, or plugin/extension experiments.
- State why the `.specify/` change is needed for SDD practice or tooling support rather than core dotfiles behavior.
- If local extension tests exist, state which local test conventions must still hold.

Omit this section entirely unless `.specify/` is actually in scope.

## Success Criteria *(mandatory)*

- **SC-001**: The affected paths and ownership boundaries are clear enough that a maintainer can tell where the change belongs without guesswork.
- **SC-002**: Validation steps are concrete and appropriate for the touched area, not copied from an unrelated app template.
- **SC-003**: Platform-specific behavior is explicit wherever Linux, Arch, macOS, or shared behavior differs.
- **SC-004**: The change can be reviewed against actual repo paths, Dotter mappings, and documentation without unresolved placeholder text.

## Assumptions

- [Assumption about target host, package scope, or deployment context]
- [Assumption about whether the change is safe to validate locally vs only by static checks]
- [Assumption about existing configs, tools, or docs that this work depends on]
