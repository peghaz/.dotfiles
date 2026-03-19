# Dotfiles

My personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's included

- `.zshrc` — Zsh configuration
- `.vimrc` — Vim configuration
- `.tmux.conf` — Tmux configuration
- `.config/kitty.conf` — Kitty terminal
- `.config/btop/` — Btop system monitor
- `.config/yazi/` — Yazi file manager
- `.config/input-remapper-2/` — Input Remapper
- `.config/uv/` — uv (Python package manager)
- `.custom_scripts/` — Custom shell scripts

## Usage

### Prerequisites

Install GNU Stow:

```bash
# Debian/Ubuntu
sudo apt install stow

# Fedora
sudo dnf install stow

# Arch
sudo pacman -S stow

# macOS
brew install stow
```

### Install

Clone the repo into your home directory and run `stow`:

```bash
cd ~
git clone <repo-url> .dotfiles
cd .dotfiles
stow .
```

This creates symlinks in your home directory pointing to the files in this repo.

### Uninstall

To remove all symlinks:

```bash
cd ~/.dotfiles
stow -D .
```

### Update

Pull the latest changes and re-stow:

```bash
cd ~/.dotfiles
git pull
stow -R .
```
