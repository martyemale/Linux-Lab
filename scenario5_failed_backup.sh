#!/bin/bash
echo "================================================"
echo "  SCENARIO 5: Failed Backup Investigation"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  A drive failure on the production database server
  triggers a restore request. The team discovers that
  nightly backups haven't run for 7 days. The most
  recent backup is from June 2nd. Leadership needs
  to know why backups stopped and when they can
  expect recovery.

OBJECTIVE:
  Investigate why the cron job failed. Fix it.
  Run an immediate backup. Implement monitoring
  so silent failures never happen again.
STORY

echo ""
echo "--- STEP 1: Check the backup directory ---"
echo '  $ ls -lh /var/backups/database/'
echo ""
cat << 'OUTPUT'
  -rw-r--r-- 1 root root 2.1G Jun  2 01:00 db_backup_20260602.sql.gz
  -rw-r--r-- 1 root root 2.1G Jun  1 01:00 db_backup_20260601.sql.gz
  -rw-r--r-- 1 root root 2.0G May 31 01:00 db_backup_20260531.sql.gz
OUTPUT
echo ""
echo "  Last backup: June 2nd. Today is June 9th."
echo "  Seven days of backups missing."

echo ""
echo "--- STEP 2: Check the cron job ---"
echo '  $ crontab -l'
echo ""
cat << 'OUTPUT'
  # Nightly database backup
  0 1 * * * /opt/scripts/db_backup.sh >> /var/log/backup.log 2>&1
OUTPUT
echo ""
echo "  Cron schedule explanation:"
echo "    0     = minute 0"
echo "    1     = hour 1 (1:00 AM)"
echo "    *     = every day of month"
echo "    *     = every month"
echo "    *     = every day of week"
echo "  Translation: runs every night at 1:00 AM"
echo ""
echo "  Cron entry exists. Job should be running."

echo ""
echo "--- STEP 3: Check the backup log ---"
echo '  $ tail -30 /var/log/backup.log'
echo ""
cat << 'OUTPUT'
  [2026-06-02 01:00:01] Starting database backup...
  [2026-06-02 01:00:45] Backup complete: db_backup_20260602.sql.gz (2.1G)
  [2026-06-03 01:00:01] Starting database backup...
  [2026-06-03 01:00:02] ERROR: mysqldump: Got error: 1045: 
    Access denied for user 'backup_user'@'localhost' (using password: YES)
  [2026-06-03 01:00:02] Backup FAILED
  [2026-06-04 01:00:01] Starting database backup...
  [2026-06-04 01:00:02] ERROR: mysqldump: Got error: 1045: 
    Access denied for user 'backup_user'@'localhost' (using password: YES)
  [2026-06-04 01:00:02] Backup FAILED
OUTPUT
echo ""
echo "  ROOT CAUSE: Database password for backup_user was"
echo "  changed on June 3rd during a security rotation."
echo "  The backup script still uses the old password."
echo "  The cron job ran every night but failed silently."

echo ""
echo "--- STEP 4: Check the backup script ---"
echo '  $ cat /opt/scripts/db_backup.sh'
echo ""
cat << 'OUTPUT'
  #!/bin/bash
  BACKUP_DIR="/var/backups/database"
  DATE=$(date +%Y%m%d)
  LOGFILE="/var/log/backup.log"
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting database backup..." >> $LOGFILE
  
  mysqldump -u backup_user -pOldPassword123 --all-databases | \
    gzip > ${BACKUP_DIR}/db_backup_${DATE}.sql.gz
  
  if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup complete: db_backup_${DATE}.sql.gz" >> $LOGFILE
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup FAILED" >> $LOGFILE
  fi
OUTPUT
echo ""
echo "  PROBLEM 1: Password hardcoded in the script"
echo "  PROBLEM 2: No alert on failure — fails silently"

