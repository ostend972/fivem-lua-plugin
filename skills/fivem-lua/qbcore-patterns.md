# QBCore Patterns

QBCore and QBOX framework patterns and API reference.

## Initialization

```lua
-- Client or Server (top of file, cached once)
local QBCore = exports['qb-core']:GetCoreObject()

-- QBOX alternative:
-- local QBCore = exports['qbx_core']:GetCoreObject()
```

Cache the core object in a local variable at the top of the file. NEVER call exports every time you need it.

```lua
-- BAD: Getting core object inside every handler
RegisterNetEvent('myScript:server:doSomething', function()
    local QBCore = exports['qb-core']:GetCoreObject() -- Wasteful export call every time
    local Player = QBCore.Functions.GetPlayer(source)
end)

-- GOOD: Cache once, reuse everywhere
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('myScript:server:doSomething', function()
    local Player = QBCore.Functions.GetPlayer(source)
end)
```

## fxmanifest.lua for QBCore

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
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'qb-core',    -- or 'qbx_core' for QBOX
    'oxmysql',
}
```

QBCore does NOT need `shared_scripts` imports like ESX. The core object is accessed via exports only. No `@qb-core/...` import exists or is needed.

## Player Functions API (Server-Side)

### Getting a Player

```lua
-- By source (server ID)
local Player = QBCore.Functions.GetPlayer(source)
if not Player then return end

-- By CitizenID (offline or online)
local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)

-- By Phone number
local Player = QBCore.Functions.GetPlayerByPhone(phone)

-- Get all online players (returns table of Player objects keyed by source)
local players = QBCore.Functions.GetQBPlayers()
for src, Player in pairs(players) do
    print(Player.PlayerData.charinfo.firstname)
end
```

Always nil-check the result. `GetPlayer` returns `nil` if the source is invalid or the player is not loaded.

### Money Operations

Money types: `'cash'`, `'bank'`, `'crypto'` (and custom types defined in shared config).

```lua
-- Get
local cash = Player.Functions.GetMoney('cash')
local bank = Player.Functions.GetMoney('bank')

-- Add (reason is optional but recommended for logging)
Player.Functions.AddMoney('cash', 1000, 'salary-payment')
Player.Functions.AddMoney('bank', 5000, 'atm-deposit')

-- Remove
Player.Functions.RemoveMoney('cash', 500, 'shop-purchase')

-- Set (overwrites current amount)
Player.Functions.SetMoney('cash', 2000)
```

The `reason` string is logged by QBCore for admin review. Always include a descriptive reason for audit trails.

### Item Operations

```lua
-- Add items
Player.Functions.AddItem('bread', 5)

-- Remove items
Player.Functions.RemoveItem('bread', 2)

-- Get single item (returns item table or nil)
local item = Player.Functions.GetItemByName('bread')
if item then
    print(item.amount)    -- Current count
    print(item.name)      -- 'bread'
    print(item.slot)      -- Inventory slot number
end

-- Get all stacks of an item (returns table of items)
local items = Player.Functions.GetItemsByName('bread')

-- Check if player has item
local hasItem = Player.Functions.HasItem('bread')       -- Returns item or false
local hasEnough = Player.Functions.HasItem('bread', 3)  -- Has at least 3?
```

Item operations are server-side only. The client requests, the server validates and executes. See the shop example below.

### Job & Gang

```lua
-- Job data
Player.PlayerData.job                    -- Full table: { name, label, grade, onduty, ... }
Player.PlayerData.job.name               -- 'police'
Player.PlayerData.job.label              -- 'Law Enforcement'
Player.PlayerData.job.grade.name         -- 'sergeant'
Player.PlayerData.job.grade.level        -- 4
Player.PlayerData.job.onduty             -- true/false
Player.PlayerData.job.isboss             -- true/false

-- Set job (name, grade level)
Player.Functions.SetJob('police', 2)

-- Gang data
Player.PlayerData.gang                   -- Full table: { name, label, grade, ... }
Player.PlayerData.gang.name              -- 'ballas'
Player.PlayerData.gang.grade.level       -- 1

-- Set gang (name, grade level)
Player.Functions.SetGang('ballas', 1)
```

### Metadata

Metadata stores arbitrary per-player data (hunger, thirst, stress, armor, custom values).

```lua
-- Set metadata
Player.Functions.SetMetaData('hunger', 100)
Player.Functions.SetMetaData('stress', 0)

-- Get metadata
local hunger = Player.Functions.GetMetaData('hunger')

