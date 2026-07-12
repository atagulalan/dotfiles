# dotfiles

CachyOS (GNOME) kişisel kurulum ve yapılandırma deposu. Sıfır makineden tam
kuruluma tek komut:

```bash
curl -fsSL https://raw.githubusercontent.com/atagulalan/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` sırasıyla: gereksinimleri kurar (git, stow, paru) → repo'yu
`~/dotfiles`'a klonlar → paketleri kurar (Enter = hepsi) → config'leri stow ile
symlink'ler → bin/desktop/mimeapps ekstralarını bağlar → GNOME eklentileri +
dconf ayarları + temalar/arkaplanı yükler → Zen Browser profilini geri yükler →
oturumu kapatmayı teklif eder.

## Scriptler

| Script | Ne yapar |
|---|---|
| `bootstrap.sh` | Sıfır makinede uçtan uca kurulum (yukarıdaki tek komut) |
| `backup.sh` | **Ana makinede**: GNOME + Zen + etc + paket listesi yedeğini alıp tek commit ile pushlar |
| `install-packages.sh` | `packages.txt`'ten paket kurar (`--all` sormadan, `--list` sadece durum) |
| `install.sh` | Stow dışı ekstralar: `bin/` scriptleri, desktop entry'leri, mimeapps |
| `gnome/backup.sh` | dconf dump + duvar kağıdı + user-dirs + kenar çubuğu bookmarks |
| `gnome/restore.sh` | Yukarıdakileri yeni makineye uygular (yolları `$HOME`'a çevirir) |
| `gnome/install-extensions.sh` | GNOME eklentilerini EGO'dan indirir; özel olanları repo'dan kopyalar |
| `gnome/sync-extensions.sh` | Özel (fork) eklentileri lokalden repo'ya senkronlar (`--commit`) |
| `zen/backup.sh` | Zen profili: eklentiler, ayarlar, zen mod/kısayolları, yer imi yedekleri |
| `zen/restore.sh` | Zen profilini yeni makineye kurar (Zen kapalıyken) |
| `etc/backup.sh` | /etc ve /opt konfigleri: coolercontrol, ollama override'ı, zapret config |
| `etc/restore.sh` | Yukarıdakileri geri yükler (sudo; ollama'da kullanıcı adı/home uyarlanır) |

## Yapı

- **Stow paketleri** (kökte gizli dosya/`.config` içeren her klasör):
  `alacritty`, `bash`, `fish`, `ghostty`, `git`, `gtk`, `icons` (monoc,
  WhiteSur-cursors), `themes` (MacTahoe), `fonts` (Victor Mono, PP Fraktion
  Mono), `mpv`, `micro`, `obs-studio`, `openrgb`, `qbittorrent`, `sunshine`,
  `syncplay`, `systemd` (kullanıcı servisleri: sunshine, qbittorrent) vb.
  `bootstrap.sh` bunları otomatik algılayıp stow'lar.
- `packages.txt` — grup grup küratörlü paket listesi (repo + AUR karışık)
- `packages-snapshot.txt` — `backup.sh`'ın ürettiği tam paket listesi
  (`pacman -Qqe` + AUR); kurulum için değil, format sonrası referans için
- `gnome/` — dconf.ini, user-dirs, bookmarks, `extensions/` altında fork
  eklentiler (ör. rounded-window-corners@fxgn)
- `zen/profile/` — Zen Browser profil yedeği (beyaz liste)
- `backgrounds/wallpaper/` — dconf'un referans verdiği aktif duvar kağıdı
- `bin/`, `desktop/` — `install.sh`'ın bağladığı script ve launcher'lar
- `mimeapps` — stow'lanmaz, kopyalanır (uygulamalar dosyayı yeniden yazıyor)

## Notlar

- **Repo public** — secret içeren hiçbir şey commit'lenmez. Zen yedeği beyaz
  liste ile alınır: şifreler, geçmiş, çerezler, site verileri, yer imleri,
  açık tabler/space'ler ve ziyaret edilen alan adlarını içeren dosyalar
  (`content-prefs.sqlite`, `permissions.sqlite`) **hariçtir**.
- Ayar değiştirdikçe ana makinede `./backup.sh` çalıştırmak yeterli.
- Fork eklenti güncelleme akışı: fork'u build edip lokale kur →
  `./gnome/sync-extensions.sh --commit`.
