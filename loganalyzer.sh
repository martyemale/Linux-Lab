#!/bin/bash
LOGFILE="$HOME/linux-lab/sample.log"
echo "Generating sample log data..."
cat > "$LOGFILE" << 'LOGDATA'
2026-06-09 08:00:01 INFO Server started
2026-06-09 08:01:15 ERROR Database connection failed
2026-06-09 08:01:16 ERROR Retry attempt 1
2026-06-09 08:01:20 INFO Database connected
2026-06-09 08:05:30 WARNING Disk usage at 75%
2026-06-09 08:10:00 INFO User marty logged in
2026-06-09 08:15:45 ERROR File not found: config.yaml
2026-06-09 08:20:00 INFO Backup started
2026-06-09 08:25:00 INFO Backup complete
2026-06-09 08:30:12 WARNING Memory usage high
2026-06-09 08:35:00 ERROR Connection timeout
2026-06-09 08:40:00 INFO Service restarted
2026-06-09 09:00:00 WARNING CPU spike detected
2026-06-09 09:15:00 ERROR Disk write failure
2026-06-09 09:20:00 INFO Recovery complete
LOGDATA
echo "=============================="
echo "Log Analysis Report"
echo "=============================="
echo ""
echo "Total log entries: $(wc -l < $LOGFILE)"
echo ""
echo "Breakdown by severity:"
for level in INFO WARNING ERROR; do
    COUNT=$(grep -c "$level" "$LOGFILE")
    echo "  $level: $COUNT"
done
echo ""
echo "All ERROR entries:"
grep "ERROR" "$LOGFILE" | while read -r line; do
    echo "  >> $line"
done
echo ""
echo "Timeline: first and last entry"
echo "  First: $(head -1 $LOGFILE)"
echo "  Last:  $(tail -1 $LOGFILE)"
