#!/usr/bin/env bash
# Interactive package installer — reads packages.txt and prompts per group.
# Usage:
#   ./install-packages.sh          interactive install
#   ./install-packages.sh --all    install everything missing, no per-group prompts
#   ./install-packages.sh --list   show groups and installed status only
set -euo pipefail

cd "$(dirname "$0")"
LIST_FILE="packages.txt"
LIST_ONLY=false
ALL=false
for arg in "$@"; do
    case $arg in
        --list) LIST_ONLY=true ;;
        --all) ALL=true ;;
    esac
done

[[ -f $LIST_FILE ]] || { echo "error: $LIST_FILE not found" >&2; exit 1; }

if ! $LIST_ONLY && ! command -v paru &>/dev/null; then
    echo "error: paru is required (install it first: https://github.com/Morganamilo/paru)" >&2
    exit 1
fi

# --- parse packages.txt into groups ---
declare -A groups
order=()
current=""
while IFS= read -r raw; do
    line="${raw%%#*}"
    line="$(echo "$line" | xargs)" # trim
    [[ -z $line ]] && continue
    if [[ $line == \[*\] ]]; then
        current="${line:1:-1}"
        order+=("$current")
        groups[$current]=""
    elif [[ -n $current ]]; then
        groups[$current]+="$line "
    fi
done <"$LIST_FILE"

# --- walk groups ---
selected=()
for group in "${order[@]}"; do
    read -ra pkgs <<<"${groups[$group]}"
    ((${#pkgs[@]})) || continue

    echo
    echo "── $group ──"
    missing=()
    for pkg in "${pkgs[@]}"; do
        if pacman -Qq "$pkg" &>/dev/null; then
            echo "  ✔ $pkg (installed)"
        else
            echo "  ✘ $pkg"
            missing+=("$pkg")
        fi
    done

    $LIST_ONLY && continue
    ((${#missing[@]})) || { echo "  → nothing to do"; continue; }

    if $ALL; then
        selected+=("${missing[@]}")
        continue
    fi

    read -rp "Install ${#missing[@]} missing from '$group'? [a]ll / [p]ick / [S]kip: " ans
    case $ans in
        a | A)
            selected+=("${missing[@]}")
            ;;
        p | P)
            for pkg in "${missing[@]}"; do
                read -rp "    install $pkg? [y/N] " yn
                [[ $yn =~ ^[yY] ]] && selected+=("$pkg")
            done
            ;;
        *) ;;
    esac
done

$LIST_ONLY && exit 0

echo
if ((${#selected[@]} == 0)); then
    echo "Nothing selected — done."
    exit 0
fi

echo "Will install: ${selected[*]}"
read -rp "Proceed? [Y/n] " go
[[ $go =~ ^[nN] ]] && { echo "Aborted."; exit 0; }

paru -S --needed "${selected[@]}"
