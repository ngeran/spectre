# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# uv
export PATH="/home/nikos/.local/share/../bin:$PATH"
. "$HOME/.cargo/env"

# Spectre Dotfile Manager
alias spectre='/usr/bin/git --git-dir=/home/nikos/.spectre_repo/ --work-tree=/home/nikos'

# tty-clock 
alias clock='tty-clock -c -C 4 -b -s'

# opencode
export PATH=/home/nikos/.opencode/bin:$PATH
