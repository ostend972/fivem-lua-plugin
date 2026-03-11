# ESX Patterns

ESX Legacy framework patterns and API reference.

---

## Initialization

Cache the ESX object once at the top of every file that needs it. Never re-fetch inside events or loops.

Bad:

```lua
-- DEPRECATED: TriggerEvent method is slow, unreliable on resource restart, and may return nil
local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)
-- ESX might still be nil when your code runs
```

Good:

```lua
-- Client or Server (top of file, cached once)
ESX = exports['es_extended']:getSharedObject()
-- Immediate, synchronous, always returns the current object
```

The exports method is instant, synchronous, and survives resource restarts. The TriggerEvent method is deprecated and will be removed.

---

## fxmanifest.lua for ESX

```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AuthorName'
description 'My ESX Script'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@es_extended/locale.lua',
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
    'es_extended',
    'oxmysql',
}
```

`@es_extended/imports.lua` provides the `ESX` global automatically (alternative to the exports method). `@es_extended/locale.lua` provides the `TranslateCap()` / `_U()` localization function.

---

## xPlayer API (Server-Side)

The `xPlayer` object represents a connected player on the server. All money, inventory, and job operations go through this object.

### Getting a Player

```lua
local xPlayer = ESX.GetPlayerFromId(source)              -- By server ID (most common)
local xPlayer = ESX.GetPlayerFromIdentifier(identifier)   -- By identifier (e.g., license:abc123)
```

Always nil-check before using:

```lua
local xPlayer = ESX.GetPlayerFromId(source)
if not xPlayer then return end
```

### Getting All Players

```lua
local xPlayers = ESX.GetExtendedPlayers()                -- All connected xPlayers
local xPlayers = ESX.GetExtendedPlayers('job', 'police') -- All players with job 'police'

for _, xPlayer in pairs(xPlayers) do
    xPlayer.showNotification('Server message')
end
```

### Money Operations

```lua
-- Cash
xPlayer.getMoney()                                -- Returns number
xPlayer.addMoney(amount, reason)                  -- reason is optional string for logs
xPlayer.removeMoney(amount, reason)
xPlayer.setMoney(amount)

-- Accounts (bank, black_money, etc.)
xPlayer.getAccount('bank')                        -- Returns { name, money, label }
xPlayer.getAccount('bank').money                  -- Just the amount
xPlayer.addAccountMoney('bank', amount, reason)
xPlayer.removeAccountMoney('bank', amount, reason)
xPlayer.setAccountMoney('bank', amount)
```

Available accounts by default: `money` (cash), `bank`, `black_money`.

Bad:

```lua
-- Never trust client-sent amounts
RegisterNetEvent('myScript:server:deposit', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeAccountMoney('bank', amount) -- Client controls the amount!
end)
```

Good:

```lua
RegisterNetEvent('myScript:server:deposit', function(amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if type(amount) ~= 'number' then return end
    if amount <= 0 then return end
    if math.floor(amount) ~= amount then return end -- Must be integer
    if xPlayer.getMoney() < amount then return end   -- Server checks balance

    xPlayer.removeMoney(amount, 'bank deposit')
    xPlayer.addAccountMoney('bank', amount, 'bank deposit')
end)
```

### Job Operations

```lua
xPlayer.getJob()                                  -- Returns { name, label, grade, grade_name, grade_label, grade_salary }
xPlayer.getJob().name                             -- e.g., 'police'
xPlayer.getJob().grade                            -- e.g., 4
xPlayer.getJob().grade_label                      -- e.g., 'Chief'
xPlayer.setJob('police', 4)                       -- Set job name and grade
xPlayer.setJob('police', 4, true)                 -- Set job, grade, and onDuty status
```

### Inventory Operations

```lua
xPlayer.getInventory()                            -- All items (array of tables)
xPlayer.getInventoryItem('bread')                 -- Returns { name, count, label, weight, ... }
xPlayer.getInventoryItem('bread').count            -- Just the count
xPlayer.addInventoryItem('bread', 5)
xPlayer.removeInventoryItem('bread', 2)
xPlayer.setInventoryItem('bread', 10)
xPlayer.canCarryItem('bread', 5)                  -- Bool: has enough weight/space?
xPlayer.canSwapItem('bread', 3, 'water', 2)       -- Bool: can swap quantities?
```

