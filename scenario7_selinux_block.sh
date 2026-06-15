#!/bin/bash
echo "================================================"
echo "  SCENARIO 7: SELinux Blocking Application"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  The development team deployed a web application to a
  new RHEL 9 server. Nginx is running, config files are
  correct, file permissions are set properly, but every
  request returns 403 Forbidden. The dev team says
  "it works on my machine." The server has SELinux
  enforcing — their dev machines don't.

OBJECTIVE:
  Identify SELinux as the cause. Fix the security
  context. Keep SELinux enforcing — never disable it
  as a shortcut.
STORY

echo ""
echo "--- STEP 1: Verify the basics ---"
echo '  $ systemctl status nginx'
echo '  Active: active (running)'
echo ""
echo '  $ ls -la /var/www/app/'
cat << 'OUTPUT'
  drwxr-xr-x 3 nginx nginx 4096 Jun 9 10:00 .
  -rw-r--r-- 1 nginx nginx 1205 Jun 9 10:00 index.html
  -rw-r--r-- 1 nginx nginx 4521 Jun 9 10:00 app.js
  drwxr-xr-x 2 nginx nginx 4096 Jun 9 10:00 assets
OUTPUT
echo ""
echo "  Service running. Files exist. Permissions correct."
echo "  Standard troubleshooting says this should work."

echo ""
echo "--- STEP 2: Check the error log ---"
echo '  $ tail /var/log/nginx/error.log'
cat << 'OUTPUT'
  2026/06/09 10:15:32 [error] 4521#0: *1 open() "/var/www/app/index.html"
  failed (13: Permission denied), client: 10.0.50.100
OUTPUT
echo ""
echo "  Permission denied — but ls -la shows correct perms."
echo "  This is the classic SELinux symptom."

echo ""
echo "--- STEP 3: Check SELinux status ---"
echo '  $ getenforce'
echo '  Enforcing'
echo ""
echo '  $ sestatus'
cat << 'OUTPUT'
  SELinux status:                 enabled
  SELinuxfs mount:                /sys/fs/selinux
  SELinux root directory:         /etc/selinux
  Loaded policy name:             targeted
  Current mode:                   enforcing
  Mode from config file:          enforcing
OUTPUT
echo ""
echo "  SELinux is enforcing. Three modes to know:"
echo "    Enforcing  = blocks and logs violations"
echo "    Permissive = logs but does NOT block"
echo "    Disabled   = completely off (not recommended)"

echo ""
echo "--- STEP 4: Check SELinux audit log ---"
echo '  $ ausearch -m avc -ts recent'
cat << 'OUTPUT'
  type=AVC msg=audit(1717934132.451:892): avc: denied { read } 
  for pid=4521 comm="nginx" name="index.html" dev="sda2" ino=524321
  scontext=system_u:system_r:httpd_t:s0 
  tcontext=unconfined_u:object_r:default_t:s0 tclass=file
OUTPUT
echo ""
echo "  KEY FINDING: The file has context 'default_t'"
echo "  but nginx (httpd_t) needs 'httpd_sys_content_t'"

echo ""
echo "--- STEP 5: Compare security contexts ---"
echo '  $ ls -Z /var/www/app/'
cat << 'OUTPUT'
  unconfined_u:object_r:default_t:s0 index.html
  unconfined_u:object_r:default_t:s0 app.js
  unconfined_u:object_r:default_t:s0 assets
OUTPUT
echo ""
echo '  $ ls -Z /var/www/html/'
cat << 'OUTPUT'
  system_u:object_r:httpd_sys_content_t:s0 index.html
OUTPUT
echo ""
echo "  The default /var/www/html has the correct context."
echo "  The new /var/www/app was copied without preserving"
echo "  SELinux labels — it got 'default_t' instead of"
echo "  'httpd_sys_content_t'."

echo ""
echo "--- STEP 6: Fix the security context ---"
echo '  # Set the correct context for all files'
echo '  $ semanage fcontext -a -t httpd_sys_content_t "/var/www/app(/.*)?"'
echo '  $ restorecon -Rv /var/www/app/'
cat << 'OUTPUT'
  Relabeled /var/www/app from default_t to httpd_sys_content_t
  Relabeled /var/www/app/index.html from default_t to httpd_sys_content_t
  Relabeled /var/www/app/app.js from default_t to httpd_sys_content_t
  Relabeled /var/www/app/assets from default_t to httpd_sys_content_t
OUTPUT

echo ""
echo "--- STEP 7: Verify the fix ---"
echo '  $ ls -Z /var/www/app/'
cat << 'OUTPUT'
  system_u:object_r:httpd_sys_content_t:s0 index.html
  system_u:object_r:httpd_sys_content_t:s0 app.js
  system_u:object_r:httpd_sys_content_t:s0 assets
OUTPUT
echo ""
echo '  $ curl -s http://localhost/app/ | head -1'
echo '  <!DOCTYPE html>'
echo ""
echo "  Application now loads. SELinux still enforcing."

echo ""
echo "--- WHAT NOT TO DO ---"
cat << 'WARNING'
  NEVER do these as a fix:
  
  $ setenforce 0           # Sets permissive — hides the problem
  $ sed -i 's/enforcing/disabled/' /etc/selinux/config
                            # Disables SELinux permanently
  
  Disabling SELinux to fix an application is like removing
  the lock from your front door because you lost your key.
  The correct fix is always to set the right context.
WARNING

echo ""
echo "--- SELINUX COMMAND REFERENCE ---"
cat << 'SUMMARY'
  Status:
    getenforce                     Show current mode
    sestatus                       Detailed status
    setenforce 1                   Set enforcing (temporary)
    setenforce 0                   Set permissive (temporary)
    /etc/selinux/config            Permanent mode setting

  Contexts:
    ls -Z                          Show file contexts
    ps -Z                          Show process contexts
    id -Z                          Show user context

  Fix Contexts:
    restorecon -Rv /path           Restore default contexts
    semanage fcontext -a -t TYPE "/path(/.*)?"
                                   Define context rule
    chcon -t TYPE file             Change context (temporary)

  Troubleshoot:
    ausearch -m avc -ts recent     Search audit log
    sealert -a /var/log/audit/audit.log
                                   Human-readable alerts
    audit2why < /var/log/audit/audit.log
                                   Explain why denied

  Booleans (toggle features):
    getsebool -a                   List all booleans
    setsebool -P httpd_can_network_connect on
                                   Allow httpd network access

  Common Types:
    httpd_sys_content_t     Web content (read only)
    httpd_sys_rw_content_t  Web content (read/write)
    var_log_t               Log files
    etc_t                   Config files
    user_home_t             User home files
SUMMARY

echo ""
echo "Scenario 7 complete."
