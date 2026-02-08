# Archold Specific Configuration (v2-stable)

This directory contains the production-ready scripts used on my main Arch Linux system (NVMe). Unlike the portable versions in the root directory, these are tailored for a specific Btrfs layout and NVMe hardware.

## 📁 Files

### ⚓ Pacman Hooks
- **`99-bootbackup_post.hook`**: The main trigger. Creates a Btrfs snapshot and generates a Rescue UKI (Unified Kernel Image) after every kernel update.
- **`90-uki-sync.hook`**: Ensures that the newly generated UKI is synchronized with the EFI partition.

### 🛠️ Recovery Tools
- **`full-rollback`**: A specialized rollback script for `/dev/nvme0n1p1`. It handles the `@` subvolume replacement and uses `subvolid` for maximum boot reliability.
- **`sync-uki`**: The heart of the boot synchronization. It detects if the system is booted from a snapshot or the main subvolume and updates the EFI partition accordingly.

## ⚠️ Hardware Specifics
These scripts are hardcoded for:
- **Root Partition**: `/dev/nvme0n1p1` (Btrfs)
- **EFI Partition**: `/dev/nvme0n1p2` (FAT32 mounted at `/efi`)
- **Root UUID**: `87fec617-ee55-46c4-8a0b-bf8d90c04587`
- **Subvolume Layout**: `@`, `@home`, `@pkg`, `@log`, `@snapshots`.

## 🚀 Usage
These scripts are part of a live system. The `full-rollback` tool should be used when booted into a Rescue UKI from the GRUB menu to restore the system state.
