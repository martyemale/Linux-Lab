#!/bin/bash
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Shell: $SHELL"
echo "Disk Usage:"
df -h /
echo "Running Processes: $(ps aux | wc -l)"
