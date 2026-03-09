# Btrfs Backup & Restore Alat

Ovaj repozitorij sadrži skripte za **inkrementalni backup** i **potpuni oporavak** (restore) Btrfs sustava. Sustav je prilagođen radu sa Snapper layoutom (`.snapshots`).

## 🚀 Glavne značajke
- **Inkrementalni prijenos**: Koristi `btrfs send/receive` (brzo i štedi prostor).
- **Automatska rotacija**: Čuva zadnjih 10 backupova i automatski briše najstarije.
- **EFI Sinkronizacija**: Arhivira EFI particiju i mapira je uz pripadajući Root snapshot u `root_to_efi.txt`.
- **Fleksibilan Restore**: Mogućnost oporavka cijelog sustava, samo `@home` ili samo `@root`.
- **Sigurnost**: Restore skripta automatski filtrira "rescue" snapshote iz popisa.

---

## 📋 Preduvjeti
Za ispravan rad skripti potrebno je imati instalirano:
- `btrfs-progs` (osnovni alati za Btrfs)
- `pv` (za prikaz progresa/brzine prijenosa)
- Montiran backup disk na `/mnt/BACKUP` (putanja se može promijeniti u skriptama)

---

## 🛠️ Upute za korištenje
### 1. Izrada Backup-a
Pokrenite skriptu s root ovlastima:
```bash
sudo btrfs_backup_complete
Dostupne opcije:
SAMO ROOT
SAMO HOME
ROOT + HOME
ROOT + HOME + PKG/TMP/LOG (puni backup)
SAMO PKG/TMP/LOG

2. Oporavak sustava (Restore)
⚠️ VAŽNO: Restore opcija formatira ciljne particije!
bash
sudo btrfs_restore_complete
Pripazite na kôd.
￼
Postupak:
Odaberite mod (Cijeli restore, samo @home ili samo @root).
Unesite ciljni disk (npr. /dev/sda2).
Potvrdite akciju upisivanjem riječi YES.
📂 Struktura podataka na backup disku
/root/ i /home/ - Btrfs podvolumeni (označeni brojevima snapshota).
/efi/ - .tar.gz arhive EFI particije.
root_to_efi.txt - Datoteka koja povezuje verziju Root-a s odgovarajućim EFI backupom.