Always check before removing:

```lua
local item = xPlayer.getInventoryItem('bread')
if not item or item.count < 2 then
    xPlayer.showNotification('Not enough bread')
    return
end
xPlayer.removeInventoryItem('bread', 2)
```

### Weapon Operations

```lua
xPlayer.addWeapon('weapon_pistol', 200)           -- weapon name, ammo count
xPlayer.removeWeapon('weapon_pistol')
xPlayer.hasWeapon('weapon_pistol')                -- Bool
xPlayer.getLoadout()                              -- All weapons (array)
```

### Identity and Metadata

```lua
xPlayer.getName()                                 -- Full name (firstname lastname)
xPlayer.getIdentifier()                           -- Primary identifier (e.g., license:abc123)
xPlayer.getGroup()                                -- Permission group ('user', 'admin', 'superadmin')
xPlayer.getCoords(true)                           -- vector3 or vector4 if true (includes heading)
xPlayer.getMeta()                                 -- Custom metadata table
xPlayer.getMeta('key')                            -- Specific metadata value
xPlayer.setMeta('key', value)                     -- Set metadata
```

### Player Actions

```lua
xPlayer.kick('reason')                            -- Kick from server
xPlayer.triggerEvent('eventName', ...)            -- Trigger client event on this player
xPlayer.showNotification('msg')                   -- Simple notification
xPlayer.showNotification('msg', 'info', 3000)     -- With type and duration (ms)
xPlayer.showHelpNotification('Press ~INPUT_CONTEXT~ to interact')
```

---

## Server Callbacks

Server callbacks let the client request data from the server asynchronously, without using events + separate response events.

### Register (Server)

```lua
ESX.RegisterServerCallback('myScript:getData', function(src, cb, param1, param2)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(nil) end

    local data = {
        name = xPlayer.getName(),
        money = xPlayer.getMoney(),
        job = xPlayer.getJob().name,
    }
    cb(data)
end)
```

### Trigger (Client)

```lua
ESX.TriggerServerCallback('myScript:getData', function(data)
    if not data then return end
    print('Name: ' .. data.name)
    print('Money: ' .. data.money)
    print('Job: ' .. data.job)
end, param1, param2)
```

Arguments after the callback function are passed to the server callback as `param1`, `param2`, etc.

### Practical Example: Checking Permissions Before Opening a Menu

```lua
-- SERVER
ESX.RegisterServerCallback('police:canAccessArmory', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(false) end

    local job = xPlayer.getJob()
    if job.name ~= 'police' or job.grade < 2 then
        return cb(false)
    end

    -- Also check proximity server-side
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local ARMORY_COORDS <const> = vector3(452.2, -980.0, 30.7)

    if #(coords - ARMORY_COORDS) > 5.0 then
        return cb(false)
    end

    cb(true)
end)

-- CLIENT
ESX.TriggerServerCallback('police:canAccessArmory', function(canAccess)
    if not canAccess then return end
    -- Open armory menu
end)
```

---

## Client Events Reference

| Event | Trigger | Callback Data |
|---|---|---|
| `esx:playerLoaded` | Player fully loaded into server | `xPlayer, isNew` |
| `esx:onPlayerDeath` | Player dies | `data` |
| `esx:setJob` | Job changes (hire, fire, promote) | `job, lastJob` |
| `esx:playerPedChanged` | Ped model changes (skin, respawn) | `newPed` |
| `esx:onPlayerSpawn` | Player respawns after death | `spawn` |

### esx:playerLoaded

Fires once when the player has fully loaded. Use this for initial setup.

```lua
RegisterNetEvent('esx:playerLoaded', function(xPlayer, isNew)
    ESX.PlayerData = xPlayer

    if isNew then
        -- First time joining the server
        ESX.ShowNotification('Welcome to the server!')
    end

    -- Start job-specific threads
    if ESX.PlayerData.job.name == 'police' then
        startPoliceThread()
    end
end)
```

### esx:onPlayerDeath

