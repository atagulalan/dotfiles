#!/usr/bin/env bash
# Rebuild Decibels src gresource with Obel waveform accent (#ff3c05) and install.
# Re-run after `pacman -Syu` if decibels updates and the peach waveform returns.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/src"
XML="$SRC/org.gnome.Decibels.src.gresource.xml"
OUT="$ROOT/org.gnome.Decibels.src.gresource"
DEST="/usr/share/org.gnome.Decibels/org.gnome.Decibels.src.gresource"

if [[ ! -f "$SRC/js/waveform-scale.js" ]]; then
  echo "missing $SRC/js/waveform-scale.js" >&2
  exit 1
fi

if ! grep -q 'OBEL_ACCENT' "$SRC/js/waveform-scale.js"; then
  echo "waveform-scale.js is missing the Obel patch; aborting" >&2
  exit 1
fi

glib-compile-resources \
  --sourcedir="$SRC" \
  --target="$OUT" \
  "$XML"

echo "built $OUT ($(wc -c <"$OUT") bytes)"

if [[ ! -f "$DEST.bak-stock" ]]; then
  sudo cp -a "$DEST" "$DEST.bak-stock"
  echo "backed up stock gresource -> $DEST.bak-stock"
fi

sudo cp -a "$OUT" "$DEST"
echo "installed $DEST"
echo "Restart Decibels to see #ff3c05 on the waveform."
