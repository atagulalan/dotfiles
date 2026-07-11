#!/usr/bin/env python3
"""dash-to-panel ayarlarini bu makinenin monitorlerine uyarlar.

dconf ini dosyasindaki (arguman) [shell/extensions/dash-to-panel] bolumunde
monitor kimligiyle ("VENDOR-SERIAL") anahtarlanan JSON sozluklerine, bu
makinede takili olup sozlukte bulunmayan her monitor icin ilk kayitli
monitorun degerleri kopyalanir. Eski kayitlar silinmez; dash-to-panel
tanimadigi kimlikleri zaten yok sayar, boylece ayni dconf her makinede calisir.
"""
import json
import re
import subprocess
import sys

INI = sys.argv[1]
KEYS = ("panel-anchors", "panel-element-positions", "panel-lengths",
        "panel-positions", "panel-sizes")

try:
    out = subprocess.run(
        ["gdbus", "call", "--session",
         "--dest", "org.gnome.Mutter.DisplayConfig",
         "--object-path", "/org/gnome/Mutter/DisplayConfig",
         "--method", "org.gnome.Mutter.DisplayConfig.GetCurrentState"],
        capture_output=True, text=True, timeout=10).stdout
except Exception as e:  # gdbus yok / oturum disi
    sys.exit(f"mutter'a ulasilamadi: {e}")

monitors = []
for _conn, vendor, _prod, serial in re.findall(
        r"\('([A-Za-z0-9-]+)', '([^']*)', '([^']*)', '([^']*)'\)", out):
    mid = f"{vendor}-{serial}"
    if mid not in monitors:
        monitors.append(mid)
if not monitors:
    sys.exit("monitor bulunamadi")

with open(INI) as f:
    lines = f.readlines()

in_section = False
changed = False
for i, line in enumerate(lines):
    if line.startswith("["):
        in_section = line.strip() == "[shell/extensions/dash-to-panel]"
        continue
    if not in_section:
        continue
    m = re.match(r"^([a-z-]+)='(.*)'\s*$", line)
    if not m or m.group(1) not in KEYS:
        continue
    try:
        d = json.loads(m.group(2))
    except json.JSONDecodeError:
        continue
    if not isinstance(d, dict) or not d:
        continue
    template = next(iter(d.values()))
    for mid in monitors:
        if mid not in d:
            d[mid] = template
            changed = True
    lines[i] = f"{m.group(1)}='{json.dumps(d)}'\n"

if changed:
    with open(INI, "w") as f:
        f.writelines(lines)
    print(f"dash-to-panel: yeni monitor girisleri eklendi ({', '.join(monitors)})")
else:
    print("dash-to-panel: tum monitorler zaten kayitli, degisiklik gerekmedi")
