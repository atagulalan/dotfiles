# dotfiles

Omarchy (Hyprland) kişisel kurulum ve yapılandırma deposu. Bu repo artık eski
GNOME makinenin dconf/eklenti düzenini otomatik uygulamaz; Omarchy'nin kendi
tema ve shell yapılandırmasını koruyup yalnızca kişisel Hyprland override'larını
yükler. Sıfır makineden tam kuruluma tek komut:

```bash
curl -fsSL https://raw.githubusercontent.com/atagulalan/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` sırasıyla: gereksinimleri kurar (git, stow, paru) → repo'yu
`~/dotfiles`'a klonlar → paketleri kurar (Enter = hepsi) → taşınabilir
config'leri stow ile symlink'ler → bin/desktop/mimeapps ekstralarını bağlar →
Zen Browser profilini geri yükler → oturumu kapatmayı teklif eder.

## Scriptler

| Script | Ne yapar |
|---|---|
| `bootstrap.sh` | Sıfır makinede uçtan uca kurulum (yukarıdaki tek komut) |
| `backup.sh` | **Ana makinede**: Hyprland + Zen + etc + paket listesi yedeğini alıp tek commit ile pushlar |
| `install-packages.sh` | `packages.txt`'ten paket kurar (`--all` sormadan, `--list` sadece durum) |
| `install.sh` | Stow dışı ekstralar: `bin/` scriptleri, desktop entry'leri, mimeapps |
| `scripts/hypr-backup.sh` | Çalışan Hyprland override'larını repoya geri alır |
| `zen/backup.sh` | Zen profili: eklentiler, ayarlar, zen mod/kısayolları, yer imi yedekleri |
| `zen/restore.sh` | Zen profilini yeni makineye kurar (Zen kapalıyken) |
| `etc/backup.sh` | /etc ve /opt konfigleri: coolercontrol, ollama override'ı, zapret config |
| `etc/restore.sh` | Yukarıdakileri geri yükler (sudo; ollama'da kullanıcı adı/home uyarlanır) |

## Yapı

- **Stow paketleri**: `hypr` (Omarchy override'ları), `omarchy` (kalıcı
  Ghostty paleti), `alacritty`, `bash`,
  `fish`, `ghostty`, `git`, `fonts`, `micro`, `openrgb`, `qbittorrent`,
  `sunshine`, `syncplay`, `systemd` vb. `bootstrap.sh` yalnızca açıkça
  tanımlanmış Omarchy-uyumlu paketi linkler.
- `packages.txt` — grup grup küratörlü paket listesi (repo + AUR karışık)
- `packages-snapshot.txt` — `backup.sh`'ın ürettiği tam paket listesi
  (`pacman -Qqe` + AUR); kurulum için değil, format sonrası referans için
- `hypr/` — Omarchy'nin varsayılanlarının üstüne yüklenen Hyprland ayarları.
  `monitors.lua` bu masaüstünün AORUS FO32U2 + döndürülmüş Dell P2219H
  düzenini içerir; başka cihazda bu dosyayı `hyprctl monitors all` çıktısına
  göre değiştirin.
- `gnome/` — yalnızca eski makine arşivi; bootstrap ve backup tarafından
  kullanılmaz.
- `zen/profile/` — Zen Browser profil yedeği (beyaz liste)
- `backgrounds/wallpaper/` — eski GNOME dconf yedeğinin duvar kağıdı arşivi
- `bin/`, `desktop/` — `install.sh`'ın bağladığı script ve launcher'lar
- `mimeapps` — stow'lanmaz, kopyalanır (uygulamalar dosyayı yeniden yazıyor)

## Notlar

- **Repo public** — secret içeren hiçbir şey commit'lenmez. Zen yedeği beyaz
  liste ile alınır: şifreler, geçmiş, çerezler, site verileri, yer imleri,
  açık tabler/space'ler ve ziyaret edilen alan adlarını içeren dosyalar
  (`content-prefs.sqlite`, `permissions.sqlite`) **hariçtir**.
- Ayar değiştirdikçe ana makinede `./backup.sh` çalıştırmak yeterli.
- Omarchy tema/font seçimini `omarchy theme set` ve `omarchy font set` ile
  yönetin; eski `gtk`, `themes` ve `icons` stow paketleri tema yöneticisiyle
  çakışmaması için kuruluma dahil edilmez.
