#!/bin/bash
echo "=============================="
echo "  Permission Audit Report"
echo "  Date: $(date)"
echo "=============================="

SCAN_DIR="${1:-.}"

echo ""
echo "Scanning: $SCAN_DIR"
echo ""

echo "World-writable files (security risk):"
FOUND=0
for file in $(find "$SCAN_DIR" -type f -perm -o=w 2>/dev/null); do
    echo "  WARNING: $file"
    FOUND=$((FOUND + 1))
done
if [ "$FOUND" -eq 0 ]; then
    echo "  None found - OK"
fi

echo ""
echo "Executable scripts:"
for file in $(find "$SCAN_DIR" -name "*.sh" -type f); do
    PERMS=$(ls -la "$file" | awk '{print $1}')
    echo "  $PERMS  $file"
done

echo ""
echo "Files by permission:"
echo "  700 (owner only): $(find "$SCAN_DIR" -type f -perm 700 2>/dev/null | wc -l | tr -d ' ')"
echo "  755 (owner+read): $(find "$SCAN_DIR" -type f -perm 755 2>/dev/null | wc -l | tr -d ' ')"
echo "  644 (standard):   $(find "$SCAN_DIR" -type f -perm 644 2>/dev/null | wc -l | tr -d ' ')"

echo ""
echo "Audit complete."
