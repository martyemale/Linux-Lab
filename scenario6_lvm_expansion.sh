#!/bin/bash
echo "================================================"
echo "  SCENARIO 6: LVM Storage Expansion"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  The production database partition /var/lib/mysql is at
  92% capacity. A new 500GB disk (/dev/sdb) was physically
  installed by the data center team. You need to add this
  disk to the existing LVM volume group and expand the
  filesystem — without taking the database offline.

OBJECTIVE:
  Add the new disk to LVM. Expand the logical volume
  and filesystem. Verify the space is available.
  Zero downtime.
STORY

echo ""
echo "--- STEP 1: Verify current storage ---"
echo '  $ lsblk'
echo ""
cat << 'OUTPUT'
  NAME                  MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
  sda                     8:0    0   200G  0 disk
  ├─sda1                  8:1    0     1G  0 part /boot
  └─sda2                  8:2    0   199G  0 part
    ├─vg_prod-lv_root   253:0    0    50G  0 lvm  /
    ├─vg_prod-lv_var    253:1    0   100G  0 lvm  /var
    └─vg_prod-lv_swap   253:2    0     8G  0 lvm  [SWAP]
  sdb                     8:16   0   500G  0 disk
OUTPUT
echo ""
echo "  sdb is the new 500GB disk. No partitions yet."

echo ""
echo "--- STEP 2: Check current LVM layout ---"
echo '  $ pvs'
cat << 'OUTPUT'
  PV         VG      Fmt  Attr PSize   PFree
  /dev/sda2  vg_prod lvm2 a--  199.00g 41.00g
OUTPUT
echo ""
echo '  $ vgs'
cat << 'OUTPUT'
  VG      #PV #LV #SN Attr   VSize   VFree
  vg_prod   1   3   0 wz--n- 199.00g 41.00g
OUTPUT
echo ""
echo '  $ lvs'
cat << 'OUTPUT'
  LV      VG      Attr       LSize   Origin Snap%
  lv_root vg_prod -wi-ao----  50.00g
  lv_var  vg_prod -wi-ao---- 100.00g
  lv_swap vg_prod -wi-ao----   8.00g
OUTPUT
echo ""
echo '  $ df -h /var'
cat << 'OUTPUT'
  Filesystem               Size  Used Avail Use% Mounted on
  /dev/mapper/vg_prod-lv_var 100G   92G    8G  92% /var
OUTPUT
echo ""
echo "  LVM terminology:"
echo "    PV (Physical Volume) = the disk or partition"
echo "    VG (Volume Group)    = pool of storage from PVs"
echo "    LV (Logical Volume)  = partition carved from VG"

echo ""
echo "--- STEP 3: Prepare the new disk ---"
echo '  $ pvcreate /dev/sdb'
cat << 'OUTPUT'
  Physical volume "/dev/sdb" successfully created.
OUTPUT
echo ""
echo '  $ pvs'
cat << 'OUTPUT'
  PV         VG      Fmt  Attr PSize   PFree
  /dev/sda2  vg_prod lvm2 a--  199.00g  41.00g
  /dev/sdb           lvm2 ---  500.00g 500.00g
OUTPUT
echo ""
echo "  New PV created but not yet assigned to a VG."

echo ""
echo "--- STEP 4: Add to volume group ---"
echo '  $ vgextend vg_prod /dev/sdb'
cat << 'OUTPUT'
  Volume group "vg_prod" successfully extended
OUTPUT
echo ""
echo '  $ vgs'
cat << 'OUTPUT'
  VG      #PV #LV #SN Attr   VSize   VFree
  vg_prod   2   3   0 wz--n- 698.99g 540.99g
OUTPUT
echo ""
echo "  VG now has 2 PVs and 540GB free space."

echo ""
echo "--- STEP 5: Extend the logical volume ---"
echo '  # Add 400GB to lv_var (keep 140GB for future use)'
echo '  $ lvextend -L +400G /dev/vg_prod/lv_var'
cat << 'OUTPUT'
  Size of logical volume vg_prod/lv_var changed 
  from 100.00 GiB to 500.00 GiB.
  Logical volume vg_prod/lv_var successfully resized.
OUTPUT

echo ""
echo "--- STEP 6: Resize the filesystem ---"
echo '  # For ext4:'
echo '  $ resize2fs /dev/vg_prod/lv_var'
echo '  # For xfs:'
echo '  $ xfs_growfs /var'
echo ""
cat << 'OUTPUT'
  Filesystem on /dev/vg_prod/lv_var resized to 500GB.
OUTPUT
echo ""
echo "  ext4 uses resize2fs. xfs uses xfs_growfs."
echo "  Both can expand ONLINE — no unmount needed."
echo "  XFS CANNOT shrink. ext4 can (but requires unmount)."

echo ""
echo "--- STEP 7: Verify ---"
echo '  $ df -h /var'
cat << 'OUTPUT'
  Filesystem               Size  Used Avail Use% Mounted on
  /dev/mapper/vg_prod-lv_var 500G   92G  408G  19% /var
OUTPUT
echo ""
echo "  From 92% to 19%. Database never went offline."

echo ""
echo "--- LVM COMMAND REFERENCE ---"
cat << 'SUMMARY'
  Physical Volumes:
    pvcreate /dev/sdb          Create a PV
    pvs                        List PVs
    pvdisplay                  Detailed PV info
    pvremove /dev/sdb          Remove a PV

  Volume Groups:
    vgcreate vg_name /dev/sdb  Create a VG
    vgextend vg_name /dev/sdb  Add PV to VG
    vgs                        List VGs
    vgdisplay                  Detailed VG info

  Logical Volumes:
    lvcreate -L 50G -n lv_name vg_name   Create LV
    lvextend -L +100G /dev/vg/lv         Extend LV
    lvreduce -L -50G /dev/vg/lv          Shrink LV
    lvs                                   List LVs

  Filesystem Resize:
    resize2fs /dev/vg/lv       Resize ext4 (online)
    xfs_growfs /mountpoint     Grow xfs (online, no shrink)

  The LVM flow: Disk -> PV -> VG -> LV -> Filesystem
SUMMARY

echo ""
echo "Scenario 6 complete."
