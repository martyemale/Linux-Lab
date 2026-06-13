#!/bin/bash
echo "=============================="
echo "  Manufacturing Asset Tracker"
echo "  Date: $(date)"
echo "=============================="

# Generate sample asset inventory
cat > assets.txt << 'DATA'
SN-40821 Server Dell-R660xs Rack-A3 Active 2024-03-15
SN-40822 Switch Cisco-9300 Rack-A3 Active 2024-03-15
SN-40823 KVM TESmart-4Port Bench-B1 Active 2024-06-01
SN-40824 Server Dell-R660xs Rack-A4 Maintenance 2024-03-15
SN-40825 Workstation Lenovo-P360 Bench-B2 Active 2024-07-20
SN-40826 UPS APC-3000 Rack-A3 Active 2024-03-15
SN-40827 Monitor Dell-U2723 Bench-B1 Inactive 2024-06-01
SN-40828 Server HPE-DL380 Rack-A5 Active 2024-09-10
SN-40829 Firewall Palo-Alto Rack-A3 Active 2024-03-15
SN-40830 Server Dell-R660xs Rack-A4 Maintenance 2025-01-12
DATA

echo ""
echo "--- All Serial Numbers ---"
awk '{print $1}' assets.txt

echo ""
echo "--- Active Assets ---"
awk '$5 == "Active" {print $1, $2, $3, $4}' assets.txt

echo ""
echo "--- Assets in Maintenance ---"
awk '$5 == "Maintenance" {print $1, $3, $4}' assets.txt

echo ""
echo "--- Asset Count by Status ---"
echo "  Active: $(awk '$5 == "Active"' assets.txt | wc -l | tr -d ' ')"
echo "  Maintenance: $(awk '$5 == "Maintenance"' assets.txt | wc -l | tr -d ' ')"
echo "  Inactive: $(awk '$5 == "Inactive"' assets.txt | wc -l | tr -d ' ')"

echo ""
echo "--- Assets by Location ---"
awk '{print $4}' assets.txt | sort | uniq -c | sort -rn

echo ""
echo "--- Servers Only ---"
awk '$2 == "Server" {print $1, $3, $4, $5}' assets.txt

echo ""
echo "Asset report complete."
