#!/bin/bash
# --- CLEANUP BROKEN ---
if [ "$(id -u)" -ne 0 ]; then echo "Root required."; exit 1; fi

DEVICE=$(findmnt -n -o SOURCE / | cut -d'[' -f1)
MOUNT_ROOT="/mnt/btrfs_cleanup"
mkdir -p "$MOUNT_ROOT"
mount -o subvolid=5 "$DEVICE" "$MOUNT_ROOT" || exit 1

mapfile -t BROKEN_SUBS < <(ls -d "$MOUNT_ROOT"/@_broken_* 2>/dev/null)

if [ ${#BROKEN_SUBS[@]} -eq 0 ]; then
    echo "Sustav je cist."
    umount "$MOUNT_ROOT"
    exit 0
fi

for sub in "${BROKEN_SUBS[@]}"; do
    echo "Brisem: $(basename "$sub")"
    btrfs subvolume delete "$sub"
done

umount "$MOUNT_ROOT"
echo "--- OCISCENO ---"
