# State Synchronization

Patterns for synchronizing data between server and clients.

## Decision Tree

```
Need to share data?
├── Global server info (server name, max players)?
│   └── Use: GlobalState
├── Per-player data (job, duty status)?
│   └── Use: Player State Bags
├── Per-entity data (vehicle owner, locked)?
│   └── Use: Entity State Bags
├── One-time action (buy item, open door)?
│   └── Use: Events (TriggerServerEvent / TriggerClientEvent)
├── Cross-resource function call?
│   └── Use: Exports
└── Frequent data sync (position, health)?
    └── Use: State Bags (NOT events)
```

## State Bags

### GlobalState

```lua
-- SERVER: Set (readable by all clients)
GlobalState.serverName = 'My Server'
GlobalState.maxLevel = 100
GlobalState.economyMultiplier = 1.5

-- CLIENT: Read
local serverName = GlobalState.serverName
```

### Player State

```lua
-- SERVER: Set player state
local player = Player(source)
player.state:set('job', 'police', true)         -- true = replicate to clients
player.state:set('onDuty', false, true)
player.state:set('rank', 4, true)

-- CLIENT: Read own state
local myJob = LocalPlayer.state.job
local onDuty = LocalPlayer.state.onDuty

-- CLIENT: Read other player's state
local targetPlayer = Player(targetServerId)
local theirJob = targetPlayer.state.job

-- CLIENT: Set own state and replicate to server
LocalPlayer.state:set('ready', true, true)
```

### Entity State

```lua
-- SERVER: Set entity state
local vehicle = CreateVehicleServerSetter(joaat('police'), 'automobile', x, y, z, h)
Entity(vehicle).state:set('isPoliceVehicle', true, true)
Entity(vehicle).state:set('owner', citizenid, true)

-- CLIENT: Read entity state
local veh = GetVehiclePedIsIn(cache.ped, false)
if veh ~= 0 then
    local isPolice = Entity(veh).state.isPoliceVehicle
end
```

### Listening to State Changes

```lua
-- Listen for any player's job change
AddStateBagChangeHandler('job', nil, function(bagName, key, value, reserved, replicated)
    if string.find(bagName, 'player:') then
        local playerId = tonumber(string.sub(bagName, 8))
        print('Player ' .. playerId .. ' job changed to: ' .. tostring(value))
    end
end)

-- Listen for specific entity state
AddStateBagChangeHandler('isPoliceVehicle', nil, function(bagName, key, value)
    if value then
        print('A police vehicle was marked')
    end
end)

-- Listen for login state (preferred over events for QBCore)
AddStateBagChangeHandler('isLoggedIn', nil, function(_, _, value)
    if value then
        isLoggedIn = true
        PlayerData = QBCore.Functions.GetPlayerData()
    else
        isLoggedIn = false
        PlayerData = {}
    end
end)
```

## Events

### Client to Server

```lua
-- Client
TriggerServerEvent('myScript:server:buyItem', 'bread')

-- Server
RegisterNetEvent('myScript:server:buyItem', function(itemName)
    local src = source
    -- Validate and process...
end)
```

### Server to Client

```lua
-- Server: to specific player
TriggerClientEvent('myScript:client:notify', source, 'Purchase successful!')

-- Server: to ALL players
TriggerClientEvent('myScript:client:announce', -1, 'Server restart in 5 minutes')

-- Client: handle
RegisterNetEvent('myScript:client:notify', function(message)
    lib.notify({ description = message, type = 'success' })
end)
```

### Same-Context Events

```lua
-- For triggering events within the same context (client-to-client or server-to-server)
-- Use AddEventHandler (NOT RegisterNetEvent)
AddEventHandler('myScript:internal:update', function(data)
    -- Only callable from same context
end)

TriggerEvent('myScript:internal:update', data)
```

## Exports

### Declaring

In fxmanifest.lua:
```lua
exports { 'getPlayerLevel', 'setPlayerLevel' }
server_exports { 'getServerData' }
```

### Defining

```lua
local playerLevel = 1

function getPlayerLevel()
    return playerLevel
end

function setPlayerLevel(level)
    playerLevel = level
end
```

### Calling from Another Resource

```lua
local level = exports['my-resource']:getPlayerLevel()
exports['my-resource']:setPlayerLevel(10)
```

## When to Use What

| Method | Direction | Persistent | Use Case |
|---|---|---|---|
| GlobalState | Server → All Clients | Until changed | Server config, rates |
| Player State | Server ↔ Client | Until changed | Job, duty, rank |
| Entity State | Server → Clients | Until entity removed | Vehicle data, NPC data |
| TriggerServerEvent | Client → Server | No | Actions, requests |
| TriggerClientEvent | Server → Client(s) | No | Notifications, updates |
| Exports | Any → Any | No | Function calls, data access |
| ox_lib Callbacks | Client ↔ Server | No | Request-response pattern |

## Anti-Patterns

```lua
-- BAD: Using events for frequently updated data
CreateThread(function()
    while true do
        Wait(1000)
        TriggerServerEvent('myScript:syncPosition', GetEntityCoords(cache.ped))
    end
end)

-- GOOD: Use state bags for frequent sync
CreateThread(function()
    while true do
        Wait(5000)
        LocalPlayer.state:set('lastCoords', GetEntityCoords(cache.ped), true)
    end
end)
```