-- Access full metadata table
local meta = Player.PlayerData.metadata
local thirst = meta['thirst']
local isHandcuffed = meta['ishandcuffed']
```

Default QBCore metadata keys: `hunger`, `thirst`, `stress`, `armor`, `ishandcuffed`, `tracker`, `injail`, `jailitems`, `status`, `phone`, `fitbit`, `bloodtype`, `dealerrep`, `craftingrep`, `attachmentcraftingrep`, `currentapartment`, `jobrep`.

### Identity

```lua
Player.PlayerData.citizenid              -- Unique character ID (e.g., 'ABC12345')
Player.PlayerData.license                -- Rockstar license
Player.PlayerData.source                 -- Server ID (same as source)

-- Character info
Player.PlayerData.charinfo               -- { firstname, lastname, birthdate, gender, nationality, phone, account }
Player.PlayerData.charinfo.firstname     -- 'John'
Player.PlayerData.charinfo.lastname      -- 'Doe'
Player.PlayerData.charinfo.birthdate     -- '1990-01-15'
Player.PlayerData.charinfo.gender        -- 0 (male) or 1 (female)
Player.PlayerData.charinfo.phone         -- Phone number string
Player.PlayerData.charinfo.account       -- Bank account number
```

### Save & Update

```lua
Player.Functions.Save()                  -- Save all player data to database
Player.Functions.UpdatePlayerData()      -- Sync current data to client
```

Call `UpdatePlayerData()` after modifying `PlayerData` directly to push changes to the client. Standard functions like `AddMoney`, `SetJob`, etc. call this automatically.

## Callbacks

### Server Callback (Server defines, Client triggers)

```lua
-- SERVER: Define the callback
QBCore.Functions.CreateCallback('myScript:server:getData', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return cb(nil) end

    cb({
        name = Player.PlayerData.charinfo.firstname,
        money = Player.Functions.GetMoney('cash'),
        job = Player.PlayerData.job.name,
    })
end)

-- CLIENT: Trigger and receive data
QBCore.Functions.TriggerCallback('myScript:server:getData', function(data)
    if not data then return end
    print('Name: ' .. data.name)
    print('Cash: ' .. data.money)
end)
```

Callbacks are the safe way to fetch server data from the client. The client sends a request, the server processes it and sends back a response. Unlike events, callbacks guarantee a response.

### Server Callback with Arguments

```lua
-- SERVER: Callback with extra parameters
QBCore.Functions.CreateCallback('myScript:server:getItemPrice', function(source, cb, itemName)
    local price = Config.Prices[itemName]
    if not price then return cb(nil) end
    cb(price)
end)

-- CLIENT: Pass arguments after the callback function
QBCore.Functions.TriggerCallback('myScript:server:getItemPrice', function(price)
    if not price then
        print('Item not found')
        return
    end
    print('Price: $' .. price)
end, 'bread') -- extra argument passed to server
```

### Client Callback (QBOX / modern QBCore)

Modern QBCore and QBOX support client callbacks -- the server triggers a callback that the client handles and returns data.

```lua
-- CLIENT: Register a client callback
QBCore.Functions.CreateClientCallback('myScript:client:getCoords', function(cb)
    local coords = GetEntityCoords(PlayerPedId())
    cb(coords)
end)

-- SERVER: Trigger it (async, must be in a thread)
CreateThread(function()
    local coords = QBCore.Functions.TriggerClientCallback('myScript:client:getCoords', source)
    print(coords)
end)
```

## Client Events Reference

| Event | Trigger | Data |
|---|---|---|
| `QBCore:Client:OnPlayerLoaded` | Player fully loaded | None |
| `QBCore:Client:OnPlayerUnload` | Player unloaded/disconnecting | None |
| `QBCore:Client:OnJobUpdate` | Job changed | `function(JobInfo)` |
| `QBCore:Client:OnGangUpdate` | Gang changed | `function(GangInfo)` |
| `QBCore:Player:SetPlayerData` | Any player data change | `function(PlayerData)` |

### Client Lifecycle Pattern

```lua
local QBCore = exports['qb-core']:GetCoreObject()

local PlayerData = {}
local isLoggedIn = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
    PlayerData.gang = GangInfo
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)
```

This pattern keeps a local copy of player data on the client, always in sync.

### Modern Alternative: State Bags

For `isLoggedIn` state, state bags avoid event boilerplate:

```lua
-- Monitor login state via state bag
AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(cache.serverId), function(_bagName, _key, value)
    if value then
        -- Player just logged in
        PlayerData = QBCore.Functions.GetPlayerData()
    else
        -- Player logged out
        PlayerData = {}
    end