Fires when the player ped health reaches zero.

```lua
RegisterNetEvent('esx:onPlayerDeath', function(data)
    -- data contains death information
    ESX.ShowNotification('You died')

    -- Stop any active interactions
    isInMenu = false
    SetNuiFocus(false, false)
end)
```

### esx:setJob

Fires when the player's job changes. Critical for starting/stopping job-specific threads.

```lua
RegisterNetEvent('esx:setJob', function(job, lastJob)
    ESX.PlayerData.job = job

    -- Stop old job threads (they check the condition and exit)
    -- Start new job threads
    if job.name == 'police' then
        startPoliceThread()
    elseif job.name == 'ambulance' then
        startMedicThread()
    end
end)
```

### esx:playerPedChanged

Fires when the ped model changes (after character customization, respawn with different model, etc.). Update any cached ped references.

```lua
RegisterNetEvent('esx:playerPedChanged', function(newPed)
    -- Update cached ped reference
    cachedPed = newPed
end)
```

### esx:onPlayerSpawn

Fires when the player respawns after death.

```lua
RegisterNetEvent('esx:onPlayerSpawn', function(spawn)
    -- spawn contains spawn position data
    -- Re-apply any persistent effects
    -- Restart any threads that were stopped on death
end)
```

---

## Server Events Reference

| Event | Trigger | Callback Data |
|---|---|---|
| `esx:playerLoaded` | Player joins and loads | `playerId, xPlayer, isNew` |
| `esx:playerDropped` | Player disconnects | `playerId, reason` |
| `esx:setJob` | Job changed server-side | `source, job, lastJob` |

### esx:playerLoaded (Server)

```lua
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer, isNew)
    if isNew then
        -- First time player: set default data
        xPlayer.addInventoryItem('bread', 5)
        xPlayer.addInventoryItem('water', 5)
        xPlayer.addMoney(5000, 'starter cash')
    end

    -- Load any custom data from database
    local result = MySQL.query.await('SELECT * FROM my_data WHERE identifier = ?', { xPlayer.getIdentifier() })
    if result and #result > 0 then
        xPlayer.setMeta('customData', result[1])
    end
end)
```

### esx:playerDropped (Server)

```lua
AddEventHandler('esx:playerDropped', function(playerId, reason)
    -- Clean up player-specific data
    cooldowns[playerId] = nil
    playerCache[playerId] = nil

    print(('Player %s dropped: %s'):format(playerId, reason))
end)
```

### esx:setJob (Server)

```lua
AddEventHandler('esx:setJob', function(source, job, lastJob)
    -- Log job changes
    print(('Player %s changed job: %s -> %s'):format(source, lastJob.name, job.name))

    -- React to job changes (e.g., remove job-specific items)
    if lastJob.name == 'police' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.hasWeapon('weapon_stungun') then
            xPlayer.removeWeapon('weapon_stungun')
        end
    end
end)
```

---

## Common Patterns

### Complete Shop Example (ESX)

A full, secure shop implementation with config, client proximity, ox_lib context menu, and server validation.

**config.lua** (shared):

```lua
Config = {}

Config.Shops = {
    {
        name = 'general_store',
        label = 'General Store',
        coords = vector3(25.7, -1347.3, 29.5),
        items = {
            { name = 'bread',  label = 'Bread',  price = 5 },
            { name = 'water',  label = 'Water',  price = 3 },
            { name = 'medkit', label = 'Medkit', price = 50 },
        },
    },
}

Config.MaxBuyAmount = 20
Config.ShopDistance = 3.0
```

**client/main.lua**:

