#!/bin/bash
echo "================================================"
echo "  SCENARIO 2: Disk Space Emergency"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  3:12 AM alert: Production database server /var partition
  is at 94% capacity. Automated backups will fail at 95%.
  If backups fail, the company loses its recovery point
  and compliance is violated.

OBJECTIVE:
  Find what's consuming space. Clean it up safely.
  Prevent it from happening again.
STORY

echo ""
echo "--- STEP 1: Assess the damage ---"
echo '  $ df -h'
echo ""
cat << 'OUTPUT'
  Filesystem      Size  Used Avail Use% Mounted on
  /dev/sda1        50G   8G   42G  16% /
  /dev/sda2        20G   2G   18G  10% /boot
  /dev/sda3       200G  188G  12G  94% /var
  /dev/sda4       100G  45G   55G  45% /home
OUTPUT

echo ""
echo "--- STEP 2: Find the biggest directories ---"
echo '  $ du -sh /var/* | sort -rh | head -10'
echo ""
cat << 'OUTPUT'
  98G   /var/log
  45G   /var/lib/mysql
  30G   /var/backups
  12G   /var/cache
  3G    /var/tmp
OUTPUT

echo ""
echo "--- STEP 3: Drill into /var/log ---"
echo '  $ find /var/log -type f -size +1G -exec ls -lh {} \;'
echo ""
cat << 'OUTPUT'
  -rw-r--r-- 1 root root 34G Jun  9 03:00 /var/log/mes-tracker/app.log
  -rw-r--r-- 1 root root 28G Jun  9 03:00 /var/log/mes-tracker/debug.log
  -rw-r--r-- 1 root root 19G Jun  8 23:59 /var/log/mes-tracker/app.log.1
  -rw-r--r-- 1 root root 12G Jun  7 23:59 /var/log/mes-tracker/app.log.2
OUTPUT
echo ""
echo "  ROOT CAUSE: Application logging at DEBUG level"
echo "  in production. Logs growing ~34GB per day."
echo "  Log rotation exists but can't keep up."

echo ""
echo "--- STEP 4: Immediate cleanup ---"
echo '  # Truncate active log (safer than rm on open files)'
echo '  $ > /var/log/mes-tracker/debug.log'
echo '  $ rm /var/log/mes-tracker/app.log.1'
echo '  $ rm /var/log/mes-tracker/app.log.2'
echo ""
echo '  $ df -h /var'
cat << 'OUTPUT'
  Filesystem      Size  Used Avail Use% Mounted on
  /dev/sda3       200G  129G  71G  65% /var
OUTPUT
echo ""
echo "  Space recovered: 59GB freed. Down to 65%."

echo ""
echo "--- STEP 5: Fix the root cause ---"
echo '  # Change log level from DEBUG to WARNING'
echo '  $ sed -i "s/log_level=DEBUG/log_level=WARNING/" /opt/mes/conf/tracker.yaml'
echo '  $ systemctl restart mes-tracker.service'
echo ""
echo '  # Configure log rotation'
echo '  $ cat /etc/logrotate.d/mes-tracker'
cat << 'OUTPUT'
  /var/log/mes-tracker/*.log {
      daily
      rotate 7
      compress
      maxsize 1G
      missingok
      notifempty
      postrotate
          systemctl reload mes-tracker
      endscript
  }
OUTPUT

echo ""
echo "--- STEP 6: Set up monitoring ---"
echo '  # Add disk space check to cron'
echo '  $ crontab -e'
echo '  0 */4 * * * /opt/scripts/diskcheck.sh | mail -s "Disk Report" admin@company.com'

echo ""
echo "--- INCIDENT SUMMARY ---"
cat << 'SUMMARY'
  Incident:    /var partition at 94% capacity
  Duration:    22 minutes (03:12 - 03:34)
  Root Cause:  DEBUG logging in production generating 34GB/day
  Resolution:  Truncated logs, removed old rotations, changed
               log level to WARNING, configured logrotate
  Impact:      No data loss. Backups resumed successfully.
  Prevention:  Logrotate policy, disk monitoring cron job,
               log level policy for production environments

  Commands Used:
    df -h              - Filesystem usage overview
    du -sh             - Directory size summary
    find -size +1G     - Find files over 1GB
    > filename         - Truncate file to zero bytes
    rm                 - Remove old log files
    sed -i             - Edit config in place
    logrotate          - Automated log rotation
    crontab -e         - Schedule recurring checks
SUMMARY

echo ""
echo "Scenario 2 complete."
