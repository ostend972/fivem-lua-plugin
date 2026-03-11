---
description: Audit FiveM Lua script code against constitution rules, security patterns, and performance best practices.
handoffs:
  - label: Optimize Performance
    agent: fivem.optimize
    prompt: Optimize the script based on review findings
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). If arguments contain a path, review that specific file or directory. Otherwise, review the current working directory.

## Outline

1. **Load review standards**:
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/constitution.md` — NEVER/ALWAYS rules
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/performance.md` — performance patterns
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/security.md` — security patterns
   - Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/ox-ecosystem.md` — ox_lib best practices

2. **Discover project files**:
   - Find `fxmanifest.lua` to identify resource root
   - List all `.lua` files in the resource
   - Identify client, server, shared files from manifest
   - Read each file

3. **Run audit checks** on every file:

### Constitution Audit (CRITICAL — any failure = must fix)

| # | Check | Severity | Pattern to Detect |
|---|-------|----------|-------------------|
| N1 | lua54 'yes' in fxmanifest | CRITICAL | Missing `lua54 'yes'` |
| N2 | No while true without Wait() | CRITICAL | `while true do` → check Wait() exists inside |
| N3 | No deprecated GetPlayerPed(-1) | HIGH | `GetPlayerPed(-1)` on client |
| N4 | No client-side money/items | CRITICAL | TriggerServerEvent for addMoney/addItem etc. |
| N5 | No global variables | HIGH | Variables without `local` keyword |
| N6 | No string.format in SQL | CRITICAL | `string.format` near MySQL/SQL calls |
| N7 | No TriggerClientEvent without target | HIGH | `TriggerClientEvent` without source parameter |
| N8 | No hardcoded credentials | CRITICAL | Passwords, tokens, API keys in code |
| N9 | RegisterNetEvent before AddEventHandler | HIGH | AddEventHandler('resource:event') without prior RegisterNetEvent |
| N10 | source saved to local in handlers | HIGH | Direct use of `source` after yield |
| A1 | fx_version 'cerulean' | HIGH | Missing or wrong fx_version |
| A2 | Config = {} for config values | MEDIUM | Hardcoded values that should be configurable |
| A3 | Dynamic Wait() in loops | HIGH | Static Wait(0) in proximity loops |
| A4 | Server-side validation | CRITICAL | Server events without source validation |
| A5 | Prepared statements for SQL | HIGH | String concatenation in SQL queries |

### Performance Audit

| # | Check | Impact | Pattern to Detect |
|---|-------|--------|-------------------|
| P1 | Native caching | MEDIUM | Repeated PlayerPedId()/GetEntityCoords() in loops |
| P2 | Dynamic sleep | HIGH | Fixed Wait() in proximity threads |
| P3 | Job-conditional threads | MEDIUM | Threads running for non-relevant jobs |
| P4 | Vector distance | LOW | Vdist()/Vdist2() instead of #(a-b) |
| P5 | Unnecessary tick threads | HIGH | CreateThread with Wait(0) without draw/input need |
| P6 | ox_lib cache usage | MEDIUM | PlayerPedId() instead of cache.ped |
| P7 | Table pre-allocation | LOW | Large tables without pre-allocation hints |
| P8 | String hashing | LOW | GetHashKey() with static strings instead of joaat() |

### Security Audit

| # | Check | Severity | Pattern to Detect |
|---|-------|----------|-------------------|
| S1 | Source validation | CRITICAL | Server events without source check |
| S2 | Parameter validation | HIGH | Missing type/range checks on event params |
| S3 | Permission checks | HIGH | Missing job/grade/permission checks |
| S4 | Proximity validation | MEDIUM | No distance check for physical interactions |
| S5 | Cooldown implementation | MEDIUM | Exploitable repeated actions without cooldown |
| S6 | Event rate limiting | MEDIUM | No protection against event spam |

### ox_lib Best Practices

| # | Check | Impact | Pattern to Detect |
|---|-------|--------|-------------------|
| O1 | Use lib.notify over framework | LOW | ESX.ShowNotification / QBCore.Functions.Notify |
| O2 | Use lib.callback over framework | MEDIUM | ESX.TriggerServerCallback / QBCore callbacks |
| O3 | Use ox_target over old targeting | MEDIUM | DrawText3D or old target systems |
| O4 | Use lib.zones over PolyZone | LOW | PolyZone imports/usage |
| O5 | Use cache.ped/coords | MEDIUM | PlayerPedId()/GetEntityCoords(ped) in loops |

4. **Generate review report**:

```markdown
# FiveM Code Review: [resource_name]

## Summary
- **Files reviewed**: [count]
- **Critical issues**: [count] 🔴
- **High issues**: [count] 🟠
- **Medium issues**: [count] 🟡
- **Low issues**: [count] 🔵
- **Overall grade**: [A/B/C/D/F]

## Grading
- **A**: 0 critical, 0 high
- **B**: 0 critical, 1-2 high
- **C**: 0 critical, 3+ high OR 1 critical (fixed)
- **D**: 1-2 critical unfixed
- **F**: 3+ critical unfixed

## Critical Issues (must fix)
### [Issue ID] [File:Line] [Check ID]
**Problem**: [description]
**Current code**:
```lua
-- Bad code
```
**Fix**:
```lua
-- Corrected code
```

## High Issues (should fix)
[same format]

## Medium Issues (recommended)
[same format]

## Low Issues (nice to have)
[same format]

## Constitution Compliance
| Rule | Status | Details |
|------|--------|---------|
| [rule] | ✓/✗ | [details] |

## Performance Score
- **Idle estimate**: [X]ms (target < 0.2ms)
- **Active estimate**: [X]ms (target < 1ms)
- **Thread count**: [N] (recommend minimum necessary)

## Recommendations
1. [Top priority fix]
2. [Second priority fix]
3. [Third priority fix]
```

5. **Offer to fix**: After presenting the report, ask if the user wants to auto-fix critical and high issues.

## Review Modes

- **Full review** (default): All checks on all files
- **Quick review** (`$ARGUMENTS` contains "quick"): Constitution + Critical security only
- **Performance only** (`$ARGUMENTS` contains "perf"): Performance checks only
- **Security only** (`$ARGUMENTS` contains "security"): Security checks only
