require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<leader>tt", function()
  require("base46").toggle_theme()
end, { desc = "Toggle light/dark GitHub theme" })

map("n", "<F12>", vim.lsp.buf.definition, { desc = "Go to definition" })

map("n", "<C-t>", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", {
  desc = "Search workspace symbols",
})

map("n", "<leader>o", function()
  require("oil").open_float()
end, { desc = "Open centered file browser" })

local function with_gitsigns(cb)
  local ok, gs = pcall(require, "gitsigns")
  if not ok then
    vim.notify("gitsigns is not available", vim.log.levels.WARN)
    return
  end

  cb(gs)
end

map("n", "<leader>gg", function()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit is not installed. Install it to use the Git menu.", vim.log.levels.WARN)
    return
  end

  vim.cmd "LazyGit"
end, { desc = "Git menu (Lazygit)" })

map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "Git status files" })
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "Git commits" })

map("n", "]h", function()
  with_gitsigns(function(gs)
    gs.nav_hunk "next"
  end)
end, { desc = "Next git hunk" })

map("n", "[h", function()
  with_gitsigns(function(gs)
    gs.nav_hunk "prev"
  end)
end, { desc = "Previous git hunk" })

map("n", "<leader>ga", function()
  with_gitsigns(function(gs)
    gs.stage_hunk()
  end)
end, { desc = "Git stage hunk" })

map("n", "<leader>gr", function()
  with_gitsigns(function(gs)
    gs.reset_hunk()
  end)
end, { desc = "Git reset hunk" })

map("n", "<leader>gA", function()
  with_gitsigns(function(gs)
    gs.stage_buffer()
  end)
end, { desc = "Git stage buffer" })

map("n", "<leader>gR", function()
  with_gitsigns(function(gs)
    gs.reset_buffer()
  end)
end, { desc = "Git reset buffer" })

map("n", "<leader>gh", function()
  with_gitsigns(function(gs)
    gs.preview_hunk()
  end)
end, { desc = "Git preview hunk" })

map("n", "<leader>gd", function()
  with_gitsigns(function(gs)
    gs.diffthis()
  end)
end, { desc = "Git diff this" })

map("i", "<C-l>", function()
  return vim.fn["copilot#Accept"]("<C-l>")
end, {
  desc = "Copilot accept suggestion",
  expr = true,
  silent = true,
  replace_keycodes = false,
})
