# NvChad User Config Guide

This repository is a user-layer Neovim configuration built on top of NvChad.

The goal of this README is to give you:

1. A fast path to productivity in a few minutes.
2. A full reference for keymaps and features.
3. A deep, practical debugging guide (DAP), including launch.json workflow and completion behavior.

## Table Of Contents

1. What This Setup Is
2. Quick Start
3. Architecture And File Layout
4. Installed Features
5. Keymaps Reference
6. Language Tooling Matrix
7. File Explorer And Icons
8. Git Workflow
9. Copilot Workflow
10. DAP Deep Guide
11. DAP Troubleshooting
12. Maintenance Notes

## What This Setup Is

This config uses NvChad as a base and applies custom behavior from the user files in the lua directory.

Primary characteristics:

1. NvChad core defaults stay intact where possible.
2. User keymaps and plugin overrides are layered on top.
3. Debugging is first-class with nvim-dap, nvim-dap-ui, nvim-dap-python, and launch.json support.

## Quick Start

### 1) First Open

Open Neovim in your project root. On first start, plugins sync automatically via lazy.nvim.

Recommended immediate checks:

1. Run :Lazy to verify plugin status.
2. Run :checkhealth for environment checks.

### 2) Core Daily Keys

1. Find files: leader ff (NvChad default)
2. Live grep: leader fw (NvChad default)
3. Toggle file browser float: leader o
4. Workspace symbols: Ctrl+t
5. Go to definition: F12

### 3) Debug Fast Path

1. Open or create launch file: leader d j
2. Set breakpoint on current line: F9
3. Start/continue debug: F5
4. Step over: F10
5. Step into: F11
6. Step out: Shift+F11
7. Stop debug: Shift+F5
8. Toggle DAP UI: leader d u

## Architecture And File Layout

Core config entry points:

