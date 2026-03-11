# Performance

## Thread Management

### CreateThread and Wait

Every thread MUST have a Wait(). No exceptions.

```lua
-- BAD: No Wait = infinite loop = client freeze/crash
CreateThread(function()
    while true do
        -- Logic here
    end
end)
```

```lua
-- GOOD: Always include Wait()
CreateThread(function()
    while true do
        Wait(0)  -- Yields to the game engine every frame
        -- Logic here
    end
end)
```

Without Wait(), the thread never yields control back to the game engine. The client freezes permanently and must be force-closed.

### Dynamic Sleep Pattern

The most important optimization pattern in FiveM. Adjust sleep based on proximity:

```lua
CreateThread(function()
    while true do
        local sleep = 2500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - Config.Location)

        if dist < Config.MaxDistance then
            sleep = 0
            -- Close enough: run logic
            DrawMarker(...)
            if IsControlJustPressed(0, 38) then
                -- Interact
            end
        elseif dist < Config.MaxDistance * 3 then
            sleep = 500
            -- Medium range: draw marker only
            DrawMarker(...)
        end

        Wait(sleep)
    end
end)
```

Key principle: The farther the player, the less frequently the loop runs.

### Job-Conditional Threads

Threads that only matter for specific jobs must STOP when the player changes job:

```lua
-- ESX
local function startPoliceThread()
    CreateThread(function()
        while ESX.PlayerData.job.name == 'police' do
            Wait(0)
            -- Police-only logic
        end
    end)
end

AddEventHandler('esx:setJob', function(job)
    if job.name == 'police' then
        startPoliceThread()
    end
end)

if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
    startPoliceThread()
end
```

```lua
-- QBCore
local function startPoliceThread()
    CreateThread(function()
        while QBCore.Functions.GetPlayerData().job.name == 'police' do
            Wait(0)
            -- Police-only logic
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    if JobInfo.name == 'police' then
        startPoliceThread()
    end
end)

local PlayerData = QBCore.Functions.GetPlayerData()
if PlayerData.job and PlayerData.job.name == 'police' then
    startPoliceThread()
end
```

When the player switches to a different job, the while condition fails and the thread exits naturally. No wasted cycles.

### Zone-Based Thread Activation

Using ox_lib zones to only run logic when player is in a zone:

```lua
local inZone = false

lib.zones.sphere({
    coords = Config.Location,
    radius = 20.0,
    onEnter = function()
        inZone = true
        startInteractionThread()
    end,
    onExit = function()
        inZone = false
    end,
})

local function startInteractionThread()
    CreateThread(function()
        while inZone do
            Wait(0)
            -- Interaction logic (only runs inside zone)
        end
    end)
end
```

## Native Optimization

### Replacement Table

| Deprecated / Slow | Optimized | Speedup |
|---|---|---|
| `GetPlayerPed(-1)` | `PlayerPedId()` | Direct native |
| `GetDistanceBetweenCoords(x1,y1,z1,x2,y2,z2,true)` | `#(vec1 - vec2)` | ~10x faster |
| `GetHashKey('model')` | `joaat('model')` | Faster hash |
| `table.insert(t, v)` | `t[#t + 1] = v` | Less overhead |
| `Citizen.CreateThread` | `CreateThread` | Alias, shorter |
| `Citizen.Wait` | `Wait` | Alias, shorter |
| `Citizen.SetTimeout` | `SetTimeout` | Alias, shorter |

### Vector Math

```lua
-- Bad: Slow native
local dist = GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true)

-- Good: Fast vector math
local dist = #(vector3(x1, y1, z1) - vector3(x2, y2, z2))

-- Better: Use cached coords
local playerCoords = GetEntityCoords(cache.ped)
local dist = #(playerCoords - targetCoords)
```

## Caching

### What to Cache

```lua
-- Cache these at script load
local playerId = PlayerId()
local serverId = GetPlayerServerId(playerId)

-- Cache ped (changes on respawn/model change)
local ped = PlayerPedId()

-- ESX: Update ped on change
AddEventHandler('esx:playerPedChanged', function(newPed)
    ped = newPed
end)

-- ox_lib cache (best option)
-- Automatically cached: cache.ped, cache.playerId, cache.serverId,
-- cache.coords, cache.vehicle, cache.seat, cache.weapon
local myPed = cache.ped           -- Auto-updated
local myCoords = cache.coords     -- Auto-updated
local myVehicle = cache.vehicle   -- Auto-updated, nil if on foot
```

### Framework Object Caching

```lua
-- Bad: Getting core object every time
RegisterNetEvent('myEvent', function()
    local QBCore = exports['qb-core']:GetCoreObject()
    -- ...
end)

-- Good: Cache once at top of file
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('myEvent', function()
    local Player = QBCore.Functions.GetPlayer(source)
    -- ...
end)
```

## Table Optimization

```lua
-- Bad: table.insert overhead
local results = {}
for i = 1, 100 do
    table.insert(results, computeValue(i))
end

-- Good: Direct index assignment
local results = {}
for i = 1, 100 do
    results[#results + 1] = computeValue(i)
end

-- Good: Pre-sized when count is known
local results = table.create(100, 0)
for i = 1, 100 do
    results[i] = computeValue(i)
end
```

## Memory Management

```lua
-- Free large tables when done
local largeData = loadLargeDataset()
processData(largeData)
largeData = nil  -- Allow GC to collect

-- Use <close> for auto-cleanup (Lua 5.4)
local file <close> = io.open('data.txt', 'r')
-- File automatically closed when variable goes out of scope
```

## Loop Best Practices

| Pattern | Wait Time | Use Case |
|---|---|---|
| Drawing markers/3D text | `Wait(0)` | Must render every frame |
| Key press detection | `Wait(0)` | Must check every frame |
| Proximity check (close) | `Wait(0)` | Player is in interaction range |
| Proximity check (medium) | `Wait(500)` | Player approaching |
| Proximity check (far) | `Wait(2500)` | Player not near |
| Periodic data sync | `Wait(60000)` | Save data every minute |
| Status check (hunger/thirst) | `Wait(10000)` | Every 10 seconds |

## Anti-Patterns

### Never: While true with constant Wait(0)

```lua
-- Bad: Checks every frame for ALL players, even when not near
CreateThread(function()
    while true do
        Wait(0)
        -- Heavy logic every frame
    end
end)

-- Good: Dynamic sleep
CreateThread(function()
    while true do
        local sleep = 1000
        if isNearTarget() then
            sleep = 0
            -- Logic
        end
        Wait(sleep)
    end
end)
```

### Never: Multiple Independent Loops When One Suffices

```lua
-- Bad: 3 separate threads for the same location
CreateThread(function() while true do Wait(0) drawMarker1() end end)
CreateThread(function() while true do Wait(0) drawMarker2() end end)
CreateThread(function() while true do Wait(0) checkInput() end end)

-- Good: Single thread handling all related logic
CreateThread(function()
    while true do
        local sleep = 2500
        if isNearLocation() then
            sleep = 0
            drawMarker1()
            drawMarker2()
            checkInput()
        end
        Wait(sleep)
    end
end)
```
