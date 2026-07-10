require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<leader>tt", function()
  require("base46").toggle_theme()
end, { desc = "Toggle light/dark GitHub theme" })

map("i", "<C-l>", function()
  return vim.fn["copilot#Accept"]("<CR>")
end, {
  desc = "Copilot accept suggestion",
  expr = true,
  silent = true,
  replace_keycodes = false,
})
