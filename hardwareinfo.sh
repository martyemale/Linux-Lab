#!/bin/bash
echo "================================================"
echo "  Hardware Information Reference"
echo "  Date: $(date)"
echo "================================================"

echo ""
echo "--- CPU ---"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo "OS: $(uname -s)"
sysctl -n hw.ncpu 2>/dev/null && echo " cores" || nproc 2>/dev/null

echo ""
echo "--- MEMORY ---"
sysctl -n hw.memsize 2>/dev/null | awk '{print "Total RAM: " $1/1024/1024/1024 " GB"}' || free -h 2>/dev/null

echo ""
echo "--- DISK ---"
df -h / | tail -1

echo ""
echo "--- HARDWARE COMMANDS (Linux exam) ---"
echo "  lscpu          - CPU details"
echo "  lsblk          - Block devices (disks)"
echo "  lspci          - PCI devices (network cards, GPUs)"
echo "  lsusb          - USB devices"
echo "  lsmem          - Memory ranges"
echo "  dmidecode      - BIOS/hardware details (root)"
echo "  cat /proc/cpuinfo  - CPU info from proc"
echo "  cat /proc/meminfo  - Memory info from proc"
echo "  uname -a       - All system info"
echo "  uname -r       - Kernel version only"
echo "  uname -m       - Architecture only"

echo ""
echo "--- KERNEL MODULES ---"
echo "  lsmod              - List loaded modules"
echo "  modprobe <name>    - Load a module"
echo "  modprobe -r <name> - Remove a module"
echo "  modinfo <name>     - Module details"
echo "  /etc/modprobe.d/   - Module config directory"

echo ""
echo "--- DEVICE MANAGEMENT ---"
echo "  /dev/sda       - First SCSI/SATA disk"
echo "  /dev/sdb       - Second disk"
echo "  /dev/sda1      - First partition on first disk"
echo "  /dev/nvme0n1   - First NVMe drive"
echo "  /dev/sr0       - CD/DVD drive"
echo "  /dev/tty       - Terminal devices"
echo "  /dev/null      - Black hole (discards input)"
echo "  /dev/zero      - Infinite zeros"
echo "  /dev/random    - Random data"

echo ""
echo "Hardware info complete."