```lua
ESX = exports['es_extended']:getSharedObject()

--- Builds and opens the shop menu for a given shop config.
--- @param shop table The shop configuration from Config.Shops
local function openShopMenu(shop)
    local options = {}

    for _, item in ipairs(shop.items) do
        options[#options + 1] = {
            title = item.label,
            description = ('$%d'):format(item.price),
            icon = 'shopping-cart',
            onSelect = function()
                local input = lib.inputDialog('Buy ' .. item.label, {
                    { type = 'number', label = 'Quantity', default = 1, min = 1, max = Config.MaxBuyAmount },
                })

                if not input then return end

                local amount = math.floor(input[1])
                if amount < 1 then return end

                TriggerServerEvent('myShop:server:buy', shop.name, item.name, amount)
            end,
        }
    end

    lib.registerContext({
        id = 'shop_menu',
        title = shop.label,
        options = options,
    })

    lib.showContext('shop_menu')
end

-- Proximity check for each shop
for _, shop in ipairs(Config.Shops) do
    lib.zones.sphere({
        coords = shop.coords,
        radius = Config.ShopDistance,
        onEnter = function()
            lib.showTextUI('[E] Open ' .. shop.label)
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        inside = function()
            if IsControlJustPressed(0, 38) then -- E key
                openShopMenu(shop)
            end
        end,
    })
end
```

**server/main.lua**:

```lua
ESX = exports['es_extended']:getSharedObject()

-- Build a fast lookup table from config
local shopItems = {}
for _, shop in ipairs(Config.Shops) do
    shopItems[shop.name] = {}
    for _, item in ipairs(shop.items) do
        shopItems[shop.name][item.name] = item
    end
end

-- Build coords lookup for proximity
local shopCoords = {}
for _, shop in ipairs(Config.Shops) do
    shopCoords[shop.name] = shop.coords
end

local cooldowns = {}
local COOLDOWN <const> = 3
local MAX_DISTANCE <const> = 10.0

RegisterNetEvent('myShop:server:buy', function(shopName, itemName, amount)
    local src = source

    -- 1. Player exists?
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- 2. Cooldown?
    if cooldowns[src] and (os.time() - cooldowns[src]) < COOLDOWN then return end
    cooldowns[src] = os.time()

    -- 3. Input validation
    if type(shopName) ~= 'string' then return end
    if type(itemName) ~= 'string' then return end
    if type(amount) ~= 'number' then return end
    if amount <= 0 or amount > Config.MaxBuyAmount then return end
    if math.floor(amount) ~= amount then return end

    -- 4. Shop and item exist?
    local shop = shopItems[shopName]
    if not shop then return end
    local item = shop[itemName]
    if not item then return end

    -- 5. Proximity? (server-side coords)
    local coords = shopCoords[shopName]
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - coords) > MAX_DISTANCE then return end

    -- 6. Can afford?
    local totalPrice = item.price * amount
    if xPlayer.getMoney() < totalPrice then
        xPlayer.showNotification('Not enough money')
        return
    end

    -- 7. Can carry?
    if not xPlayer.canCarryItem(itemName, amount) then
        xPlayer.showNotification('Inventory full')
        return
    end

    -- 8. Execute
    xPlayer.removeMoney(totalPrice, 'shop purchase: ' .. itemName)
    xPlayer.addInventoryItem(itemName, amount)
    xPlayer.showNotification(('Bought %dx %s for $%d'):format(amount, item.label, totalPrice))
end)

-- Cleanup on disconnect
AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
```

### Secure Job Check Pattern

Bad:

```lua
-- Client-only job check is NOT secure
-- Cheaters can spoof ESX.PlayerData
if ESX.PlayerData.job.name == 'police' then
    TriggerServerEvent('police:server:spawnVehicle', 'police3')
end
```

Good:

```lua
-- CLIENT: Quick check for UI purposes (not security)
local function isPolice()
    return ESX.PlayerData.job and ESX.PlayerData.job.name == 'police'
end

-- SERVER: ALWAYS verify server-side for any privileged action
local function isPlayerPolice(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    return xPlayer.getJob().name == 'police'
end

-- SERVER: With grade check
local function isPlayerPoliceCommand(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local job = xPlayer.getJob()
    return job.name == 'police' and job.grade >= 3
end

RegisterNetEvent('police:server:spawnVehicle', function(model)
    local src = source
    if not isPlayerPolice(src) then return end
    -- Proceed with vehicle spawn...
end)
```

### ESX PlayerData on Client

On the client, `ESX.PlayerData` holds a cached copy of the player's data. Keep it updated via events.

