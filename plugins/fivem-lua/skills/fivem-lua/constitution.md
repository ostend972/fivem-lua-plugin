# Constitution

Core principles for every FiveM Lua script. These rules are **NON-NEGOTIABLE**. Violations cause crashes, exploits, or unacceptable performance.

---

## NEVER Rules

Rules that must **NEVER** be violated under any circumstance.

---

### NEVER 1: Loop Without Wait

A `while true` loop without `Wait()` runs every single frame with zero yielding. The game engine never gets a chance to process anything else. This **will** freeze and crash the client or server within seconds. There is no exception to this rule.

Bad:

```lua
CreateThread(function()
    while true do
        -- No Wait = GUARANTEED CRASH
        -- The thread never yields, the engine locks up
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
    end
end)
```

Good:

```lua
CreateThread(function()
    while true do
        Wait(0) -- Minimum: yields for one frame (~16ms)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
    end
end)
```

Better (when real-time is not needed):

```lua
CreateThread(function()
    while true do
        Wait(1000) -- Check once per second, not 60 times per second
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
    end
end)
```

---

### NEVER 2: Trust Client Data

Client data can **always** be spoofed by cheaters. Modded clients can trigger any event with any arguments. Money amounts, item counts, coordinates, weapon hashes sent from the client are **never** trustworthy.

Bad:

```lua
-- CLIENT
TriggerServerEvent('shop:buy', 'bread', 0) -- Cheater sends price = 0

-- SERVER
RegisterNetEvent('shop:buy', function(item, price)
    -- Trusting client-sent price = free items for cheaters
    RemoveMoney(source, price)
    AddItem(source, item)
end)
```

Good:

```lua
-- CLIENT
TriggerServerEvent('shop:buy', 'bread') -- Client only sends WHAT, never HOW MUCH

-- SERVER
local Prices <const> = {
    bread = 5,
    water = 3,
    medkit = 50,
}

RegisterNetEvent('shop:buy', function(item)
    local src = source
    local price = Prices[item]

    if not price then return end -- Item doesn't exist in price table

    local money = GetPlayerMoney(src)
    if money < price then return end -- Can't afford

    RemoveMoney(src, price)  -- Server looks up the real price
    AddItem(src, item)
end)
```

---

### NEVER 3: Use Global Variables Without Justification

`local` variables are faster due to Lua's register-based VM. Globals are stored in the environment table, requiring a hash lookup every access. Globals also leak across files in the same resource, causing name collisions and unpredictable bugs.

Bad:

```lua
playerPed = PlayerPedId()       -- Global, leaks across all files
isNearShop = false              -- Global, any file can overwrite it
counter = 0                     -- Global, name collision guaranteed

function DoSomething()          -- Global function, pollutes environment
    counter = counter + 1
end
```

Good:

```lua
local playerPed = PlayerPedId()    -- Local, scoped to this file
local isNearShop = false           -- Local, safe from collisions
local counter = 0                  -- Local, fast access

local function doSomething()       -- Local function, not exported
    counter = counter + 1
end
```

The only valid globals are intentional exports: `Config`, framework shared objects, and explicitly documented API functions.

---

### NEVER 4: Use Deprecated Natives

Deprecated natives are slower, less readable, and may be removed in future FiveM builds. Use the modern replacements.

| Deprecated | Replacement | Why |
|---|---|---|
| `GetPlayerPed(-1)` | `PlayerPedId()` | Faster, cleaner |
| `GetDistanceBetweenCoords(...)` | `#(vec1 - vec2)` | 10x faster vector math |
| `GetHashKey('model')` | `joaat('model')` | Faster hash |
| `table.insert(t, v)` | `t[#t + 1] = v` | Less overhead |
| `Citizen.CreateThread` | `CreateThread` | Alias, shorter |
| `Citizen.Wait` | `Wait` | Alias, shorter |

Bad:

```lua
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = GetPlayerPed(-1)
        local coords = GetEntityCoords(ped)
        local shopCoords = vector3(100.0, 200.0, 30.0)
        local dist = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, shopCoords.x, shopCoords.y, shopCoords.z, true)
        local hash = GetHashKey('prop_atm_01')
    end
end)
```

