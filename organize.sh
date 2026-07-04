#!/bin/bash
FRATERNITY_DIR="$HOME/Documents/organized/fraternity"
DOWNLOADS="$HOME/Downloads"

mkdir -p "$FRATERNITY_DIR"

found=0
for file in "$DOWNLOADS"/*GAK* "$DOWNLOADS"/*gak*; do
    if [ -f "$file" ]; then
        mv "$file" "$FRATERNITY_DIR/"
        echo "Moved: $(basename "$file")"
        found=$((found + 1))
    fi
done

if [ "$found" -eq 0 ]; then
    echo "No GAK files found in Downloads."
else
    echo "Moved $found file(s) to $FRATERNITY_DIR"
fi
