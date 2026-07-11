source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# pnpm
set -gx PNPM_HOME "/home/xava/.local/share/pnpm"
if not string match -q -- "$PNPM_HOME/bin" $PATH
  set -gx PATH "$PNPM_HOME/bin" $PATH
end
# pnpm end

# OpenClaw Completion
test -f "/home/xava/.openclaw/completions/openclaw.fish"; and source "/home/xava/.openclaw/completions/openclaw.fish"
# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/xava/.lmstudio/bin
# End of LM Studio CLI section


# opencode
fish_add_path /home/xava/.opencode/bin
