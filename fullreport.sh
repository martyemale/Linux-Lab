#!/bin/bash
REPORT="system_report_$(date +%Y%m%d_%H%M%S).txt"

echo "Generating full system report..."
echo ""

{
    echo "================================================"
    echo "  FULL SYSTEM REPORT"
    echo "  Generated: $(date)"
    echo "  By: $(whoami)@$(hostname)"
    echo "================================================"
    
    echo ""
    echo "--- SYSTEM INFO ---"
    echo "Hostname: $(hostname)"
    echo "User: $(whoami)"
    echo "Uptime: $(uptime)"
    echo "Shell: $SHELL"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    
    echo ""
    echo "--- DISK ---"
    df -h /
    
    echo ""
    echo "--- NETWORK ---"
    ifconfig en0 | grep "inet "
    
    echo ""
    echo "--- TOP 5 CPU ---"
    ps aux | sort -nrk 3,3 | head -5
    
    echo ""
    echo "--- LOGGED IN USERS ---"
    who
    
    echo ""
    echo "--- PROCESS COUNT ---"
    echo "Total: $(ps aux | wc -l | tr -d ' ')"
    
    echo ""
    echo "================================================"
    echo "  END OF REPORT"
    echo "================================================"
} > "$REPORT"

echo "Report saved to: $REPORT"
echo "Size: $(wc -c < $REPORT | tr -d ' ') bytes"
echo ""
echo "Preview (first 10 lines):"
head -10 "$REPORT"
