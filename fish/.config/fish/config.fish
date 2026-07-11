source /usr/share/cachyos-fish-config/cachyos-config.fish

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
