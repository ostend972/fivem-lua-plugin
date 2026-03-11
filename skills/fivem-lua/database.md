# Database

Database patterns using oxmysql (the standard MySQL wrapper for FiveM).

## Setup

In fxmanifest.lua:
```lua
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}
dependencies { 'oxmysql' }
```

Database: MariaDB is recommended over MySQL for better compatibility and performance.

## Query Patterns

### SELECT

```lua
-- Single row
local result = MySQL.query.await('SELECT * FROM users WHERE identifier = ?', { identifier })
if result and result[1] then
    local user = result[1]
    print(user.name)
end

-- Single value (scalar)
local money = MySQL.scalar.await('SELECT money FROM users WHERE identifier = ?', { identifier })

-- Single row (prepare returns first row directly)
local user = MySQL.single.await('SELECT * FROM users WHERE identifier = ?', { identifier })
if user then print(user.name) end

-- Multiple rows
local items = MySQL.query.await('SELECT * FROM items WHERE owner = ?', { identifier })
for _, item in ipairs(items or {}) do
    print(item.name, item.count)
end
```

### INSERT

```lua
-- Insert and get ID
local insertId = MySQL.insert.await('INSERT INTO logs (action, source, timestamp) VALUES (?, ?, ?)', {
    'purchase', identifier, os.time()
})

-- Insert with callback (non-blocking)
MySQL.insert('INSERT INTO logs (action, source) VALUES (?, ?)', { 'login', identifier }, function(id)
    print('Inserted log #' .. id)
end)
```

### UPDATE

```lua
-- Update and get affected rows
local affectedRows = MySQL.update.await('UPDATE users SET money = money + ? WHERE identifier = ?', {
    1000, identifier
})

if affectedRows > 0 then
    print('Money updated')
end
```

### DELETE

```lua
MySQL.query.await('DELETE FROM logs WHERE timestamp < ?', { os.time() - 86400 })
```

## Async vs Callback

```lua
-- Callback style (non-blocking, good for fire-and-forget)
MySQL.query('SELECT * FROM users WHERE id = ?', { id }, function(result)
    -- Handle result
end)

-- Async/await style (blocking, must be inside CreateThread)
CreateThread(function()
    local result = MySQL.query.await('SELECT * FROM users WHERE id = ?', { id })
    -- Handle result immediately
end)
```

Rule: Use `.await` inside CreateThread for sequential logic. Use callbacks for independent operations.

## Prepared Statements

oxmysql automatically uses prepared statements. All `?` placeholders are parameterized, preventing SQL injection.

```lua
-- SAFE: Parameterized (automatic protection)
MySQL.query.await('SELECT * FROM users WHERE name = ?', { playerInput })

-- DANGEROUS: String concatenation (SQL INJECTION!)
MySQL.query.await('SELECT * FROM users WHERE name = "' .. playerInput .. '"')
```

NEVER use string concatenation for queries. ALWAYS use `?` placeholders.

## Transactions

```lua
local success = MySQL.transaction.await({
    { 'UPDATE accounts SET money = money - ? WHERE id = ?', { amount, fromAccount } },
    { 'UPDATE accounts SET money = money + ? WHERE id = ?', { amount, toAccount } },
    { 'INSERT INTO transactions (from_id, to_id, amount) VALUES (?, ?, ?)', { fromAccount, toAccount, amount } },
})

if success then
    print('Transaction completed')
else
    print('Transaction rolled back')
end
```

## Common Anti-Patterns

Bad: Query inside a loop
```lua
-- BAD: N+1 query problem
for _, player in ipairs(players) do
    local data = MySQL.query.await('SELECT * FROM users WHERE id = ?', { player.id })
end

-- GOOD: Single query with IN clause
local ids = table.concat(playerIds, ',')
local data = MySQL.query.await('SELECT * FROM users WHERE id IN (' .. string.rep('?,', #playerIds - 1) .. '?)', playerIds)
```

Bad: Not checking results
```lua
-- BAD
local user = MySQL.single.await('SELECT * FROM users WHERE id = ?', { id })
print(user.name) -- Crashes if user is nil!

-- GOOD
local user = MySQL.single.await('SELECT * FROM users WHERE id = ?', { id })
if not user then return end
print(user.name)
```

## Quick Reference

| Method | Returns | Use Case |
|---|---|---|
| `MySQL.query` | `table` (rows) | SELECT multiple rows |
| `MySQL.single` | `table` or `nil` | SELECT single row |
| `MySQL.scalar` | `value` or `nil` | SELECT single value |
| `MySQL.insert` | `number` (insert ID) | INSERT |
| `MySQL.update` | `number` (affected rows) | UPDATE |
| `MySQL.transaction` | `boolean` | Multiple queries atomically |
| `.await` suffix | Synchronous result | Inside CreateThread |
| Callback parameter | Async result | Fire-and-forget |
