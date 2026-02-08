# Arch Linux Btrfs Rescue System (UKI)

[Read instructions in Croatian here / Pročitajte upute na hrvatskom jeziku ovdje](README.hr.md)

---

## English

Automated **Rescue UKI** (Unified Kernel Image) snapshot system for Arch Linux.

### Features
- Creates a full Btrfs snapshot and UKI on every kernel update via Pacman hook.
- Custom GRUB menu entries for direct booting into read-write snapshots.
- Automatically fixes `fstab` within snapshots to ensure `@home` is mounted correctly.
- Includes manual rollback and cleanup scripts.

### Scripts in this repository
- `setup-rescue.sh`: Main installer (Snapper + Hooks + GRUB config).
- `create-rescue-snapshot`: Core logic for generating UKI and patching fstab.
- `rollback.sh`: Manual restore script (moves snapshot back to `@`).
- `cleanup-broken.sh`: Deletes old `@_broken_` subvolumes after recovery.

### Installation
```bash
git clone https://github.com/lav1968/arch-btrfs-rescue.git
cd arch-btrfs-rescue
sudo ./setup-rescue.sh
