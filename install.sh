#!/usr/bin/env bash
# Extras that stow can't handle: bin scripts, desktop entries, mimeapps copy.
# Configs themselves are symlinked by stow (see bootstrap.sh).

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Linking bin scripts..."
mkdir -p ~/.local/bin
for f in "$DIR"/bin/*; do
    chmod +x "$f"
    ln -sf "$f" ~/.local/bin/"$(basename "$f")"
done

echo "Installing desktop entries..."
mkdir -p ~/.local/share/applications
for f in "$DIR"/desktop/*.desktop; do
    ln -sf "$f" ~/.local/share/applications/"$(basename "$f")"
done

# mimeapps.list is copied, not symlinked: apps rewrite it and would
# otherwise clobber the repo copy through the symlink.
echo "Copying mimeapps.list..."
mkdir -p ~/.config
cp "$DIR"/mimeapps/.config/mimeapps.list ~/.config/mimeapps.list

echo "Done."
