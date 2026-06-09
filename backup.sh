#!/bin/bash
BACKUP_DIR="$HOME/linux-lab/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Starting backup at $(date)"
echo "Backup directory: $BACKUP_DIR"
echo "========================="

COUNT=0
for file in *.sh; do
    cp "$file" "$BACKUP_DIR/${file%.sh}_${TIMESTAMP}.sh"
    echo "Backed up: $file"
    COUNT=$((COUNT + 1))
done

echo "========================="
echo "Backup complete: $COUNT files copied"
ls -la "$BACKUP_DIR"
