return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "mfussenegger/nvim-dap",
    lazy = false,
    dependencies = {
      "mfussenegger/nvim-dap-python",
      {
        "igorlfs/nvim-dap-view",
        version = "1.*",
      },
    },
    config = function()
      require "configs.dap"
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "rcarriga/cmp-dap",
    },
    opts = function()
      return require "configs.cmp"
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-file-browser.nvim",
    },
    opts = function()
      return require "configs.telescope"
    end,
    config = function(_, opts)
      local telescope = require "telescope"

      telescope.setup(opts)
      for _, extension in ipairs(opts.extensions_list or {}) do
        pcall(telescope.load_extension, extension)
      end
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = function()
      return require "configs.nvimtree"
    end,
  },

  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    keys = function()
      return require("configs.multicursor").keys
    end,
    config = function()
      require("configs.multicursor").setup()
    end,
  },

  {
    "Civitasv/cmake-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
    },
    cmd = function()
      return require("configs.cmake").commands
    end,
    keys = function()
      return require("configs.cmake").keys
    end,
    config = function()
      require("cmake-tools").setup(require("configs.cmake").options)
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "c",
        "cpp",
        "rust",
        "go",
        "gomod",
        "gosum",
        "python",
        "dockerfile",
        "toml",
        "bash",
      },
    },
  },

  {
    "github/copilot.vim",
    lazy = false,
  },
}
