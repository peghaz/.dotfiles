local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    c = { "clang_format" },
    cpp = { "clang_format" },
    rust = { "rustfmt" },
    go = { "goimports", "gofmt" },
    python = { "ruff_format" },
    json = { "biome", "jq", stop_after_first = true },
    jsonc = { "biome" },
    tex = { "latexindent" },
    toml = { "taplo" },
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  format_on_save = function(bufnr)
    return {
      timeout_ms = vim.bo[bufnr].filetype == "tex" and 2000 or 500,
      lsp_format = "fallback",
    }
  end,
}

return options
