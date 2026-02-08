#!/bin/bash
# --- SETUP RESCUE SYSTEM ---
if [ "$EUID" -ne 0 ]; then
  echo "GRESKA: Pokrenite kao root (sudo ./setup-rescue.sh)."
  exit 1
fi

echo "--- FAZA 1: Instalacija i detekcija ---"
pacman -Sy --needed --noconfirm snapper rsync mkinitcpio

ROOT_UUID=$(findmnt -n -o UUID /)
BOOT_UUID=$(findmnt -n -o UUID /boot)

if [ -z "$ROOT_UUID" ]; then
    echo "GRESKA: Ne mogu detektirati ROOT UUID!"
    exit 1
fi

# Snapper Initial Setup
if [ ! -f "/etc/snapper/configs/root" ]; then
    umount /.snapshots 2>/dev/null
    rm -rf /.snapshots
    snapper -c root create-config /
    chmod 750 /.snapshots
fi

echo "--- FAZA 2: Instalacija glavne rescue skripte ---"
cat << EOF > /usr/local/bin/create-rescue-snapshot
#!/bin/bash
# 1. Zastita
CURRENT_OPTS=\$(findmnt -n -o OPTIONS /)
if [[ "\$CURRENT_OPTS" == *"@snapshots"* ]]; then
    echo "Sustav je bootan iz snapshota. Preskacem."
    exit 0
fi

# 2. Parametri
R_UUID="$ROOT_UUID"
B_UUID="$BOOT_UUID"
sync

# 3. Snapshot
S_ID=\$(snapper -c root create -d "Rescue-\$(date +%Y%m%d)" --print-number)
[ -z "\$S_ID" ] && exit 1
S_PATH="/.snapshots/\$S_ID/snapshot"
btrfs property set -ts "\$S_PATH" ro false

# 4. UKI Generiranje
mkdir -p "\$S_PATH/boot"
echo "root=UUID=\$R_UUID rw rootflags=subvol=/@snapshots/\$S_ID/snapshot compress=zstd:3,discard=async" > /tmp/rescue_cmd
mkinitcpio -k /boot/vmlinuz-linux -c /etc/mkinitcpio.conf --uki "\$S_PATH/boot/rescue.efi" --cmdline /tmp/rescue_cmd
chmod 644 "\$S_PATH/boot/rescue.efi"

# 5. FSTAB Reset (Garantira montiranje @home)
if [ -f "\$S_PATH/etc/fstab" ]; then
    mkdir -p "\$S_PATH/home" "\$S_PATH/var/log" "\$S_PATH/var/cache/pacman/pkg" "\$S_PATH/.snapshots"
    TMP_FSTAB="/tmp/fstab_gen"
    grep "UUID=\$B_UUID" "\$S_PATH/etc/fstab" > "\$TMP_FSTAB"
    echo "UUID=\$R_UUID / btrfs rw,relatime,compress=zstd:3,discard=async,space_cache=v2,subvol=/@snapshots/\$S_ID/snapshot 0 0" >> "\$TMP_FSTAB"
    echo "UUID=\$R_UUID /home btrfs rw,relatime,compress=zstd:3,discard=async,space_cache=v2,subvol=/@home 0 0" >> "\$TMP_FSTAB"
    echo "UUID=\$R_UUID /var/cache/pacman/pkg btrfs rw,relatime,compress=zstd:3,discard=async,space_cache=v2,subvol=/@pkg 0 0" >> "\$TMP_FSTAB"
    echo "UUID=\$R_UUID /var/log btrfs rw,relatime,compress=zstd:3,discard=async,space_cache=v2,subvol=/@log 0 0" >> "\$TMP_FSTAB"
    echo "UUID=\$R_UUID /.snapshots btrfs rw,relatime,compress=zstd:3,subvol=/@snapshots 0 0" >> "\$TMP_FSTAB"
    mv "\$TMP_FSTAB" "\$S_PATH/etc/fstab"
fi

# 6. Backup i rotacija
DATE=\$(date +%Y_%m_%d_%H.%M.%S)
DEST="/.bootbackup/\${DATE}_post"
mkdir -p "\$DEST"
rsync -a --delete /boot/ "\$DEST/"
echo "\$S_ID" > "\$DEST/snap_id.txt"
ls -1dt /.bootbackup/*_post/ | tail -n +6 | xargs rm -rf 2>/dev/null
sync
grub-mkconfig -o /boot/grub/grub.cfg
echo "--- RESCUE SPREMAN (ID: \$S_ID) ---"
EOF

chmod +x /usr/local/bin/create-rescue-snapshot

echo "--- FAZA 3: Postavljanje Hook-a i GRUB-a ---"
mkdir -p /etc/pacman.d/hooks
cat << EOF > /etc/pacman.d/hooks/99-bootbackup.hook
[Trigger]
Operation = Upgrade
Operation = Install
Type = Package
Target = linux
Target = mkinitcpio
Target = systemd
[Action]
Description = Generiranje Rescue UKI Snapshota
When = PostTransaction
Exec = /usr/local/bin/create-rescue-snapshot
EOF

cat << 'EOF' > /etc/grub.d/40_custom
#!/bin/sh
exec tail -n +3 $0
# Dinamicki UKI unosi
EOF
cat << 'EOF' >> /etc/grub.d/40_custom
count=0
for d in $(ls -rd /.bootbackup/*_post/ 2>/dev/null); do
    [ -d "$d" ] || continue
    [ "$count" -ge 5 ] && break
    sid=$(cat "$d/snap_id.txt" 2>/dev/null)
    uuid=$(findmnt -n -o UUID /)
    echo "menuentry \"RESCUE Snapshot #$sid (UKI)\" --class recovery {"
        echo "    insmod btrfs"
        echo "    search --no-floppy --set=root --fs-uuid $uuid"
        echo "    chainloader /@snapshots/$sid/snapshot/boot/rescue.efi"
    echo "}"
    count=$((count + 1))
done
EOF
chmod +x /etc/grub.d/40_custom
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
grub-mkconfig -o /boot/grub/grub.cfg
echo "--- SETUP ZAVRSEN ---"
