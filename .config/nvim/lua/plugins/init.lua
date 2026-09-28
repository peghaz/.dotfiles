return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = function()
      return require "configs.conform"
    end,
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
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      return require("configs.git").gitsigns(opts)
    end,
  },

  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    keys = function()
      return require("configs.git").diffview_keys
    end,
    opts = function()
      return require("configs.git").diffview
    end,
  },

  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    keys = function()
      return require("configs.git").neogit_keys
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "sindrets/diffview.nvim",
    },
    opts = function()
      return require("configs.git").neogit
    end,
  },

  {
    "folke/which-key.nvim",
    opts = require("configs.whichkey").options,
  },

  {
    "Vigemus/iron.nvim",
    ft = "python",
    cmd = { "IronRepl", "IronRestart", "IronFocus", "IronHide", "IronSend" },
    config = function()
      require("configs.repl").setup()
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

  {
    "tadmccorkle/markdown.nvim",
    ft = "markdown",
    opts = function()
      return require("configs.markdown").options
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = "markdown",
    build = "cd app && npm install",
    init = function()
      require("configs.markdown").setup_preview()
    end,
  },

  {
    "lervag/vimtex",
    tag = "v2.17",
    lazy = false,
    init = function()
      require("configs.latex").setup()
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
        "markdown",
        "markdown_inline",
      },
    },
  },

  {
    "github/copilot.vim",
    lazy = false,
    init = function()
      vim.g.copilot_no_tab_map = true
    end,
  },
}
