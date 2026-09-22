local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    c = { "clang_format" },
    cpp = { "clang_format" },
    rust = { "rustfmt" },
    go = { "goimports", "gofmt" },
    python = { "ruff_format" },
    toml = { "taplo" },
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
