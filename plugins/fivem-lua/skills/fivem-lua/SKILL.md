---
name: fivem-lua
description: FiveM Lua scripting mastery for ESX, QBCore and QBOX - project structure, performance optimization, security hardening, ox ecosystem, database patterns, NUI development, state management, debugging
user-invocable: true
---

# FiveM Lua Scripting - Best Practices & Rules

Apply these rules when writing, reviewing, or debugging FiveM Lua scripts. Follow the workflow below for every new script.

## Workflow

When creating a new FiveM script, follow these phases in order:

1. **Constitution Check** - Review [constitution.md](./constitution.md) rules. Every rule is non-negotiable.
2. **Structure Setup** - Set up the project following [script-structure.md](./script-structure.md).
3. **Framework Integration** - Apply the correct framework patterns:
   - [esx-patterns.md](./esx-patterns.md) for ESX Legacy
   - [qbcore-patterns.md](./qbcore-patterns.md) for QBCore / QBOX
4. **Implementation** - Write code following:
   - [performance.md](./performance.md) for thread and native optimization
   - [security.md](./security.md) for server-side validation and anti-exploit
   - [ox-ecosystem.md](./ox-ecosystem.md) for ox_lib, oxmysql, ox_inventory, ox_target
   - [database.md](./database.md) for database query patterns
   - [state-sync.md](./state-sync.md) for state bags, events, and exports
   - [nui-patterns.md](./nui-patterns.md) for HTML/JS user interfaces
5. **Validation** - Debug and profile using [debugging.md](./debugging.md).

## Constitution

Core principles that MUST NEVER be violated. Violations cause exploits, crashes, or unacceptable performance.

See [constitution.md](./constitution.md) for:
- NEVER rules (hard crashes, security holes, deprecated patterns)
- ALWAYS rules (mandatory practices for every script)
- Lua 5.4 mandatory features

## Script Structure

See [script-structure.md](./script-structure.md) for:
- `fxmanifest.lua` template and configuration
- Folder structure and file naming conventions
- Config pattern (`Config = {}`)
- Dependency declaration
- Resource start order

## Performance

See [performance.md](./performance.md) for:
- Thread management with `CreateThread` and `Wait()`
- Dynamic sleep pattern for proximity checks
- Job-conditional loops
- Native function optimization (replacements table)
- Caching strategies
- Memory management with `nil` cleanup

## Security

See [security.md](./security.md) for:
- Server-side validation checklist
- Anti-exploit patterns with cooldowns and proximity checks
- Event security (`RegisterNetEvent` vs `AddEventHandler`)
- Never handle money/items/weapons client-side
- Rate limiting patterns

## ESX Patterns

See [esx-patterns.md](./esx-patterns.md) for:
- ESX initialization via exports
- `xPlayer` API reference (money, job, inventory, weapons, notifications)
- ESX server callbacks
- ESX client events
- ESX-specific coding patterns

## QBCore Patterns

See [qbcore-patterns.md](./qbcore-patterns.md) for:
- QBCore initialization via exports
- `Player.Functions` API reference (money, items, job, gang, metadata)
- QBCore callbacks (server and client)
- QBCore events (player loaded, job update, data sync)
- QBOX compatibility notes

## Ox Ecosystem

See [ox-ecosystem.md](./ox-ecosystem.md) for:
- `ox_lib` UI modules (notifications, menus, progress bars, dialogs, skillcheck)
- `ox_lib` utility modules (zones, points, cache, callbacks)
- `ox_inventory` integration
- `ox_target` interaction system
- Import patterns and setup

## Database

See [database.md](./database.md) for:
- `oxmysql` setup and configuration
- Query patterns (select, insert, update, delete)
- Prepared statements (automatic SQL injection protection)
- Async/await patterns in threads
- Transaction patterns
- Migration best practices

## State Synchronization

See [state-sync.md](./state-sync.md) for:
- State bags (GlobalState, Player state, Entity state)
- `AddStateBagChangeHandler` patterns
- Events vs exports decision tree
- Inter-resource communication
- When to use state bags vs events

## NUI Patterns

See [nui-patterns.md](./nui-patterns.md) for:
- NUI setup in `fxmanifest.lua`
- Lua to JS communication (`SendNUIMessage`)
- JS to Lua communication (`RegisterNUICallback`)
- Focus management (`SetNuiFocus`)
- Framework recommendations (Svelte 5, React + Vite)
- Boilerplate templates

## GTA V & FiveM Natives

See [natives-reference.md](./natives-reference.md) for:
- 45 namespaces overview (44 GTA V + 1 CFX)
- Most used natives by category (Player, Ped, Entity, Vehicle, Blips, Streaming)
- Native optimization table (cache.ped, joaat, vector math)
- CFX-specific natives (StateBags, NUI, Events)
- Full reference links to docs.fivem.net/natives/

## Debugging

See [debugging.md](./debugging.md) for:
- Toggle debug mode pattern
- Performance profiling (`os.clock`, `GetGameTimer`, `resmon`)
- Common errors and fixes
- Error handling patterns (`pcall`, assert, error values)
- `dolu_tool` for in-game development
