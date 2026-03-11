---
description: Analyze and optimize FiveM Lua script performance — threads, natives, memory, and network.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). If arguments contain a path, optimize that specific file. Otherwise, optimize the entire resource.

## Outline

1. **Load optimization standards**:
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/performance.md` — all optimization patterns
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/ox-ecosystem.md` — ox_lib cache and utilities
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/constitution.md` — performance-related rules

2. **Discover and read all Lua files** in the resource.

3. **Performance analysis** — check each file for:

### Thread Optimization
- [ ] All proximity loops use dynamic Wait() pattern
- [ ] Job-conditional threads stop when job doesn't match
- [ ] No unnecessary tick (Wait(0)) threads
- [ ] Threads clean up on resource stop
- [ ] No nested CreateThread inside loops

### Native Optimization
- [ ] Frequently called natives are cached as locals at file top
- [ ] `cache.ped` used instead of `PlayerPedId()` in loops
- [ ] `cache.coords` used instead of `GetEntityCoords()` in loops
- [ ] `cache.vehicle` used instead of `GetVehiclePedIsIn()` in loops
- [ ] `#(a - b)` used instead of `Vdist()` / `Vdist2()`
- [ ] `joaat()` used instead of `GetHashKey()` for static strings
- [ ] Squared distance comparisons where possible (`dist * dist` vs `dist`)

### Memory Optimization
- [ ] Large tables set to nil when no longer needed
- [ ] Event handlers cleaned up on resource stop
- [ ] No circular references in tables
- [ ] Strings pre-computed outside loops where possible

### Network Optimization
- [ ] Minimal data in TriggerServerEvent / TriggerClientEvent
- [ ] State bags used for persistent synced data
- [ ] No excessive event triggering (rate limiting)
- [ ] Batch operations instead of per-item events

### ox_lib Optimization
- [ ] lib.zones used instead of manual distance threads
- [ ] lib.points used for proximity callbacks
- [ ] cache module used for player data
- [ ] lib.callback used instead of manual event pairs

4. **Generate optimization report**:

```markdown
# Performance Optimization: [resource_name]

## Current Performance Estimate
- **Client idle**: ~[X]ms
- **Client active**: ~[X]ms
- **Server per-player**: ~[X]ms
- **Thread count**: [N]
- **Event frequency**: [estimate]

## Optimizations Applied

### [OPT-001] [File:Line] Thread Sleep Optimization
**Before**: Fixed Wait(0) in proximity loop
**After**: Dynamic Wait() based on distance
**Impact**: ~[X]ms saved when player is far

```lua
-- Before
CreateThread(function()
    while true do
        Wait(0)
        -- check distance every frame
    end
end)

-- After
CreateThread(function()
    while true do
        local sleep = 1000
        local dist = #(cache.coords - targetCoords)
        if dist < 50.0 then
            sleep = 500
            if dist < 10.0 then
                sleep = 0
                -- interaction logic
            end
        end
        Wait(sleep)
    end
end)
```

### [OPT-002] [File:Line] Native Caching
[same format for each optimization]

## Estimated Performance After Optimization
- **Client idle**: ~[X]ms (was [X]ms)
- **Client active**: ~[X]ms (was [X]ms)
- **Improvement**: ~[X]% reduction

## Optimization Summary
| Category | Issues Found | Fixed | Improvement |
|----------|-------------|-------|-------------|
| Thread | [N] | [N] | [estimate] |
| Native | [N] | [N] | [estimate] |
| Memory | [N] | [N] | [estimate] |
| Network | [N] | [N] | [estimate] |
| ox_lib | [N] | [N] | [estimate] |
| **Total** | **[N]** | **[N]** | **[estimate]** |
```

5. **Apply optimizations**: After presenting the report, automatically apply all optimizations to the files. Show a diff summary of all changes made.

6. **Post-optimization validation**:
   - Verify all changes maintain correct behavior
   - Re-check constitution compliance
   - Confirm no regressions introduced

## Optimization Priority Order

1. **Critical**: Threads without Wait(), infinite loops
2. **High**: Static Wait(0) in proximity loops, uncached natives in loops
3. **Medium**: Missing ox_lib cache, Vdist usage, missing job conditionals
4. **Low**: String optimization, table pre-allocation, joaat usage
