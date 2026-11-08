#!/usr/bin/env bash
set -euo pipefail
EXT="$HOME/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com"
THEME="$HOME/.themes/Adwaita-Obel/gnome-shell/gnome-shell.css"
UUID_DTP="dash-to-panel@jderose9.github.com"

for f in appIcons.js extension.js stylesheet.css; do
  if [[ -f "$EXT/$f.pre-inactive-opacity" ]]; then
    cp -a "$EXT/$f.pre-inactive-opacity" "$EXT/$f"
    echo "Restored $f"
  fi
done
if [[ -f "$THEME.pre-inactive-opacity" ]]; then
  cp -a "$THEME.pre-inactive-opacity" "$THEME"
  echo "Restored theme css"
fi

python3 - <<'PY'
import ast, subprocess
uuid = 'dtp-inactive-opacity@xava.local'
raw = subprocess.check_output(['gsettings','get','org.gnome.shell','enabled-extensions'], text=True)
lst = [x for x in ast.literal_eval(raw) if x != uuid]
gv = '[' + ', '.join("'" + x + "'" for x in lst) + ']'
subprocess.check_call(['gsettings','set','org.gnome.shell','enabled-extensions', gv])
print('Removed companion uuid')
PY

gdbus call --session --dest org.gnome.Shell.Extensions \
  --object-path /org/gnome/Shell/Extensions \
  --method org.gnome.Shell.Extensions.DisableExtension "$UUID_DTP" >/dev/null
sleep 0.8
gdbus call --session --dest org.gnome.Shell.Extensions \
  --object-path /org/gnome/Shell/Extensions \
  --method org.gnome.Shell.Extensions.EnableExtension "$UUID_DTP" >/dev/null

# bounce user theme
CUR=$(gsettings get org.gnome.shell.extensions.user-theme name)
gsettings set org.gnome.shell.extensions.user-theme name ''
sleep 0.3
gsettings set org.gnome.shell.extensions.user-theme name "$CUR"
echo Done.
