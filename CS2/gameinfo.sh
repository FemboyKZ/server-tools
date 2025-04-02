#!/bin/sh

file_path="$(dirname "$0")/serverfiles/game/csgo/gameinfo.gi"
line_to_add="			Game	csgo/addons/metamod"
marker="Game_LowViolence"

dos2unix "$file_path" 2>/dev/null

if [ -f "$file_path" ]; then
    if ! grep -Pq "^\s*Game\s+csgo/addons/metamod\s*$" "$file_path"; then
        sed -i "/$marker/a\\$line_to_add" "$file_path"
        echo "Line added after the marker '$marker'."
    else
        echo "Line already exists in the file."
    fi
else
    echo "File not found: $file_path"
fi
