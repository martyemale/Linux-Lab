#!/bin/bash
echo "================================================"
echo "  Regular Expressions Reference"
echo "  Date: $(date)"
echo "================================================"

echo ""
echo "--- BASIC REGEX ---"
echo "  .        Any single character"
echo "  *        Zero or more of previous"
echo "  ^        Start of line"
echo "  \$        End of line"
echo "  [ ]      Character class"
echo "  [^ ]     Negated class"
echo "  \        Escape special character"

echo ""
echo "--- EXTENDED REGEX (grep -E or egrep) ---"
echo "  +        One or more of previous"
echo "  ?        Zero or one of previous"
echo "  |        OR (alternation)"
echo "  ( )      Grouping"
echo "  { }      Repetition count"

echo ""
echo "--- PRACTICAL EXAMPLES ---"
echo ""

cat > /tmp/regex_test.txt << 'DATA'
192.168.1.100 - - [09/Jun/2026] "GET /index.html" 200
10.0.50.25 - admin [09/Jun/2026] "POST /login" 401
172.16.0.5 - - [09/Jun/2026] "GET /api/data" 200
192.168.1.100 - - [09/Jun/2026] "GET /style.css" 200
10.0.50.30 - - [09/Jun/2026] "DELETE /api/user" 403
192.168.1.200 - root [09/Jun/2026] "POST /admin" 500
DATA

echo "Test log file:"
cat /tmp/regex_test.txt

echo ""
echo "1. Lines starting with 192:"
grep "^192" /tmp/regex_test.txt

echo ""
echo "2. Lines ending with 200:"
grep "200$" /tmp/regex_test.txt

echo ""
echo "3. Lines containing POST or DELETE:"
grep -E "POST|DELETE" /tmp/regex_test.txt

echo ""
echo "4. Lines with any 40x error:"
grep -E "40[0-9]" /tmp/regex_test.txt

echo ""
echo "5. Lines with a username (not just -):"
grep -v "\- \-" /tmp/regex_test.txt

echo ""
echo "6. Extract just IP addresses:"
grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /tmp/regex_test.txt

echo ""
echo "7. Count requests per IP:"
grep -oE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /tmp/regex_test.txt | sort | uniq -c | sort -rn

echo ""
echo "--- COMMON EXAM PATTERNS ---"
echo "  grep '^root' /etc/passwd       Lines starting with root"
echo "  grep 'bash\$' /etc/passwd       Lines ending with bash"
echo "  grep -E '^[A-Z]' file          Lines starting with uppercase"
echo "  grep -v '^#' config            Remove comment lines"
echo "  grep -c 'ERROR' logfile        Count error lines"
echo "  grep -i 'warning' logfile      Case insensitive search"
echo "  grep -r 'TODO' /src/           Recursive search in directory"

echo ""
rm /tmp/regex_test.txt
echo "Regex guide complete."
