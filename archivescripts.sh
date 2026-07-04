#!/bin/bash
ARCHIVE="$HOME/Documents/organized/linux-scripts-archive"
DOWNLOADS="$HOME/Downloads"

mkdir -p "$ARCHIVE"

found=0
for file in "$DOWNLOADS"/*.sh; do
    if [ -f "$file" ]; then
        cp "$file" "$ARCHIVE/"
        echo "Archived: $(basename "$file")"
        found=$((found + 1))
    fi
done

if [ "$found" -eq 0 ]; then
    echo "No .sh files found in Downloads."
else
    echo "Archived $found file(s) to $ARCHIVE"
fi
