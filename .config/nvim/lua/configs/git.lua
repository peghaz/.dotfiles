local M = {}

M.neogit = {
  integrations = {
    diffview = true,
    telescope = true,
  },
}

M.diffview = {
  enhanced_diff_hl = true,
  view = {
    merge_tool = {
      layout = "diff3_mixed",
      disable_diagnostics = true,
      winbar_info = true,
    },
  },
}

M.neogit_keys = {
  { "<leader>gg", "<cmd>Neogit<CR>", desc = "Git status" },
}

M.diffview_keys = {
  { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Git diff" },
  { "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "Git diff close" },
  { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Git file history" },
  { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Git repository history" },
}

function M.gitsigns(options)
  options = options or {}
  local previous_on_attach = options.on_attach

  options.on_attach = function(bufnr)
    if previous_on_attach then
      previous_on_attach(bufnr)
    end

    local gitsigns = require "gitsigns"

    local function map(mode, lhs, rhs, desc, extra)
      local mapping_options = vim.tbl_extend("force", {
        buffer = bufnr,
        desc = "Git " .. desc,
      }, extra or {})

      vim.keymap.set(mode, lhs, rhs, mapping_options)
    end

    local function navigate(direction, fallback)
      return function()
        if vim.wo.diff then
          return fallback
        end

        vim.schedule(function()
          gitsigns.nav_hunk(direction)
        end)
        return "<Ignore>"
      end
    end

    map("n", "]c", navigate("next", "]c"), "next hunk", { expr = true })
    map("n", "[c", navigate("prev", "[c"), "previous hunk", { expr = true })
    map("n", "<leader>gp", gitsigns.preview_hunk, "preview hunk")
    map("n", "<leader>gs", gitsigns.stage_hunk, "stage hunk")
    map("x", "<leader>gs", function()
      gitsigns.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
    end, "stage selection")
    map("n", "<leader>gu", gitsigns.undo_stage_hunk, "undo staged hunk")
    map("n", "<leader>gr", gitsigns.reset_hunk, "reset hunk")
    map("x", "<leader>gr", function()
      gitsigns.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
    end, "reset selection")
    map("n", "<leader>gb", function()
      gitsigns.blame_line { full = true }
    end, "blame line")
  end

  return options
end

return M
