# Neovim Configuration Guide

This is a personal [NvChad](https://nvchad.com/) user configuration managed as part of a GNU Stow dotfiles repository. It keeps NvChad's defaults and adds language tooling, automatic formatting, a GitHub light/dark theme pair, and extra Treesitter parsers.

The `<leader>` key is **Space** throughout this guide.

## Contents

1. [What is included](#what-is-included)
2. [Prerequisites](#prerequisites)
3. [Installation and first launch](#installation-and-first-launch)
4. [How the configuration is organized](#how-the-configuration-is-organized)
5. [Daily navigation](#daily-navigation)
6. [Editing and completion](#editing-and-completion)
7. [Formatting](#formatting)
8. [Language servers](#language-servers)
9. [Treesitter](#treesitter)
10. [Git integration](#git-integration)
11. [Appearance and themes](#appearance-and-themes)
12. [Maintenance and customization](#maintenance-and-customization)
13. [Troubleshooting](#troubleshooting)

## What is included

- NvChad 2.5 as the base configuration and UI
- lazy.nvim for plugin management
- NvimTree for browsing project files
- Telescope for files, text, buffers, help, marks, and Git searches
- nvim-cmp, LuaSnip, friendly-snippets, and autopairs for completion
- Neovim LSP support with Mason available for installing external tools
- Conform for manual and format-on-save formatting
- Treesitter parsers for the configured development languages
- Gitsigns for Git change indicators
- Integrated horizontal, vertical, and floating terminals
- GitHub dark and light themes with a one-key toggle

## Prerequisites

Install the following before starting:

- **Neovim 0.11 or newer**
- **Git**, used to bootstrap lazy.nvim and download plugins
- **GNU Stow**, used by the parent dotfiles repository
- A **Nerd Font**, needed for file, statusline, and diagnostic icons
- **ripgrep (`rg`)**, recommended for Telescope live grep
- A system clipboard provider such as `xclip`, `xsel`, or `wl-clipboard` on Linux

Language servers and formatters are separate command-line programs. Install only the ones needed for the languages you use; the relevant names are listed later in this guide.

## Installation and first launch

This configuration is stored under `.config/nvim` in the parent dotfiles repository and linked into the home directory with GNU Stow.

### 1. Back up an existing configuration

If `~/.config/nvim` already exists, move it somewhere safe before applying these dotfiles:

```bash
mv ~/.config/nvim ~/.config/nvim.backup
```

Also consider backing up `~/.local/share/nvim`, `~/.local/state/nvim`, and `~/.cache/nvim` if replacing another Neovim distribution.

### 2. Clone and stow the dotfiles

```bash
git clone https://github.com/peghaz/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow .
```

Stow creates `~/.config/nvim` as links to the files in the repository.

### 3. Start Neovim

```bash
nvim
```

On the first launch, `init.lua` clones lazy.nvim when necessary. lazy.nvim then installs the pinned NvChad and plugin dependencies. After installation:

1. Run `:Lazy` and confirm that the plugins are installed.
2. Run `:Mason` to install language servers and related tools.
3. Run `:checkhealth` to inspect Neovim, providers, clipboard support, and plugins.
4. Restart Neovim after the initial installation.

The committed `lazy-lock.json` pins plugin revisions so that installations remain reproducible.

## How the configuration is organized

Startup follows this sequence:

1. `init.lua` sets Space as the leader key and bootstraps lazy.nvim.
2. lazy.nvim loads NvChad 2.5 and the user plugin specifications.
3. NvChad generates and loads its theme and statusline highlights.
4. `lua/options.lua` and `lua/autocmds.lua` load the NvChad defaults.
5. `lua/mappings.lua` loads NvChad mappings and applies local additions.

The main customization points are:

| Path | Purpose |
| --- | --- |
| `lua/chadrc.lua` | Theme and NvChad UI choices |
| `lua/plugins/init.lua` | Added plugins and overrides of NvChad plugin options |
| `lua/mappings.lua` | User-defined mappings layered over NvChad defaults |
| `lua/configs/lspconfig.lua` | Enabled language servers |
| `lua/configs/conform.lua` | Formatter selection and format-on-save behavior |
| `lua/configs/lazy.lua` | lazy.nvim UI and runtime-path settings |

## Daily navigation

### Discover mappings

Press Space and pause to open WhichKey. It displays available mapping groups and is the easiest way to discover NvChad commands.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>ch` | Normal | Open the NvChad cheatsheet |
| `<leader>wK` | Normal | Show all WhichKey mappings |
| `<leader>wk` | Normal | Query a key prefix in WhichKey |
| `;` | Normal | Enter command-line mode |
| `jk` | Insert | Return to Normal mode |

### Find files and text

Telescope supplies the main search workflows:

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files in the project |
| `<leader>fa` | Find all files, including hidden and ignored files |
| `<leader>fw` | Search project text with ripgrep |
| `<leader>fz` | Search inside the current buffer |
| `<leader>fb` | Search open buffers |
| `<leader>fo` | Search recently opened files |
| `<leader>fh` | Search Neovim help tags |
| `<leader>ma` | Search marks |

`<leader>fw` requires `rg` to be available on `PATH`.

### Browse files

| Key | Action |
| --- | --- |
| `<C-n>` | Toggle NvimTree |
| `<leader>e` | Focus NvimTree |

NvimTree uses the standard NvChad configuration. The custom `lua/configs/nvimtree.lua` module currently exists as an inactive configuration draft and is not loaded.

### Work with buffers and windows

| Key | Action |
| --- | --- |
| `<Tab>` | Go to the next buffer |
| `<S-Tab>` | Go to the previous buffer |
| `<leader>b` | Create an empty buffer |
| `<leader>x` | Close the current buffer |
| `<C-h>` | Move to the window on the left |
| `<C-j>` | Move to the window below |
| `<C-k>` | Move to the window above |
| `<C-l>` | Move to the window on the right |

The buffer mappings are available while NvChad's tab/buffer line is enabled, which is the default in this configuration.

### Use terminals

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>h` | Normal | Open a new horizontal terminal |
| `<leader>v` | Normal | Open a new vertical terminal |
| `<A-h>` | Normal/Terminal | Toggle the persistent horizontal terminal |
| `<A-v>` | Normal/Terminal | Toggle the persistent vertical terminal |
| `<A-i>` | Normal/Terminal | Toggle the floating terminal |
| `<C-x>` | Terminal | Leave Terminal mode |

Some desktop environments or terminal emulators intercept Alt combinations. See [Troubleshooting](#troubleshooting) if a terminal mapping does not arrive in Neovim.

### General editing mappings

| Key | Mode | Action |
| --- | --- | --- |
| `<C-s>` | Normal | Save the current file |
| `<C-c>` | Normal | Copy the whole file to the system clipboard |
| `<Esc>` | Normal | Clear search highlighting |
| `<leader>/` | Normal/Visual | Toggle a comment |
| `<leader>n` | Normal | Toggle line numbers |
| `<leader>rn` | Normal | Toggle relative line numbers |

In Insert mode, `<C-b>` and `<C-e>` move to the beginning and end of the line. `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` move the cursor left, down, up, and right.

## Editing and completion

Completion is provided by nvim-cmp and draws suggestions from:

- attached language servers
- LuaSnip snippets and friendly-snippets
- words in the current buffer
- Neovim's Lua API
- filesystem paths

Autopairs inserts and manages matching delimiters such as `()`, `{}`, and `[]`. Completion is loaded when Insert mode is first entered.

| Key | Action while completing |
| --- | --- |
| `<C-Space>` | Open completion manually |
| `<C-n>` or `<Tab>` | Select the next item |
| `<C-p>` or `<S-Tab>` | Select the previous item |
| `<CR>` | Confirm the selected item |
| `<C-d>` / `<C-f>` | Scroll documentation up/down |
| `<C-e>` | Close completion |

`<Tab>` and `<S-Tab>` also move forward and backward through snippet placeholders when the completion menu is closed.

## Formatting

[Conform](https://github.com/stevearc/conform.nvim) formats supported buffers automatically on save with a 500 ms timeout. If no configured formatter is available, it falls back to an attached LSP formatter when possible.

Use `<leader>fm` in Normal or Visual mode to format manually.

| File type | Formatter executable |
| --- | --- |
| Lua | `stylua` |
| C and C++ | `clang-format` |
| Rust | `rustfmt` |
| Go | `goimports`, then `gofmt` |
| Python | `ruff` (`ruff_format`) |
| TOML | `taplo` |
| Shell and Bash | `shfmt` |

Conform does not install these programs. Install them with Mason, your language toolchain, or the system package manager. Use `:ConformInfo` in a buffer to see the selected formatter and whether its executable is available.

## Language servers

NvChad configures Neovim's native LSP client and always enables `lua_ls`. This configuration additionally enables the following servers:

| Language or file type | Neovim server name | Common executable/package |
| --- | --- | --- |
| Lua | `lua_ls` | `lua-language-server` |
| HTML | `html` | `vscode-html-language-server` / `html-lsp` |
| CSS | `cssls` | `vscode-css-language-server` / `css-lsp` |
| C and C++ | `clangd` | `clangd` |
| Rust | `rust_analyzer` | `rust-analyzer` |
| Go | `gopls` | `gopls` |
| Python | `pyright` | `pyright-langserver` / `pyright` |
| Dockerfile | `dockerls` | `docker-langserver` / `dockerfile-language-server` |
| Docker Compose | `docker_compose_language_service` | `docker-compose-langserver` / `docker-compose-language-service` |
| TOML | `taplo` | `taplo` |
| Bash | `bashls` | `bash-language-server` |

The configuration enables clients; it does not automatically install their executables.

### Install a server

1. Open `:Mason`.
2. Find the desired package.
3. Press `i` to install it.
4. Reopen the relevant file or restart Neovim.
5. Run `:LspInfo` to verify that the client attached.

Installing the executable through a system package manager is also valid as long as it is on `PATH` when Neovim starts.

### LSP mappings

These mappings become available in a buffer after an LSP client attaches:

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `<leader>D` | Go to type definition |
| `<leader>ra` | Rename the symbol under the cursor |
| `<leader>wa` | Add a workspace folder |
| `<leader>wr` | Remove a workspace folder |
| `<leader>wl` | List workspace folders |
| `<leader>ds` | Put diagnostics in the location list |

Hover, references, code actions, and diagnostic navigation also remain available through Neovim's built-in LSP commands and WhichKey-discoverable NvChad behavior.

## Treesitter

Treesitter provides syntax-aware highlighting and parsing. The configuration ensures parsers are installed for:

- Vim, Lua, and Vimdoc
- HTML and CSS
- C and C++
- Rust
- Go, Go modules, and Go sums
- Python
- Dockerfile
- TOML
- Bash

Use `:TSUpdate` to update installed parsers. Use `:TSInstall <language>` to add another parser without changing the configuration; add it to `ensure_installed` in `lua/plugins/init.lua` if it should remain part of this setup.

## Git integration

Gitsigns displays added, changed, and deleted line indicators in Git-managed files. Telescope supplies two useful repository views:

| Key | Action |
| --- | --- |
| `<leader>gt` | Search changed files from Git status |
| `<leader>cm` | Search Git commits |

There is no Lazygit integration or custom hunk-action mapping in the active configuration. Use the command line or add a dedicated plugin if a full Git interface is desired.

## Appearance and themes

The default colorscheme is `github_dark`; the paired light theme is `github_light`.

| Key | Action |
| --- | --- |
| `<leader>tt` | Toggle between GitHub dark and light themes |
| `<leader>th` | Open NvChad's theme picker |

NvChad also supplies the statusline, tab/buffer line, indentation guides, icons, menus, and notification styling. A Nerd Font must be selected in the terminal for the glyphs to render correctly.

Important inherited editor defaults include:

- absolute line numbers
- two-space indentation with spaces
- case-insensitive search that becomes case-sensitive when uppercase letters are used
- mouse support
- the system clipboard through `unnamedplus`

## Maintenance and customization

### Update plugins

Open `:Lazy`, inspect available updates, and run the update action. Review the resulting `lazy-lock.json` change before committing it.

Useful commands include:

| Command | Purpose |
| --- | --- |
| `:Lazy` | Inspect, install, update, or clean plugins |
| `:Mason` | Install and inspect external development tools |
| `:TSUpdate` | Update Treesitter parsers |
| `:checkhealth` | Diagnose Neovim and provider problems |
| `:ConformInfo` | Inspect formatter selection and availability |
| `:LspInfo` | Inspect LSP clients for the current buffer |

### Add or change behavior

- Add plugins or override NvChad plugin options in `lua/plugins/init.lua`.
- Add mappings in `lua/mappings.lua` after `require "nvchad.mappings"`.
- Add LSP server names in `lua/configs/lspconfig.lua` and install their executables.
- Add formatter mappings in `lua/configs/conform.lua`.
- Add Treesitter parser names to `ensure_installed` in `lua/plugins/init.lua`.
- Change the default and toggle themes in `lua/chadrc.lua`.

Keep this README synchronized when changing a user-visible mapping, tool, or workflow.

### Inactive configuration modules

The repository contains `configs/dap.lua`, `configs/cmp.lua`, `configs/devicons.lua`, `configs/lsp_servers.lua`, and `configs/nvimtree.lua`. They are not currently imported by an active plugin specification, so their DAP, DAP completion, custom icon, extended server-list, and custom tree behaviors are **not available at runtime**. They are retained as configuration drafts and are intentionally not documented as working features.

Similarly, Copilot, Oil, Lazygit, Visual Multi, and nvim-dap are not declared as active plugins.

## Troubleshooting

### Icons appear as boxes

Install a Nerd Font and select that font in the terminal emulator. Restart the terminal and Neovim afterward.

### Live grep fails

Confirm that ripgrep is installed and visible to Neovim:

```vim
:echo executable('rg')
```

A result of `1` means Neovim can find it.

### An LSP client does not attach

1. Open the relevant source file and run `:LspInfo`.
2. Check the server in `:Mason`, or verify its executable with `:echo executable('server-command')`.
3. Confirm that the file type is correct with `:set filetype?`.
4. Inspect `:messages` and `:checkhealth vim.lsp` for errors.

### A file does not format

Run `:ConformInfo` and verify that the expected formatter is configured and available. If it is unavailable, install the executable and restart Neovim so the updated `PATH` is inherited.

### Clipboard operations fail

Run `:checkhealth provider`. On Linux, install a clipboard utility appropriate for the display server, such as `wl-clipboard` on Wayland or `xclip`/`xsel` on X11.

### Alt or function keys do not work

The terminal emulator or desktop environment may intercept the key. Check its keyboard shortcuts and ensure Alt is sent as Meta/Escape to terminal applications. WhichKey and command-line commands provide alternatives when a key cannot be forwarded.

### Reset plugin state

Start with `:Lazy sync` and `:checkhealth`. Deleting Neovim data directories should be a last resort because it removes downloaded plugins and other local state; back them up before doing so.

## Credits

- [NvChad](https://github.com/NvChad/NvChad) and its plugin ecosystem
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- The broader Neovim plugin community
