# Debugging

Tools and patterns for debugging and profiling FiveM scripts.

## Debug Mode Toggle

```lua
-- config.lua
Config.Debug = false

-- Anywhere in your script
local function debugLog(msg)
    if not Config.Debug then return end
    print(('[%s] %s'):format(GetCurrentResourceName(), msg))
end

-- Usage
debugLog('Player entered zone')
debugLog(('Distance: %.2f'):format(dist))
```

NEVER leave print() statements in production code. Always use a debug toggle.

## Performance Profiling

### Measuring Execution Time

```lua
-- Using os.clock (CPU time)
local start = os.clock()
-- Code to measure
local elapsed = os.clock() - start
print(('Execution: %.4f seconds'):format(elapsed))

-- Using GetGameTimer (wall time, client-side)
local startTime = GetGameTimer()
-- Code to measure
local elapsed = GetGameTimer() - startTime
print(('Execution: %d ms'):format(elapsed))
```

### resmon (Resource Monitor)

Built-in FiveM command to see resource CPU usage:

```
resmon 1       -- Enable resource monitor
resmon 0       -- Disable
```

Shows real-time CPU time per resource. Target: keep each script under 0.2ms average.

### Profiler

```
profiler record 30         -- Record 30 seconds
profiler save my_profile   -- Save results
profiler view my_profile   -- View results in browser
```

## Common Errors and Fixes

### "attempt to index a nil value"

Cause: Accessing a property on a nil variable.

```lua
-- BAD
local xPlayer = ESX.GetPlayerFromId(source)
print(xPlayer.getName())  -- Crashes if xPlayer is nil!

-- GOOD
local xPlayer = ESX.GetPlayerFromId(source)
if not xPlayer then return end
print(xPlayer.getName())
```

### "attempt to call a nil value"

Cause: Calling a function that doesn't exist.

```lua
-- Common cause: Resource not started / dependency missing
-- Fix: Check dependencies in fxmanifest.lua
-- Fix: Check resource start order in server.cfg
```

### "SCRIPT ERROR: @resource/file.lua:XX: ..."

Read the line number, check the exact line. Common causes:
- Nil variable access
- Wrong function arguments
- Missing dependency
- Typo in variable name

### Server/Client Mismatch

```lua
-- Symptom: Event never fires
-- Cause: Event registered on wrong side

-- Server registers:
RegisterNetEvent('myScript:server:action', function() end)

-- Client must trigger the SERVER event:
TriggerServerEvent('myScript:server:action')
-- NOT TriggerEvent('myScript:server:action')  -- This is local only!
```

## Error Handling

### pcall (Protected Call)

```lua
-- Catch runtime errors without crashing the thread
local success, result = pcall(function()
    return riskyOperation()
end)

if not success then
    print('Error: ' .. tostring(result))
    return
end

-- Use result safely
```

### Error Values Pattern

```lua
-- Return nil + error message instead of throwing
local function withdrawMoney(xPlayer, amount)
    if not xPlayer then return nil, 'Player not found' end
    if xPlayer.getMoney() < amount then return nil, 'Insufficient funds' end

    xPlayer.removeMoney(amount)
    return true
end

-- Caller handles errors
local success, err = withdrawMoney(xPlayer, 500)
if not success then
    xPlayer.showNotification(err, 'error')
    return
end
```

### Assert for Pre-conditions

```lua
-- Fail loudly if assumption is violated
local function processPayment(player, amount)
    assert(player ~= nil, 'processPayment: player is nil')
    assert(type(amount) == 'number', 'processPayment: amount must be a number')
    assert(amount > 0, 'processPayment: amount must be positive')

    -- Safe to proceed
end
```

## Development Tools

### dolu_tool

Free, open-source dev tool for FiveM:
- Object spawner and entity debugger
- Copy coordinates (vector3/vector4)
- Move/rotate/delete objects with 3D gizmo
- MLO detection and debugging
- Configurable keybinds
- Install: github.com/dolutattoo/dolu_tool

### FxDK (FiveM Development Kit)

Official IDE by Cfx.re:
- Integrated game preview
- Auto-restart on file changes
- Built-in console
- Resource management

## Pre-Release Checklist

- [ ] `Config.Debug = false`
- [ ] No `print()` statements (use debug toggle)
- [ ] `resmon` shows < 0.2ms per resource
- [ ] No errors in server/client console
- [ ] All events validate source and data
- [ ] All loops have appropriate Wait() values
- [ ] Memory cleaned up (`= nil` for large tables)
- [ ] Test with 2+ players (not just solo)
- [ ] Test edge cases (disconnect during action, empty inventory, etc.)
