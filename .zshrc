source /usr/share/zsh-antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle pip
antigen bundle fzf
antigen bundle lein
antigen bundle command-not-found
antigen bundle jeffreytse/zsh-vi-mode
antigen bundle docker
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle rupa/z
antigen bundle wting/autojump
antigen bundle changyuheng/fz
antigen bundle djui/alias-tips
antigen bundle hlissner/zsh-autopair    # Auto-close brackets/quotes
antigen bundle zdharma-continuum/fast-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle colored-man-pages

# ? System management
antigen bundle python
antigen bundle sudo
antigen bundle safe-paste
antigen bundle last-working-dir


# ? File managemet
antigen bundle cp
antigen bundle rsync
antigen bundle mv
antigen bundle fd
antigen bundle ripgrep


# Load the theme.
antigen theme bira

# Tell Antigen that you're done.
antigen apply

mkdir -p ~/.antigen/bundles/robbyrussell/oh-my-zsh/cache/completions
mkdir -p ~/.oh-my-zsh/cache/completions

# ? Adding TensorRT to the PATH
export LD_LIBRARY_PATH="/usr/local/TensorRT/lib:$LD_LIBRARY_PATH"
export PATH="/usr/local/TensorRT/bin:$PATH"

export PATH="$HOME/.local/bin:/usr/local/cuda/bin:/usr/local/go/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64"

export VCPKG_ROOT="/home/mehdi/vcpkg"
export PATH=$VCPKG_ROOT:$PATH

# ? Adding TensorRT to the PATH
export LD_LIBRARY_PATH="/usr/local/TensorRT/lib:$LD_LIBRARY_PATH"
export PATH="/usr/local/TensorRT/bin:$PATH"

# Yazi file browser config
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/mehdi/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/mehdi/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/home/mehdi/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/home/mehdi/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/home/mehdi/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/home/mehdi/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
