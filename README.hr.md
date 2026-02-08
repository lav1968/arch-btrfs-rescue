# Arch Linux Btrfs Rescue Sustav (UKI)

Ovaj repozitorij sadrži skripte za automatizaciju izrade **Rescue UKI** (Unified Kernel Image) snapshotova na sustavima koji koriste Btrfs datotečni sustav.

## 🛠️ Glavne Skripte
- **`setup-rescue.sh`**: Glavna instalacijska skripta. Konfigurira Snapper, instalira Pacman hook i priprema GRUB.
- **`create-rescue-snapshot`**: Skripta (koja se instalira u `/usr/local/bin/`) koja generira UKI kernel i popravlja `fstab` unutar snapshota.
- **`rollback.sh`**: Alat za manualni povratak sustava na odabrani snapshot (vraća `@` subvolumen).
- **`cleanup-broken.sh`**: Higijenska skripta za brisanje starih `@_broken_` subvolumena nakon oporavka.

## 🚀 Kako sustav radi
1. Pri svakom ažuriranju kernela (via Pacman), sustav radi Btrfs snapshot korijenskog subvolumena (`@`).
2. Generira se **Unified Kernel Image (UKI)** koji sadrži kernel, initramfs i cmdline, te se sprema unutar tog snapshota.
3. GRUB automatski dodaje novu stavku: **"RESCUE Snapshot #ID (UKI Mode)"**.
4. Ako sustav postane nestabilan, možete bootati direktno u taj snapshot (koji je u Read-Write modu).

## 🆘 Postupak Oporavka (Rollback)
1. Restartajte računalo i u GRUB-u odaberite **Rescue Snapshot**.
2. Kada se sustav podigne, provjerite radi li sve (uključujući `/home`).
3. Pokrenite rollback skriptu:
   ```bash
   sudo ./rollback.sh
