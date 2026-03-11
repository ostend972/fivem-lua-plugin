# FiveM Script Specification: {{SCRIPT_NAME}}

## Overview
- **Script Name**: {{resource_name}}
- **Framework**: {{ESX Legacy / QBCore / QBOX}}
- **Type**: {{Job Script / System / Minigame / UI / Utility}}
- **Description**: {{1-2 sentence summary}}

## Dependencies
| Dependency | Required | Purpose |
|------------|----------|---------|
| ox_lib | {{Yes/No}} | {{purpose}} |
| ox_target | {{Yes/No}} | {{purpose}} |
| ox_inventory | {{Yes/No}} | {{purpose}} |
| oxmysql | {{Yes/No}} | {{purpose}} |

## Features

### Client-Side
- [ ] {{feature description}}

### Server-Side
- [ ] {{feature description}}

### Shared
- [ ] Config system with all configurable values
- [ ] Locale support

## User Scenarios

### Scenario 1: {{Primary Flow}}
1. Player does {{action}}
2. System responds with {{response}}
3. Result: {{outcome}}

## Database Schema (if needed)
- Table: {{table_name}}
  - Columns: {{list}}

## NUI (if needed)
- Framework: {{Svelte 5 / React + Vite}}
- Pages/Views: {{list}}

## Security Requirements
- [ ] All money/item operations server-side only
- [ ] Server-side proximity validation
- [ ] Event rate limiting
- [ ] Input validation on all server events

## Performance Requirements
- [ ] Dynamic Wait() patterns for proximity checks
- [ ] Job-conditional threads
- [ ] Cached natives
- [ ] No tick loops without Wait()

## Config Values
- {{Config.value}}: {{type}} - {{description}} - {{default}}

## Success Criteria
- [ ] Script starts without errors
- [ ] All features work as described
- [ ] resmon < 0.2ms idle
- [ ] Passes constitution quality gates
- [ ] No security vulnerabilities

## Assumptions
- {{list}}

## Edge Cases
- {{list}}