Good:

```lua
local SHOP_COORDS <const> = vec3(100.0, 200.0, 30.0)
local ATM_HASH <const> = joaat('prop_atm_01')

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - SHOP_COORDS)
    end
end)
```

---

### NEVER 5: Handle Money/Items/Weapons Client-Side

All financial, inventory, and weapon operations **must** happen server-side. The client can only **request** an action. The server **validates** and **executes**.

Bad:

```lua
-- CLIENT: directly giving money/items = instant exploit
RegisterNetEvent('reward:give', function()
    ESX.SetPlayerData('money', ESX.GetPlayerData().money + 50000)
    -- Cheater can trigger this event whenever they want
end)
```

Good:

```lua
-- CLIENT: only sends a request
TriggerServerEvent('reward:claim', rewardId)

-- SERVER: validates everything, then executes
RegisterNetEvent('reward:claim', function(rewardId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end
    if not IsRewardValid(src, rewardId) then return end
    if HasAlreadyClaimed(src, rewardId) then return end

    xPlayer.addMoney(50000)
    MarkRewardClaimed(src, rewardId)
end)
```

---

### NEVER 6: Use `AddEventHandler` for Client-to-Server Events

`AddEventHandler` registers a handler for same-context events only (client-to-client or server-to-server). It does **not** accept network events. For any event sent across the network (client to server, server to client), you **must** use `RegisterNetEvent`.

Using `AddEventHandler` for network events silently fails -- the handler never fires and you get no error.

Bad:

```lua
-- SERVER: this will NEVER fire from a client TriggerServerEvent
AddEventHandler('myScript:buyItem', function(item)
    -- Dead code. Client events never reach this handler.
end)
```

Good:

```lua
-- SERVER: RegisterNetEvent makes this reachable from clients
RegisterNetEvent('myScript:server:buyItem', function(item)
    local src = source
    -- This handler actually receives client events
end)
```

Same-context usage (this is where `AddEventHandler` is correct):

```lua
-- SERVER to SERVER (same context, no network)
AddEventHandler('txAdmin:events:serverShuttingDown', function()
    print('Server shutting down')
end)

-- Resource lifecycle events (same context)
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('Resource started')
    end
end)
```

---

### NEVER 7: Expose Sensitive Data in Shared Scripts

Files declared as `shared_scripts` in `fxmanifest.lua` are loaded on **both** client and server. Anything in a shared script is fully visible to every connected client. Cheaters can read these files directly.

Bad:

```lua
-- config.lua (loaded as shared_script)
Config = {}
Config.WebhookURL = 'https://discord.com/api/webhooks/1234/abcdef'  -- Leaked
Config.DatabaseHost = '192.168.1.100'                                -- Leaked
Config.AdminSteamIds = { 'steam:110000100000001' }                   -- Leaked
Config.ApiKey = 'sk-live-abc123'                                     -- Leaked
```

Good:

```lua
-- config.lua (shared_script) - only non-sensitive data
Config = {}
Config.MaxDistance = 50.0
Config.ShopLocations = {
    vec3(100.0, 200.0, 30.0),
    vec3(300.0, 400.0, 30.0),
}
Config.Prices = {
    bread = 5,
    water = 3,
}

-- sv_config.lua (server_script) - sensitive data stays server-only
ServerConfig = {}
ServerConfig.WebhookURL = 'https://discord.com/api/webhooks/1234/abcdef'
ServerConfig.AdminSteamIds = { 'steam:110000100000001' }
```

---

### NEVER 8: Use mysql-async

`mysql-async` is deprecated, unmaintained, and lacks modern features. Use `oxmysql` -- it provides async queries, prepared statements, connection pooling, and is actively maintained by the Overextended community.

Bad:

```lua
-- fxmanifest.lua
server_scripts {
    '@mysql-async/lib/MySQL.lua', -- Deprecated, unmaintained
    'sv_main.lua',
}

-- sv_main.lua
MySQL.Async.fetchAll('SELECT * FROM users WHERE id = @id', { ['@id'] = playerId }, function(results)
    -- Callback hell, no prepared statements
end)
```

