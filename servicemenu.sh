#!/bin/bash

show_disk() {
    echo "Disk Usage:"
    df -h / | tail -1 | awk '{print "  Used: "$3" / "$2" ("$5" full)"}'
}

show_network() {
    echo "Network Info:"
    echo "  IP: $(ifconfig en0 | grep 'inet ' | awk '{print $2}')"
    echo "  Hostname: $(hostname)"
}

show_processes() {
    echo "Process Summary:"
    echo "  Total: $(ps aux | wc -l | tr -d ' ')"
    echo "  Top CPU consumer: $(ps aux | sort -nrk 3,3 | head -1 | awk '{print $11}')"
}

echo "=============================="
echo "  System Admin Menu"
echo "=============================="
echo "1) Disk Usage"
echo "2) Network Info"
echo "3) Process Summary"
echo "4) Run All"
echo "=============================="
read -p "Select an option: " choice

case $choice in
    1) show_disk ;;
    2) show_network ;;
    3) show_processes ;;
    4) show_disk; echo ""; show_network; echo ""; show_processes ;;
    *) echo "Invalid option: $choice" ;;
esac
