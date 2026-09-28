# Neovim Configuration Tutorial

This is a personal [NvChad](https://nvchad.com/) configuration managed inside a GNU Stow dotfiles repository. This guide is written as a refresher: start at the top on a new machine, or jump to the workflow you have forgotten.

The leader key is **Space**. For example, `<leader>ff` means: press Space, then `f`, then `f`.

## Start here: what installs what?

The setup has nine moving parts. Keeping them separate makes maintenance much easier.

| Tool | What it manages | Where this configuration lives |
| --- | --- | --- |
| **lazy.nvim** | Neovim plugins such as Telescope, NvimTree, and Conform | `lua/plugins/init.lua` and NvChad's plugin specifications |
| **Mason** | External programs such as language servers and formatters | Installed locally with `:Mason` or `:MasonInstall` |
| **nvim-lspconfig** | Connects Neovim to installed language servers | `lua/configs/lspconfig.lua` |
| **Conform** | Chooses and runs formatters | `lua/configs/conform.lua` |
| **Treesitter** | Syntax parsers used for highlighting and code awareness | The Treesitter specification in `lua/plugins/init.lua` |
| **nvim-dap** | Runs debuggers and coordinates the visual debugging UI | `lua/configs/dap.lua` |
| **CMake Tools** | Creates, configures, builds, runs, tests, and debugs CMake projects | `lua/configs/cmake.lua` |
| **Markdown tools** | Provides Markdown editing operators and synchronized browser preview | `lua/configs/markdown.lua` |
| **VimTeX** | Compiles LaTeX continuously and coordinates the PDF viewer | `lua/configs/latex.lua` |

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
- Node.js and npm for the Markdown browser preview

For LaTeX authoring on Fedora, install a TeX distribution, `latexmk`, `latexindent`, and Zathura with a PDF backend. The exact TeX Live collection can be expanded later if a document uses packages that are not installed.

```bash
sudo dnf install latexmk texlive-latexindent zathura zathura-pdf-mupdf
```

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

These commands cover the Mason-managed language servers, formatters, and debug adapter used by this configuration:

```vim
:MasonInstall lua-language-server stylua
:MasonInstall html-lsp css-lsp
:MasonInstall clangd clang-format codelldb
:MasonInstall rust-analyzer
:MasonInstall gopls goimports
:MasonInstall pyright ruff
:MasonInstall debugpy
:MasonInstall marksman texlab
:MasonInstall dockerfile-language-server docker-compose-language-service
:MasonInstall taplo
:MasonInstall bash-language-server shfmt
```

Two formatters come from their language toolchains rather than Mason:

```bash
rustup component add rustfmt
go version  # gofmt is included with Go
```

`debugpy` is Python's debug adapter rather than a language server or formatter. The DAP configuration uses Mason's isolated `debugpy-adapter` directly, so a system-wide Debugpy installation is neither required nor used.

### What each language uses

| Language | LSP configuration | Mason package | Formatter | Treesitter parser |
| --- | --- | --- | --- | --- |
| Lua | `lua_ls` | `lua-language-server` | `stylua` | `lua` |
| HTML | `html` | `html-lsp` | LSP fallback when supported | `html` |
| CSS | `cssls` | `css-lsp` | LSP fallback when supported | `css` |
| C | `clangd` | `clangd` | `clang-format` | `c` |
| C++ | `clangd` | `clangd`, `codelldb` for debugging | `clang-format` | `cpp` |
| Rust | `rust_analyzer` | `rust-analyzer` | `rustfmt` from Rustup | `rust` |
| Go | `gopls` | `gopls` | `goimports`, then `gofmt` | `go`, `gomod`, `gosum` |
| Python | `pyright` | `pyright` | `ruff` | `python` |
| Markdown | `marksman` | `marksman` | LSP fallback when supported | `markdown`, `markdown_inline` |
| LaTeX | `texlab` | `texlab` | `latexindent` from TeX Live | VimTeX syntax |
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
| `<C-p>` | Quickly open a project file, like VS Code's Go to File menu |
| `<leader>ff` | Find project files |
| `<leader>fa` | Find all files, including hidden and ignored files |
| `<leader>fw` | Search project text with ripgrep |
| `<leader>fz` | Fuzzy-search inside the current file |
| `<leader>fb` | Search open buffers |
| `<leader>fo` | Search recently opened files |
| `<leader>fh` | Search Neovim help |
| `<leader>ma` | Search marks |

Example: to find every occurrence of a function name, press `<leader>fw`, type the name, and press Enter on a result.

`<C-p>` is the quickest route to the standard project-file picker. It searches from Neovim's current working directory and respects Git-ignore rules. The existing `<leader>ff` mapping opens the same picker.

### Browse the project tree

There are two complementary file-browser views. Telescope is the primary, keyboard-first browser: it opens in the center with a large file preview and starts in the current file's directory. NvimTree provides the complete project hierarchy in a centered floating window.

| Key | What it does |
| --- | --- |
| `<leader>e` | Open the centered Telescope file browser |
| `<C-n>` | Toggle the floating project tree |

In the Telescope browser, type to filter names and press Enter to open the selected file or directory. Backspace moves to the parent directory. `<C-b>` toggles between browsing files and fuzzy-searching directories, `<C-h>` toggles hidden entries, and `<C-f>` searches file contents beneath the directory currently being browsed. Press `?` from Normal mode to see every available action.

The browser also supports filesystem operations from Normal mode: `c` creates, `r` renames, `m` moves, and `y` copies. Press `d` to move an item to the Linux trash with `trash-put`; press `D` only when you want to delete it permanently. Both actions ask for confirmation. Use `<Tab>` and `<S-Tab>` to build a multi-selection before applying an operation.

NvimTree follows the current working directory and highlights the active file. Inside the tree, `d` also moves the selected item to the trash and `D` permanently deletes it. `f` starts a live filename filter, `F` clears it, `I` toggles Git-ignored entries, and `g?` shows all contextual mappings. Move focus away or press `<C-n>` again to close the floating tree.

This setup requires the `trash-cli` package and its `trash-put` command. Use `trash-list` to inspect deleted items and `trash-restore` to recover one.

### Manage file tabs, buffers, and windows

The labels across the top look like VS Code tabs, but NvChad implements them as Neovim **buffers**. A buffer is an open file; a window is a visible pane that displays a buffer. This setup uses the top bar for file buffers and does not require Vim tab pages for everyday file navigation.

| Key | What it does |
| --- | --- |
| `<Tab>` | Next buffer |
| `<S-Tab>` | Previous buffer |
| `<leader>b` | Create an empty buffer |
| `<leader>x` | Close the current buffer |
| `<leader>fb` | Search and switch between open buffers |
| `<C-h>` | Move to the window on the left |
| `<C-j>` | Move to the window below |
| `<C-k>` | Move to the window above |
| `<C-l>` | Move to the window on the right |

To close the file shown in the active top-bar entry, return to Normal mode with `<Esc>` and press `<leader>x` (Space, then `x`). If the file has unsaved changes, Neovim asks whether to save them instead of silently discarding them. Closing a buffer does not delete its file from disk. You can also click the close icon in the top bar, but the keyboard mapping is the normal workflow.

The buffer mappings depend on NvChad's tab/buffer line, which is enabled in this configuration. Native Vim tab pages are separate workspaces that can each contain several windows and buffers; they are intentionally not used as file tabs here.

### Edit, save, and comment

Press `<C-d>` in Normal mode to select the word under the cursor, then press it repeatedly to add the next textual occurrence. You can also select any text in Visual mode and press `<C-d>` to add its next match. Once the cursors are in place, use normal editing commands or enter Insert mode to edit every occurrence together; press `<Esc>` from Normal mode to clear the extra cursors.

These mappings deliberately apply only in Normal and Visual modes. While typing in Insert mode, `<C-p>` continues to select the previous completion item and `<C-d>` continues to scroll completion documentation. Normal-mode `<C-d>` no longer performs Neovim's default half-page-down motion.

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

For C and C++, clangd suggestions open automatically after the first typed character. clangd results are ranked ahead of snippets and words already present in the buffer. `<C-Space>` remains available to reopen the menu manually.

| Key | What it does while completing |
| --- | --- |
| `<C-Space>` | Open completion manually |
| `<C-n>` or `<Tab>` | Select the next item |
| `<C-p>` or `<S-Tab>` | Select the previous item |
| `<CR>` | Confirm the selected item |
| `<C-d>` / `<C-f>` | Scroll documentation up/down |
| `<C-e>` | Close completion |

When the completion menu is closed, `<Tab>` and `<S-Tab>` move forward and backward through snippet placeholders.

For project-aware C/C++ results, configure the CMake project once so that `compile_commands.json` exists. The CMake workflow below creates the root symlink automatically. Use `:LspInfo` in a `.c` or `.cpp` file to confirm that `clangd` is attached; use `:MasonInstall clangd` if it is missing.

### Use GitHub Copilot

Copilot provides faint inline suggestions separately from the nvim-cmp popup. Authenticate once with `:Copilot setup`, follow the browser prompt, and use `:Copilot status` to check the connection. This configuration loads Copilot at startup, and the login is normally saved between Neovim sessions. If setup is requested again on every launch, inspect `:Copilot status` and `:messages`; that is not the expected workflow.

| Key or command | What it does |
| --- | --- |
| `<Tab>` | Accept the visible inline suggestion; otherwise continue through completion or snippet items |
| `<M-Right>` | Accept the next word |
| `<M-C-Right>` | Accept the next line |
| `<M-]>` / `<M-[>` | Show the next/previous suggestion |
| `<M-\>` | Request a suggestion |
| `<C-]>` | Dismiss the suggestion |
| `:Copilot status` | Show authentication and availability status |

`<M-…>` means Alt/Meta. Some terminal emulators reserve these combinations; use `:Copilot panel` as a fallback for browsing suggestions.

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

Conform formats supported files automatically immediately before they are saved. It waits up to 500 ms for most formatters and up to two seconds for `latexindent`, then falls back to an attached LSP formatter when no configured formatter is available.

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
| LaTeX | `latexindent` |
| TOML | `taplo` |
| Shell/Bash | `shfmt` |

If formatting does not happen, run `:ConformInfo`. The most common cause is a missing executable.

## 7. Write Markdown and LaTeX

### Edit and preview Markdown

Markdown files load [markdown.nvim](https://github.com/tadmccorkle/markdown.nvim) for document-aware editing and [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) for a live browser view. The preview updates asynchronously as the buffer changes, follows the editor position, renders tables and task lists, and uses KaTeX for mathematics.

| Key | Mode | What it does |
| --- | --- | --- |
| `<leader>mp` | Normal | Start or stop the synchronized browser preview |
| `<leader>mo` | Normal | Show the document table of contents in the location list |
| `<leader>mi` | Normal/Visual | Insert a table of contents or replace the selected lines |
| `<leader>mc` | Normal/Visual | Toggle the current task-list item or selected items |
| `<leader>mj` / `<leader>mk` | Normal | Insert a matching list item below/above |
| `<leader>mr` | Normal/Visual | Renumber every ordered list or the selected lists |

The Markdown-specific editing operators are active only in Markdown buffers:

| Key | What it does |
| --- | --- |
| `gs{motion}{style}` | Apply an inline style over a motion |
| `gss{style}` | Apply an inline style to the current line |
| `ds{style}` | Remove the surrounding inline style |
| `cs{old}{new}` | Change one surrounding inline style into another |
| `gl{motion}` / Visual `gl` | Turn text into a Markdown link |
| `gx` | Follow the link under the cursor; web links open in the browser |
| `]]` / `[[` | Go to the next/previous heading |
| `]c` / `]p` | Go to the current/parent heading |

The style letter is `i` for emphasis, `b` for bold, `s` for strikethrough, or `c` for inline code. For example, type `gsiwb` to make the inner word bold.

The preview plugin installs its bundled application during `:Lazy sync`. If `<leader>mp` reports a missing application, run `:Lazy build markdown-preview.nvim`, restart Neovim, and try again.

### Build and view LaTeX

[VimTeX](https://github.com/lervag/vimtex) manages the document structure, `latexmk` compilation, errors, and Zathura integration. [TexLab](https://github.com/latex-lsp/texlab) separately provides completion, diagnostics, references, and symbols. TexLab's build-on-save feature is deliberately disabled so it cannot start a second compiler alongside VimTeX.

Open Neovim from the directory containing the main `.tex` document. VimTeX normally discovers included files automatically; for an unusual multi-file layout, add this line near the top of a child document:

```tex
%! TeX root = main.tex
```

| Key | Command | What it does |
| --- | --- | --- |
| `<leader>lb` | `:VimtexCompile` | Start or toggle continuous `latexmk` compilation |
| `<leader>ls` | `:VimtexStop` | Stop the compiler |
| `<leader>lv` | `:VimtexView` | Open the PDF or forward-search the cursor position in Zathura |
| `<leader>le` | `:VimtexErrors` | Show parsed compiler errors and warnings |
| `<leader>lc` | `:VimtexClean` | Remove auxiliary build files |
| `<leader>lt` | `:VimtexTocOpen` | Open the document table of contents |
| `<leader>li` | `:VimtexInfo` | Show the detected root, compiler, viewer, and project state |

A typical session is: press `<leader>lb` once, save normally while `latexmk` rebuilds in the background, and press `<leader>lv` to open the live-updating PDF. Use `<leader>ls` when finished. Zathura is preferred because it reliably reloads changed PDFs and supports SyncTeX source-to-PDF navigation. If Zathura is unavailable, the configuration falls back to `xdg-open`; this normally opens the PDF in a browser, but automatic refresh and SyncTeX then depend on that application.

VimTeX also provides extensive LaTeX-aware motions and text objects under its default local-leader prefix, which is `\`. Run `:help vimtex-default-mappings` for the complete list. Use the normal `<leader>fm` mapping to format a `.tex` file with `latexindent`.

VimTeX is pinned to v2.17 because the installed Neovim 0.12.2 is older than the 0.12.4 minimum required by VimTeX v2.18. The pin can be removed after upgrading Neovim.

## 8. Build and debug CMake C++ projects

CMake projects use cmake-tools.nvim for project creation, configuration, building, running, testing, and target-aware debugging. Builds use `build/<configuration>`, and generation creates a `compile_commands.json` link at the project root so clangd sees the exact compiler flags and include paths.

### Start a project

Open Neovim in an empty project directory and press `<leader>Ci`, or run:

```vim
:CMakeQuickStart
```

Choose C or C++, an executable or library, and a project name. The plugin creates a minimal project that is ready to configure. For just one file, create or open `CMakeLists.txt`, type `cmi`, select the friendly-snippets completion, and expand it with `<Tab>`.

For established projects, open Neovim at the directory containing `CMakeLists.txt`. `CMakePresets.json` and `CMakeUserPresets.json` are used when present; otherwise CMake Tools offers its normal kit and build-type selection.

### Configure, build, and run

| Key | Command | What it does |
| --- | --- | --- |
| `<leader>Ci` | `:CMakeQuickStart` | Create a minimal C/C++ project |
| `<leader>Cg` | `:CMakeGenerate` | Configure the project and generate the build system |
| `<leader>Cb` | `:CMakeBuild` | Select and build a target |
| `<leader>Cr` | `:CMakeRun` | Build and run an executable target |
| `<leader>Cd` | `:CMakeDebug` | Build and debug an executable target |
| `<leader>Ct` | `:CMakeRunTest` | Run CTest tests |
| `<leader>Cs` | `:CMakeSettings` | Select presets, build type, targets, and other settings |

Build output appears in Quickfix; use `:copen`, `:cnext`, and `:cprev` to inspect and navigate compiler errors. Program output runs in a horizontal terminal. Successful build windows close automatically.

### Debug a target

CodeLLDB is installed separately through Mason and registered with nvim-dap. A typical session is:

1. Generate with `<leader>Cg` and select a `Debug` build when prompted.
2. Set breakpoints with `<F9>`.
3. Press `<leader>Cd` and choose an executable target.
4. Continue and step with the same `<F5>`, `<F10>`, `<F11>`, and `<S-F11>` mappings used by Python debugging.
5. Stop with `<S-F5>`.

The existing DAP panel opens automatically and shows scopes, watches, threads, breakpoints, the REPL, and program output. Use `:CMakeLaunchArgs` before running or debugging when the target needs command-line arguments.

Verify the native debug adapter with:

```vim
:echo executable(stdpath('data') .. '/mason/bin/codelldb')
```

The result should be `1`.

## 9. Debug Python visually

Python debugging is provided by nvim-dap, nvim-dap-python, and nvim-dap-view. Debugpy is installed separately by Mason:

```vim
:MasonInstall debugpy
```

Verify that Mason's adapter is available:

```vim
:echo executable(stdpath('data') .. '/mason/bin/debugpy-adapter')
```

The result should be `1`.

### Debug the current Python file

1. Start Neovim from the project root and open a Python file.
2. Put the cursor on an executable line and press `<F9>` to set a breakpoint.
3. Press `<F5>` and select the current-file Python configuration if prompted.
4. When execution stops, inspect variables, watches, and the call stack in the tabbed panel below the source window.
5. Step with `<F10>`/`<F11>`, continue with `<F5>`, and stop with `<S-F5>`.

The UI opens automatically when a debugging session initializes and closes when the session exits or is terminated. It uses one compact panel with tabs for scopes, watches, threads, breakpoints, the DAP REPL, and the program console. Use the highlighted letters in the tab bar to jump directly to a view, `]v`/`[v` to move between views, and `g?` inside the panel to see view-specific actions. `<leader>du` toggles the panel manually, `<leader>dr` focuses the REPL, and `<leader>dC` focuses the program console.

When execution is paused, current variable values appear inline beside their definitions. Values changed by the last step use a distinct warning-style highlight, making state changes visible without opening the scopes view.

The DAP REPL has Python-aware completion supplied by Debugpy. Type part of an expression and use `<C-Space>` to request suggestions, `<C-n>`/`<C-p>` or `<Tab>`/`<S-Tab>` to select one, and `<CR>` to accept it. Buffer words are offered as a fallback. Debugger completion is scoped to the REPL and does not change completion in normal source buffers.

### Debugging mappings

| Key | What it does |
| --- | --- |
| `<F5>` / `<leader>dc` | Start or continue debugging |
| `<S-F5>` / `<leader>dx` | Terminate the session |
| `<F9>` / `<leader>db` | Toggle a breakpoint |
| `<leader>dB` | Set a conditional breakpoint |
| `<F10>` / `<leader>do` | Step over |
| `<F11>` / `<leader>di` | Step into |
| `<S-F11>` / `<leader>dO` | Step out |
| `<leader>dl` | Run the previous configuration again |
| `<leader>dr` | Open and focus the DAP REPL tab |
| `<leader>du` | Toggle the visual DAP UI |
| `<leader>dC` | Open and focus the program console tab |
| `<leader>dj` | Open or create `.vscode/launch.json` |

### Project configurations and virtual environments

Run `:DapEditLaunchJSON` or press `<leader>dj` to open the project's `.vscode/launch.json`. If it does not exist, the command creates a standard JSON configuration that launches the current Python file in the integrated terminal. Existing project launch configurations are read when a new session starts.

The Debugpy adapter and the Python running the project are intentionally separate. The adapter always comes from Mason. nvim-dap-python chooses the project interpreter from `VIRTUAL_ENV`, `CONDA_PREFIX`, or common project directories such as `.venv`, `venv`, `env`, and `.env`, falling back to the system Python when no environment is detected.

## 10. Git, terminals, and appearance

### Inspect Git changes

Gitsigns displays added, changed, and deleted line indicators beside Git-managed files. Neogit provides a keyboard-driven status screen, while Diffview provides side-by-side diffs, file history, and three-way conflict resolution.

#### Repository status and visual diffs

| Key | What it does |
| --- | --- |
| `<leader>gg` | Open the Neogit status screen |
| `<leader>gd` | Open the repository diff in Diffview |
| `<leader>gD` | Close the active Diffview |
| `<leader>gh` | Show history for the current file |
| `<leader>gH` | Show repository history |
| `<leader>gt` | Search files shown by Git status |
| `<leader>cm` | Search Git commits |

Inside Neogit, use `s` to stage the item under the cursor, `u` to unstage it, `x` to discard it after confirmation, and `<Tab>` to expand or collapse sections. Press `c` to open commit actions, `P` for push actions, `p` for pull actions, and `?` for contextual help. Press `q` to close Neogit.

Inside Diffview, `<Tab>` and `<S-Tab>` move between changed files, `[c` and `]c` move between diff hunks, and `g?` opens contextual help. Diffview uses a temporary native tab-page workspace; close it with `<leader>gD` or `:DiffviewClose` rather than the normal file-buffer shortcut.

#### Work with individual hunks

These mappings are available in Git-managed file buffers:

| Key | What it does |
| --- | --- |
| `]c` / `[c` | Go to the next/previous changed hunk |
| `<leader>gp` | Preview the current hunk |
| `<leader>gs` | Stage the current hunk or Visual selection |
| `<leader>gu` | Undo staging for the current hunk |
| `<leader>gr` | Discard the current hunk or Visual selection |
| `<leader>gb` | Show full blame information for the current line |

`<leader>gr` replaces the hunk in the current buffer immediately; save to persist it, or use `u` before saving to undo it. Use the preview first when you are unsure. Repository-wide discard operations in Neogit ask for confirmation.

#### Resolve merge conflicts

Run `<leader>gd` while a merge or rebase is stopped on conflicts. Diffview opens a three-way layout with **OURS**, the editable local result, and **THEIRS**. The labels in the winbar are authoritative: during a normal merge, ours is the current branch and theirs is the incoming branch; during a rebase, Git's perspective can make those names feel reversed.

| Key | What it does in a conflict |
| --- | --- |
| `]x` / `[x` | Go to the next/previous conflict |
| `<leader>co` | Choose ours for the current conflict |
| `<leader>ct` | Choose theirs for the current conflict |
| `<leader>cb` | Choose the common base |
| `<leader>ca` | Keep both sides and remove the markers |
| `dx` | Delete the entire conflict region |

Use the uppercase variants—`<leader>cO`, `<leader>cT`, `<leader>cB`, `<leader>cA`, and `dX`—to apply that decision to every conflict in the current file. Save the resolved file, stage it from Neogit, and continue the merge or rebase from the appropriate Neogit popup.

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

## 11. Complete shortcut reference

`<leader>` is Space. This reference concentrates the useful configured mappings and modern Neovim defaults; press Space and pause or use `<leader>ch` whenever you want a searchable, live list.

### Daily shortcuts

| Workflow | Keys |
| --- | --- |
| Discover keys | Space and pause, `<leader>ch`, `<leader>wK` |
| Open a file / search text | `<C-p>`, `<leader>fw` |
| Browse files | `<leader>e`, `<C-n>` |
| Select next occurrence | `<C-d>` |
| Switch / close files | `<Tab>`, `<S-Tab>`, `<leader>x` |
| Save / format | `<C-s>`, `<leader>fm` |
| Markdown edit / preview | `gs…`, `<leader>mp`, `<leader>mo` |
| LaTeX build / view | `<leader>lb`, `<leader>lv` |
| Definition / references / rename | `gd`, `grr`, `<leader>ra` |
| Git status / diff | `<leader>gg`, `<leader>gd` |
| Build / debug CMake | `<leader>Cb`, `<leader>Cd` |
| Debug | `<F5>`, `<F9>`, `<F10>`, `<F11>`, `<S-F5>` |
| Terminal | `<leader>h`, `<leader>v`, `<A-i>` |

### Discovery and commands

| Key or command | Mode/context | What it does |
| --- | --- | --- |
| Space, then pause | Normal | Open the WhichKey menu |
| `<leader>ch` | Normal | Open the NvCheatsheet |
| `<leader>wk` | Normal | Show mappings that begin with the entered keys |
| `<leader>wK` | Normal | Show all mappings |
| `;` | Normal | Enter command-line mode |
| `:Lazy` | Command | Manage plugins |
| `:Mason` | Command | Manage language tools and debug adapters |
| `:LspInfo` | Command | Inspect attached language servers |
| `:ConformInfo` | Command | Inspect formatters |
| `:checkhealth` | Command | Run general health checks |

### Files, search, and explorers

| Key | Mode/context | What it does |
| --- | --- | --- |
| `<C-p>` / `<leader>ff` | Normal | Find project files |
| `<leader>fa` | Normal | Find all files, including hidden and Git-ignored files |
| `<leader>fw` | Normal | Search text in project files |
| `<leader>fz` | Normal | Fuzzy-search the current buffer |
| `<leader>fo` | Normal | Reopen recent files |
| `<leader>fh` | Normal | Search help tags |
| `<leader>ma` | Normal | Search marks |
| `<leader>fm` | Normal/Visual | Format the file or selection |
| `<leader>e` | Normal | Open the centered Telescope file browser |
| `<C-n>` | Normal | Toggle the floating NvimTree project tree |
| `<leader>gt` | Normal | Search files reported by Git status |
| `<leader>cm` | Normal | Search Git commits |
| `c` / `r` / `m` / `y` | Telescope browser, Normal | Create / rename / move / copy an item |
| `d` / `D` | Telescope browser or NvimTree | Trash / permanently delete an item, after confirmation |
| `<Tab>` / `<S-Tab>` | Telescope browser | Add/remove an item from the multi-selection |
| `f` / `F` | NvimTree | Start / clear the live filename filter |
| `I` | NvimTree | Toggle Git-ignored files |
| `g?` | Explorer | Show contextual mappings |

### Buffers and windows

| Key | Mode/context | What it does |
| --- | --- | --- |
| `<Tab>` / `<S-Tab>` | Normal | Go to the next/previous file buffer |
| `]b` / `[b` | Normal | Go to the next/previous buffer |
| `<leader>fb` | Normal | Find an open buffer |
| `<leader>b` | Normal | Create an empty buffer |
| `<leader>x` | Normal | Close the current buffer safely |
| `<C-h/j/k/l>` | Normal | Focus the window left/below/above/right |

### Editing and navigation

| Key | Mode/context | What it does |
| --- | --- | --- |
| `jk` | Insert | Return to Normal mode |
| `<C-s>` | Normal | Save the current file |
| `<C-c>` | Normal | Copy the whole file to the system clipboard |
| `<Esc>` | Normal | Clear search highlighting |
| `<leader>/` / `gc` | Normal/Visual | Toggle a comment using the comment operator |
| `gcc` | Normal | Toggle a line comment |
| `<C-d>` | Normal/Visual | Select the next matching occurrence for multi-editing |
| `[Space` / `]Space` | Normal | Insert a blank line above/below |
| `[n` / `]n` | Visual | Select the previous/next Tree-sitter node |
| `an` / `in` | Visual | Select the outer/inner Tree-sitter node |
| `gx` | Normal/Visual | Open the path or URL under the cursor |
| `<leader>n` / `<leader>rn` | Normal | Toggle absolute / relative line numbers |
| `<C-b/e>` | Insert | Move to the beginning/end of the line |
| `<C-h/j/k/l>` | Insert | Move left/down/up/right |

### Completion and Copilot

| Key | Mode/context | What it does |
| --- | --- | --- |
| `<C-Space>` | Insert/completion | Open completion manually |
| `<C-n>` / `<C-p>` | Insert/completion | Select the next/previous item |
| `<Tab>` / `<S-Tab>` | Insert/completion | Accept Copilot, move through completion, or jump through snippets |
| `<CR>` | Insert/completion | Confirm the selected completion item |
| `<C-d>` / `<C-f>` | Insert/completion | Scroll completion documentation up/down |
| `<C-e>` | Insert/completion | Close completion |
| `<M-Right>` / `<M-C-Right>` | Insert/Copilot | Accept the next word/line |
| `<M-]>` / `<M-[>` | Insert/Copilot | Show the next/previous suggestion |
| `<M-\>` / `<C-]>` | Insert/Copilot | Request/dismiss a suggestion |

### LSP and diagnostics

| Key | Mode/context | What it does |
| --- | --- | --- |
| `gd` / `gD` | Normal | Go to definition/declaration |
| `grr` | Normal | Find references |
| `gri` / `grt` | Normal | Go to implementation/type definition |
| `K` | Normal | Show hover documentation |
| `gra` | Normal/Visual | Show code actions |
| `<leader>ra` / `grn` | Normal | Rename the symbol |
| `gO` | Normal | List document symbols |
| `<C-s>` | Insert | Show signature help |
| `]d` / `[d` | Normal | Go to the next/previous diagnostic |
| `]D` / `[D` | Normal | Go to the last/first diagnostic |
| `<C-w>d` | Normal | Show the diagnostic under the cursor |
| `<leader>ds` | Normal | Put diagnostics in the location list |
| `<leader>wa` / `<leader>wr` / `<leader>wl` | Normal | Add/remove/list workspace folders |

### Markdown and LaTeX

| Key | Mode/context | What it does |
| --- | --- | --- |
| `<leader>mp` | Markdown | Toggle the synchronized browser preview |
| `<leader>mo` / `<leader>mi` | Markdown | Show / insert the table of contents |
| `<leader>mc` | Markdown, Normal/Visual | Toggle task-list items |
| `<leader>mj` / `<leader>mk` | Markdown | Insert a list item below/above |
| `<leader>mr` | Markdown, Normal/Visual | Renumber ordered lists |
| `gs…` / `ds…` / `cs…` | Markdown | Add / delete / change inline styles |
| `gl` / `gx` | Markdown | Create / follow a link |
| `]]` / `[[` | Markdown | Go to the next/previous heading |
| `<leader>lb` / `<leader>ls` | LaTeX | Start continuous compilation / stop it |
| `<leader>lv` / `<leader>le` | LaTeX | View the PDF / show compiler errors |
| `<leader>lc` / `<leader>lt` / `<leader>li` | LaTeX | Clean / show contents / show project information |

### Build and debug

| Key | Mode/context | What it does |
| --- | --- | --- |
| `<leader>Ci` | Normal | Create a minimal C/C++ CMake project |
| `<leader>Cg` / `<leader>Cb` | Normal | Generate / build the CMake project |
| `<leader>Cr` / `<leader>Cd` | Normal | Run / debug a CMake target |
| `<leader>Ct` / `<leader>Cs` | Normal | Run CTest / open CMake settings |
| `<F5>` / `<leader>dc` | Normal | Start or continue debugging |
| `<S-F5>` / `<leader>dx` | Normal | Terminate debugging |
| `<F9>` / `<leader>db` | Normal | Toggle a breakpoint |
| `<leader>dB` | Normal | Set a conditional breakpoint |
| `<F10>` / `<leader>do` | Normal | Step over |
| `<F11>` / `<leader>di` | Normal | Step into |
| `<S-F11>` / `<leader>dO` | Normal | Step out |
| `<leader>dl` | Normal | Run the previous debug configuration |
| `<leader>du` / `<leader>dr` / `<leader>dC` | Normal | Toggle DAP UI / focus REPL / focus console |
| `<leader>dj` | Normal | Open or create `.vscode/launch.json` |

### Git and conflicts

| Key | Mode/context | What it does |
| --- | --- | --- |
| `<leader>gg` | Normal | Open Neogit status |
| `<leader>gd` / `<leader>gD` | Normal | Open / close Diffview |
| `<leader>gh` / `<leader>gH` | Normal | Show file / repository history |
| `]c` / `[c` | Git buffer or Diffview | Go to the next/previous changed hunk |
| `<leader>gp` | Git buffer | Preview the current hunk |
| `<leader>gs` / `<leader>gu` | Git buffer | Stage / unstage the current hunk or selection |
| `<leader>gr` / `<leader>gb` | Git buffer | Discard the hunk / show full line blame |
| `s` / `u` / `x` | Neogit | Stage / unstage / discard the selected item |
| `c` / `P` / `p` | Neogit | Open commit / push / pull actions |
| `]x` / `[x` | Diffview conflict | Go to the next/previous conflict |
| `<leader>co/ct/cb/ca` | Diffview conflict | Choose ours/theirs/base/both for this conflict |
| `<leader>cO/cT/cB/cA` | Diffview conflict | Choose ours/theirs/base/both for the whole file |
| `dx` / `dX` | Diffview conflict | Delete this / every conflict region |

### Terminals and interface

| Key | Mode/context | What it does |
| --- | --- | --- |
| `<leader>h` / `<leader>v` | Normal | Open a horizontal / vertical terminal |
| `<A-h>` / `<A-v>` | Normal/Terminal | Toggle the persistent horizontal / vertical terminal |
| `<A-i>` | Normal/Terminal | Toggle the floating terminal |
| `<C-x>` | Terminal | Leave Terminal mode |
| `<leader>pt` | Normal | Find a hidden terminal |
| `<leader>tt` / `<leader>th` | Normal | Toggle GitHub light/dark / open the theme picker |

## 12. VS Code coverage and future roadmap

This comparison covers stock VS Code workflows. It cannot account for every extension from a personal VS Code installation.

| Area | Status | Current setup or gap |
| --- | --- | --- |
| File opening, text search, and explorers | Implemented | Telescope and NvimTree provide fuzzy search, previews, tree browsing, file operations, hidden files, and Git-ignore visibility. |
| File tabs, panes, and integrated terminals | Implemented | Buffers, window navigation, a top buffer line, and persistent/floating terminals cover the everyday workflow. |
| Git status, diffs, history, and conflicts | Implemented | Neogit, Diffview, and Gitsigns cover staging, history, hunks, blame, and ours/theirs resolution. |
| Completion, snippets, and Copilot | Implemented | nvim-cmp, LuaSnip, LSP sources, and Copilot provide popup and inline completion. |
| Language intelligence and formatting | Implemented | Neovim LSP, Mason, clangd, and Conform cover navigation, diagnostics, refactoring, and format-on-save. |
| Python and C++ debugging | Implemented | nvim-dap provides breakpoints, stepping, watches, REPL, console, inline values, Debugpy, and CodeLLDB. |
| CMake C/C++ workflow | Implemented | Project scaffolding, presets, configure, build, run, CTest, and target-aware debugging are integrated. |
| Markdown authoring and preview | Implemented | Markdown-aware editing, TOC/list/task operations, link navigation, and synchronized browser preview are integrated. |
| LaTeX authoring and PDF preview | Implemented | TexLab, VimTeX, continuous latexmk builds, formatting, errors, Zathura live preview, and SyncTeX are integrated. |
| Multi-cursor editing and themes | Implemented | Next-occurrence selection and GitHub light/dark themes are configured. |
| Problems panel | Partial | Diagnostics and location lists exist, but there is no persistent VS Code-style Problems panel. |
| Symbols and breadcrumbs | Partial | `gO` lists document symbols, but there is no persistent outline or breadcrumb bar. |
| Tests | Partial | CTest is integrated through CMake; there is no unified test explorer or Python test integration. |
| Tasks | Partial | CMake tasks are covered, but there is no general task runner or `.vscode/tasks.json` workflow. |
| Workspaces and sessions | Partial | Project directories work normally, but open buffers, panes, and terminals are not restored as a named workspace. |
| Launch configurations | Partial | DAP can read and create a basic `.vscode/launch.json`, but it does not reproduce the full VS Code debugger-extension ecosystem. |
| Project-wide replace UI | Missing | Search exists, but there is no dedicated preview-and-review replace interface. |
| Fuzzy command palette shortcut | Missing | Commands can be run with `:`, but a VS Code-like fuzzy command palette is not mapped. |
| Notebooks, remote development, and collaboration | Missing | Jupyter notebooks, Remote SSH/Containers, Live Share, and a graphical settings editor are outside the current setup. |

### Suggested additions, in priority order

These recommendations are not installed by the Markdown and LaTeX changes above.

1. Complete the editor-navigation layer: map Telescope's command picker, add [Trouble](https://github.com/folke/trouble.nvim) for a Problems panel, [Aerial](https://github.com/stevearc/aerial.nvim) for an outline, and [grug-far](https://github.com/MagicDuck/grug-far.nvim) for project-wide replace with previews.
2. Add project workflows: [persistence.nvim](https://github.com/folke/persistence.nvim) for session restore, [Overseer](https://github.com/stevearc/overseer.nvim) for general tasks, and [Neotest](https://github.com/nvim-neotest/neotest) for a unified test explorer.
3. Add Neovim-native editing power: [Flash](https://github.com/folke/flash.nvim) for rapid visible-text jumps, [nvim-surround](https://github.com/kylechui/nvim-surround) for editing quotes/brackets/tags, [Tree-sitter textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) for syntax-aware selections and motions, [treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) for sticky code context, and [Undotree](https://github.com/mbbill/undotree) for visual persistent undo history.

## 13. Maintain or extend the setup

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

The files `configs/devicons.lua` and `configs/lsp_servers.lua` are not imported by active plugin specifications. Their custom icon and server-list behavior is therefore unavailable. The working behavior documented above comes from NvChad defaults and the active specifications in `lua/plugins/init.lua`. The other modules listed in the configuration map below are active local overrides.

## 14. Troubleshooting

### A language server does not attach

1. Run `:LspInfo` in the affected file.
2. Check the file type with `:set filetype?`.
3. Open `:Mason` and confirm that the server is installed.
4. Run `:checkhealth vim.lsp` and inspect `:messages`.
5. Reopen the file or restart Neovim after installing the executable.

### A file does not format

Run `:ConformInfo`. Confirm that the expected formatter is listed and available. If the file type has no formatter in the table above, formatting depends on LSP fallback support.

### Python debugging does not start

1. Run `:Mason` and confirm that `debugpy` is installed.
2. Confirm that `:echo executable(stdpath('data') .. '/mason/bin/debugpy-adapter')` returns `1`.
3. Start Neovim from the project root and open a Python file before pressing `<F5>`.
4. Run `:DapShowLog` and inspect `:messages` for adapter errors.
5. If the wrong Python environment is used, activate it before starting Neovim or configure its path in `.vscode/launch.json`.

The configuration deliberately ignores user-local `debugpy` launchers, so repairing or removing a stale `~/.local/bin/debugpy` is not required for Neovim debugging.

### A CMake project does not build or debug

1. Start Neovim from the directory containing the top-level `CMakeLists.txt`.
2. Confirm that `cmake`, a compiler, and the selected generator such as `ninja` are executable.
3. Run `:CMakeGenerate!` to clean and regenerate stale build metadata.
4. Open `:CMakeSettings` and verify the preset, build type, build target, and launch target.
5. For debugging, use a `Debug` or `RelWithDebInfo` build and confirm that Mason's `codelldb` is executable.
6. Inspect the `cmake-tools` buffer, Quickfix, `:DapShowLog`, and `:messages` for the underlying error.

### Markdown preview does not open

1. Confirm the current file type is `markdown` with `:set filetype?`.
2. Confirm `node` and `npm` are executable.
3. Run `:Lazy build markdown-preview.nvim`, restart Neovim, and press `<leader>mp` again.
4. Inspect `:messages` if the preview server starts but the browser does not open.

### LaTeX does not build or open its PDF

1. Run `:VimtexInfo` or press `<leader>li` and verify the detected root document, `latexmk` compiler, and Zathura viewer.
2. Confirm `latexmk`, the selected TeX engine, and `zathura` are executable.
3. Run `:LspInfo` in the `.tex` file and install TexLab with `:MasonInstall texlab` if it is missing.
4. Press `<leader>le` to inspect parsed compiler errors, then use `:VimtexCompileOutput` for the complete log.
5. If a multi-file document has the wrong root, add `%! TeX root = main.tex` to the child file.
6. If formatting fails, run `:ConformInfo` and confirm that `latexindent` is executable.

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
| `lua/configs/cmp.lua` | Completion defaults, C/C++ priorities, and DAP REPL completion |
| `lua/configs/cmake.lua` | CMake Tools commands, mappings, build layout, and output behavior |
| `lua/configs/markdown.lua` | Markdown editing, browser-preview settings, and buffer mappings |
| `lua/configs/latex.lua` | TexLab settings, VimTeX integration, and LaTeX buffer mappings |
| `lua/configs/git.lua` | Neogit, Diffview, and Gitsigns workflow and mappings |
| `lua/configs/dap.lua` | Shared visual debugger layout and DAP lifecycle behavior |
| `lua/configs/dap_cpp.lua` | Mason CodeLLDB adapter for C and C++ |
| `lua/configs/multicursor.lua` | VS Code-style next-match multicursor behavior |
| `lua/configs/nvimtree.lua` | Floating project-tree layout and rendering |
| `lua/configs/telescope.lua` | Centered pickers and file-browser behavior |
| `lua/configs/lazy.lua` | lazy.nvim UI and performance settings |

## Credits

- [NvChad](https://github.com/NvChad/NvChad)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [Mason](https://github.com/mason-org/mason.nvim)
- [Conform](https://github.com/stevearc/conform.nvim)
- [cmake-tools.nvim](https://github.com/Civitasv/cmake-tools.nvim)
- [markdown.nvim](https://github.com/tadmccorklin/markdown.nvim)
- [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim)
- [VimTeX](https://github.com/lervag/vimtex)
- [TexLab](https://github.com/latex-lsp/texlab)
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view)
- [nvim-dap-python](https://github.com/mfussenegger/nvim-dap-python)
- [cmp-dap](https://github.com/rcarriga/cmp-dap)
- [Neogit](https://github.com/NeogitOrg/neogit)
- [Diffview](https://github.com/sindrets/diffview.nvim)
- [Gitsigns](https://github.com/lewis6991/gitsigns.nvim)
- [multicursor.nvim](https://github.com/jake-stewart/multicursor.nvim)
- [telescope-file-browser.nvim](https://github.com/nvim-telescope/telescope-file-browser.nvim)
- The broader Neovim plugin community
