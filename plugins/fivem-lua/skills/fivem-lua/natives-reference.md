# FiveM Natives Quick Reference

Essential GTA V and CFX natives for FiveM Lua scripting. For the full reference: https://docs.fivem.net/natives/

## Namespaces Overview

There are **45 namespaces** total: 44 GTA V namespaces + 1 CFX (FiveM-specific).

### Most Used in FiveM Scripting
| Namespace | Purpose | Examples |
|-----------|---------|----------|
| **CFX** | FiveM-specific natives | StateBags, Events, NUI, DUI, Convars |
| **PLAYER** | Player management | GetPlayerPed, GetPlayerServerId, PlayerId |
| **PED** | Ped control & appearance | SetPedComponentVariation, IsPedInVehicle, TaskWarpPedIntoVehicle |
| **ENTITY** | Entity manipulation | GetEntityCoords, SetEntityCoords, DoesEntityExist, DeleteEntity |
| **VEHICLE** | Vehicle control | CreateVehicle, SetVehicleColours, GetVehicleNumberPlateText |
| **OBJECT** | Object spawning | CreateObject, PlaceObjectOnGroundProperly, DeleteObject |
| **HUD** | UI elements | DrawText, ShowNotification, AddBlipForCoord, SetBlipSprite |
| **STREAMING** | Asset loading | RequestModel, HasModelLoaded, SetModelAsNoLongerNeeded |
| **CAM** | Camera control | CreateCam, SetCamActive, RenderScriptCams |
| **TASK** | NPC tasks | TaskGoToCoordAnyMeans, TaskPlayAnim, ClearPedTasks |
| **GRAPHICS** | Visual effects | DrawMarker, StartParticleFxLooped, SetTimecycleModifier |
| **NETWORK** | Networking | NetworkGetNetworkIdFromEntity, NetToVeh, NetToPed |
| **INTERIOR** | MLO/Interiors | GetInteriorAtCoords, IsInteriorReady, LoadInterior |
| **WEAPON** | Weapons | GiveWeaponToPed, RemoveAllPedWeapons, GetSelectedPedWeapon |

### Other Namespaces (Less Common)
APP, AUDIO, BRAIN, CLOCK, CUTSCENE, DATAFILE, DECORATOR, DLC, EVENT, FILES, FIRE, ITEMSET, LOADINGSCREEN, LOCALIZATION, MISC, MOBILE, MONEY, NETSHOPPING, PAD, PATHFIND, PHYSICS, RECORDING, REPLAY, SAVEMIGRATION, SCRIPT, SECURITY, SHAPETEST, SOCIALCLUB, STATS, SYSTEM, WATER, ZONE

## Essential Natives by Category

### Player & Ped (Client)
```lua
-- Player identification
local playerId = PlayerId()                          -- PLAYER: local player ID
local playerPed = PlayerPedId()                      -- PLAYER: local player ped (or cache.ped)
local serverId = GetPlayerServerId(playerId)         -- PLAYER: server ID from client ID

-- Ped state
local coords = GetEntityCoords(ped)                  -- ENTITY: position vector3
local heading = GetEntityHeading(ped)                -- ENTITY: rotation
local health = GetEntityHealth(ped)                  -- ENTITY: health (100-200, 100 = dead)
local armor = GetPedArmour(ped)                      -- PED: armor value
local isDead = IsPedDeadOrDying(ped, true)           -- PED: death check
local isInVehicle = IsPedInAnyVehicle(ped, false)    -- PED: vehicle check
local weapon = GetSelectedPedWeapon(ped)             -- WEAPON: current weapon hash
```

### Player & Ped (Server)
```lua
-- Server player identification
local src = source                                    -- current event source
local playerPed = GetPlayerPed(src)                  -- PLAYER: ped from server source
local playerCoords = GetEntityCoords(playerPed)      -- ENTITY: server-side coords
local playerName = GetPlayerName(src)                -- PLAYER: player name

-- Player state (server)
local identifiers = GetPlayerIdentifiers(src)        -- CFX: Steam, license, discord, etc.
local tokens = GetPlayerTokens(src)                  -- CFX: hardware tokens
local endpoint = GetPlayerEndpoint(src)              -- CFX: IP address
local ping = GetPlayerPing(src)                      -- PLAYER: latency
```

