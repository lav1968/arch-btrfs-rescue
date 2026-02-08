#!/bin/bash
# --- PORTABILNI ROLLBACK ---

if [ "$(id -u)" -ne 0 ]; then
    echo "GRESKA: Pokrenite kao root."
    exit 1
fi

DEVICE=$(findmnt -n -o SOURCE / | cut -d'[' -f1)
MOUNT_ROOT="/mnt/btrfs_base"

echo "--- START: ROLLBACK SUSTAVA ---"
mkdir -p "$MOUNT_ROOT"
mount -o subvolid=5 "$DEVICE" "$MOUNT_ROOT" || exit 1

# Detekcija SNAP_ID iz kojeg smo bootani
CURRENT_PATH=$(findmnt -n -o SOURCE /)
SNAP_ID=$(echo "$CURRENT_PATH" | grep -oP '(?<=snapshots/)\d+')

if [ -z "$SNAP_ID" ]; then
    echo -n "Nisam detektirao ID. Unesite ga ručno: "
    read -r SNAP_ID
fi

SRC="$MOUNT_ROOT/@snapshots/$SNAP_ID/snapshot"
if [ ! -d "$SRC" ]; then 
    echo "GRESKA: Snapshot $SNAP_ID ne postoji na disku!"
    umount "$MOUNT_ROOT"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "Spremam trenutni @ u @_broken_$TIMESTAMP"
mv "$MOUNT_ROOT/@" "$MOUNT_ROOT/@_broken_$TIMESTAMP"

echo "Vraćam sustav na Snapshot ID: $SNAP_ID"
btrfs subvolume snapshot "$SRC" "$MOUNT_ROOT/@"

# --- PORTABILNI FSTAB FIX ---
# Vraćamo subvol na /@ (tvoj standard) unutar novog @ volumena
# Koristimo privremeni file da izbjegnemo bilo kakve greške
TARGET_FSTAB="$MOUNT_ROOT/@/etc/fstab"
if [ -f "$TARGET_FSTAB" ]; then
    sed -i "s|subvol=/@snapshots/$SNAP_ID/snapshot|subvol=/@|g" "$TARGET_FSTAB"
fi

umount "$MOUNT_ROOT"
echo "--- ROLLBACK GOTOV. Možete rebootati. ---"
