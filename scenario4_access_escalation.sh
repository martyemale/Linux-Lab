#!/bin/bash
echo "================================================"
echo "  SCENARIO 4: Vendor Access Escalation"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  Ticket #INC-40821 was submitted last night after the
  MES database began throwing replication errors. The
  database vendor's support engineer already has a
  standard read-only account (vendor_dbsupport) on the
  production server. However, they need temporary
  elevated access to run diagnostic queries and restart
  the replication service. Your manager approves the
  escalation per the existing vendor support agreement.

OBJECTIVE:
  Elevate the existing vendor account permissions
  temporarily. Document the change. Set an automatic
  reversion so elevated access doesn't persist.
STORY

echo ""
echo "--- STEP 1: Verify the existing account ---"
echo '  $ id vendor_dbsupport'
echo ""
cat << 'OUTPUT'
  uid=1003(vendor_dbsupport) gid=1003(vendor_dbsupport) groups=1003(vendor_dbsupport),1008(db-readonly)
OUTPUT
echo ""
echo "  Account exists. Currently in db-readonly group only."

echo ""
echo "--- STEP 2: Verify the ticket and approval ---"
echo '  Ticket:    INC-40821'
echo '  Approved:  Manager verbal + email confirmation'
echo '  Duration:  48-hour window for troubleshooting'
echo '  Scope:     MySQL replication diagnostics and restart'

echo ""
echo "--- STEP 3: Add to elevated group temporarily ---"
echo '  $ groupadd db-elevated 2>/dev/null'
echo '  $ usermod -aG db-elevated vendor_dbsupport'
echo '  $ id vendor_dbsupport'
echo ""
cat << 'OUTPUT'
  uid=1003(vendor_dbsupport) gid=1003(vendor_dbsupport) 
  groups=1003(vendor_dbsupport),1008(db-readonly),1011(db-elevated)
OUTPUT

echo ""
echo "--- STEP 4: Grant scoped sudo permissions ---"
echo '  $ visudo -f /etc/sudoers.d/vendor-escalation'
echo ""
cat << 'OUTPUT'
  # Temporary escalation per INC-40821
  # Approved by: Floor Manager
  # Expires: June 11, 2026
  vendor_dbsupport ALL=(root) NOPASSWD: /usr/bin/systemctl restart mysql, \
    /usr/bin/systemctl status mysql, \
    /usr/bin/mysql -u repl_diag -p*
OUTPUT
echo ""
echo "  Vendor can now restart mysql and run diagnostic queries."
echo "  They CANNOT modify configs, create users, or access"
echo "  other services."

echo ""
echo "--- STEP 5: Expand log access ---"
echo '  $ chown root:db-elevated /var/log/mysql'
echo '  $ chmod 750 /var/log/mysql'
echo '  $ setfacl -m g:db-elevated:rx /var/log/mysql/replication.log'
echo ""
cat << 'OUTPUT'
  setfacl explanation:
    -m             Modify ACL
    g:db-elevated  Apply to group db-elevated
    :rx            Grant read and execute
    
  ACLs allow granular permissions beyond standard chmod.
  The vendor can read the replication log without giving
  access to all logs in the directory.
OUTPUT

echo ""
echo "--- STEP 6: Schedule automatic reversion ---"
echo '  $ cat /opt/scripts/revoke_escalation.sh'
cat << 'OUTPUT'
  #!/bin/bash
  # Auto-revert vendor escalation per INC-40821
  gpasswd -d vendor_dbsupport db-elevated
  rm /etc/sudoers.d/vendor-escalation
  setfacl -x g:db-elevated /var/log/mysql/replication.log
  logger "INC-40821: Vendor escalation reverted automatically"
OUTPUT
echo ""
echo '  $ at now + 48 hours -f /opt/scripts/revoke_escalation.sh'
echo '  job 4 at Wed Jun 11 09:00:00 2026'
echo ""
echo "  Permissions automatically revert in 48 hours."
echo "  No human action required. No forgotten access."

echo ""
echo "--- STEP 7: Notify and log ---"
echo '  $ logger "INC-40821: Vendor access escalated for vendor_dbsupport by $(whoami)"'
echo '  $ echo "$(date) - INC-40821 - vendor_dbsupport elevated" >> /var/log/access_changes.log'

echo ""
echo "--- INCIDENT DOCUMENTATION ---"
cat << 'SUMMARY'
  Ticket:        INC-40821
  Account:       vendor_dbsupport (existing)
  Change:        Added to db-elevated group, scoped sudo,
                 ACL on replication log
  Duration:      48-hour window with auto-revert
  Approved By:   Floor Manager per vendor support agreement
  Reverts:       Automatically via at scheduler

  Commands Used:
    id                     - Verify current access
    usermod -aG            - Add user to group
    visudo -f              - Create scoped sudo file
    chown / chmod          - Set directory permissions
    setfacl                - Granular file ACL
    at now + 48 hours      - Schedule future task
    gpasswd -d             - Remove user from group
    logger                 - Write to system log

  Security Principles:
    Existing account:     No new accounts created
    Ticket-driven:        Change tied to incident number
    Scoped access:        Only commands needed for the task
    Time-bound:           Auto-reverts in 48 hours
    Auditable:            Logged in syslog and access log
    Least privilege:      Read-only expanded, not full admin
SUMMARY

echo ""
echo "Scenario 4 complete."
