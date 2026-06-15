#!/bin/bash
echo "================================================"
echo "  SCENARIO 3: Network Connectivity Failure"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  You arrive at a customer site Monday morning. You open
  your laptop and try to SSH into the production server
  at 10.0.50.25. Connection times out. The server was
  working fine Friday. Nobody touched it over the weekend.
  The floor supervisor says the system is running locally
  but remote access is down.

OBJECTIVE:
  Systematically troubleshoot the network path from your
  laptop to the server. Restore remote access.
STORY

echo ""
echo "--- STEP 1: Verify your own network ---"
echo '  $ ip addr show (Linux) / ifconfig en0 (Mac)'
echo ""
cat << 'OUTPUT'
  inet 10.0.50.100/24 brd 10.0.50.255
OUTPUT
echo "  You have an IP on the correct subnet. Good."

echo ""
echo "--- STEP 2: Ping the server ---"
echo '  $ ping -c 4 10.0.50.25'
echo ""
cat << 'OUTPUT'
  PING 10.0.50.25 (10.0.50.25): 56 data bytes
  Request timeout for icmp_seq 0
  Request timeout for icmp_seq 1
  Request timeout for icmp_seq 2
  Request timeout for icmp_seq 3
  --- 10.0.50.25 ping statistics ---
  4 packets transmitted, 0 packets received, 100% packet loss
OUTPUT
echo "  Server not responding to ping. Could be firewall or server is down."

echo ""
echo "--- STEP 3: Ping the gateway ---"
echo '  $ ip route show default'
echo '  default via 10.0.50.1 dev eth0'
echo '  $ ping -c 2 10.0.50.1'
echo ""
cat << 'OUTPUT'
  PING 10.0.50.1 (10.0.50.1): 56 data bytes
  64 bytes from 10.0.50.1: icmp_seq=0 ttl=64 time=1.2ms
  64 bytes from 10.0.50.1: icmp_seq=1 ttl=64 time=0.9ms
OUTPUT
echo "  Gateway responds. Network infrastructure is fine."
echo "  Problem is between the gateway and the server."

echo ""
echo "--- STEP 4: Check if SSH port is open ---"
echo '  $ nc -zv 10.0.50.25 22 -w 5'
echo ""
cat << 'OUTPUT'
  nc: connect to 10.0.50.25 port 22 (tcp) timed out: Operation in progress
OUTPUT
echo "  Port 22 not reachable. SSH service or firewall issue."

echo ""
echo "--- STEP 5: Walk to server room, check locally ---"
echo '  Plugged monitor and keyboard directly into server.'
echo '  $ systemctl status sshd'
echo ""
cat << 'OUTPUT'
  ● sshd.service - OpenSSH server daemon
     Loaded: loaded (/usr/lib/systemd/system/sshd.service)
     Active: active (running)
OUTPUT
echo "  SSH daemon is running. Problem is the firewall."

echo ""
echo "--- STEP 6: Check firewall rules ---"
echo '  $ firewall-cmd --list-all'
echo ""
cat << 'OUTPUT'
  public (active)
    target: default
    services: dhcpv6-client
    ports:
OUTPUT
echo ""
echo "  ROOT CAUSE: SSH service not allowed through firewall."
echo "  Someone ran a firewall reset over the weekend that"
echo "  wiped the custom rules."

echo ""
echo "--- STEP 7: Restore SSH access ---"
echo '  $ firewall-cmd --permanent --add-service=ssh'
echo '  $ firewall-cmd --permanent --add-port=8080/tcp'
echo '  $ firewall-cmd --reload'
echo '  $ firewall-cmd --list-all'
echo ""
cat << 'OUTPUT'
  public (active)
    target: default
    services: dhcpv6-client ssh
    ports: 8080/tcp
OUTPUT

echo ""
echo "--- STEP 8: Verify remote access ---"
echo '  Back at your laptop:'
echo '  $ ssh admin@10.0.50.25'
echo '  Last login: Fri Jun 6 17:30:22 2026'
echo '  admin@prodserver1 ~$ '
echo ""
echo "  Remote access restored."

echo ""
echo "--- INCIDENT SUMMARY ---"
cat << 'SUMMARY'
  Incident:    SSH remote access failure to production server
  Duration:    18 minutes (troubleshooting time)
  Root Cause:  Firewall rules reset over weekend, SSH service
               removed from allowed services list
  Resolution:  Re-added SSH and application port to firewall,
               reloaded firewall configuration
  Impact:      No production impact (system ran locally),
               remote management was unavailable
  Prevention:  Backup firewall rules, document all custom
               rules, alert on firewall config changes

  Troubleshooting Path:
    1. ip addr / ifconfig     - Verify own network
    2. ping server            - Test reachability
    3. ping gateway           - Isolate network segment
    4. nc -zv (netcat)        - Test specific port
    5. systemctl status sshd  - Verify service locally
    6. firewall-cmd --list    - Check firewall rules
    7. firewall-cmd --add     - Restore access
    8. ssh                    - Verify fix

  Key Concept: Troubleshoot layer by layer.
    Physical -> IP -> Gateway -> Port -> Service -> Firewall
SUMMARY

echo ""
echo "Scenario 3 complete."
