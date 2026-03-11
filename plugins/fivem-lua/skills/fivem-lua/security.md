# Security

## Golden Rule

**Never trust the client.** Any data sent from client to server can be spoofed, modified, or fabricated by cheaters. The server MUST validate EVERYTHING independently.

## Server-Side Validation Checklist

Every server event handler MUST follow this checklist in order:

```
1. Player exists?     → local xPlayer = ESX.GetPlayerFromId(source)  / QBCore.Functions.GetPlayer(source)
                        if not xPlayer then return end
2. Cooldown passed?   → if cooldowns[src] and (os.time() - cooldowns[src]) < COOLDOWN then return end
3. Permissions OK?    → Check job, grade, admin level
4. Proximity valid?   → Get coords SERVER-SIDE with GetEntityCoords(GetPlayerPed(src))
                        if #(pedCoords - validCoords) > MAX_DIST then return end
5. Data valid?        → Validate types, ranges, existence of referenced items
6. Execute action     → Only now perform the actual operation
```

## Event Security

### RegisterNetEvent vs AddEventHandler

Show the critical difference with examples:
- RegisterNetEvent: for client→server communication (network events)
- AddEventHandler: for same-context events only (client→client or server→server)

Using AddEventHandler for network events = any resource can trigger it locally = security hole.

### Securing Server Events

```lua
-- BAD: No validation at all
RegisterNetEvent('shop:buy', function(item, count, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeMoney(price)        -- Client controls the price!
    xPlayer.addInventoryItem(item, count) -- Client controls the item and count!
end)

-- GOOD: Full server-side validation
local SHOP_COORD <const> = vector3(441.1, -981.1, 30.7)
local MAX_DISTANCE <const> = 10.0
local COOLDOWN <const> = 3
local cooldowns = {}

RegisterNetEvent('shop:buy', function(itemName)
    local src = source

    -- 1. Player exists?
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- 2. Cooldown?
    if cooldowns[src] and (os.time() - cooldowns[src]) < COOLDOWN then return end
    cooldowns[src] = os.time()

    -- 3. Item exists in config?
    local item = Config.ShopItems[itemName]
    if not item then return end

    -- 4. Proximity? (SERVER coords, not client)
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - SHOP_COORD) > MAX_DISTANCE then return end

    -- 5. Has enough money?
    if xPlayer.getMoney() < item.price then return end

    -- 6. Execute
    xPlayer.removeMoney(item.price)
    xPlayer.addInventoryItem(item.name, 1)
end)
```

Show the same pattern for QBCore.

## What MUST Be Server-Side

Table:
| Operation | Client Can | Server Must |
|---|---|---|
| Add/remove money | Request only | Validate + execute |
| Add/remove items | Request only | Validate + execute |
| Give/remove weapons | Request only | Validate + execute |
| Set job/grade | Never | Full control |
| Database operations | Never | Full control |
| Admin commands | Never trigger | Verify permissions |
| Spawn vehicles | Request only | Validate + create |
| Teleport player | Never | Validate + execute |

## Anti-Exploit Patterns

### Rate Limiting (Cooldowns)

```lua
local cooldowns = {}
local COOLDOWN_TIME <const> = 5 -- seconds

RegisterNetEvent('myScript:action', function()
    local src = source
    local now = os.time()

    if cooldowns[src] and (now - cooldowns[src]) < COOLDOWN_TIME then
        return -- Too fast, ignore
    end
    cooldowns[src] = now

    -- Process action...
end)

-- Clean up on disconnect
AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
```

### Proximity Validation

ALWAYS use server-side coordinates, NEVER accept coordinates from client:

```lua
-- BAD: Client sends their coordinates
RegisterNetEvent('atm:withdraw', function(clientCoords, amount)
    -- clientCoords can be FAKED
end)

-- GOOD: Server gets coordinates independently
RegisterNetEvent('atm:withdraw', function(amount)
    local src = source
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local nearATM = false

    for _, atmCoord in ipairs(Config.ATMLocations) do
        if #(pedCoords - atmCoord) < 3.0 then
            nearATM = true
            break
        end
    end

    if not nearATM then return end
    -- Process withdrawal...
end)
```

### Input Validation

```lua
RegisterNetEvent('myScript:setName', function(name)
    local src = source

    -- Type check
    if type(name) ~= 'string' then return end

    -- Length check
    if #name < 2 or #name > 32 then return end

    -- Character validation (no special chars)
    if not name:match('^[%a%s]+$') then return end

    -- Process...
end)
```

## Event Naming Security

Use unpredictable, namespaced event names for sensitive operations:

```lua
-- BAD: Predictable names, easy to brute-force
RegisterNetEvent('admin:giveMoney', ...)
RegisterNetEvent('bank:addCash', ...)

-- GOOD: Namespaced with resource name
RegisterNetEvent('myBanking:server:processTransaction', ...)
RegisterNetEvent('myAdmin:server:executeAction', ...)
```

## Source Validation Edge Cases

```lua
RegisterNetEvent('myEvent', function(data)
    local src = source

    -- Validate source is a real player
    if not src or src <= 0 then return end
    if not GetPlayerName(src) then return end

    -- For server-internal events, check if source is server
    -- Server source = 65535
    if src == 65535 then
        -- Event came from server, not a player
    end
end)
```

## Quick Reference

| Pattern | Exploitable? | Fix |
|---|---|---|
| Client sends price/amount | Yes | Server looks up from Config |
| Client sends coordinates | Yes | Server uses GetEntityCoords(GetPlayerPed(src)) |
| Client sends item name | Partially | Server validates against Config |
| No cooldown on events | Yes | Add os.time() cooldown |
| Money handled client-side | Yes | All money ops server-side |
| AddEventHandler for net events | Yes | Use RegisterNetEvent |
| No source validation | Yes | Check player exists first |
