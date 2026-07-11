export PATH="/home/xava/.nvm/versions/node/v24.15.0/bin:$PATH"
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

. "$HOME/.local/bin/env"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/xava/.lmstudio/bin"
# End of LM Studio CLI section

