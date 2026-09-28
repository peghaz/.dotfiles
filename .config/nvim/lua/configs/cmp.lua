local cmp = require "cmp"
local options = require "nvchad.configs.cmp"

options.completion = vim.tbl_deep_extend("force", options.completion or {}, {
  autocomplete = {
    cmp.TriggerEvent.TextChanged,
  },
  keyword_length = 1,
})

options.enabled = function()
  if vim.bo.buftype ~= "prompt" then
    return true
  end

  local ok, cmp_dap = pcall(require, "cmp_dap")
  return ok and cmp_dap.is_dap_buffer()
end

cmp.setup.filetype("dap-repl", {
  sources = cmp.config.sources({
    { name = "dap" },
  }, {
    { name = "buffer" },
  }),
})

cmp.setup.filetype({ "c", "cpp" }, {
  completion = options.completion,
  sources = cmp.config.sources({
    { name = "nvim_lsp", priority = 1000 },
    { name = "luasnip", priority = 750 },
  }, {
    { name = "buffer", keyword_length = 2 },
    { name = "async_path" },
  }),
})

return options
