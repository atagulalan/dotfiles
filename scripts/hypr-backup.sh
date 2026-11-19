#!/usr/bin/env bash
# Copy the portable, hand-maintained Hyprland settings back into this repo.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$HOME/.config/hypr"
target_dir="$repo_dir/hypr/.config/hypr"

for file in hyprland.lua monitors.lua input.lua looknfeel.lua bindings.lua autostart.lua hyprsunset.conf xdph.conf; do
    [[ -e "$source_dir/$file" ]] || continue
    [[ "$source_dir/$file" -ef "$target_dir/$file" ]] && continue
    cp "$source_dir/$file" "$target_dir/$file"
done

echo "Hyprland ayarları güncellendi."
