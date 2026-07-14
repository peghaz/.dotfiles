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
  -- markdown
  "marksman",
  -- docker
  "dockerls",
  "docker_compose_language_service",
  -- toml
  "taplo",
  -- yaml / json
  "yamlls",
  "jsonls",
  -- bash
  "bashls",
}

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