echo ""
echo "--- STEP 5: Fix the backup script ---"
echo '  $ cat /opt/scripts/db_backup_fixed.sh'
echo ""
cat << 'OUTPUT'
  #!/bin/bash
  BACKUP_DIR="/var/backups/database"
  DATE=$(date +%Y%m%d)
  LOGFILE="/var/log/backup.log"
  CRED_FILE="/root/.db_backup_creds"
  ALERT_EMAIL="infra-team@company.com"
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting database backup..." >> $LOGFILE
  
  mysqldump --defaults-extra-file=$CRED_FILE --all-databases | \
    gzip > ${BACKUP_DIR}/db_backup_${DATE}.sql.gz
  
  if [ $? -eq 0 ]; then
    SIZE=$(ls -lh ${BACKUP_DIR}/db_backup_${DATE}.sql.gz | awk '{print $5}')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup complete: ${SIZE}" >> $LOGFILE
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BACKUP FAILED" >> $LOGFILE
    echo "Database backup failed on $(hostname) at $(date)" | \
      mail -s "ALERT: Backup Failure" $ALERT_EMAIL
    logger "CRITICAL: Database backup failed on $(hostname)"
  fi
OUTPUT
echo ""
echo "  FIX 1: Credentials in a protected file (chmod 600)"
echo "  FIX 2: Email alert on failure"
echo "  FIX 3: Syslog entry for centralized monitoring"

echo ""
echo "--- STEP 6: Secure the credentials file ---"
echo '  $ cat /root/.db_backup_creds'
cat << 'OUTPUT'
  [client]
  user=backup_user
  password=NewSecurePassword456
OUTPUT
echo '  $ chmod 600 /root/.db_backup_creds'
echo '  $ chown root:root /root/.db_backup_creds'
echo '  $ ls -la /root/.db_backup_creds'
echo '  -rw------- 1 root root 58 Jun 9 09:15 /root/.db_backup_creds'
echo ""
echo "  Only root can read this file. Password is not"
echo "  visible in the script, cron logs, or process list."

echo ""
echo "--- STEP 7: Run immediate backup ---"
echo '  $ /opt/scripts/db_backup_fixed.sh'
echo '  $ tail -1 /var/log/backup.log'
echo '  [2026-06-09 09:20:15] Backup complete: 2.1G'
echo ""
echo '  $ ls -lh /var/backups/database/ | tail -1'
echo '  -rw-r--r-- 1 root root 2.1G Jun 9 09:20 db_backup_20260609.sql.gz'

echo ""
echo "--- STEP 8: Add backup verification cron ---"
echo '  $ crontab -e'
cat << 'OUTPUT'
  # Nightly database backup
  0 1 * * * /opt/scripts/db_backup_fixed.sh >> /var/log/backup.log 2>&1
  
  # Morning backup verification
  0 7 * * * /opt/scripts/verify_backup.sh
OUTPUT
echo ""
echo '  verify_backup.sh checks if today backup file exists'
echo '  and is larger than 1GB. Alerts if missing or too small.'

echo ""
echo "--- INCIDENT SUMMARY ---"
cat << 'SUMMARY'
  Incident:      7 days of missing database backups
  Root Cause:    Password rotation on June 3rd broke the
                 backup script. No alerting on failure.
  Resolution:    Updated credentials using secure file,
                 ran immediate backup, added failure alerts
  Data Impact:   Recovery point is June 2nd instead of today.
                 7 days of data at risk if second drive fails.
  Prevention:
    - Credentials in protected files, not scripts
    - Email alerts on backup failure
    - Morning verification cron job
    - Syslog integration for central monitoring

  Commands Used:
    crontab -l / -e       - View and edit cron jobs
    tail                  - Read log files
    mysqldump             - Database backup utility
    chmod 600             - Restrict credential file
    mail                  - Send alert email
    logger                - Write to syslog
    $? (exit code)        - Check if previous command succeeded

  Cron Format:
    MIN HOUR DOM MON DOW command
    0   1    *   *   *   = every day at 1:00 AM
    0   7    *   *   *   = every day at 7:00 AM
    */5 *    *   *   *   = every 5 minutes
    0   0    1   *   *   = first of every month at midnight
SUMMARY

echo ""
echo "Scenario 5 complete."
