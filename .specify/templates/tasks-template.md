---
description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Validation**: Include only the checks that match the touched area. For Dotter-managed changes, prefer `dotter -v -d`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: User story label such as `US1`, `US2`, `US3`
- Include exact repo paths in every implementation task

## Phase 1: Scope And Setup

**Purpose**: Confirm boundaries, impacted paths, and platform/package scope before editing

- [ ] T001 Confirm affected paths in `config/`, `etc/`, `local/`, `.dotter/`, or `docs/`
- [ ] T002 Confirm platform/package scope (`common`, `linux`, `arch`, `macos`, or host-specific)
- [ ] T003 [P] Identify any `.dotter/` mapping or variable updates required by the change

Only if the feature explicitly targets SDD/tooling work:

- [ ] T00X Confirm why `.specify/` is in scope and which auxiliary paths are affected

---

## Phase 2: Foundational Changes

**Purpose**: Make prerequisite updates that block story work

- [ ] T004 Update `.dotter/` package mappings or template variables if file ownership or deployment targets change
- [ ] T005 [P] Prepare any supporting script/config scaffolding needed by all user stories
- [ ] T006 [P] Add or update documentation placeholders only if the feature changes commands, paths, or operator workflow

---

## Phase 3: User Story 1 - [Title] (Priority: P1)

**Goal**: [Describe the primary maintainer-visible outcome]

**Independent Test**: [Describe the focused validation for this story]

### Validation Tasks For User Story 1

- [ ] T007 [P] [US1] Run `dotter -v -d` if the story changes Dotter-managed files
- [ ] T008 [P] [US1] Run the narrowest useful validation for touched scripts/configs

### Implementation Tasks For User Story 1

- [ ] T009 [P] [US1] Update primary files in `[exact path]`
- [ ] T010 [US1] Update related support files in `[exact path]`
- [ ] T011 [US1] Update `.dotter/` mappings in `[exact path]` if deployment ownership changed
- [ ] T012 [US1] Update documentation in `docs/[exact path]` if user-facing behavior changed

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Describe the secondary outcome]

**Independent Test**: [Describe the focused validation for this story]

### Validation Tasks For User Story 2

- [ ] T013 [P] [US2] Run the validation relevant to the affected files and platform scope

### Implementation Tasks For User Story 2

- [ ] T014 [P] [US2] Update files in `[exact path]`
- [ ] T015 [US2] Update dependent config/script/docs paths in `[exact path]`

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Describe the lower-priority outcome]

**Independent Test**: [Describe the focused validation for this story]

### Validation Tasks For User Story 3

- [ ] T016 [P] [US3] Run the validation relevant to the touched area

### Implementation Tasks For User Story 3

- [ ] T017 [P] [US3] Update files in `[exact path]`
- [ ] T018 [US3] Update dependent paths or docs in `[exact path]`

---

## Final Phase: Cross-Cutting Validation And Cleanup

- [ ] T019 Re-run `dotter -v -d` if any Dotter-managed files changed
- [ ] T020 Verify platform scoping is still correct in `.dotter/`, configs, and docs
- [ ] T021 Verify docs reference real commands, paths, and behaviors
- [ ] T022 Verify no unrelated `.specify/` practice tooling or `.specify/extensions/*` test workflow was affected unless intentionally changed

---

## Dependencies & Execution Order

- Scope/setup must complete before foundational changes.
- Foundational changes must complete before user-story implementation when they affect shared mappings or paths.
- User stories may run in parallel only when they touch different files and do not contend on the same boundary.
- Documentation updates should land in the same feature whenever behavior, paths, or commands change.

## Notes

- Prefer the smallest correct boundary.
- Do not invent generic build, database, API, or frontend tasks for this repository.
- Treat `.specify/` work as optional practice/tooling unless the feature explicitly targets spec-kit behavior.
- If the work targets `.specify/extensions/*`, replace the generic validation tasks above with the actual local test conventions for that extension.
