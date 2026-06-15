#!/bin/bash
echo "================================================"
echo "  SCENARIO 11: Runaway Process Performance"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  It's 2:30 PM. The manufacturing floor reports the
  MES interface is extremely slow. Page loads take 30+
  seconds. Operators are hand-writing tracking data on
  paper as a workaround. You SSH in and even the shell
  feels sluggish.

OBJECTIVE:
  Identify the resource hog. Determine if it's critical
  or rogue. Take appropriate action to restore
  performance without killing essential services.
STORY

echo ""
echo "--- STEP 1: Quick system overview ---"
echo '  $ uptime'
cat << 'OUTPUT'
  14:32:15 up 45 days, 3:12, 4 users, load average: 12.84, 11.27, 8.53
OUTPUT
echo ""
echo "  Load average: 12.84 / 11.27 / 8.53"
echo "  (1 min / 5 min / 15 min)"
echo ""
echo "  This server has 4 CPU cores. A load of 12.84"
echo "  means processes are waiting 3x longer than they"
echo "  should. The load is climbing (8 -> 11 -> 12)."
echo ""
echo "  Rule of thumb: load average should stay below"
echo "  the number of CPU cores. 4 cores = stay under 4."

echo ""
echo "--- STEP 2: Find the resource hog ---"
echo '  $ top -bn1 | head -20'
cat << 'OUTPUT'
  top - 14:32:20 up 45 days, 4 users, load average: 12.84, 11.27, 8.53
  Tasks: 287 total,   4 running, 283 sleeping
  %Cpu(s): 94.2 us,  3.1 sy,  0.0 ni,  1.8 id,  0.0 wa,  0.9 hi
  MiB Mem:  16384.0 total,   412.3 free, 14821.7 used,  1150.0 buff/cache
  MiB Swap:  8192.0 total,  6144.0 free,  2048.0 used

    PID USER     PR  NI    VIRT    RES  %CPU %MEM  TIME+  COMMAND
  18432 appuser  20   0  12.5g  11.2g  385  68.4  4:32:17 data_import
   4521 mesuser  20   0   2.1g   1.8g   12  11.0  45:12.3 mes-tracker
   4890 mysql    20   0   4.2g   3.1g    8  18.9  12:05:4 mysqld
    587 root     20   0   512m   128m    2   0.8   1:23.4 systemd
OUTPUT
echo ""
echo "  FOUND IT: PID 18432 'data_import' by appuser"
echo "    - 385% CPU (using all 4 cores)"
echo "    - 11.2GB RAM (68% of total memory)"
echo "    - Running for 4 hours 32 minutes"
echo "    - Swap usage at 2GB (system is out of RAM)"

echo ""
echo "--- STEP 3: Investigate the process ---"
echo '  $ ps -fp 18432'
cat << 'OUTPUT'
  UID      PID  PPID  C STIME TTY  TIME     CMD
  appuser  18432  1   99 10:00 ?   4:32:17  /opt/tools/data_import --full --no-limit
OUTPUT
echo ""
echo '  $ ls -la /proc/18432/cwd'
cat << 'OUTPUT'
  lrwxrwxrwx 1 appuser appuser 0 Jun 9 14:33 /proc/18432/cwd -> /opt/tools
OUTPUT
echo ""
echo "  Someone kicked off a full data import at 10 AM"
echo "  with the --no-limit flag, meaning no throttling."
echo "  This is a legitimate process but misconfigured —"
echo "  it's eating all resources because it wasn't limited."

echo ""
echo "--- STEP 4: Reduce priority immediately ---"
echo '  # Renice to lowest priority so MES gets CPU first'
echo '  $ renice 19 -p 18432'
cat << 'OUTPUT'
  18432 (process ID) old priority 0, new priority 19
OUTPUT
echo ""
cat << 'OUTPUT'
  Nice values: -20 (highest priority) to 19 (lowest priority)
    Default:  0
    Negative: only root can set (higher priority)
    Positive: any user can lower their own priority

  Common usage:
    nice -n 10 command     Start command with low priority
    renice 19 -p PID       Lower running process priority
    renice -5 -p PID       Raise priority (root only)
OUTPUT