end)
```

State bags are reactive and automatically synced. Prefer them for state that multiple resources need to observe.

### Job-Conditional Thread

```lua
local function startPoliceThread()
    CreateThread(function()
        while PlayerData.job and PlayerData.job.name == 'police' do
            Wait(0)
            -- Police-only logic (radar, cuff system, etc.)
        end
        -- Thread exits naturally when job changes
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job and PlayerData.job.name == 'police' then
        startPoliceThread()
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    if JobInfo.name == 'police' then
        startPoliceThread()
    end
end)
```

When the player switches to a different job, the `while` condition fails and the thread exits. No wasted CPU cycles.

## Server Events Reference

| Event | Trigger | Data |
|---|---|---|
| `QBCore:Server:OnPlayerLoaded` | Player finishes loading | None (use `source`) |
| `QBCore:Server:OnPlayerUnload` | Player disconnects | `source` |
| `QBCore:Server:SetMetaData` | Metadata changed | `meta, data` |

### Server Player Lifecycle

```lua
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    print(Player.PlayerData.charinfo.firstname .. ' has loaded in')
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    -- Clean up any data for this player
    cooldowns[src] = nil
end)
```

Note: `OnPlayerUnload` uses `AddEventHandler` (not `RegisterNetEvent`) because it is a same-context server event, not a network event.

## Notifications

### QBCore Built-In

```lua
-- Server-side (sends to a specific player)
QBCore.Functions.Notify(source, 'Purchase successful!', 'success', 5000)
QBCore.Functions.Notify(source, 'Not enough money', 'error', 3000)
QBCore.Functions.Notify(source, 'Processing...', 'primary', 2000)
```

Notification types: `'success'`, `'error'`, `'primary'`, `'police'`.

### ox_lib Notifications (Preferred)

If using ox_lib, prefer its notification system for richer UI:

```lua
-- Client-side
lib.notify({
    title = 'Shop',
    description = 'Item purchased!',
    type = 'success',
    duration = 5000,
})

-- Server-side (to specific player)
TriggerClientEvent('ox_lib:notify', source, {
    title = 'Shop',
    description = 'Not enough money',
    type = 'error',
})
```

## QBOX Compatibility Notes

QBOX is backwards-compatible with most QBCore scripts. Key differences:

| Aspect | QBCore | QBOX |
|---|---|---|
| Core import | `exports['qb-core']:GetCoreObject()` | `exports['qbx_core']:GetCoreObject()` |
| Inventory | `qb-inventory` | `ox_inventory` |
| Target system | `qb-target` | `ox_target` |
| UI library | Custom / qb-menu | `ox_lib` natively |
| Notifications | `QBCore.Functions.Notify` | `ox_lib` notify |
| Phone | `qb-phone` | Various (qs-smartphone, lb-phone) |

Migration notes:
- Most QBCore events still work via QBOX's compatibility bridge
- `QBCore.Functions.*` API remains the same
- Player object API (`Player.Functions.*`) remains the same
- Prefer Ox exports when available for better performance and maintenance
- QBOX resources use `qbx_` prefix instead of `qb-`

## Common Patterns

### Complete Shop Example (QBCore)

A fully secured shop with config, client interaction, and server validation.

**config.lua** (shared):

```lua
Config = {}

Config.ShopLocation = vector3(24.47, -1346.62, 29.5)
Config.MaxDistance = 2.0

Config.Items = {
    { name = 'bread',  label = 'Bread',  price = 5 },
    { name = 'water',  label = 'Water',  price = 3 },
    { name = 'medkit', label = 'Medkit', price = 50 },
}
```

**client/main.lua**:

```lua
local QBCore = exports['qb-core']:GetCoreObject()

local SHOP_COORDS <const> = Config.ShopLocation

-- Proximity detection with dynamic sleep
CreateThread(function()
    while true do
        local sleep = 2500
        local coords = GetEntityCoords(PlayerPedId())
        local dist = #(coords - SHOP_COORDS)

        if dist < Config.MaxDistance then
            sleep = 0
            -- Show interaction prompt
            DrawText3D(SHOP_COORDS.x, SHOP_COORDS.y, SHOP_COORDS.z + 0.3, '[E] Open Shop')

            if IsControlJustPressed(0, 38) then -- E key
                openShopMenu()
            end
        elseif dist < 10.0 then
            sleep = 500
        end

        Wait(sleep)
    end
end)

local function openShopMenu()
    -- Build menu options from config
    local options = {}
    for _, item in ipairs(Config.Items) do
        options[#options + 1] = {
            title = item.label,
            description = ('$%d'):format(item.price),
            onSelect = function()
                TriggerServerEvent('myShop:server:buyItem', item.name)
            end,
        }
    end

    lib.registerContext({
        id = 'shop_menu',
        title = 'Shop',
        options = options,
    })
    lib.showContext('shop_menu')
end

--- Draws 3D text at world coordinates.
--- @param x number
--- @param y number
--- @param z number
--- @param text string
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end
```

**server/main.lua**:

```lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Build lookup table from config for O(1) access
local SHOP_ITEMS <const> = {}
for _, item in ipairs(Config.Items) do
    SHOP_ITEMS[item.name] = item
end

local SHOP_COORD <const> = Config.ShopLocation
local MAX_DISTANCE <const> = Config.MaxDistance + 5.0 -- Small buffer for network latency
local COOLDOWN <const> = 2 -- seconds
local cooldowns = {}

