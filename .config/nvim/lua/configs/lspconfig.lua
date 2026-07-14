require("nvchad.configs.lspconfig").defaults()
local servers = require "configs.lsp_servers"

local function ensure_mason_bin_on_path()
  local sep = package.config:sub(1, 1) == "\\" and ";" or ":"
  local mason_bin = vim.fn.stdpath "data" .. "/mason/bin"

  if vim.fn.isdirectory(mason_bin) == 1 then
    local path = vim.env.PATH or ""
    if not vim.startswith(path, mason_bin .. sep) and not path:find(sep .. mason_bin, 1, true) then
      vim.env.PATH = mason_bin .. sep .. path
    end
  end
end

local function warn_missing_servers(servers)
  local missing = {}

  for _, name in ipairs(servers) do
    local cfg = vim.lsp.config[name]
    local cmd = cfg and cfg.cmd
    local exe = type(cmd) == "table" and cmd[1] or cmd

    if type(exe) == "string" and exe ~= "" and vim.fn.executable(exe) == 0 then
      table.insert(missing, exe)
    end
  end

  if #missing > 0 then
    table.sort(missing)
    vim.schedule(function()
      vim.notify(
        "Missing LSP binaries: "
          .. table.concat(missing, ", ")
          .. ". Install with :Mason or your package manager.",
        vim.log.levels.WARN
      )
    end)
  end
end

ensure_mason_bin_on_path()
vim.lsp.enable(servers)
warn_missing_servers(servers)

-- read :h vim.lsp.config for changing options of lsp servers