Good:

```lua
-- fxmanifest.lua
server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Modern, maintained, performant
    'sv_main.lua',
}

-- sv_main.lua (callback style)
MySQL.query('SELECT * FROM users WHERE id = ?', { playerId }, function(results)
    if not results or #results == 0 then return end
    local user = results[1]
end)

-- sv_main.lua (async style - cleaner)
local results = MySQL.query.await('SELECT * FROM users WHERE id = ?', { playerId })
if not results or #results == 0 then return end
local user = results[1]
```

---

### NEVER 9: Use the Old ESX Import Method

The legacy `TriggerEvent('esx:getSharedObject')` import method is deprecated, slower, and unreliable during resource restarts. The exports method is instant and always returns the current object.

Bad:

```lua
local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)
-- ESX might still be nil if the event hasn't fired yet
```

Good:

```lua
ESX = exports['es_extended']:getSharedObject()
-- Immediate, synchronous, always returns the object
```

For QBCore, same principle:

```lua
-- Good
local QBCore = exports['qb-core']:GetCoreObject()
```

---

### NEVER 10: Forget to Validate `source` in Server Events

`source` identifies the player who triggered a server event. It can be `nil` during resource start, `0` from server console, or reference a player who disconnected between the event being sent and processed. Always validate before using.

Bad:

```lua
RegisterNetEvent('myScript:server:saveData', function(data)
    -- source could be nil, 0, or a disconnected player
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.setMoney(data.money) -- CRASH if xPlayer is nil
end)
```

Good:

```lua
RegisterNetEvent('myScript:server:saveData', function(data)
    local src = source -- Cache immediately, source can change in async contexts

    if not src or src <= 0 then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if type(data) ~= 'table' then return end
    if type(data.money) ~= 'number' then return end
    if data.money < 0 then return end

    xPlayer.setMoney(data.money)
end)
```

---

## ALWAYS Rules

Rules that must **ALWAYS** be followed.

---

### ALWAYS 1: Use Lua 5.4

In `fxmanifest.lua`, always enable Lua 5.4. It provides `<const>` and `<close>` annotations, compound assignment operators (`+=`, `-=`), generational garbage collection, integer/float distinction, and measurably better performance.

```lua
-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes' -- REQUIRED: enables Lua 5.4 features
```

Without `lua54 'yes'`, you are running Lua 5.3 and lose access to `<const>`, `<close>`, and performance improvements.

---

### ALWAYS 2: Use `local` for Everything

Every variable and every function should be `local` unless it is an intentional export.

```lua
-- Variables: always local
local playerPed = PlayerPedId()
local coords = GetEntityCoords(playerPed)
local isReady = false

-- Functions: always local
local function calculateDistance(a, b)
    return #(a - b)
end

-- Tables: always local
local cache = {}

-- Loop variables are automatically local
for i = 1, 10 do
    -- i is local to this loop
end

for _, player in ipairs(GetPlayers()) do
    -- player is local to this loop
end
```

The only valid globals are `Config` tables for resource configuration and explicitly documented API functions that other resources need to call.

---

### ALWAYS 3: Use `<const>` for Constants

Values that never change after assignment must be marked with `<const>`. This prevents accidental reassignment and signals intent to other developers. Requires Lua 5.4.

```lua
local MAX_DISTANCE <const> = 50.0
local ITEM_NAME <const> = 'bread'
local MAX_PLAYERS <const> = 128
local SHOP_MODEL <const> = joaat('prop_shop_front')
local DEFAULT_COORDS <const> = vec3(100.0, 200.0, 30.0)

-- Attempting to reassign will throw an error at runtime
MAX_DISTANCE = 100.0 -- ERROR: attempt to assign to const variable 'MAX_DISTANCE'
```

Use `<const>` for:
- Distances, thresholds, limits
- Model hashes, item names, event names
- Coordinates that never change
- Configuration values read once at startup

---

### ALWAYS 4: Use Dynamic Wait in Proximity Loops

Loops that check player distance to a point should use a large wait when far away and a small wait when close. This saves massive CPU when the player is nowhere near the target.

