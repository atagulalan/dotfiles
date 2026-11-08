function yi
    set -l pkg (
        yay -Slq \
        | fzf \
            --height=85% \
            --layout=reverse \
            --border=rounded \
            --prompt='󰏖  Package > ' \
            --pointer='▶' \
            --marker='✓' \
            --info=inline-right \
            --preview='yay -Si {} 2>/dev/null || yay -Ai {} 2>/dev/null' \
            --preview-window='right,50%,border-left,wrap' \
            --bind='ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
            --bind='ctrl-/:toggle-preview' \
            --bind='space:toggle' \
            --multi
    )

    test -n "$pkg"; and yay -S $pkg
end
