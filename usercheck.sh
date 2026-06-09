#!/bin/bash
echo "=============================="
echo "User Account Report"
echo "Date: $(date)"
echo "=============================="

echo ""
echo "Users with login shells:"
echo "--------------------------"
while IFS=: read -r username password uid gid comment home shell; do
    if [ "$uid" -ge 500 ] 2>/dev/null; then
        echo "User: $username | UID: $uid | Home: $home | Shell: $shell"
    fi
done < /etc/passwd

echo ""
echo "Total accounts in /etc/passwd: $(wc -l < /etc/passwd)"
echo "Currently logged in:"
who | wc -l