Bad:

```lua
CreateThread(function()
    while true do
        Wait(0) -- 60 checks per second, always, even when 500m away
        local coords = GetEntityCoords(PlayerPedId())
        local dist = #(coords - SHOP_COORDS)
        if dist < 2.0 then
            -- Show interaction
        end
    end
end)
```

Good:

```lua
local SHOP_COORDS <const> = vec3(100.0, 200.0, 30.0)
local MAX_DISTANCE <const> = 50.0

CreateThread(function()
    while true do
        local sleep = 2500 -- Default: check every 2.5 seconds when far
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - SHOP_COORDS)

        if dist < MAX_DISTANCE then
            sleep = 500 -- Getting closer, check more often
        end

        if dist < 10.0 then
            sleep = 100 -- Near the shop, check frequently
        end

        if dist < 2.0 then
            sleep = 0 -- Right at the shop, check every frame for interaction
            -- Draw marker, show help text, handle input
            DrawMarker(1, SHOP_COORDS.x, SHOP_COORDS.y, SHOP_COORDS.z, --[[ ... ]])
            if IsControlJustPressed(0, 38) then -- E key
                TriggerServerEvent('shop:server:open')
            end
        end

        Wait(sleep)
    end
end)
```

---

### ALWAYS 5: Cache Frequently Used Values

Natives like `PlayerPedId()` and `GetEntityCoords()` are relatively expensive when called every frame. Cache values that don't change within a tick or that change infrequently.

Bad:

```lua
CreateThread(function()
    while true do
        Wait(0)
        -- Calling PlayerPedId() 4 times per frame
        local coords = GetEntityCoords(PlayerPedId())
        local health = GetEntityHealth(PlayerPedId())
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local weapon = GetSelectedPedWeapon(PlayerPedId())
    end
end)
```

Good:

```lua
-- Cache the framework object once at resource start
local ESX <const> = exports['es_extended']:getSharedObject()

CreateThread(function()
    while true do
        Wait(0)
        -- Call PlayerPedId() once, reuse the value
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local health = GetEntityHealth(ped)
        local vehicle = GetVehiclePedIsIn(ped, false)
        local weapon = GetSelectedPedWeapon(ped)
    end
end)
```

For values that change less often, cache with a refresh interval:

```lua
local cachedPed = PlayerPedId()

CreateThread(function()
    while true do
        Wait(1000) -- Refresh ped reference every second
        cachedPed = PlayerPedId()
    end
end)
```

---

### ALWAYS 6: Use `fx_version 'cerulean'`

`cerulean` is the latest stable `fx_version`. It is required for modern FiveM features including `RegisterNetEvent` shorthand, `ox_lib` compatibility, and current Lua 5.4 support.

```lua
-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'my-resource'
description 'A well-structured resource'
author 'Author Name'
version '1.0.0'
```

Do not use `adamant`, `bodacious`, or any older fx_version.

---

### ALWAYS 7: Validate Server-Side Before Any Action

Every server event handler must follow this validation checklist before executing any game logic:

```lua
RegisterNetEvent('myScript:server:performAction', function(targetId, itemName, amount)
    local src = source

    -- 1. Player exists?
    if not src or src <= 0 then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- 2. Permissions?
    if not HasPermission(src, 'canPerformAction') then return end

    -- 3. Proximity? (if action requires being near something)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    if #(playerCoords - targetCoords) > 5.0 then return end

    -- 4. Data valid? (type checks, range checks)
    if type(itemName) ~= 'string' then return end
    if type(amount) ~= 'number' then return end
    if amount <= 0 or amount > 100 then return end
    if math.floor(amount) ~= amount then return end -- Must be integer

    -- 5. Cooldown? (prevent spam)
    if IsOnCooldown(src, 'performAction') then return end
    SetCooldown(src, 'performAction', 5000) -- 5 second cooldown

    -- 6. Execute
    xPlayer.removeInventoryItem(itemName, amount)
    TriggerClientEvent('myScript:client:actionResult', src, true)
end)
```

The order matters. Check cheapest validations first (existence, type checks) before expensive ones (database queries, distance calculations).

