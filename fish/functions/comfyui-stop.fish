function comfyui-stop
    if pkill -f "python main.py"
        echo "ComfyUI durduruldu."
    else
        echo "ComfyUI zaten çalışmıyor."
    end
end
