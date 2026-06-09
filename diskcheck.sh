#!/bin/bash
THRESHOLD=80
USAGE=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')

echo "Disk usage is at ${USAGE}%"

if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "WARNING: Disk usage exceeds ${THRESHOLD}%!"
    echo "Action required - clean up files immediately"
else
    echo "Status: OK - below ${THRESHOLD}% threshold"
fi
