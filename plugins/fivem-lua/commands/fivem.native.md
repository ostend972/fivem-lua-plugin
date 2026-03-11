---
description: Search and document FiveM/GTA V natives — find the right native function for any game operation with usage examples in Lua.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The user wants to find or learn about a specific GTA V / FiveM native function. Use the search query from `$ARGUMENTS`.

1. **Load native reference**: Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/natives-reference.md` for common natives.

2. **Determine search type**:
   - If `$ARGUMENTS` is a native name (e.g., "GetEntityCoords"): look up that specific native
   - If `$ARGUMENTS` is a hash (e.g., "0xE8522D58"): look up by hash
   - If `$ARGUMENTS` is a description (e.g., "how to get player position"): search for matching natives
   - If `$ARGUMENTS` is a namespace (e.g., "VEHICLE"): list common natives in that namespace

3. **Search strategy**:
   a. First check the local natives-reference.md for the native
   b. If not found locally, use context7 to search FiveM documentation:
      - Search `fivem/fivem` or `overextended/ox_lib` on context7
   c. If still not found, use web search for `site:docs.fivem.net/natives [query]`
   d. If needed, fetch the specific native page: `https://docs.fivem.net/natives/?_0x[HASH]`

4. **Present results** in this format:

```markdown
## [NativeName]

**Namespace**: [NAMESPACE] | **API Set**: [client/server/shared] | **Hash**: 0x[HASH]

### Signature (Lua)
```lua
local result = NativeName(param1, param2, ...)
```

### Parameters
| Name | Type | Description |
|------|------|-------------|
| param1 | type | description |

### Returns
| Type | Description |
|------|-------------|
| type | description |

### Description
[What this native does, any important notes]

### Usage Example
```lua
-- Example in FiveM Lua context
[practical example code]
```

### Related Natives
- [Related native 1] — [brief description]
- [Related native 2] — [brief description]

### Performance Notes
- [Any optimization tips for this native]
- [ox_lib cache alternative if applicable]
```

5. **If searching by description**, present a table of matching natives:

```markdown
## Search Results: "[query]"

| Native | Namespace | Side | Description |
|--------|-----------|------|-------------|
| GetEntityCoords | ENTITY | shared | Get entity position |
| SetEntityCoords | ENTITY | shared | Set entity position |

Select a native for detailed documentation.
```

6. **If listing a namespace**, show the most commonly used natives:

```markdown
## Namespace: [NAME]

**Total natives**: ~[N] | **Docs**: https://docs.fivem.net/natives/?n_[NAME]

### Most Used
| Native | Side | Description |
|--------|------|-------------|
| [name] | [side] | [description] |
```

## Native Namespaces Reference

45 namespaces available:

**Most Used**: CFX, PLAYER, PED, ENTITY, VEHICLE, OBJECT, HUD, STREAMING, CAM, TASK, GRAPHICS, NETWORK, INTERIOR, WEAPON

**All**: APP, AUDIO, BRAIN, CAM, CFX, CLOCK, CUTSCENE, DATAFILE, DECORATOR, DLC, ENTITY, EVENT, FILES, FIRE, GRAPHICS, HUD, INTERIOR, ITEMSET, LOADINGSCREEN, LOCALIZATION, MISC, MOBILE, MONEY, NETSHOPPING, NETWORK, OBJECT, PAD, PATHFIND, PED, PHYSICS, PLAYER, RECORDING, REPLAY, SAVEMIGRATION, SCRIPT, SECURITY, SHAPETEST, SOCIALCLUB, STATS, STREAMING, SYSTEM, TASK, VEHICLE, WATER, WEAPON, ZONE

## Quick Tips

- Always check if a native is **client-only**, **server-only**, or **shared**
- Server natives use `source` (player server ID), client natives use `PlayerId()` or `PlayerPedId()`
- Many natives marked "RPC" can be called from server and execute on client
- Use `joaat('string')` instead of `GetHashKey('string')` for static hashes
- Prefer ox_lib cache (`cache.ped`, `cache.coords`) over repeated native calls in loops
- Full reference: https://docs.fivem.net/natives/