---

### ALWAYS 8: Use Naming Conventions

Consistent naming makes code readable and prevents conflicts.

| Element | Convention | Example |
|---|---|---|
| Local variables | camelCase | `local playerPed` |
| Local functions | camelCase | `local function getData()` |
| Global variables | PascalCase | `Config` |
| Global functions | PascalCase | `function GetPlayerLevel()` |
| Constants | UPPER_SNAKE_CASE | `local MAX_HP <const> = 100` |
| Events | resource:context:action | `'myScript:server:buyItem'` |
| Files | lowercase or kebab-case | `cl_main.lua`, `sv_main.lua` |

Event naming breakdown:

```lua
-- Pattern: 'resourceName:context:action'
-- context = server, client, or shared

-- Server events (client triggers, server handles)
RegisterNetEvent('myShop:server:buyItem', function(itemName) end)
RegisterNetEvent('myShop:server:sellItem', function(itemName, amount) end)

-- Client events (server triggers, client handles)
RegisterNetEvent('myShop:client:openMenu', function(shopData) end)
RegisterNetEvent('myShop:client:notify', function(message) end)
```

File naming:

```
cl_main.lua       -- Client entry point
sv_main.lua       -- Server entry point
sh_config.lua     -- Shared config
cl_shop.lua       -- Client shop logic
sv_shop.lua       -- Server shop logic
sv_commands.lua   -- Server commands
```

---

### ALWAYS 9: Document Functions

Use the `---` annotation format. This enables IDE intellisense in VS Code with the Lua Language Server extension.

```lua
--- Calculates the distance between a player and a set of coordinates.
--- Returns -1.0 if the player ped is invalid.
--- @param playerId number The server-side player ID
--- @param targetCoords vector3 The target position
--- @return number distance The distance in game units
local function getPlayerDistance(playerId, targetCoords)
    local ped = GetPlayerPed(playerId)
    if not DoesEntityExist(ped) then return -1.0 end

    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - targetCoords)
end

--- Checks if a player has enough money for a purchase.
--- @param src number The player source ID
--- @param price number The required amount
--- @return boolean canAfford Whether the player can afford it
local function canAfford(src, price)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    return xPlayer.getMoney() >= price
end

--- Formats a number as a currency string.
--- @param amount number The amount to format
--- @return string formatted The formatted string (e.g., "$1,234")
local function formatMoney(amount)
    local formatted = tostring(math.floor(amount))
    formatted = formatted:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return '$' .. formatted
end
```

---

### ALWAYS 10: Use Early Returns

Deeply nested `if` blocks are hard to read and error-prone. Use early returns to handle edge cases first, keeping the main logic at the lowest indentation level.

Bad:

```lua
local function processTransaction(src, itemName, amount)
    if src then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            local price = Prices[itemName]
            if price then
                local totalCost = price * amount
                if xPlayer.getMoney() >= totalCost then
                    if amount > 0 and amount <= 100 then
                        xPlayer.removeMoney(totalCost)
                        xPlayer.addInventoryItem(itemName, amount)
                        return true
                    end
                end
            end
        end
    end
    return false
end
```

Good:

```lua
local function processTransaction(src, itemName, amount)
    if not src then return false end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local price = Prices[itemName]
    if not price then return false end

    if amount <= 0 or amount > 100 then return false end

    local totalCost = price * amount
    if xPlayer.getMoney() < totalCost then return false end

    xPlayer.removeMoney(totalCost)
    xPlayer.addInventoryItem(itemName, amount)
    return true
end
```

---

## Quality Gates

Before considering a script complete, every item must pass:

- [ ] All loops have `Wait()` with appropriate sleep values
- [ ] All money/item operations are server-side
- [ ] All events validate `source` and input
- [ ] No global variables without justification
- [ ] No deprecated natives
- [ ] Config values externalized (not hardcoded)
- [ ] Lua 5.4 enabled in fxmanifest (`lua54 'yes'`)
- [ ] Sensitive data not in shared scripts
- [ ] Functions documented with `---`
- [ ] No `console.log`/`print` in production (use debug toggle)
