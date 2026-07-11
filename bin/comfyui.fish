#!/usr/bin/env fish

set COMFYUI_DIR ~/Documents/ComfyUI

cd $COMFYUI_DIR

source venv/bin/activate.fish

python main.py &

sleep 3

xdg-open http://127.0.0.1:8188
