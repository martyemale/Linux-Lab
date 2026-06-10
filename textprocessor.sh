#!/bin/bash
echo "=============================="
echo "  Text Processing with sed"
echo "  Date: $(date)"
echo "=============================="

# Create sample config file
cat > sample_config.txt << 'CONFIG'
# Server Configuration
hostname=localhost
port=8080
max_connections=100
log_level=INFO
database_host=localhost
database_port=3306
admin_email=admin@example.com
debug_mode=false
CONFIG

echo ""
echo "Original config:"
cat sample_config.txt

echo ""
echo "========================="
echo "sed demonstrations:"
echo "========================="

echo ""
echo "1. Replace localhost with 192.168.1.50:"
sed 's/localhost/192.168.1.50/g' sample_config.txt | grep -v "^#"

echo ""
echo "2. Change port 8080 to 443:"
sed 's/8080/443/' sample_config.txt | grep port

echo ""
echo "3. Show only uncommented lines:"
sed '/^#/d' sample_config.txt

echo ""
echo "4. Add prefix to every line:"
sed 's/^/  >> /' sample_config.txt

echo ""
echo "5. Replace in-place (backup first):"
cp sample_config.txt sample_config.txt.bak
sed -i '' 's/false/true/' sample_config.txt
echo "  debug_mode changed:"
grep debug_mode sample_config.txt
echo "  backup preserved:"
grep debug_mode sample_config.txt.bak

echo ""
echo "Processing complete."