### Entity Management
```lua
-- Existence & ownership
local exists = DoesEntityExist(entity)               -- ENTITY: check if valid
local isNetworked = NetworkGetEntityIsNetworked(entity) -- NETWORK: networked check
local netId = NetworkGetNetworkIdFromEntity(entity)  -- NETWORK: get net ID

-- Position & movement
SetEntityCoords(entity, x, y, z, false, false, false, false) -- ENTITY: teleport
SetEntityHeading(entity, heading)                    -- ENTITY: set rotation
FreezeEntityPosition(entity, true)                   -- ENTITY: freeze/unfreeze
SetEntityInvincible(entity, true)                    -- ENTITY: godmode

-- Cleanup
SetEntityAsNoLongerNeeded(entity)                    -- ENTITY: mark for GC
DeleteEntity(entity)                                 -- ENTITY: immediate delete
```

### Vehicle Operations
```lua
-- Creation (server-side recommended)
local vehicle = CreateVehicle(modelHash, x, y, z, heading, true, true)

-- Properties
local plate = GetVehicleNumberPlateText(vehicle)     -- VEHICLE: plate text
local speed = GetEntitySpeed(vehicle)                -- ENTITY: m/s speed
local health = GetVehicleEngineHealth(vehicle)       -- VEHICLE: -4000 to 1000
local fuel = GetVehicleFuelLevel(vehicle)            -- VEHICLE: 0-100

-- Modifications
SetVehicleColours(vehicle, primary, secondary)       -- VEHICLE: paint
SetVehicleNumberPlateText(vehicle, "PLATE")          -- VEHICLE: set plate
SetVehicleModKit(vehicle, 0)                         -- VEHICLE: enable mods
SetVehicleMod(vehicle, modType, modIndex, false)     -- VEHICLE: apply mod

-- Enter/Exit
TaskWarpPedIntoVehicle(ped, vehicle, -1)             -- TASK: instant enter (-1 = driver)
TaskEnterVehicle(ped, vehicle, -1, -1, 1.0, 1, 0)   -- TASK: animated enter
```

### Blips & Map
```lua
-- Create blip
local blip = AddBlipForCoord(x, y, z)               -- HUD: coord blip
local blip = AddBlipForEntity(entity)                -- HUD: entity blip

-- Configure blip
SetBlipSprite(blip, spriteId)                        -- HUD: icon (1-826)
SetBlipDisplay(blip, 4)                              -- HUD: show on map & minimap
SetBlipScale(blip, 0.8)                              -- HUD: size
SetBlipColour(blip, colorId)                         -- HUD: color (0-85)
SetBlipAsShortRange(blip, true)                      -- HUD: minimap only when near
BeginTextCommandSetBlipName("STRING")                -- HUD: start name
AddTextComponentSubstringPlayerName("Name")          -- HUD: set name text
EndTextCommandSetBlipName(blip)                      -- HUD: apply name

-- Remove
RemoveBlip(blip)                                     -- HUD: delete blip
```

### Model & Streaming
```lua
-- Load model (REQUIRED before spawning)
local model = joaat('prop_bench_01a')                -- or GetHashKey('model_name')
RequestModel(model)                                  -- STREAMING: request
while not HasModelLoaded(model) do                   -- STREAMING: wait
    Wait(0)
end

-- Use model...
CreateObject(model, x, y, z, true, true, false)

-- Cleanup (ALWAYS after use)
SetModelAsNoLongerNeeded(model)                      -- STREAMING: free memory
```