```lua
ESX = exports['es_extended']:getSharedObject()

-- PlayerData is populated after esx:playerLoaded
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
end)

-- Keep job updated
RegisterNetEvent('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

-- Access cached data (client only, not secure)
local money = ESX.PlayerData.money
local jobName = ESX.PlayerData.job.name
local jobGrade = ESX.PlayerData.job.grade
```

### Admin/Group Check Pattern

```lua
-- SERVER: Check permission group
local function isAdmin(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    return group == 'admin' or group == 'superadmin'
end

RegisterNetEvent('admin:server:giveItem', function(targetId, itemName, amount)
    local src = source
    if not isAdmin(src) then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then return end

    target.addInventoryItem(itemName, amount)
end)
```

### ESX Usable Items

Register server-side items that trigger when a player uses them from inventory.

```lua
-- SERVER
ESX.RegisterUsableItem('medkit', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local item = xPlayer.getInventoryItem('medkit')
    if not item or item.count < 1 then return end

    xPlayer.removeInventoryItem('medkit', 1)
    TriggerClientEvent('myScript:client:useMedkit', src)
end)

-- CLIENT
RegisterNetEvent('myScript:client:useMedkit', function()
    local ped = PlayerPedId()

    -- Play animation
    lib.requestAnimDict('mini@repair')
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_player', 8.0, -8.0, 5000, 49, 0, false, false, false)

    -- Progress bar
    if lib.progressBar({
        duration = 5000,
        label = 'Using medkit...',
        useWhileDead = false,
        canCancel = true,
        anim = { dict = 'mini@repair', clip = 'fixing_a_player' },
    }) then
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        lib.notify({ title = 'Health', description = 'Fully healed', type = 'success' })
    else
        -- Cancelled: server should re-add the item
        TriggerServerEvent('myScript:server:cancelMedkit')
    end
end)
```

---

## Quick Reference

| Need | ESX Method |
|---|---|
| Get player object | `ESX.GetPlayerFromId(source)` |
| Get player by identifier | `ESX.GetPlayerFromIdentifier(identifier)` |
| Get all players | `ESX.GetExtendedPlayers()` |
| Get all players with job | `ESX.GetExtendedPlayers('job', 'police')` |
| Get cash | `xPlayer.getMoney()` |
| Add cash | `xPlayer.addMoney(amount, reason)` |
| Remove cash | `xPlayer.removeMoney(amount, reason)` |
| Get bank balance | `xPlayer.getAccount('bank').money` |
| Add bank money | `xPlayer.addAccountMoney('bank', amount, reason)` |
| Remove bank money | `xPlayer.removeAccountMoney('bank', amount, reason)` |
| Add item | `xPlayer.addInventoryItem(name, count)` |
| Remove item | `xPlayer.removeInventoryItem(name, count)` |
| Check item count | `xPlayer.getInventoryItem(name).count` |
| Can carry item? | `xPlayer.canCarryItem(name, count)` |
| Set job | `xPlayer.setJob(name, grade)` |
| Get job name | `xPlayer.getJob().name` |
| Get job grade | `xPlayer.getJob().grade` |
| Add weapon | `xPlayer.addWeapon(weapon, ammo)` |
| Remove weapon | `xPlayer.removeWeapon(weapon)` |
| Has weapon? | `xPlayer.hasWeapon(weapon)` |
| Get name | `xPlayer.getName()` |
| Get identifier | `xPlayer.getIdentifier()` |
| Get permission group | `xPlayer.getGroup()` |
| Get coords | `xPlayer.getCoords(true)` |
| Kick player | `xPlayer.kick(reason)` |
| Trigger client event | `xPlayer.triggerEvent(eventName, ...)` |
| Notification | `xPlayer.showNotification(msg, type, duration)` |
| Register server callback | `ESX.RegisterServerCallback(name, function(src, cb, ...) end)` |
| Trigger server callback | `ESX.TriggerServerCallback(name, function(result) end, ...)` |
| Register usable item | `ESX.RegisterUsableItem(name, function(src) end)` |
| Client: get cached data | `ESX.PlayerData` |
| Client: show notification | `ESX.ShowNotification(msg)` |
| Client: show help notification | `ESX.ShowHelpNotification(msg)` |
