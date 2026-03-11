---
description: Generate a technical implementation plan for a FiveM Lua script from the specification.
handoffs:
  - label: Generate Tasks
    agent: fivem.tasks
    prompt: Break the plan into implementation tasks
    send: true
  - label: Review Plan
    agent: fivem.review
    prompt: Review the plan against FiveM best practices
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Load context**:
   - Read `specs/spec.md` for requirements
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/constitution.md` for non-negotiable rules
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/script-structure.md` for project structure
   - Read framework-specific patterns based on spec (esx-patterns.md or qbcore-patterns.md)
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/performance.md` for optimization patterns
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/security.md` for security patterns
   - If NUI needed: Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/nui-patterns.md`
   - If database needed: Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/database.md`
   - If state sync needed: Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/state-sync.md`
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/ox-ecosystem.md` for ox_lib patterns

2. **Constitution Check**: Verify the plan respects ALL constitution rules:
   - NEVER rules: confirm none are violated
   - ALWAYS rules: confirm all are followed
   - If any violation found: ERROR with specific rule reference

3. **Generate plan.md** in `specs/plan.md`:

```markdown
# Implementation Plan: [SCRIPT NAME]

## Summary
- **Resource name**: [name]
- **Framework**: [ESX/QBCore/QBOX]
- **Estimated files**: [count]
- **Dependencies**: [list]
- **Complexity**: [Simple / Medium / Complex]

## Constitution Compliance
| Rule | Status | Notes |
|------|--------|-------|
| lua54 'yes' in manifest | ✓ | Will use Lua 5.4 features |
| No client money/items | ✓ | All handled server-side |
| Server-side validation | ✓ | 6-step checklist applied |
| [etc.] | | |

## Project Structure
```
[resource_name]/
├── fxmanifest.lua
├── config/
│   └── config.lua          -- Config = {} shared config
├── client/
│   ├── main.lua            -- Client entry point
│   └── [feature].lua       -- Feature modules
├── server/
│   ├── main.lua            -- Server entry point
│   └── [feature].lua       -- Feature modules
├── shared/
│   └── utils.lua           -- Shared utilities (if needed)
├── locales/
│   ├── en.lua
│   └── fr.lua
├── sql/
│   └── install.sql         -- Database schema
└── html/                   -- NUI (if needed)
    ├── index.html
    ├── css/
    ├── js/
    └── [framework]/        -- Svelte/React source
```

## fxmanifest.lua Plan
```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name '[resource_name]'
description '[description]'
author '[author]'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',     -- if using ox_lib
    'config/config.lua',
}

client_scripts {
    'client/main.lua',
    -- additional client files
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- if using database
    'server/main.lua',
    -- additional server files
}

-- NUI (if needed)
-- ui_page 'html/index.html'
-- files { 'html/**/*' }
```

## Technical Decisions

### Framework Integration
- Initialization pattern: [exports pattern]
- Player data access: [method]
- Callback system: [ox_lib callbacks / framework callbacks]

### Performance Strategy
- Thread management: [Dynamic Wait / Job-conditional / etc.]
- Native caching: [Which natives to cache]
- ox_lib cache usage: [cache.ped, cache.coords, etc.]
- Proximity optimization: [Distance checks with squared distance]

### Security Strategy
- Server validation: [6-step checklist application]
- Event protection: [RegisterNetEvent patterns]
- Anti-exploit: [Cooldowns, proximity checks, rate limiting]

### Database Design (if applicable)
- Tables: [list with columns]
- Query patterns: [prepared statements, transactions]
- Migrations: [install.sql approach]

### State Management
- State bags: [which data uses state bags]
- Events: [client → server events list]
- Exports: [shared exports list]

### NUI Design (if applicable)
- Framework: [Svelte 5 / React + Vite]
- Communication: [SendNUIMessage / RegisterNUICallback patterns]
- Pages: [list of views]

## Architecture Diagram
```
[ASCII diagram showing client ↔ server ↔ database flow]
```

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| [risk] | [high/medium/low] | [mitigation] |
```

4. **Research phase** (if unknowns exist):
   - Research any NEEDS CLARIFICATION items
   - Use context7 for up-to-date documentation
   - Use web search for FiveM-specific patterns
   - Document findings in plan

5. **Report**: Output plan path, structure, dependency list, and readiness for `/fivem.tasks`.

## Key Rules

- Every file in the plan must map to a constitution rule
- Performance patterns must be specific (not generic "optimize")
- Security patterns must reference the 6-step validation checklist
- Database queries must use prepared statements (oxmysql)
- Client/server split must be explicit for every feature