### Animations
```lua
-- Load anim dict (REQUIRED before playing)
RequestAnimDict('anim_dict')                         -- STREAMING: request
while not HasAnimDictLoaded('anim_dict') do          -- STREAMING: wait
    Wait(0)
end

-- Play animation
TaskPlayAnim(ped, 'anim_dict', 'anim_name',
    8.0,   -- blendInSpeed
    -8.0,  -- blendOutSpeed
    -1,    -- duration (-1 = full)
    0,     -- flags (1=loop, 16=upperbody, 32=controllable)
    0,     -- playbackRate
    false, false, false -- lockX, lockY, lockZ
)

-- Stop
ClearPedTasks(ped)                                   -- TASK: stop all tasks
RemoveAnimDict('anim_dict')                          -- STREAMING: free memory
```

### Drawing & Markers (Client only, requires Wait(0))
```lua
-- 3D Marker (call every frame)
DrawMarker(
    1,          -- type (1=cylinder, 2=arrow_up, 20=ring, etc.)
    x, y, z,    -- position
    0, 0, 0,    -- direction
    0, 0, 0,    -- rotation
    1.0, 1.0, 1.0, -- scale
    255, 0, 0, 100, -- RGBA
    false,      -- bobUpAndDown
    false,      -- faceCamera
    2,          -- p19 (2 = draw regardless of distance)
    false,      -- rotate
    nil, nil,   -- textureDict, textureName
    false       -- drawOnEnts
)

-- NOTE: Prefer ox_lib zones/points over manual DrawMarker loops
-- ox_lib handles the rendering thread automatically
```

### CFX Natives (FiveM-Specific)
```lua
-- State Bags
local state = Player(serverId).state                 -- player state bag
local entityState = Entity(entity).state             -- entity state bag
GlobalState.myKey = value                            -- global state

AddStateBagChangeHandler('key', nil, function(bagName, key, value)
    -- React to state changes
end)

-- NUI
SendNUIMessage({ action = 'open', data = {} })       -- CFX: Lua → JS
RegisterNUICallback('close', function(data, cb)       -- CFX: JS → Lua
    SetNuiFocus(false, false)
    cb('ok')
end)
SetNuiFocus(true, true)                              -- CFX: enable NUI input

-- Events
RegisterNetEvent('resource:event')                   -- CFX: register net event
AddEventHandler('resource:event', function() end)    -- CFX: add handler
TriggerServerEvent('resource:event', data)           -- CFX: client → server
TriggerClientEvent('resource:event', target, data)   -- CFX: server → client (-1 = all)

-- Resource
GetCurrentResourceName()                             -- CFX: this resource name
GetResourceState('resource_name')                    -- CFX: started/stopped/etc.
```

## Native Optimization Table

| Instead of | Use | Why |
|-----------|-----|-----|
| `PlayerPedId()` in loop | `cache.ped` (ox_lib) | Cached, no native call |
| `GetEntityCoords(ped)` in loop | `cache.coords` (ox_lib) | Cached, updated automatically |
| `GetVehiclePedIsIn(ped)` in loop | `cache.vehicle` (ox_lib) | Cached |
| `Vdist(a, b, c, d, e, f)` | `#(vec3a - vec3b)` | Lua vector math, faster |
| `Vdist2(a, b, c, d, e, f)` | `#(vec3a - vec3b)` | Same, Vdist2 returns squared |
| `GetHashKey('string')` | `joaat('string')` | Lua-side hash, no native call |
| `GetPlayerPed(-1)` | `PlayerPedId()` or `cache.ped` | -1 is deprecated |
| `Citizen.CreateThread` | `CreateThread` | Modern equivalent |
| `Citizen.Wait` | `Wait` | Modern equivalent |

## Full Documentation

- **All Natives**: https://docs.fivem.net/natives/
- **CFX Only**: https://docs.fivem.net/natives/?n_CFX
- **Client Only**: Filter with "API Set: client"
- **Server Only**: Filter with "API Set: server"
- **GitHub Source**: https://github.com/citizenfx/natives
- **URL Pattern**: `https://docs.fivem.net/natives/?_0x[HASH]` for any specific native
