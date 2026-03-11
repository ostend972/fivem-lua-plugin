# Ox Ecosystem

The Ox ecosystem is the modern standard for FiveM development. These libraries work standalone or with any framework (ESX, QBCore, QBOX).

## Setup

In fxmanifest.lua:
```lua
shared_scripts { '@ox_lib/init.lua' }
dependencies { 'ox_lib' }
```

## ox_lib - UI Modules

### Notifications

```lua
-- Client
lib.notify({
    title = 'Success',
    description = 'Item purchased!',
    type = 'success',       -- 'inform', 'error', 'success', 'warning'
    duration = 5000,
    position = 'top',       -- 'top', 'top-right', 'bottom', etc.
    icon = 'check',         -- FontAwesome icon name
})
```

### Context Menu

```lua
lib.registerContext({
    id = 'shop_menu',
    title = 'General Store',
    options = {
        {
            title = 'Water',
            description = 'Fresh water - $5',
            icon = 'bottle-water',
            onSelect = function()
                TriggerServerEvent('shop:buy', 'water')
            end,
        },
        {
            title = 'Bread',
            description = 'Fresh bread - $3',
            icon = 'bread-slice',
            onSelect = function()
                TriggerServerEvent('shop:buy', 'bread')
            end,
        },
    },
})

lib.showContext('shop_menu')
```

### Input Dialog

```lua
local input = lib.inputDialog('Character Name', {
    { type = 'input', label = 'First Name', required = true, min = 2, max = 20 },
    { type = 'input', label = 'Last Name', required = true, min = 2, max = 20 },
    { type = 'number', label = 'Age', required = true, min = 18, max = 99 },
    { type = 'select', label = 'Gender', options = {
        { value = 'male', label = 'Male' },
        { value = 'female', label = 'Female' },
    }},
})

if not input then return end -- Player cancelled
local firstName, lastName, age, gender = input[1], input[2], input[3], input[4]
```

### Alert Dialog

```lua
local alert = lib.alertDialog({
    header = 'Confirm Purchase',
    content = 'Buy this vehicle for $25,000?',
    centered = true,
    cancel = true,
})

if alert == 'confirm' then
    -- Process purchase
end
```

### Progress Bar

```lua
if lib.progressBar({
    duration = 5000,
    label = 'Repairing vehicle...',
    useWhileDead = false,
    canCancel = true,
    disable = { car = true, move = true, combat = true },
    anim = {
        dict = 'mini@repair',
        clip = 'fixing_a_player',
    },
    prop = {
        model = 'prop_tool_wrench',
        bone = 57005,
        pos = vec3(0.14, 0.04, -0.03),
        rot = vec3(-90.0, 0.0, 0.0),
    },
}) then
    -- Success: repair complete
    lib.notify({ description = 'Vehicle repaired!', type = 'success' })
else
    -- Cancelled
    lib.notify({ description = 'Repair cancelled', type = 'error' })
end
```

### Progress Circle

```lua
if lib.progressCircle({
    duration = 3000,
    label = 'Searching...',
    position = 'bottom',
    canCancel = true,
}) then
    -- Done
end
```

### Skillcheck

```lua
local success = lib.skillCheck({'easy', 'easy', 'medium'}, {'w', 'a', 's', 'd'})

if success then
    -- Player passed all stages
end
```

### Text UI

```lua
-- Show
lib.showTextUI('[E] - Open Shop', { position = 'right-center', icon = 'shop' })

-- Hide
lib.hideTextUI()
```

### Radial Menu

```lua
lib.addRadialItem({
    id = 'police_menu',
    icon = 'shield',
    label = 'Police Menu',
    onSelect = function()
        -- Open police actions
    end,
})

-- Remove
lib.removeRadialItem('police_menu')
```

## ox_lib - Utility Modules

### Zones

