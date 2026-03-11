# Tasks: {{SCRIPT_NAME}}

## Overview
- **Total tasks**: {{N}}
- **Framework**: {{ESX/QBCore/QBOX}}
- **Phases**: {{N}}

## Phase 1: Project Setup
- [ ] T001 Create resource folder structure per plan.md
- [ ] T002 Create fxmanifest.lua with lua54 'yes' and all dependencies
- [ ] T003 Create config/config.lua with Config = {} pattern
- [ ] T004 [P] Create locales/en.lua
- [ ] T005 [P] Create locales/fr.lua
- [ ] T006 Create sql/install.sql with schema (if needed)

## Phase 2: Server Foundation
- [ ] T007 Create server/main.lua with framework initialization
- [ ] T008 Implement server validation helpers
- [ ] T009 Register all net events

## Phase 3: Client Foundation
- [ ] T010 Create client/main.lua with framework initialization
- [ ] T011 Implement base thread with dynamic Wait()
- [ ] T012 [P] Set up ox_lib zones/points
- [ ] T013 [P] Set up ox_target interactions

## Phase 4+: Features
{{One phase per feature from spec}}

### Phase 4: {{Feature}} - Server
- [ ] T0XX [US1] Implement server logic
- [ ] T0XX [US1] Add 6-step validation
- [ ] T0XX [US1] Add database queries

### Phase 4: {{Feature}} - Client
- [ ] T0XX [P] [US1] Implement client interaction
- [ ] T0XX [P] [US1] Add ox_lib UI elements

## Phase N: Polish & Validation
- [ ] T0XX Run constitution quality gates
- [ ] T0XX Verify resmon < 0.2ms idle
- [ ] T0XX Test exploit resistance
- [ ] T0XX Verify Config completeness
- [ ] T0XX Final constitution review

## Dependencies
```
Phase 1 → Phase 2 → Phase 3 → Phase 4+ → Phase N
```

## Parallel Execution Guide
- Locale files (T004, T005) are independent
- Server features with different events can run in parallel
- Client features on different threads can run in parallel
