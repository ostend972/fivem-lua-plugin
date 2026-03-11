# Implementation Plan: {{SCRIPT_NAME}}

## Summary
- **Resource name**: {{name}}
- **Framework**: {{ESX/QBCore/QBOX}}
- **Estimated files**: {{count}}
- **Dependencies**: {{list}}
- **Complexity**: {{Simple / Medium / Complex}}

## Constitution Compliance
| Rule | Status | Notes |
|------|--------|-------|
| lua54 'yes' in manifest | {{✓/✗}} | {{notes}} |
| No client money/items | {{✓/✗}} | {{notes}} |
| Server-side validation | {{✓/✗}} | {{notes}} |
| Dynamic Wait() | {{✓/✗}} | {{notes}} |
| No globals | {{✓/✗}} | {{notes}} |
| Prepared statements | {{✓/✗}} | {{notes}} |

## Project Structure
```
{{resource_name}}/
├── fxmanifest.lua
├── config/
│   └── config.lua
├── client/
│   └── main.lua
├── server/
│   └── main.lua
├── shared/
│   └── utils.lua
├── locales/
│   ├── en.lua
│   └── fr.lua
└── sql/
    └── install.sql
```

## fxmanifest.lua Plan
```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name '{{resource_name}}'
description '{{description}}'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}
```

## Technical Decisions

### Framework Integration
- Initialization: {{pattern}}
- Player data: {{method}}
- Callbacks: {{system}}

### Performance Strategy
- Thread management: {{approach}}
- Native caching: {{which natives}}
- ox_lib cache: {{usage}}

### Security Strategy
- Server validation: {{approach}}
- Event protection: {{method}}
- Anti-exploit: {{measures}}

### Database Design
- Tables: {{list}}
- Query patterns: {{approach}}

### State Management
- State bags: {{usage}}
- Events: {{list}}
- Exports: {{list}}

## Architecture
```
Client                    Server                    Database
  │                         │                         │
  │── TriggerServerEvent ──→│                         │
  │                         │── MySQL.query ─────────→│
  │                         │←── result ──────────────│
  │←── TriggerClientEvent ──│                         │
```

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| {{risk}} | {{level}} | {{mitigation}} |
