---
description: Create or update a FiveM Lua script specification from a natural language description.
handoffs:
  - label: Build Technical Plan
    agent: fivem.plan
    prompt: Create a plan for this FiveM script spec
    send: true
  - label: Review Existing Code
    agent: fivem.review
    prompt: Review existing code against the specification
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/fivem.specify` is the script description. Do not ask the user to repeat it unless they provided an empty command.

Given that description, do this:

1. **Load the FiveM constitution**: Read `${CLAUDE_PLUGIN_ROOT}/skills/fivem-lua/constitution.md` to understand non-negotiable rules.

2. **Determine framework**: From the description or project context, identify:
   - Framework: ESX Legacy, QBCore, or QBOX
   - If not specified, ask user to choose (recommend QBOX for new projects)
   - Load the corresponding patterns file (`esx-patterns.md` or `qbcore-patterns.md`)

3. **Create project directory** (if new script):
   - Create the script folder with the name derived from the description
   - Initialize the spec directory: `specs/` inside the script folder
   - Create `specs/spec.md` using the template below

4. **Follow this execution flow**:

   1. Parse user description
      If empty: ERROR "No script description provided"
   2. Extract key concepts:
      - Script purpose (job, minigame, system, UI, etc.)
      - Target framework (ESX/QBCore/QBOX)
      - Client-side features needed
      - Server-side features needed
      - Database requirements
      - NUI requirements (if any)
      - Dependencies (ox_lib, ox_target, ox_inventory, etc.)
   3. For unclear aspects:
      - Make informed guesses based on FiveM best practices
      - Mark with [NEEDS CLARIFICATION] only if critical (max 3)
   4. Fill specification sections
   5. Return: SUCCESS (spec ready for planning)

5. **Write the specification** to `specs/spec.md`:

```markdown
# FiveM Script Specification: [SCRIPT NAME]

## Overview
- **Script Name**: [resource_name] (snake_case, no spaces)
- **Framework**: [ESX Legacy / QBCore / QBOX]
- **Type**: [Job Script / System / Minigame / UI / Utility / Other]
- **Description**: [1-2 sentence summary]

## Dependencies
| Dependency | Required | Purpose |
|------------|----------|---------|
| ox_lib | Yes/No | [Why needed] |
| ox_target | Yes/No | [Why needed] |
| ox_inventory | Yes/No | [Why needed] |
| oxmysql | Yes/No | [Why needed] |

## Features

### Client-Side
- [ ] [Feature 1 description]
- [ ] [Feature 2 description]

### Server-Side
- [ ] [Feature 1 description]
- [ ] [Feature 2 description]

### Shared
- [ ] Config system with all configurable values
- [ ] Locale support (if needed)

## User Scenarios

### Scenario 1: [Primary Flow]
1. Player does [action]
2. System responds with [response]
3. Result: [outcome]

### Scenario 2: [Secondary Flow]
[...]

## Database Schema (if needed)
- Table: [table_name]
  - Columns: [list]
  - Relationships: [if any]

## NUI (if needed)
- Framework: [Svelte 5 / React + Vite]
- Pages/Views: [list]

## Security Requirements
- [ ] All money/item operations server-side only
- [ ] Server-side proximity validation
- [ ] Event rate limiting
- [ ] Input validation on all server events

## Performance Requirements
- [ ] Dynamic Wait() patterns for proximity checks
- [ ] Job-conditional threads
- [ ] Cached natives (PlayerPedId, GetEntityCoords)
- [ ] No tick loops without Wait()

## Config Values
List all values that should be in Config:
- [Config.value1]: [type] - [description] - [default]

## Success Criteria
- [ ] Script starts without errors
- [ ] All features work as described
- [ ] No performance warnings in resmon (< 0.2ms idle)
- [ ] Passes constitution quality gates
- [ ] No security vulnerabilities

## Assumptions
- [List any assumptions made]

## Edge Cases
- [List edge cases to handle]
```

6. **Validate the spec**:
   - Check all mandatory sections are filled
   - Verify framework choice is consistent throughout
   - Ensure security requirements align with constitution
   - Ensure performance requirements align with constitution
   - Check that dependencies match features (e.g., ox_target if using target interactions)

7. **Handle [NEEDS CLARIFICATION]**:
   If any remain (max 3), present options to user:
   ```
   ## Question [N]: [Topic]
   **Context**: [relevant detail]
   **Options**:
   | Option | Answer | Implications |
   |--------|--------|--------------|
   | A | [answer] | [impact] |
   | B | [answer] | [impact] |
   | C | [answer] | [impact] |
   ```
   Wait for user response, then update spec.

8. **Report completion**: Output spec file path, framework choice, dependencies identified, and readiness for `/fivem.plan`.

## Quick Guidelines

- Focus on **WHAT** the script does and **WHY**
- Include all FiveM-specific requirements (framework, deps, client/server split)
- Always include security and performance requirements (from constitution)
- Config values must be exhaustive - anything that might change goes in Config
- Resource name must be snake_case (e.g., `my_job_script`)
