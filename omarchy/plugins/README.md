# Omarchy plugin yedekleri (yerel değiştirilmiş sürümler)

Bu klasör, 2026-11-19 tarihinde `~/.config/omarchy/plugins` altından alınan
çalışma kopyalarını içerir. Git altındaki plugin'lerin `.git` klasörleri
hariç tutuldu; dosyalar o anki **yerel/değiştirilmiş** halleriyle kaydedildi.

- `xava.gnome-workspaces`, `xava.idle` — kendim yazdığım plugin'ler, hiçbir
  zaman git'te olmadı.
- `io.github.amitcpatel.omabar-drawer`, `io.github.atagulalan.window-controls`,
  `omaplug` — upstream repo üzerinde commit edilmemiş yerel tweak'ler.

Geri yüklemek için ilgili klasörü `~/.config/omarchy/plugins/<ad>/` altına
kopyalayıp `omarchy plugin list` ile tanımlanıp tanınmadığını kontrol et.
`omarchy plugin update` çalıştırırsan bu tweak'ler ezilebilir.

Dikkat: Bu commit'ler yereldir, remote'a push edilmedi.
