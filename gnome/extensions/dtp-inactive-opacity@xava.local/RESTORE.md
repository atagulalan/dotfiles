# Undo

## Preferred (after next login, when this extension loads)
```bash
gnome-extensions disable dtp-inactive-opacity@xava.local
```

## Immediate DtP file patch undo
```bash
EXT=~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com
cp -a "$EXT/appIcons.js.pre-inactive-opacity" "$EXT/appIcons.js"
gdbus call --session --dest org.gnome.Shell.Extensions \
  --object-path /org/gnome/Shell/Extensions \
  --method org.gnome.Shell.Extensions.ReloadExtension \
  dash-to-panel@jderose9.github.com
```

Inactive opacity is 140/255 (~55%). Edit INACTIVE in appIcons.js hook or extension.js to tweak.
