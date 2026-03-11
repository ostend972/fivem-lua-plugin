# NUI Patterns

NUI (New UI) allows creating HTML/CSS/JS interfaces inside FiveM.

## Setup

### fxmanifest.lua

```lua
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
```

For framework-based NUI (Svelte, React):
```lua
ui_page 'web/dist/index.html'

files {
    'web/dist/**/*',
}
```

## Lua to JavaScript

### SendNUIMessage

```lua
-- Client: Send data to NUI
SendNUIMessage({
    action = 'open',
    data = {
        title = 'Shop',
        items = Config.Items,
        playerMoney = playerMoney,
    },
})
```

### JavaScript: Receive

```javascript
window.addEventListener('message', (event) => {
    const { action, data } = event.data

    switch (action) {
        case 'open':
            document.getElementById('app').style.display = 'block'
            renderShop(data.items, data.playerMoney)
            break
        case 'close':
            document.getElementById('app').style.display = 'none'
            break
        case 'update':
            updateUI(data)
            break
    }
})
```

## JavaScript to Lua

### RegisterNUICallback

```lua
-- Client: Register callback
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    TriggerServerEvent('shop:buy', data.itemName)
    cb('ok')
end)

RegisterNUICallback('getPlayerData', function(data, cb)
    cb({
        name = GetPlayerName(PlayerId()),
        money = playerMoney,
    })
end)
```

### JavaScript: Send

```javascript
// Close UI
async function closeUI() {
    await fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        body: JSON.stringify({}),
    })
}

// Buy item
async function buyItem(itemName) {
    await fetch(`https://${GetParentResourceName()}/buyItem`, {
        method: 'POST',
        body: JSON.stringify({ itemName }),
    })
}

// Get data with response
async function getPlayerData() {
    const resp = await fetch(`https://${GetParentResourceName()}/getPlayerData`, {
        method: 'POST',
        body: JSON.stringify({}),
    })
    return await resp.json()
}
```

## Focus Management

```lua
-- Give focus to NUI (cursor + keyboard)
SetNuiFocus(true, true)     -- hasFocus, hasCursor

-- Give cursor only (game still controllable)
SetNuiFocus(true, false)

-- Remove focus
SetNuiFocus(false, false)

-- ALWAYS remove focus when closing UI
RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
```

IMPORTANT: Always provide a way to close the NUI. If SetNuiFocus(true, true) is set and there's no close mechanism, the player is STUCK.

## Escape Key to Close

```lua
-- Common pattern: ESC key closes NUI
CreateThread(function()
    while isMenuOpen do
        Wait(0)
        if IsControlJustPressed(0, 200) then -- ESC key
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'close' })
            isMenuOpen = false
        end
    end
end)
```

Or handle it in JavaScript:
```javascript
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeUI()
    }
})
```

## Complete NUI Example

Show a full minimal example with:
1. HTML with a simple shop interface
2. CSS for basic styling
3. JavaScript with message handling and fetch callbacks
4. Lua client with SendNUIMessage, RegisterNUICallback, SetNuiFocus
5. How to open/close properly

## Framework Recommendations (2026)

| Framework | Pros | Best For |
|---|---|---|
| Svelte 5 + Vite + TS | Ultra-lightweight, compile-time perf | New projects, performance |
| React + Vite + TS | Large ecosystem, many devs know it | Teams with React experience |
| Vue 3 + Vite + TS | Simple, reactive, good DX | Quick prototypes |
| Vanilla HTML/CSS/JS | Zero build step, simple | Very simple UIs |

### Boilerplates

- Svelte: `kCore-framework/fivem-svelte-boilerplate-lua`
- React: `project-error/fivem-react-boilerplate-lua`
- React modern: `Teezy-Core/fivem-nui-boilerplate`

## Anti-Patterns

```lua
-- BAD: No way to close
SetNuiFocus(true, true)
SendNUIMessage({ action = 'open' })
-- Player is now STUCK if JS has no close button

-- GOOD: Always provide close mechanism
SetNuiFocus(true, true)
SendNUIMessage({ action = 'open' })
-- Plus ESC handler and close button in HTML
```
