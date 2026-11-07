#!/usr/bin/env bash
# Syntax check for every Lua file in the addon and the test harness.
set -eo pipefail
cd "$(dirname "$0")/.."

if command -v lua5.1 >/dev/null 2>&1; then
  LUA=lua5.1
elif command -v lua5.4 >/dev/null 2>&1; then
  LUA=lua5.4
else
  LUA=lua
fi

echo "Interprete: $LUA"
count=0
while IFS= read -r file; do
  "$LUA" -e "local chunk, err = loadfile('$file'); if not chunk then error(err, 0) end"
  count=$((count + 1))
done < <(find ForeverHUD tests -name '*.lua' -print | sort)

echo "OK: $count ficheros Lua sin errores de sintaxis"
