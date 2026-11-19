test -f /usr/share/cachyos-fish-config/cachyos-config.fish; and source /usr/share/cachyos-fish-config/cachyos-config.fish

# fastfetch açılış mesajını kapat (cachyos-config'in greeting fonksiyonunu ezer;
# sistem dosyasını elle düzenlemek paket güncellemesinde/yeni makinede kaybolur)
function fish_greeting
end

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- "$PNPM_HOME/bin" $PATH
  set -gx PATH "$PNPM_HOME/bin" $PATH
end
# pnpm end

# OpenClaw Completion
test -f "$HOME/.openclaw/completions/openclaw.fish"; and source "$HOME/.openclaw/completions/openclaw.fish"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# LM Studio CLI (lms)
set -gx PATH $PATH $HOME/.lmstudio/bin

# opencode
fish_add_path $HOME/.opencode/bin

# Python CLI tools installed by mise (comfy, comfy-cli, etc.)
fish_add_path $HOME/.local/share/mise/installs/python/latest/bin

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/xava/.lmstudio/bin
# End of LM Studio CLI section