1. init.lua: bootstraps lazy.nvim, loads NvChad, then user modules.
2. lua/plugins/init.lua: plugin additions and plugin option overrides.
3. lua/mappings.lua: user keymaps.
4. lua/configs/*: feature-specific behavior (DAP, CMP, LSP, formatters, icons, tree).

Important user config files:

1. [lua/plugins/init.lua](lua/plugins/init.lua)
2. [lua/mappings.lua](lua/mappings.lua)
3. [lua/configs/dap.lua](lua/configs/dap.lua)
4. [lua/configs/cmp.lua](lua/configs/cmp.lua)
5. [lua/configs/lspconfig.lua](lua/configs/lspconfig.lua)
6. [lua/configs/conform.lua](lua/configs/conform.lua)
7. [lua/configs/devicons.lua](lua/configs/devicons.lua)
8. [lua/configs/nvimtree.lua](lua/configs/nvimtree.lua)

## Installed Features

### UI, Editing, Navigation

1. NvChad base UI and defaults
2. Treesitter grammar support for configured languages
3. Oil floating file manager
4. NvimTree with custom rendering options
5. Extended devicons overrides

### Completion

1. nvim-cmp via NvChad
2. DAP completion via cmp-dap in debug buffers

### AI

1. github/copilot.vim
2. Copilot accept mapping on Ctrl+l in insert mode

### Git

1. gitsigns (hunk navigation/actions)
2. lazygit.nvim for full Git TUI entry
3. Telescope git status and commits shortcuts

### Debugging

1. nvim-dap
2. nvim-dap-ui
3. nvim-dap-python
4. nvim-nio
5. launch.json create/open helper command
6. REPL-first bottom pane layout

## Keymaps Reference

This section covers notable user-defined mappings from [lua/mappings.lua](lua/mappings.lua).

### General

1. ; -> command mode (:)
2. insert jk -> escape
3. leader t t -> toggle light/dark GitHub theme

### Navigation And Code Intelligence

1. F12 -> go to definition
2. Ctrl+t -> workspace symbol search (Telescope LSP dynamic workspace symbols)

### File Browsing

1. leader o -> open Oil floating browser

### Git

1. leader g g -> open Lazygit (warns if lazygit binary is not installed)
2. leader g s -> Telescope git status
3. leader g c -> Telescope git commits
4. ] h / [ h -> next/previous hunk
5. leader g a -> stage hunk
6. leader g r -> reset hunk
7. leader g A -> stage buffer
8. leader g R -> reset buffer
9. leader g h -> preview hunk
10. leader g d -> diff this

### Debugging (VS Code-Like F Keys + Leader Fallback)

Function keys:

1. F5 -> debug start/continue
2. Shift+F5 -> debug stop
3. F9 -> toggle breakpoint
4. F10 -> step over
5. F11 -> step into
6. Shift+F11 -> step out

Leader debug group:

1. leader d c -> continue
2. leader d i -> step into
3. leader d o -> step over
4. leader d O -> step out
5. leader d b -> toggle breakpoint
6. leader d B -> conditional breakpoint prompt
7. leader d l -> run last
8. leader d r -> toggle REPL
9. leader d u -> toggle DAP UI
10. leader d C -> open DAP console float
11. leader d x -> terminate
12. leader d j -> open/create launch.json

### Copilot

1. insert Ctrl+l -> accept Copilot suggestion

## Language Tooling Matrix

### LSP Servers

Configured in [lua/configs/lspconfig.lua](lua/configs/lspconfig.lua):

1. html
2. cssls
3. clangd
4. rust_analyzer
5. gopls
6. pyright
7. marksman
8. dockerls
9. docker_compose_language_service
10. taplo
11. yamlls
12. jsonls
13. bashls

### Formatters (Conform)

Configured in [lua/configs/conform.lua](lua/configs/conform.lua):

1. lua -> stylua
2. c/cpp -> clang_format
3. rust -> rustfmt
4. go -> goimports + gofmt
5. python -> ruff_format
6. markdown/yaml/json/jsonc -> prettier
7. toml -> taplo
8. sh/bash -> shfmt

format_on_save is enabled with LSP fallback.

### Treesitter Parsers

Configured in [lua/plugins/init.lua](lua/plugins/init.lua):

1. vim, lua, vimdoc
2. html, css
3. c, cpp
4. rust
5. go, gomod, gosum
6. python
7. markdown, markdown_inline
8. yaml
9. json, jsonc
10. dockerfile
11. toml
12. bash

## File Explorer And Icons

### Oil

Oil is configured as a centered floating browser with rounded border and hidden-file visibility enabled.

Open with leader o.

### NvimTree

NvimTree uses custom render behavior and icon glyph configuration from [lua/configs/nvimtree.lua](lua/configs/nvimtree.lua).

### Devicons Overrides

Icon overrides are defined in [lua/configs/devicons.lua](lua/configs/devicons.lua), including common files such as:

1. README variants
2. Dockerfile and compose files
3. yaml/yml
4. json/jsonc
5. toml
6. named entries such as .github and data (subject to consumer plugin behavior)

## Git Workflow

### Fast Path

1. leader g g to open Lazygit for staging, committing, branching, conflict handling.
2. Use gitsigns mappings for hunk-focused workflows directly in code buffers.
3. Use Telescope git shortcuts for status and commit search.

### Lazygit Requirement

The Lazygit Neovim plugin is installed, but the lazygit binary must also exist on your machine for leader g g to open it.

## Copilot Workflow

Copilot plugin is configured to avoid default Tab mapping conflicts and uses Ctrl+l accept in insert mode.

Common checks:

1. :Copilot status
2. :Copilot auth (if needed)

## DAP Deep Guide

This section is the canonical reference for debugging in this setup.

### DAP Stack In This Config

1. nvim-dap: debug adapter protocol core
2. nvim-dap-ui: panes for scopes, breakpoints, stacks, watches, and tray REPL
3. nvim-dap-python: Python adapter integration
4. nvim-cmp + cmp-dap: completion in DAP-capable input buffers

### launch.json Model

This setup follows current nvim-dap provider behavior where .vscode/launch.json is read on demand.

Custom helper command:

1. :DapEditLaunchJSON

What it does:

1. Creates .vscode/launch.json if missing.
2. Writes a default Python launch config.
3. Opens the file for editing.

### Python Interpreter Resolution

In [lua/configs/dap.lua](lua/configs/dap.lua), Python path is resolved in this order:

1. VIRTUAL_ENV/bin/python
2. project .venv/bin/python
3. project venv/bin/python
4. python3 from PATH
5. python from PATH

This favors project-local virtual environments, then system fallback.

### DAP UI Layout

Configured layout:

1. Left sidebar:
1. scopes
2. breakpoints
3. stacks
4. watches
2. Bottom tray:
1. repl only (completion-friendly)

Console access:

1. :DapShowConsole command
2. leader d C mapping

### Session Lifecycle

DAP UI is automatically opened/closed through listeners:

1. Open after session initialization
2. Close before termination
3. Close before exit
4. Close before disconnect

### Breakpoints

#### Standard Breakpoint

1. Move cursor to desired line.
2. Press F9 (or leader d b).
3. Red breakpoint sign should appear in gutter.

#### Conditional Breakpoint

1. Press leader d B.
2. Enter condition expression in prompt.
3. Debugger stops only when condition evaluates truthy.

### Start/Step/Stop Flow

1. Start/Continue: F5
2. Step Over: F10
3. Step Into: F11
4. Step Out: Shift+F11
5. Stop: Shift+F5

### REPL vs Console

Use cases:

1. REPL: expression interaction, completion-capable context
2. Console: adapter/integrated terminal output, not general IntelliSense context

### Debug Completions

Configured in [lua/configs/cmp.lua](lua/configs/cmp.lua):

1. cmp is enabled in DAP prompt buffers through cmp_dap.is_dap_buffer check.
2. DAP completion source is registered for:
1. dap-repl
2. dapui_watches
3. dapui_hover

Practical use:

1. During active session, open REPL (leader d r).
2. Enter insert mode.
3. Trigger completion with Ctrl+Space.

Adapter capability check:

1. Run :lua= require("dap").session() and require("dap").session().capabilities.supportsCompletionsRequest
2. If false, completion responses are unsupported by the active adapter/session.

## DAP Troubleshooting

### 1) No Completions In Debug REPL

Checklist:

1. Ensure session is active.
2. Confirm REPL buffer is focused (not console output buffer).
3. Trigger completion with Ctrl+Space.
4. Run capability check command above.
5. If capability is false, adapter limitation is the blocker.

### 2) launch.json Not Used

Checklist:

1. Ensure file path is project/.vscode/launch.json.
2. Use leader d j to create/open expected file.
3. Validate JSON syntax.
4. Restart debug session.

### 3) Breakpoints Do Not Hit

Checklist:

1. Verify correct launch configuration in launch.json.
2. Confirm file being executed matches edited file.
3. Check Python interpreter/debugpy environment mismatch.
4. Confirm code path is reached.

### 4) Function Keys Do Not Trigger

Some terminals intercept function keys or require Fn mode toggles.

Fallback:

1. Use leader d mappings.
2. Adjust terminal keyboard passthrough settings.

### 5) Debug Fails To Start For Python

Checklist:

1. Ensure Python interpreter exists in one of configured resolution paths.
2. Ensure debugpy is installed in selected runtime environment.
3. Validate launch.json configuration fields (type, request, program).

## Maintenance Notes

When changing mappings/plugins/config behavior:

1. Update [lua/mappings.lua](lua/mappings.lua) and this README together.
2. Update plugin inventory when editing [lua/plugins/init.lua](lua/plugins/init.lua).
3. Update DAP section when editing [lua/configs/dap.lua](lua/configs/dap.lua) or [lua/configs/cmp.lua](lua/configs/cmp.lua).
4. Re-run :Lazy and :checkhealth after major changes.

## Credits

1. NvChad and its ecosystem.
2. Lazy.nvim and broader Neovim plugin community.
