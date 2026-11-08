# CodexBar Usage

Bu GNOME Shell eklentisi `/usr/bin/codexbar usage --provider codex --format json`
komutunu 60 saniyede bir çalıştırır. Panelde 5 saatlik ve haftalık kalan kullanım
yüzdesini; açılır menüde ilerleme çubuklarını, yenilenme sürelerini ve reset
hakkını gösterir.

İlk kurulumdan sonra GNOME Shell'in eklentiyi keşfetmesi için Wayland oturumunu
kapatıp yeniden açın. Sonra etkinleştirin:

```sh
gnome-extensions enable codexbar@xava.local
```

Sorun giderme:

```sh
journalctl --user -f -o cat /usr/bin/gnome-shell
```
