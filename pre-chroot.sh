#!/bin/bash

# ==========================================
#  PRE-CHROOT: FORMATTING, MOUNTING & PACSTRAP
# ==========================================
cfdisk

BOOT_DEV="/dev/sda1"
ROOT_DEV="/dev/sda2"

echo "=========================================="
echo " 1. FORMATTING PARTITIONS WITH LABELS     "
echo "=========================================="
# Adding the UEFI label
mkfs.vfat -F32 -n UEFI "$BOOT_DEV"

# Adding the ROOT label and explicit F2FS compression features
mkfs.f2fs -f -l ROOT -O extra_attr -O inode_checksum -O sb_checksum -O compression "$ROOT_DEV"

echo "=========================================="
echo " 2. MOUNTING FILE SYSTEMS                 "
echo "=========================================="
mount -o compress_algorithm=zstd:6,compress_chksum,atgc,gc_merge,lazytime "$ROOT_DEV" /mnt
mkdir -p /mnt/boot
mount "$BOOT_DEV" /mnt/boot

echo "=========================================="
echo " 3. INJECTING CACHYOS REPOS INTO LIVE ISO "
echo "=========================================="

echo "=========================================="
echo " 4. RUNNING PACSTRAP                      "
echo "=========================================="
pacstrap -K /mnt base base-devel intel-ucode f2fs-tools git nano plymouth sudo

echo "=========================================="
echo " 5. GENERATING FSTAB                      "
echo "=========================================="
genfstab -U /mnt >> /mnt/etc/fstab

echo "=========================================="
echo " PRE-CHROOT COMPLETE! RUN: arch-chroot /mnt "
echo "=========================================="
