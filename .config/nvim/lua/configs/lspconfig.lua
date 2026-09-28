require("nvchad.configs.lspconfig").defaults()

vim.lsp.config("clangd", require "configs.clangd")
vim.lsp.config("texlab", require("configs.latex").lsp)

local servers = {
  -- web
  "html",
  "cssls",
  -- c / c++
  "clangd",
  -- rust
  "rust_analyzer",
  -- go
  "gopls",
  -- python
  "pyright",
  -- prose
  "marksman",
  "texlab",
  -- docker
  "dockerls",
  "docker_compose_language_service",
  -- toml
  "taplo",
  -- bash
  "bashls",
}

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
