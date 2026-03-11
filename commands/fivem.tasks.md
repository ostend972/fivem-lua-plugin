---
description: Generate actionable, dependency-ordered tasks for FiveM script implementation from the plan.
handoffs:
  - label: Start Implementation
    agent: fivem.implement
    prompt: Implement the tasks in order
    send: true
  - label: Review Plan First
    agent: fivem.review
    prompt: Review the plan before generating tasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Load design documents**:
   - **Required**: `specs/plan.md` (tech stack, structure, architecture)
   - **Required**: `specs/spec.md` (features, requirements, scenarios)
   - **Required**: `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/constitution.md` (quality gates)

2. **Extract task sources**:
   - From plan.md: File structure, dependencies, framework setup
   - From spec.md: Features (client + server), database, NUI
   - From constitution: Mandatory quality checks

3. **Generate `specs/tasks.md`** following this structure:

```markdown
# Tasks: [SCRIPT NAME]

## Overview
- **Total tasks**: [N]
- **Framework**: [ESX/QBCore/QBOX]
- **Estimated phases**: [N]

## Phase 1: Project Setup

- [ ] T001 Create resource folder structure per plan.md
- [ ] T002 Create fxmanifest.lua with all dependencies and lua54 'yes'
- [ ] T003 Create config/config.lua with all Config values from spec
- [ ] T004 [P] Create locales/en.lua with all translatable strings
- [ ] T005 [P] Create locales/fr.lua with French translations
- [ ] T006 Create sql/install.sql with database schema (if needed)

## Phase 2: Server Foundation

- [ ] T007 Create server/main.lua with framework initialization
- [ ] T008 Implement server-side player validation helpers
- [ ] T009 [P] Create database migration and seed functions (if needed)
- [ ] T010 Register all server events with RegisterNetEvent (no handlers on net events without registration)

## Phase 3: Client Foundation

- [ ] T011 Create client/main.lua with framework initialization
- [ ] T012 Implement base thread with dynamic Wait() pattern
- [ ] T013 [P] Set up ox_lib zones/points for interaction areas (if needed)
- [ ] T014 [P] Set up ox_target interactions (if needed)

## Phase 4+: Feature Implementation

(One phase per major feature from spec.md)

### Phase 4: [Feature Name] - Server
- [ ] T0XX [US1] Implement [feature] server logic in server/[feature].lua
- [ ] T0XX [US1] Add server-side validation (6-step checklist) for [feature] events
- [ ] T0XX [US1] Implement database queries with prepared statements for [feature]

### Phase 4: [Feature Name] - Client
- [ ] T0XX [P] [US1] Implement [feature] client UI/interaction in client/[feature].lua
- [ ] T0XX [P] [US1] Add ox_lib progress bars / menus for [feature]
- [ ] T0XX [US1] Connect client events to server callbacks for [feature]

## Phase N-1: NUI (if needed)

- [ ] T0XX Create html/index.html with NUI boilerplate
- [ ] T0XX Implement NUI framework (Svelte/React) components
- [ ] T0XX Register all NUI callbacks with RegisterNUICallback
- [ ] T0XX Implement SendNUIMessage calls from client Lua
- [ ] T0XX Handle SetNuiFocus toggling

## Phase N: Polish & Validation

- [ ] T0XX Run constitution quality gates checklist
- [ ] T0XX Verify resmon performance (< 0.2ms idle, < 1ms active)
- [ ] T0XX Test all server events for exploit resistance
- [ ] T0XX Verify all Config values are used (no hardcoded values)
- [ ] T0XX Test with framework (ESX/QBCore/QBOX) player lifecycle
- [ ] T0XX Final review against constitution NEVER/ALWAYS rules

## Dependencies
```
Phase 1 (Setup) → Phase 2 (Server) → Phase 3 (Client)
                                    ↘ Phase 4+ (Features, can be parallel per feature)
                                    → Phase N-1 (NUI, after client)
All phases → Phase N (Polish)
```

## Parallel Execution Guide
- T004 & T005 can run in parallel (locales are independent)
- Server features [P] can run in parallel if they don't share events
- Client features [P] can run in parallel if they don't share threads
- NUI components can be parallelized by view/page
```

4. **Task Generation Rules**:
   - Every task MUST have: `- [ ] [TaskID] [P?] [Story?] Description with file path`
   - Setup phase: No story label
   - Feature phases: MUST have story label [US1], [US2], etc.
   - Polish phase: No story label
   - [P] marker only for truly parallelizable tasks
   - Each task must be specific enough for an LLM to execute without extra context
   - File paths must be explicit in every task

5. **FiveM-Specific Task Rules**:
   - Server files ALWAYS come before their client counterparts
   - Database schema ALWAYS comes before server code that uses it
   - Framework initialization ALWAYS comes first in each side (client/server)
   - ox_lib must be initialized before using any ox_lib feature
   - Constitution quality gates ALWAYS in final phase

6. **Report**: Output path to tasks.md, total count, phases, parallel opportunities, and readiness for `/fivem.implement`.
