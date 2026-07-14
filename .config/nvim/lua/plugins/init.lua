return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts = function()
      return {
        ensure_installed = require "configs.lsp_servers",
        automatic_installation = true,
      }
    end,
  },

  {
    "github/copilot.vim",
    init = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
    end,
    lazy = false,
  },

  {
    "mg979/vim-visual-multi",
    branch = "master",
    keys = {
      { "<C-d>", "<Plug>(VM-Find-Under)", mode = "n", desc = "Select next occurrence" },
      { "<C-d>", "<Plug>(VM-Find-Subword-Under)", mode = "x", desc = "Select next occurrence" },
    },
  },

  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Oil",
    opts = {
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = true,
      },
      float = {
        padding = 4,
        max_width = 0.8,
        max_height = 0.8,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
    },
  },

  {
    "nvim-tree/nvim-web-devicons",
    opts = function(_, opts)
      local custom = require "configs.devicons"

      opts.override = vim.tbl_deep_extend("force", opts.override or {}, custom.override)
      opts.override_by_filename = vim.tbl_deep_extend(
        "force",
        opts.override_by_filename or {},
        custom.override_by_filename
      )
      opts.override_by_extension = vim.tbl_deep_extend(
        "force",
        opts.override_by_extension or {},
        custom.override_by_extension
      )

      return opts
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts or {}, require "configs.nvimtree")
    end,
  },

  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  {
    "mfussenegger/nvim-dap",
    lazy = false,
    dependencies = {
      "nvim-neotest/nvim-nio",
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      require "configs.dap"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
    "hrsh7th/nvim-cmp",
    -- cmp-dap must depend on nvim-cmp, not nvim-dap: nvim-dap is `lazy = false`, and
    -- cmp-dap's after/plugin requires "cmp", which would force-load nvim-cmp during
    -- lazy's init phase. lazy only sources a plugin's after/plugin once init is done,
    -- so every cmp source (nvim_lsp, buffer, luasnip, nvim_lua) would silently never register.
    dependencies = { "rcarriga/cmp-dap" },
    opts = function()
      return require "configs.cmp"
    end,
  },

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
        "markdown", "markdown_inline",
        "yaml",
        "json", "jsonc",
        "dockerfile",
        "toml",
        "bash",
      },
    },
  },
}
