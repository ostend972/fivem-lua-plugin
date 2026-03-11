# Script Structure

## Project Structure

Show the standard folder structure:

```
mon-script/
├── fxmanifest.lua
├── config.lua
├── client/
│   ├── main.lua
│   ├── events.lua
│   └── utils.lua
├── server/
│   ├── main.lua
│   ├── callbacks.lua
│   └── events.lua
├── shared/
│   └── config.lua
├── locales/
│   ├── en.lua
│   └── fr.lua
└── html/                   # Only if NUI needed
    ├── index.html
    ├── style.css
    └── script.js
```

Explain each folder's role.

## fxmanifest.lua

### Complete Template

```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AuthorName'
description 'Script description'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',     -- If using ox_lib
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/events.lua',
    'client/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- If using database
    'server/main.lua',
    'server/callbacks.lua',
    'server/events.lua',
}

dependencies {
    'ox_lib',               -- Adapt to your needs
    'oxmysql',
}

-- ui_page 'html/index.html' -- Uncomment if NUI
-- files { 'html/index.html', 'html/style.css', 'html/script.js' }

-- For ESX:
-- shared_scripts { '@es_extended/imports.lua', '@es_extended/locale.lua' }
-- dependencies { 'es_extended' }

-- For QBCore:
-- dependencies { 'qb-core' }

-- For QBOX:
-- dependencies { 'qbx_core' }
```

### Key Fields Reference Table

| Field | Purpose | Required |
|---|---|---|
| `fx_version` | FiveM API version, always 'cerulean' | Yes |
| `game` | Target game, 'gta5' | Yes |
| `lua54` | Enable Lua 5.4, always 'yes' | Yes |
| `shared_scripts` | Scripts loaded on BOTH client and server | No |
| `client_scripts` | Scripts loaded on client only | No |
| `server_scripts` | Scripts loaded on server only | No |
| `dependencies` | Resources that must start before this one | No |
| `ui_page` | HTML entry point for NUI | No |
| `files` | Files accessible by client (NUI assets) | No |
| `server_exports` | Functions exported server-side | No |
| `exports` | Functions exported client-side | No |

### Security Rules for fxmanifest

- NEVER put sensitive data scripts in `shared_scripts` (visible to all clients)
- NEVER put server logic in `client_scripts`
- API keys, webhooks, DB credentials go in `server_scripts` ONLY
- Config with sensitive data: use `sv_config.lua` in server_scripts, not shared

## File Naming Conventions

| Pattern | Example | Usage |
|---|---|---|
| `client/main.lua` | Main client entry point | Folder-based (recommended) |
| `cl_main.lua` | Client main (flat) | Prefix-based (alternative) |
| `sv_main.lua` | Server main (flat) | Prefix-based (alternative) |
| `sh_config.lua` | Shared config (flat) | Prefix-based (alternative) |

Prefer folder-based structure for scripts with 3+ files. Use prefix-based for simple scripts.

## Config Pattern

Show the standard Config table pattern:

```lua
Config = {}

Config.Debug = false
Config.Framework = 'esx' -- 'esx', 'qbcore', 'qbox'

Config.Locations = {
    shop = vector3(441.1, -981.1, 30.7),
    garage = vector3(215.5, -795.3, 30.7),
}

Config.Items = {
    { name = 'water', label = 'Water', price = 5 },
    { name = 'bread', label = 'Bread', price = 3 },
}

Config.MaxDistance = 10.0
Config.Cooldown = 5 -- seconds
```

Explain:
- Config is a global table (intentionally global for cross-file access)
- Use descriptive keys
- Group related values
- Put ALL configurable values here (never hardcode)

## Resource Start Order

When using the Ox ecosystem, resources MUST start in this order in server.cfg:

```
ensure oxmysql
ensure ox_lib
ensure [framework]      # es_extended / qb-core / qbx_core
ensure ox_inventory
ensure ox_target
ensure [your_scripts]
```

Use direct, factual style with Bad/Good examples where relevant. No unnecessary prose.
