---
description: Execute the FiveM script implementation by processing all tasks defined in tasks.md with constitution enforcement.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Load implementation context**:
   - **REQUIRED**: Read `specs/tasks.md` for the complete task list
   - **REQUIRED**: Read `specs/plan.md` for architecture and file structure
   - **REQUIRED**: Read `specs/spec.md` for requirements and features
   - **REQUIRED**: Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/constitution.md` for quality gates
   - Load framework patterns based on spec (esx-patterns.md or qbcore-patterns.md)
   - Load `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/performance.md`
   - Load `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/security.md`
   - Load `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/ox-ecosystem.md`

2. **Pre-implementation constitution check**:
   - Verify plan complies with ALL NEVER rules
   - Verify plan includes ALL ALWAYS rules
   - If violations found: STOP and list violations. Do not proceed.

3. **Parse tasks.md** and extract:
   - Task phases with dependencies
   - Sequential vs parallel [P] tasks
   - File paths for each task

4. **Execute implementation phase by phase**:

   ### Phase 1: Setup
   - Create folder structure exactly as in plan.md
   - Write `fxmanifest.lua` with:
     - `fx_version 'cerulean'`
     - `game 'gta5'`
     - `lua54 'yes'` (MANDATORY - constitution rule)
     - All dependencies in correct order
   - Write `config/config.lua` with Config = {} pattern
   - Write locale files
   - Write SQL schema (if needed)

   ### Phase 2: Server Foundation
   - Framework initialization using correct pattern:
     - ESX: `ESX = exports['es_extended']:getSharedObject()`
     - QBCore: `QBCore = exports['qb-core']:GetCoreObject()`
     - QBOX: Same as QBCore with ox_lib
   - Register all net events BEFORE adding handlers
   - Implement validation helpers

   ### Phase 3: Client Foundation
   - Framework initialization (client-side)
   - Base thread with dynamic Wait() pattern:
     ```lua
     CreateThread(function()
         while true do
             local sleep = 1000
             local playerCoords = cache.coords or GetEntityCoords(cache.ped)
             local dist = #(playerCoords - targetCoords)
             if dist < 50.0 then
                 sleep = 500
                 if dist < 10.0 then
                     sleep = 0
                     -- interaction logic
                 end
             end
             Wait(sleep)
         end
     end)
     ```
   - ox_lib zones/points/target setup

   ### Phase 4+: Features
   - Implement server logic FIRST, then client
   - Every server event handler must follow the 6-step validation:
     1. Check source is valid player
     2. Validate all parameters
     3. Check permissions/job
     4. Verify proximity (server-side coords)
     5. Apply cooldown
     6. Execute action
   - Use ox_lib for all UI (notifications, menus, progress bars)
   - Use prepared statements for all database queries
   - Cache frequently used values

   ### NUI Phase (if applicable)
   - Set up NUI framework
   - Implement SendNUIMessage / RegisterNUICallback pairs
   - Handle SetNuiFocus properly (always false on close)

   ### Polish Phase
   - Run constitution quality gates
   - Verify performance patterns
   - Check for hardcoded values (move to Config)
   - Verify all strings use locales (if applicable)
   - Ensure no `print()` calls remain (use debug mode pattern)

5. **Progress tracking**:
   - After each task: mark as `[X]` in tasks.md
   - Report progress after each phase
   - If a task fails: halt and report error with context
   - For parallel [P] tasks: report each individually

6. **Post-implementation validation**:
   - Re-read ALL generated files
   - Run constitution checklist against the code:
     - [ ] `lua54 'yes'` in fxmanifest
     - [ ] No `while true do` without `Wait()`
     - [ ] No deprecated `GetPlayerPed(-1)` on client
     - [ ] No `TriggerServerEvent` for money/items/weapons
     - [ ] No `source` used on client side
     - [ ] All server events use `RegisterNetEvent`
     - [ ] No hardcoded values (all in Config)
     - [ ] Dynamic Wait() patterns used
     - [ ] Server-side validation on ALL events
     - [ ] Prepared statements for ALL queries
   - If any violation: FIX immediately and report the fix

7. **Completion report**:
   ```
   ## Implementation Complete

   **Resource**: [name]
   **Files created**: [count]
   **Tasks completed**: [X/total]
   **Constitution violations found & fixed**: [count]
   **Performance**: Expected < 0.2ms idle

   ### Files
   - [list all created files]

   ### Next Steps
   - Test in-game with `/ensure [resource]`
   - Monitor with `resmon` command
   - Run `/fivem.review` for detailed audit
   ```

## Implementation Code Standards

When writing Lua code, ALWAYS follow these patterns:

### Variable Declarations
```lua
-- Use local for EVERYTHING
local myVar = 'value'
local function myFunc() end

-- NEVER use global variables (constitution rule)
```

### Native Optimization
```lua
-- Cache natives at file top
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetGameTimer = GetGameTimer

-- Use vector math
local dist = #(coordsA - coordsB) -- NOT Vdist()
```

### Event Pattern
```lua
-- Server: ALWAYS register before handling
RegisterNetEvent('resource:eventName')
AddEventHandler('resource:eventName', function(data)
    local src = source
    -- 6-step validation here
end)

-- Client: Use ox_lib callbacks when possible
lib.callback('resource:getData', false, function(result)
    -- handle result
end)
```

### ox_lib Patterns
```lua
-- Notifications
lib.notify({ title = 'Title', description = 'Message', type = 'success' })

-- Progress bar
if lib.progressBar({ duration = 5000, label = 'Action...', canCancel = true }) then
    -- success
end

-- Context menu
lib.registerContext({ id = 'menu_id', title = 'Menu', options = { ... } })
lib.showContext('menu_id')
```
