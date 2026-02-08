#!/bin/bash
# --- MANUALNI ROLLBACK ---
if [ "$(id -u)" -ne 0 ]; then
    echo "GRESKA: Pokrenite kao root."
    exit 1
fi

DEVICE=$(findmnt -n -o SOURCE / | cut -d'[' -f1)
MOUNT_ROOT="/mnt/btrfs_base"

echo "--- START: ROLLBACK SUSTAVA ---"
mkdir -p "$MOUNT_ROOT"
mount -o subvolid=5 "$DEVICE" "$MOUNT_ROOT" || exit 1

CURRENT_PATH=$(findmnt -n -o SOURCE /)
SNAP_ID=$(echo "$CURRENT_PATH" | grep -oP '(?<=snapshots/)\d+')

if [ -z "$SNAP_ID" ]; then
    echo -n "Unesite ID rucno: "
    read -r SNAP_ID
fi

SRC="$MOUNT_ROOT/@snapshots/$SNAP_ID/snapshot"
if [ ! -d "$SRC" ]; then echo "GRESKA: Putanja ne postoji!"; exit 1; fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "Spremam pokvareni @ u @_broken_$TIMESTAMP"
mv "$MOUNT_ROOT/@" "$MOUNT_ROOT/@_broken_$TIMESTAMP"

echo "Vracam sustav na Snapshot ID: $SNAP_ID"
btrfs subvolume snapshot "$SRC" "$MOUNT_ROOT/@"

# Popravak fstaba u novom @ volumenu
sed -i "s|subvol=/@snapshots/$SNAP_ID/snapshot|subvol=@|g" "$MOUNT_ROOT/@/etc/fstab"

umount "$MOUNT_ROOT"
echo "--- ROLLBACK GOTOV. REBOOTAJTE ---"
