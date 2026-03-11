#!/usr/bin/env bash
# FiveM Lua Quality Check Hook
# Runs automatically after Write/Edit on .lua files
# Checks for critical constitution violations

# Read the tool result from stdin
INPUT=$(cat)

# Extract file path from the tool result
FILE_PATH=$(echo "$INPUT" | grep -oP '"filePath"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check .lua files
if [[ ! "$FILE_PATH" =~ \.lua$ ]]; then
  exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

WARNINGS=""

# Check 1: while true without Wait
if grep -qP 'while\s+true\s+do' "$FILE_PATH"; then
  # Check if Wait exists somewhere in the file (basic check)
  if ! grep -qP '\bWait\s*\(' "$FILE_PATH"; then
    WARNINGS="${WARNINGS}\n⚠️ CRITICAL: 'while true do' found without any Wait() call in $FILE_PATH"
  fi
fi

# Check 2: GetPlayerPed(-1) deprecated
if grep -qP 'GetPlayerPed\s*\(\s*-1\s*\)' "$FILE_PATH"; then
  WARNINGS="${WARNINGS}\n⚠️ HIGH: Deprecated GetPlayerPed(-1) found. Use PlayerPedId() or cache.ped instead in $FILE_PATH"
fi

# Check 3: string.format in SQL context
if grep -qP 'string\.format.*[Ss][Qq][Ll]|[Ss][Qq][Ll].*string\.format|string\.format.*MySQL|MySQL.*string\.format' "$FILE_PATH"; then
  WARNINGS="${WARNINGS}\n⚠️ CRITICAL: string.format used near SQL queries. Use prepared statements (@params) in $FILE_PATH"
fi

# Check 4: Global variables (basic heuristic - function without local)
if grep -qP '^\s*function\s+\w+\s*\(' "$FILE_PATH"; then
  if grep -cP '^\s*function\s+\w+\s*\(' "$FILE_PATH" | grep -qvP '^0$'; then
    # Only warn if there are non-local functions that aren't method definitions
    NON_LOCAL=$(grep -cP '^\s*function\s+(?!.*[:.])' "$FILE_PATH" 2>/dev/null || echo "0")
    if [ "$NON_LOCAL" -gt 0 ]; then
      WARNINGS="${WARNINGS}\n⚠️ MEDIUM: $NON_LOCAL global function(s) detected. Use 'local function' in $FILE_PATH"
    fi
  fi
fi

# Output warnings if any found
if [ -n "$WARNINGS" ]; then
  echo -e "\n🔍 FiveM Lua Quality Check:${WARNINGS}"
  echo -e "\n📋 Run /fivem.review for a full audit."
fi

exit 0
