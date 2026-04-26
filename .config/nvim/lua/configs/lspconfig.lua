require("nvchad.configs.lspconfig").defaults()

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
