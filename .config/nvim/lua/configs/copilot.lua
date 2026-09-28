local M = {}

function M.setup()
  -- Keep Tab exclusively for nvim-cmp and LuaSnip.
  vim.g.copilot_no_tab_map = true

  vim.keymap.set("i", "<C-l>", 'copilot#Accept("\\<Right>")', {
    desc = "Copilot accept suggestion",
    expr = true,
    replace_keycodes = false,
  })
end

return M