RegisterNetEvent('myShop:server:buyItem', function(itemName)
    local src = source

    -- 1. Player exists?
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- 2. Cooldown?
    if cooldowns[src] and (os.time() - cooldowns[src]) < COOLDOWN then return end
    cooldowns[src] = os.time()

    -- 3. Data valid? (item exists in server config)
    if type(itemName) ~= 'string' then return end
    local item = SHOP_ITEMS[itemName]
    if not item then return end

    -- 4. Proximity? (SERVER-SIDE coordinates)
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - SHOP_COORD) > MAX_DISTANCE then return end

    -- 5. Has enough money?
    if Player.Functions.GetMoney('cash') < item.price then
        QBCore.Functions.Notify(src, 'Not enough cash', 'error', 3000)
        return
    end

    -- 6. Execute
    Player.Functions.RemoveMoney('cash', item.price, 'shop-purchase-' .. itemName)
    Player.Functions.AddItem(itemName, 1)
    QBCore.Functions.Notify(src, 'Purchased ' .. item.label, 'success', 3000)
end)

-- Clean up cooldowns on disconnect
AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
```

This example follows the full server-side validation checklist from [security.md](./security.md):
1. Player exists
2. Cooldown check
3. Data validation (item exists in config)
4. Proximity check (server-side coords)
5. Money check
6. Execute

### Job Check Pattern

```lua
-- Server: Restrict action to specific job
RegisterNetEvent('myScript:server:policeAction', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Check job name
    if Player.PlayerData.job.name ~= 'police' then return end

    -- Check minimum grade
    if Player.PlayerData.job.grade.level < 3 then return end

    -- Check on-duty status
    if not Player.PlayerData.job.onduty then return end

    -- Execute police action...
end)
```

### Duty Toggle Pattern

```lua
-- Client: Toggle duty status
RegisterNetEvent('myScript:client:toggleDuty', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    TriggerServerEvent('QBCore:ToggleDuty')
end)

-- Listen for duty changes
RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
    if onDuty then
        -- Equip uniform, set blip, etc.
    else
        -- Remove uniform, clear blip, etc.
    end
end)
```

### Multi-Character / CitizenID Lookup

```lua
-- Server: Offline player lookup by CitizenID
RegisterNetEvent('myScript:server:lookupPlayer', function(citizenid)
    local src = source
    if type(citizenid) ~= 'string' then return end

    -- Check online players first
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player then
        -- Player is online
        print('Online: ' .. Player.PlayerData.charinfo.firstname)
        return
    end

    -- Player offline, query database
    local result = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', { citizenid })
    if not result or #result == 0 then return end

    local data = json.decode(result[1].charinfo)
    print('Offline: ' .. data.firstname)
end)
```

## Quick Reference

| Need | QBCore Method |
|---|---|
| Get player object | `QBCore.Functions.GetPlayer(source)` |
| Get by CitizenID | `QBCore.Functions.GetPlayerByCitizenId(cid)` |
| Get cash | `Player.Functions.GetMoney('cash')` |
| Get bank | `Player.Functions.GetMoney('bank')` |
| Add money | `Player.Functions.AddMoney(type, amount, reason)` |
| Remove money | `Player.Functions.RemoveMoney(type, amount, reason)` |
| Add item | `Player.Functions.AddItem(name, count)` |
| Remove item | `Player.Functions.RemoveItem(name, count)` |
| Has item | `Player.Functions.HasItem(name)` |
| Has item (min count) | `Player.Functions.HasItem(name, count)` |
| Get item info | `Player.Functions.GetItemByName(name)` |
| Set job | `Player.Functions.SetJob(name, grade)` |
| Get job name | `Player.PlayerData.job.name` |
| Get job grade | `Player.PlayerData.job.grade.level` |
| Is on duty | `Player.PlayerData.job.onduty` |
| Set gang | `Player.Functions.SetGang(name, grade)` |
| Get gang name | `Player.PlayerData.gang.name` |
| Set metadata | `Player.Functions.SetMetaData(key, value)` |
| Get metadata | `Player.Functions.GetMetaData(key)` |
| Get CitizenID | `Player.PlayerData.citizenid` |
| Get character info | `Player.PlayerData.charinfo` |
| Save to DB | `Player.Functions.Save()` |
| Sync to client | `Player.Functions.UpdatePlayerData()` |
| Server callback | `QBCore.Functions.CreateCallback(name, fn)` |
| Trigger callback | `QBCore.Functions.TriggerCallback(name, fn, ...)` |
| Notify | `QBCore.Functions.Notify(src, msg, type, ms)` |
| Get all players | `QBCore.Functions.GetQBPlayers()` |
| Client player data | `QBCore.Functions.GetPlayerData()` |
