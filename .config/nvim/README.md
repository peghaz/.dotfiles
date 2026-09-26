# Neovim Configuration Tutorial

This is a personal [NvChad](https://nvchad.com/) configuration managed inside a GNU Stow dotfiles repository. This guide is written as a refresher: start at the top on a new machine, or jump to the workflow you have forgotten.

The leader key is **Space**. For example, `<leader>ff` means: press Space, then `f`, then `f`.

## Start here: what installs what?

The setup has five moving parts. Keeping them separate makes maintenance much easier.

| Tool | What it manages | Where this configuration lives |
| --- | --- | --- |
| **lazy.nvim** | Neovim plugins such as Telescope, NvimTree, and Conform | `lua/plugins/init.lua` and NvChad's plugin specifications |
| **Mason** | External programs such as language servers and formatters | Installed locally with `:Mason` or `:MasonInstall` |
| **nvim-lspconfig** | Connects Neovim to installed language servers | `lua/configs/lspconfig.lua` |
| **Conform** | Chooses and runs formatters | `lua/configs/conform.lua` |
| **Treesitter** | Syntax parsers used for highlighting and code awareness | The Treesitter specification in `lua/plugins/init.lua` |

The most important distinction is:

> Lazy installs Neovim plugins. Mason installs command-line development tools used by those plugins.

## 1. Install the configuration

### Prerequisites

Install these before opening Neovim:

- Neovim 0.11 or newer
- Git
- GNU Stow
- A Nerd Font selected in the terminal
- [ripgrep](https://github.com/BurntSushi/ripgrep) for project text search
- A clipboard provider: `wl-clipboard` on Wayland, or `xclip`/`xsel` on X11

Language runtimes such as Go and Rust are still installed separately from Neovim.

### Clone and stow the dotfiles

Back up an existing Neovim configuration first, then clone and stow the repository:

```bash
mv ~/.config/nvim ~/.config/nvim.backup
git clone https://github.com/peghaz/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow .
```

Open a project from its root:

```bash
cd /path/to/project
nvim .
```

On the first launch, `init.lua` bootstraps lazy.nvim. Lazy then downloads NvChad and its plugin dependencies using the versions pinned in `lazy-lock.json`.

### First-launch checklist

Run these commands inside Neovim. Type `:` first, enter the command, and press Enter.

```vim
:Lazy sync
:Mason
:TSInstallAll
:checkhealth
```

- `:Lazy sync` installs, updates, and cleans Neovim plugins according to the lockfile.
- `:Mason` opens the external-tool installer.
- `:TSInstallAll` installs every syntax parser listed by this configuration.
- `:checkhealth` reports missing providers and environment problems.

Restart Neovim after the first installation.

## 2. Install language servers and formatters

The configuration enables language integrations, but it does not automatically install every external executable. Install only the languages you actually use.

### Install through the Mason interface

Run:

```vim
:Mason
```

Search for a package, move the cursor onto it, and press `i` to install it. Press `g?` inside Mason to see all of its keys.

### Install through commands

These commands cover every active language server and every formatter that Mason can provide for this configuration:

```vim
:MasonInstall lua-language-server stylua
:MasonInstall html-lsp css-lsp
:MasonInstall clangd clang-format
:MasonInstall rust-analyzer
:MasonInstall gopls goimports
:MasonInstall pyright ruff
:MasonInstall dockerfile-language-server docker-compose-language-service
:MasonInstall taplo
:MasonInstall bash-language-server shfmt
```

Two formatters come from their language toolchains rather than Mason:

```bash
rustup component add rustfmt
go version  # gofmt is included with Go
```

### What each language uses

| Language | LSP configuration | Mason package | Formatter | Treesitter parser |
| --- | --- | --- | --- | --- |
| Lua | `lua_ls` | `lua-language-server` | `stylua` | `lua` |
| HTML | `html` | `html-lsp` | LSP fallback when supported | `html` |
| CSS | `cssls` | `css-lsp` | LSP fallback when supported | `css` |
| C | `clangd` | `clangd` | `clang-format` | `c` |
| C++ | `clangd` | `clangd` | `clang-format` | `cpp` |
| Rust | `rust_analyzer` | `rust-analyzer` | `rustfmt` from Rustup | `rust` |
| Go | `gopls` | `gopls` | `goimports`, then `gofmt` | `go`, `gomod`, `gosum` |
| Python | `pyright` | `pyright` | `ruff` | `python` |
| Dockerfile | `dockerls` | `dockerfile-language-server` | LSP fallback when supported | `dockerfile` |
| Docker Compose | `docker_compose_language_service` | `docker-compose-language-service` | LSP fallback when supported | — |
| TOML | `taplo` | `taplo` | `taplo` | `toml` |
| Shell/Bash | `bashls` | `bash-language-server` | `shfmt` | `bash` |

To verify the current file:

```vim
:LspInfo
:ConformInfo
:set filetype?
```

`LspInfo` should show an attached client. `ConformInfo` shows the selected formatter and whether its executable was found.

## 3. Learn and discover the keys

You do not need to memorize everything at once.

1. Press Space and pause to open WhichKey for the leader-key menu.
2. Continue pressing keys to narrow the menu.
3. Use `<leader>ch` for NvChad's cheatsheet.
4. Use `<leader>wK` to list mappings through WhichKey.
5. Use `<leader>wk`, then enter a key prefix, to inspect a specific mapping group.

The tables below use these mode names:

- **Normal**: the default command/navigation mode.
- **Insert**: the mode used while typing text.
- **Visual**: the mode used while selecting text.
- **Terminal**: input is being sent to a terminal buffer.

## 4. Daily workflow tutorial

### Find a file or search the project

Telescope provides the main search workflows.

| Key | What it does |
| --- | --- |
| `<leader>ff` | Find project files |
| `<leader>fa` | Find all files, including hidden and ignored files |
| `<leader>fw` | Search project text with ripgrep |
| `<leader>fz` | Fuzzy-search inside the current file |
| `<leader>fb` | Search open buffers |
| `<leader>fo` | Search recently opened files |
| `<leader>fh` | Search Neovim help |
| `<leader>ma` | Search marks |

Example: to find every occurrence of a function name, press `<leader>fw`, type the name, and press Enter on a result.

### Browse the project tree

NvimTree provides the file explorer.

| Key | What it does |
| --- | --- |
| `<C-n>` | Toggle the project tree |
| `<leader>e` | Focus the project tree |

Press `<C-n>` again to close it. NvimTree itself has contextual mappings; press `g?` while the tree is focused to view them.

### Move between buffers and windows

Buffers are open files; windows are the visible panes displaying them.

| Key | What it does |
| --- | --- |
| `<Tab>` | Next buffer |
| `<S-Tab>` | Previous buffer |
| `<leader>b` | Create an empty buffer |
| `<leader>x` | Close the current buffer |
| `<C-h>` | Move to the window on the left |
| `<C-j>` | Move to the window below |
| `<C-k>` | Move to the window above |
| `<C-l>` | Move to the window on the right |

The buffer mappings depend on NvChad's tab/buffer line, which is enabled in this configuration.

### Edit, save, and comment

| Key | Mode | What it does |
| --- | --- | --- |
| `jk` | Insert | Return to Normal mode |
| `;` | Normal | Enter command-line mode without Shift |
| `<C-s>` | Normal | Save the current file |
| `<C-c>` | Normal | Copy the whole file to the system clipboard |
| `<Esc>` | Normal | Clear search highlighting |
| `<leader>/` | Normal/Visual | Comment or uncomment the line/selection |
| `<leader>n` | Normal | Toggle absolute line numbers |
| `<leader>rn` | Normal | Toggle relative line numbers |

In Insert mode, `<C-b>` and `<C-e>` move to the beginning and end of the line. `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` move the cursor left, down, up, and right.

### Use completion and snippets

nvim-cmp loads when Insert mode is first entered. It combines suggestions from attached language servers, snippets, the current buffer, Neovim's Lua API, and filesystem paths. LuaSnip handles snippets, and nvim-autopairs manages matching brackets and quotes.

| Key | What it does while completing |
| --- | --- |
| `<C-Space>` | Open completion manually |
| `<C-n>` or `<Tab>` | Select the next item |
| `<C-p>` or `<S-Tab>` | Select the previous item |
| `<CR>` | Confirm the selected item |
| `<C-d>` / `<C-f>` | Scroll documentation up/down |
| `<C-e>` | Close completion |

When the completion menu is closed, `<Tab>` and `<S-Tab>` move forward and backward through snippet placeholders.

## 5. Navigate and understand code with LSP

Open a source file from the project root and run `:LspInfo`. If the expected client is attached, these mappings are available.

### NvChad LSP mappings

| Key | What it does |
| --- | --- |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `<leader>D` | Go to type definition |
| `<leader>ra` | Rename the symbol under the cursor |
| `<leader>wa` | Add a workspace folder |
| `<leader>wr` | Remove a workspace folder |
| `<leader>wl` | List workspace folders |
| `<leader>ds` | Put diagnostics in the location list |

### Neovim's built-in LSP mappings

Neovim 0.11+ also supplies these defaults when the server supports the operation:

| Key | What it does |
| --- | --- |
| `K` | Show hover documentation |
| `gra` | Show code actions |
| `gri` | Go to implementation |
| `grn` | Rename a symbol |
| `grr` | Find references |
| `grt` | Go to type definition |
| `gO` | List document symbols |
| `<C-s>` | Show signature help in Insert mode |

If a mapping appears to do nothing, first check `:LspInfo`. A configured server cannot attach until its executable has been installed.

## 6. Format code

Conform formats supported files automatically immediately before they are saved. It waits up to 500 ms for the formatter and falls back to an attached LSP formatter when no configured formatter is available.

To format manually in Normal or Visual mode:

| Key | What it does |
| --- | --- |
| `<leader>fm` | Format the current file |

Configured formatter sequence:

| File type | Formatter |
| --- | --- |
| Lua | `stylua` |
| C/C++ | `clang-format` |
| Rust | `rustfmt` |
| Go | `goimports`, then `gofmt` |
| Python | `ruff` |
| TOML | `taplo` |
| Shell/Bash | `shfmt` |

If formatting does not happen, run `:ConformInfo`. The most common cause is a missing executable.

## 7. Git, terminals, and appearance

### Inspect Git changes

Gitsigns displays added, changed, and deleted line indicators beside Git-managed files. Telescope provides repository-wide views:

| Key | What it does |
| --- | --- |
| `<leader>gt` | Search files shown by Git status |
| `<leader>cm` | Search Git commits |

This setup does not include Lazygit or custom hunk-action mappings.

### Open terminals

| Key | Mode | What it does |
| --- | --- | --- |
| `<leader>h` | Normal | Open a new horizontal terminal |
| `<leader>v` | Normal | Open a new vertical terminal |
| `<A-h>` | Normal/Terminal | Toggle the persistent horizontal terminal |
| `<A-v>` | Normal/Terminal | Toggle the persistent vertical terminal |
| `<A-i>` | Normal/Terminal | Toggle the floating terminal |
| `<C-x>` | Terminal | Leave Terminal mode |
| `<leader>pt` | Normal | Find a hidden terminal with Telescope |

If an Alt mapping does not work, the terminal emulator or desktop environment may be intercepting it.

### Change the theme

The default theme is `github_dark`; its paired light theme is `github_light`.

| Key | Source | What it does |
| --- | --- | --- |
| `<leader>tt` | Local mapping | Toggle GitHub dark/light |
| `<leader>th` | NvChad | Open the theme picker |

## 8. Quick cheatsheet

| Workflow | Keys or command | Provided by |
| --- | --- | --- |
| Discover keys | Space and pause, `<leader>ch`, `<leader>wK` | WhichKey / NvChad |
| Find files/text | `<leader>ff`, `<leader>fw`, `<leader>fz` | Telescope |
| File explorer | `<C-n>`, `<leader>e` | NvimTree |
| Buffers | `<Tab>`, `<S-Tab>`, `<leader>b`, `<leader>x` | NvChad |
| Windows | `<C-h/j/k/l>` | NvChad |
| Comment | `<leader>/` | Neovim comment operator / NvChad mapping |
| Definition/rename | `gd`, `<leader>ra` | LSP / NvChad |
| Hover/actions/references | `K`, `gra`, `grr` | Neovim LSP defaults |
| Diagnostics | `<leader>ds` | LSP / NvChad |
| Format | `<leader>fm` | Conform / NvChad mapping |
| Git status/commits | `<leader>gt`, `<leader>cm` | Telescope |
| Terminals | `<leader>h`, `<leader>v`, `<A-i>` | NvChad |
| Toggle theme | `<leader>tt` | Local mapping |
| Plugin manager | `:Lazy` | lazy.nvim |
| Tool installer | `:Mason` | Mason |
| LSP status | `:LspInfo` | Neovim LSP |
| Formatter status | `:ConformInfo` | Conform |
| General diagnostics | `:checkhealth` | Neovim |

## 9. Maintain or extend the setup

### Add a Neovim plugin

Add a lazy.nvim plugin specification to `lua/plugins/init.lua`, then run:

```vim
:Lazy sync
```

Mason is not used for this step.

### Add a language server

1. Add its nvim-lspconfig server name to `lua/configs/lspconfig.lua`.
2. Install the corresponding executable with `:Mason` or a system package manager.
3. Open a matching file and verify it with `:LspInfo`.

### Add a formatter

1. Add its Conform formatter name under the relevant file type in `lua/configs/conform.lua`.
2. Install the executable with Mason or the language toolchain.
3. Verify it with `:ConformInfo`.

### Add a Treesitter parser

Add the parser name to `ensure_installed` in `lua/plugins/init.lua`, then run `:TSInstallAll`. After Treesitter has loaded for an open file, `:TSUpdate` updates installed parsers.

### Add a mapping

Add it to `lua/mappings.lua` after `require "nvchad.mappings"`. Give the mapping a useful `desc` so WhichKey can display it.

### Change the theme

Change `theme` and `theme_toggle` in `lua/chadrc.lua`.

### Inactive draft modules

The files `configs/dap.lua`, `configs/cmp.lua`, `configs/devicons.lua`, `configs/lsp_servers.lua`, and `configs/nvimtree.lua` are not imported by active plugin specifications. Their custom DAP, completion, icon, server-list, and tree behavior is therefore unavailable. The working behavior documented above comes from NvChad defaults and the active specifications in `lua/plugins/init.lua`.

## 10. Troubleshooting

### A language server does not attach

1. Run `:LspInfo` in the affected file.
2. Check the file type with `:set filetype?`.
3. Open `:Mason` and confirm that the server is installed.
4. Run `:checkhealth vim.lsp` and inspect `:messages`.
5. Reopen the file or restart Neovim after installing the executable.

### A file does not format

Run `:ConformInfo`. Confirm that the expected formatter is listed and available. If the file type has no formatter in the table above, formatting depends on LSP fallback support.

### Project text search fails

Telescope's `<leader>fw` needs ripgrep:

```vim
:echo executable('rg')
```

The result should be `1`.

### Clipboard operations fail

Run `:checkhealth provider` and install a provider suitable for the display server, such as `wl-clipboard`, `xclip`, or `xsel`.

### Icons appear as boxes

Install a Nerd Font, select it in the terminal emulator, and restart the terminal and Neovim.

### A mapping is missing or has changed

Press Space and pause, use `<leader>ch`, or run:

```vim
:verbose nmap <keys>
```

The verbose mapping output shows where the current mapping was defined.

### Plugins fail to load

Start with `:Lazy sync`, restart Neovim, and run `:checkhealth`. The downloaded plugin and state directories under `~/.local` should only be deleted as a last resort and after making a backup.

## Configuration map

| Path | Purpose |
| --- | --- |
| `init.lua` | Bootstraps lazy.nvim and loads the configuration |
| `lua/chadrc.lua` | Theme and NvChad UI settings |
| `lua/plugins/init.lua` | Active plugin additions and overrides |
| `lua/mappings.lua` | Local mappings layered over NvChad mappings |
| `lua/options.lua` | Local options layered over NvChad options |
| `lua/autocmds.lua` | Local autocommands layered over NvChad autocommands |
| `lua/configs/lspconfig.lua` | Enabled language servers |
| `lua/configs/conform.lua` | Formatters and format-on-save behavior |
| `lua/configs/lazy.lua` | lazy.nvim UI and performance settings |

## Credits

- [NvChad](https://github.com/NvChad/NvChad)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [Mason](https://github.com/mason-org/mason.nvim)
- [Conform](https://github.com/stevearc/conform.nvim)
- The broader Neovim plugin community