echo ""
echo "--- STEP 5: Limit memory usage with cgroups ---"
echo '  $ systemd-run --scope -p MemoryMax=2G --uid=appuser /opt/tools/data_import --full'
echo '  (For a running process, use cgroup directly:)'
echo '  $ echo 2147483648 > /sys/fs/cgroup/memory/import_job/memory.limit_in_bytes'
echo ""
cat << 'OUTPUT'
  cgroups (control groups) limit resources per process:
    MemoryMax     Cap memory usage
    CPUQuota      Limit CPU percentage
    IOWeight      Control disk I/O priority
    
  Exam tests cgroups v1 and v2 concepts.
OUTPUT

echo ""
echo "--- STEP 6: Check system recovery ---"
echo '  After renice:'
echo '  $ uptime'
cat << 'OUTPUT'
  14:38:15 up 45 days, 3:18, 4 users, load average: 6.21, 9.84, 8.97
OUTPUT
echo ""
echo "  Load dropping: 12.84 -> 6.21 (1 min average)"
echo "  MES application is responding again."
echo "  Data import still running but at lowest priority."

echo ""
echo "--- STEP 7: Monitor ongoing ---"
echo '  $ vmstat 5 3'
cat << 'OUTPUT'
  procs ----memory---- ---swap--- ----io---- -system-- ------cpu------
   r  b   swpd   free   si   so    bi    bo   in   cs  us sy id wa st
   3  0 2048000 812000   10    5   120   340  890 4521  62 8  28  2  0
   2  0 2048000 890000    5    0    80   210  670 3200  45 6  47  2  0
   1  0 2020000 1024000   0    0    40   180  520 2800  30 5  63  2  0
OUTPUT
echo ""
echo "  Reading vmstat columns:"
echo "    r   = processes waiting for CPU (decreasing: good)"
echo "    swpd = swap used (decreasing: system recovering)"
echo "    free = free memory (increasing: good)"
echo "    us  = user CPU% (decreasing: import yielding CPU)"
echo "    id  = idle CPU% (increasing: resources freeing up)"

echo ""
echo "--- STEP 8: Prevent recurrence ---"
echo '  # Create a systemd service with resource limits'
echo '  $ cat /etc/systemd/system/data-import.service'
cat << 'OUTPUT'
  [Unit]
  Description=Scheduled Data Import

  [Service]
  Type=oneshot
  User=appuser
  ExecStart=/opt/tools/data_import --full
  Nice=15
  MemoryMax=2G
  CPUQuota=50%
  IOWeight=50
  TimeoutStopSec=3600

  [Install]
  WantedBy=multi-user.target
OUTPUT
echo ""
echo "  Future imports run through systemd with:"
echo "    Nice=15      Low CPU priority"
echo "    MemoryMax=2G Can't consume more than 2GB"
echo "    CPUQuota=50% Can't use more than 2 of 4 cores"
echo "    IOWeight=50  Reduced disk I/O priority"

echo ""
echo "--- PERFORMANCE MONITORING REFERENCE ---"
cat << 'SUMMARY'
  Real-time Monitoring:
    top                   Interactive process viewer
    top -bn1              Single snapshot (for scripts)
    htop                  Enhanced interactive viewer
    vmstat 5              System stats every 5 seconds
    iostat 5              Disk I/O stats every 5 seconds
    sar                   Historical system activity

  Process Priority:
    nice -n VALUE cmd     Start with priority
    renice VALUE -p PID   Change running process
    Values: -20 (highest) to 19 (lowest)
    Default: 0
    Only root can go negative

  Memory Analysis:
    free -h               Memory summary
    cat /proc/meminfo     Detailed memory info
    swapon --show         Swap device info
    vmstat                Swap activity (si/so columns)

  CPU Analysis:
    uptime                Load averages
    mpstat                Per-CPU statistics
    /proc/cpuinfo         CPU hardware info
    nproc                 Number of CPU cores
    lscpu                 CPU architecture info

  Process Investigation:
    ps -fp PID            Full details on one process
    /proc/PID/cwd         Working directory
    /proc/PID/cmdline     Full command line
    /proc/PID/status      Process status details
    lsof -p PID           Files opened by process
    strace -p PID         System calls (advanced)

  Resource Limits:
    ulimit -a             Show user limits
    /etc/security/limits.conf   Set permanent limits
    cgroups v1/v2         Kernel-level resource control
    systemd resource directives (MemoryMax, CPUQuota)
SUMMARY

echo ""
echo "Scenario 11 complete."
