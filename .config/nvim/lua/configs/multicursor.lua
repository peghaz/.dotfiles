local M = {}

M.keys = {
  {
    "<C-d>",
    function()
      require("multicursor-nvim").matchAddCursor(1)
    end,
    mode = { "n", "x" },
    desc = "Add cursor at next match",
  },
}

function M.setup()
  local multicursor = require "multicursor-nvim"

  multicursor.setup()
  multicursor.addKeymapLayer(function(map)
    map("n", "<Esc>", function()
      if multicursor.cursorsEnabled() then
        multicursor.clearCursors()
      else
        multicursor.enableCursors()
      end
    end)
  end)
end

return M
