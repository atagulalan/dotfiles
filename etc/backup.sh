#!/usr/bin/env bash
# /etc ve /opt altindaki uygulama konfiglerini yedekler
# (coolercontrol, ollama servis override'i, zapret).
# Gizli dosyalar (.passwd, *.key, *.crt) bilerek alinmaz.
# Kullanim: ./backup.sh [--no-push]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CC_FILES=(config.toml config-ui.json modes.json alerts.json calibrations.json)
if [[ -d /etc/coolercontrol ]]; then
    mkdir -p "$SCRIPT_DIR/coolercontrol"
    for f in "${CC_FILES[@]}"; do
        [[ -f /etc/coolercontrol/$f ]] && cp "/etc/coolercontrol/$f" "$SCRIPT_DIR/coolercontrol/"
    done
    echo "coolercontrol yedeklendi (${CC_FILES[*]})"
else
    echo "coolercontrol kurulu degil, atlandi."
fi

if [[ -f /etc/systemd/system/ollama.service.d/override.conf ]]; then
    mkdir -p "$SCRIPT_DIR/ollama"
    cp /etc/systemd/system/ollama.service.d/override.conf "$SCRIPT_DIR/ollama/"
    echo "ollama servis override'i yedeklendi"
else
    echo "ollama override yok, atlandi."
fi

# Sadece ana config alinir; hostlist'ler (ziyaret edilen alan adlari) bilerek alinmaz.
if [[ -f /opt/zapret/config ]]; then
    mkdir -p "$SCRIPT_DIR/zapret"
    cp /opt/zapret/config "$SCRIPT_DIR/zapret/"
    echo "zapret config yedeklendi"
else
    echo "zapret kurulu degil, atlandi."
fi

cd "$SCRIPT_DIR/.."
if ! git status --porcelain etc/ | grep -q .; then
    echo "Degisiklik yok."
    exit 0
fi
git status --short etc/
[[ ${1:-} == "--no-push" ]] && exit 0
git add etc/
git commit -m "chore: etc yedegi $(date +%Y-%m-%d)"
git push
