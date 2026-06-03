function ai
    set cmd (ollama run qwen3-coder:30b "Return ONLY a valid linux shell command for: $argv. No explanation. Do not include wrap the command in backticks.")
    
    echo ">>> $cmd"
    read -P "Execute? [y/N] " ans
    
    if test "$ans" = "y" -o "$ans" = "Y"
        eval $cmd
    end
end
