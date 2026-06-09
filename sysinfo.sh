#!/bin/bash
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Shell: $SHELL"
echo "Disk Usage:"
df -h /
echo "Running Processes: $(ps aux | wc -l)"
echo "========================="
echo "Network Info:"
ifconfig en0 | grep "inet "
echo "========================="
echo "Top 5 CPU Processes:"
ps aux | sort -nrk 3,3 | head -5
echo "========================="
echo "Logged In Users:"
who
