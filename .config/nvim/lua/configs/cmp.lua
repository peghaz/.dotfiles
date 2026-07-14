local cmp = require "cmp"
local options = require "nvchad.configs.cmp"

options.enabled = function()
  if vim.bo.buftype ~= "prompt" then
    return true
  end

  local ok, cmp_dap = pcall(require, "cmp_dap")
  return ok and cmp_dap.is_dap_buffer()
end

cmp.setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
  sources = {
    { name = "dap" },
    { name = "buffer" },
  },
})

return options
