#!/bin/bash
echo "================================================"
echo "  SCENARIO 9: GRUB Bootloader Recovery"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  A production server was patched overnight with a new
  kernel update. When the server rebooted, it dropped
  to a GRUB rescue prompt instead of booting normally.
  The MES application is offline. The floor supervisor
  reports the production line has been down since 5 AM.

OBJECTIVE:
  Boot the server using the previous kernel. Fix the
  GRUB configuration. Ensure the server boots reliably.
STORY

echo ""
echo "--- STEP 1: Understand what you see ---"
echo '  Screen shows:'
echo '  grub rescue>'
echo ""
cat << 'OUTPUT'
  GRUB rescue means the bootloader cannot find its
  configuration file or the kernel image. Common causes:
    - Corrupted grub.cfg after update
    - Kernel image deleted or moved
    - Wrong root partition in config
    - Filesystem corruption on /boot
OUTPUT

echo ""
echo "--- STEP 2: Find the boot partition from GRUB ---"
echo '  grub rescue> ls'
cat << 'OUTPUT'
  (hd0) (hd0,gpt3) (hd0,gpt2) (hd0,gpt1)
OUTPUT
echo ""
echo '  grub rescue> ls (hd0,gpt2)/'
cat << 'OUTPUT'
  vmlinuz-5.14.0-362.el9.x86_64
  vmlinuz-5.14.0-427.el9.x86_64
  initramfs-5.14.0-362.el9.x86_64.img
  initramfs-5.14.0-427.el9.x86_64.img
  grub2/
OUTPUT
echo ""
echo "  Found /boot on (hd0,gpt2) with two kernels."
echo "  The older kernel (362) is our fallback."

echo ""
echo "--- STEP 3: Boot manually from GRUB ---"
echo '  grub rescue> set root=(hd0,gpt2)'
echo '  grub rescue> set prefix=(hd0,gpt2)/grub2'
echo '  grub rescue> insmod normal'
echo '  grub rescue> normal'
echo ""
echo "  This loads the GRUB menu. From the menu:"
echo "  Select the OLDER kernel (362) to boot safely."
cat << 'OUTPUT'
  GRUB menu appears:
    Red Hat Enterprise Linux (5.14.0-427.el9) *
    Red Hat Enterprise Linux (5.14.0-362.el9)
  
  Arrow down to 362, press Enter.
  System boots with the old kernel.
OUTPUT

echo ""
echo "--- STEP 4: Verify you booted the old kernel ---"
echo '  $ uname -r'
echo '  5.14.0-362.el9.x86_64'
echo ""
echo '  $ uptime'
echo '  06:12 up 2 min, 1 user'
echo ""
echo "  Server is up on the old kernel. MES service"
echo "  starts automatically. Production line resumes."

echo ""
echo "--- STEP 5: Investigate the failed kernel ---"
echo '  $ journalctl -b -1 | tail -30'
cat << 'OUTPUT'
  Jun 09 05:00:12 prodserver kernel: Failed to load driver module nvidia
  Jun 09 05:00:13 prodserver kernel: PANIC: VFS: Unable to mount root fs
  Jun 09 05:00:13 prodserver kernel: Kernel panic - not syncing
OUTPUT
echo ""
echo "  ROOT CAUSE: New kernel (427) missing driver module."
echo "  The initramfs for the new kernel was not rebuilt"
echo "  with the required hardware drivers."

echo ""
echo "--- STEP 6: Rebuild initramfs for new kernel ---"
echo '  $ dracut --force /boot/initramfs-5.14.0-427.el9.x86_64.img 5.14.0-427.el9.x86_64'
cat << 'OUTPUT'
  Rebuilding initramfs with all detected drivers...
  Done.
OUTPUT

echo ""
echo "--- STEP 7: Regenerate GRUB config ---"
echo '  $ grub2-mkconfig -o /boot/grub2/grub.cfg'
cat << 'OUTPUT'
  Generating grub configuration file ...
  Found linux image: /boot/vmlinuz-5.14.0-427.el9.x86_64
  Found initrd image: /boot/initramfs-5.14.0-427.el9.x86_64.img
  Found linux image: /boot/vmlinuz-5.14.0-362.el9.x86_64
  Found initrd image: /boot/initramfs-5.14.0-362.el9.x86_64.img
  done
OUTPUT

echo ""
echo "--- STEP 8: Set default kernel ---"
echo '  # Keep old kernel as default until new one is verified'
echo '  $ grubby --set-default /boot/vmlinuz-5.14.0-362.el9.x86_64'
echo '  $ grubby --default-kernel'
echo '  /boot/vmlinuz-5.14.0-362.el9.x86_64'
echo ""
echo "  Default set to old kernel. New kernel available"
echo "  in GRUB menu for testing during maintenance window."

echo ""
echo "--- BOOT PROCESS REFERENCE ---"
cat << 'SUMMARY'
  Linux Boot Sequence (exam tested):
    1. BIOS/UEFI    - Hardware init, finds boot device
    2. GRUB2        - Bootloader, loads kernel + initramfs
    3. Kernel       - Loads into memory, initializes hardware
    4. initramfs    - Temporary root with drivers to mount real root
    5. systemd      - PID 1, starts all services (init system)
    6. Targets      - multi-user.target (CLI) or graphical.target (GUI)

  GRUB Commands:
    grub2-mkconfig -o /boot/grub2/grub.cfg    Rebuild config
    grubby --set-default KERNEL               Set default kernel
    grubby --default-kernel                   Show default
    grubby --info=ALL                         List all kernels

  Kernel Management:
    uname -r                          Current kernel version
    rpm -qa kernel                    List installed kernels
    dracut --force INITRAMFS KERNEL   Rebuild initramfs

  Boot Targets (runlevels):
    systemctl get-default                  Show default target
    systemctl set-default multi-user.target   CLI boot
    systemctl set-default graphical.target    GUI boot
    systemctl isolate rescue.target           Single user mode
    
  Legacy Runlevels -> Systemd Targets:
    0 = poweroff.target
    1 = rescue.target
    3 = multi-user.target
    5 = graphical.target
    6 = reboot.target
SUMMARY

echo ""
echo "Scenario 9 complete."
