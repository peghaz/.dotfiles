# ~/.config/omf/init.fish

# -----------------------------
# Prompt
# -----------------------------
# Two-line prompt:
#
# mehdi@legion ~/path/to/project (main)
# ❯

# Disable right prompt from OMF themes.
function fish_right_prompt
end


# -----------------------------
# Fish Git prompt options
# -----------------------------

set -g __fish_git_prompt_showdirtystate yes
set -g __fish_git_prompt_showstashstate yes
set -g __fish_git_prompt_showuntrackedfiles yes
set -g __fish_git_prompt_showupstream auto
set -g __fish_git_prompt_color_branch brmagenta


# -----------------------------
# Abbreviations
# -----------------------------
# Abbreviations expand after pressing Space.
# Example: typing "gs " becomes "git status ".

abbr -a ll 'ls -lah'
abbr -a la 'ls -A'
abbr -a l 'ls -CF'

abbr -a c clear

abbr -a gs 'git status'
abbr -a ga 'git add'
abbr -a gaa 'git add --all'
abbr -a gc 'git commit'
abbr -a gcm 'git commit -m'
abbr -a gp 'git push'
abbr -a gpf 'git push --force-with-lease'
abbr -a gl 'git pull'
abbr -a gd 'git diff'
abbr -a gds 'git diff --staged'
abbr -a gco 'git checkout'
abbr -a gb 'git branch'
abbr -a gba 'git branch -a'
abbr -a gst 'git status'

abbr -a py python
abbr -a pipi 'pip install'

abbr -a grep rg
abbr -a find fd

abbr -a svi 'sudo nvim'


# -----------------------------
# Safer file operations
# -----------------------------

abbr -a cp 'cp -i'
abbr -a mv 'mv -i'
abbr -a rm 'rm -i'


# -----------------------------
# Optional local machine overrides
# -----------------------------
# Put secrets or machine-specific config here.
# Do not commit this file.

if test -f ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end
