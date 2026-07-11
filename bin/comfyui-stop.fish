#!/usr/bin/env fish

if pkill -f "python main.py"
    echo "ComfyUI durduruldu."
else
    echo "ComfyUI zaten çalışmıyor."
end