```lua
-- Sphere zone
local zone = lib.zones.sphere({
    coords = vec3(441.1, -981.1, 30.7),
    radius = 5.0,
    debug = Config.Debug,
    onEnter = function()
        lib.showTextUI('[E] - Interact')
    end,
    onExit = function()
        lib.hideTextUI()
    end,
    inside = function()
        if IsControlJustPressed(0, 38) then
            -- E pressed inside zone
        end
    end,
})

-- Box zone
local zone = lib.zones.box({
    coords = vec3(0, 0, 0),
    size = vec3(10, 10, 5),
    rotation = 45,
    debug = Config.Debug,
    onEnter = function() end,
    onExit = function() end,
})

-- Poly zone
local zone = lib.zones.poly({
    points = {
        vec3(0, 0, 0),
        vec3(10, 0, 0),
        vec3(10, 10, 0),
        vec3(0, 10, 0),
    },
    thickness = 5,
    debug = Config.Debug,
    onEnter = function() end,
    onExit = function() end,
})

-- Remove zone
zone:remove()
```

### Cache (auto-updated values)

```lua
-- These values are automatically cached and updated by ox_lib:
cache.ped           -- PlayerPedId() auto-updated
cache.playerId      -- PlayerId()
cache.serverId      -- GetPlayerServerId()
cache.coords        -- GetEntityCoords(cache.ped)
cache.vehicle       -- Current vehicle (or false)
cache.seat          -- Current seat (or false)
cache.weapon        -- Current weapon hash (or false/nil)

-- Usage: ALWAYS prefer cache over native calls
local dist = #(cache.coords - targetCoords)
```

### Callbacks (simplified)

```lua
-- Server: register
lib.callback.register('myScript:getPrice', function(source, itemName)
    return Config.Prices[itemName] or 0
end)

-- Client: call (async)
local price = lib.callback.await('myScript:getPrice', false, 'bread')
print('Price: ' .. price)

-- Client: call (callback style)
lib.callback('myScript:getPrice', false, function(price)
    print('Price: ' .. price)
end, 'bread')
```

### Locale (translations)

```lua
-- In locales/en.lua
return {
    shop_title = 'General Store',
    not_enough_money = 'You don\'t have enough money!',
    item_purchased = 'You purchased %s for $%d',
}

-- Usage
local text = locale('shop_title')
local msg = locale('item_purchased', 'Bread', 5)
```

## ox_target

```lua
-- Add target to entity
exports.ox_target:addLocalEntity(entity, {
    {
        name = 'talk_to_npc',
        icon = 'fa-solid fa-comments',
        label = 'Talk',
        onSelect = function(data)
            -- Interact with NPC
        end,
        canInteract = function(entity, distance, coords, name, bone)
            return distance < 2.0
        end,
    },
})

-- Add target to model
exports.ox_target:addModel('s_m_y_cop_01', {
    {
        name = 'police_interact',
        icon = 'fa-solid fa-shield',
        label = 'Request Backup',
        onSelect = function() end,
    },
})

-- Add global sphere target
exports.ox_target:addSphereZone({
    coords = vec3(441.1, -981.1, 30.7),
    radius = 1.5,
    debug = Config.Debug,
    options = {
        {
            name = 'open_shop',
            icon = 'fa-solid fa-shop',
            label = 'Open Shop',
            onSelect = function()
                lib.showContext('shop_menu')
            end,
        },
    },
})

-- Remove
exports.ox_target:removeEntity(entity, 'talk_to_npc')
exports.ox_target:removeSphereZone('open_shop')
```

## ox_inventory (brief)

```lua
-- Server: exports
exports.ox_inventory:AddItem(source, 'bread', 5)
exports.ox_inventory:RemoveItem(source, 'bread', 2)
exports.ox_inventory:GetItem(source, 'bread')    -- Returns item data
exports.ox_inventory:CanCarryItem(source, 'bread', 5) -- Bool

-- Client: open inventory
exports.ox_inventory:openInventory('stash', { id = 'police_locker' })
```

## Quick Reference

| Need | ox_lib Function |
|---|---|
| Notification | `lib.notify({...})` |
| Context menu | `lib.registerContext` / `lib.showContext` |
| Input dialog | `lib.inputDialog(title, fields)` |
| Progress bar | `lib.progressBar({...})` |
| Skillcheck | `lib.skillCheck(difficulty, keys)` |
| Text UI | `lib.showTextUI` / `lib.hideTextUI` |
| Zone | `lib.zones.sphere` / `.box` / `.poly` |
| Cache | `cache.ped`, `cache.coords`, `cache.vehicle` |
| Callback | `lib.callback.register` / `lib.callback.await` |
| Target | `exports.ox_target:addSphereZone` |
