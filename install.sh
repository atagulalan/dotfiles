#!/usr/bin/env bash

set -e

echo "Linking fish scripts..."

mkdir -p ~/.local/bin
ln -sf ~/dotfiles/fish/comfyui.fish ~/.local/bin/comfyui.fish
chmod +x ~/.local/bin/comfyui.fish
ln -sf ~/dotfiles/fish/comfyui-stop.fish ~/.local/bin/comfyui-stop.fish
chmod +x ~/.local/bin/comfyui-stop.fish

echo "Linking fish functions..."

mkdir -p ~/.config/fish/functions
ln -sf ~/dotfiles/fish/functions/comfyui.fish ~/.config/fish/functions/comfyui.fish
ln -sf ~/dotfiles/fish/functions/comfyui-stop.fish ~/.config/fish/functions/comfyui-stop.fish

echo "Installing desktop entries..."

mkdir -p ~/.local/share/applications
ln -sf ~/dotfiles/desktop/comfyui.desktop ~/.local/share/applications/comfyui.desktop
ln -sf ~/dotfiles/desktop/comfyui-stop.desktop ~/.local/share/applications/comfyui-stop.desktop

echo "Copying mimeapps.list..."

cp ~/dotfiles/mimeapps/.config/mimeapps.list ~/.config/mimeapps.list

echo "Done."
