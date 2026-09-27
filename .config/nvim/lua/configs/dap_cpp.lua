local M = {}

function M.setup(dap)
  local adapter = vim.fn.stdpath "data" .. "/mason/bin/codelldb"

  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = adapter,
      args = { "--port", "${port}" },
    },
  }
end

return M
