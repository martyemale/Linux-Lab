#!/bin/bash
echo "================================================"
echo "  SCENARIO 1: MES Service Down"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  It's 6:47 AM. The manufacturing floor reports that the
  production tracking system is not responding. Operators
  cannot scan components. The line is stopped.
  
  You SSH into the production server to investigate.
  
OBJECTIVE:
  Identify why the service is down. Restore it. Document
  what happened.
STORY

echo ""
echo "--- STEP 1: Check the service status ---"
echo '  $ systemctl status mes-tracker.service'
echo ""
cat << 'OUTPUT'
  ● mes-tracker.service - Manufacturing Execution Tracker
     Loaded: loaded (/etc/systemd/system/mes-tracker.service)
     Active: failed (Result: exit-code) since Mon 2026-06-09 06:42:12 CDT
    Process: 4521 ExecStart=/opt/mes/bin/tracker (code=exited, status=1/FAILURE)
   Main PID: 4521 (code=exited, status=1/FAILURE)
OUTPUT

echo ""
echo "--- STEP 2: Check the logs ---"
echo '  $ journalctl -u mes-tracker.service --since "06:00" --no-pager'
echo ""
cat << 'OUTPUT'
  Jun 09 06:42:10 prodserver1 tracker[4521]: Loading configuration from /opt/mes/conf/tracker.yaml
  Jun 09 06:42:11 prodserver1 tracker[4521]: ERROR: Invalid YAML syntax at line 47
  Jun 09 06:42:11 prodserver1 tracker[4521]: ERROR: Failed to parse configuration file
  Jun 09 06:42:12 prodserver1 tracker[4521]: FATAL: Cannot start without valid configuration
OUTPUT

echo ""
echo "--- STEP 3: Identify the config change ---"
echo '  $ ls -la /opt/mes/conf/'
echo ""
cat << 'OUTPUT'
  -rw-r--r-- 1 mesadmin mesgroup 2847 Jun 08 23:15 tracker.yaml
  -rw-r--r-- 1 mesadmin mesgroup 2834 Jun 01 08:00 tracker.yaml.bak
OUTPUT

echo ""
echo "--- STEP 4: Compare config files ---"
echo '  $ diff tracker.yaml.bak tracker.yaml'
echo ""
cat << 'OUTPUT'
  47c47
  <   database_port: 3306
  ---
  >   database_port: 3306:
OUTPUT
echo ""
echo "  ROOT CAUSE: Extra colon added to line 47 during"
echo "  last night's maintenance window at 23:15."

echo ""
echo "--- STEP 5: Restore and restart ---"
echo '  $ cp /opt/mes/conf/tracker.yaml.bak /opt/mes/conf/tracker.yaml'
echo '  $ systemctl restart mes-tracker.service'
echo '  $ systemctl status mes-tracker.service'
echo ""
cat << 'OUTPUT'
  ● mes-tracker.service - Manufacturing Execution Tracker
     Loaded: loaded (/etc/systemd/system/mes-tracker.service)
     Active: active (running) since Mon 2026-06-09 06:55:30 CDT
   Main PID: 4892
OUTPUT

echo ""
echo "--- STEP 6: Verify production ---"
echo '  $ curl -s http://localhost:8080/health'
echo '  {"status":"healthy","uptime":"30s","connections":12}'

echo ""
echo "--- INCIDENT SUMMARY ---"
cat << 'SUMMARY'
  Incident:    MES tracking service failure
  Duration:    13 minutes (06:42 - 06:55)
  Root Cause:  YAML syntax error in config (extra colon on line 47)
  Resolution:  Restored backup config, restarted service
  Impact:      Production line halted for ~8 minutes
  Prevention:  Implement config validation before restart
  
  Commands Used:
    systemctl status/restart  - Service management
    journalctl -u             - Service-specific logs
    ls -la                    - File timestamps
    diff                      - Compare file versions
    cp                        - Restore backup
    curl                      - Health check verification
SUMMARY

echo ""
echo "Scenario 1 complete."
