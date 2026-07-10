return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "github/copilot.vim",
    init = function()
      vim.g.copilot_no_tab_map = true
    end,
    cmd = "Copilot",
    event = "InsertEnter",
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc",
        "html", "css",
        "c", "cpp",
        "rust",
        "go", "gomod", "gosum",
        "python",
        "dockerfile",
        "toml",
        "bash",
      },
    },
  },
}
