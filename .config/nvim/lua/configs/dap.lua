local dap = require "dap"
local dap_view = require "dap-view"
local dap_python = require "dap-python"

local uv = vim.uv or vim.loop
local debugpy_adapter = vim.fn.stdpath "data" .. "/mason/bin/debugpy-adapter"

local function file_exists(path)
  return path and uv.fs_stat(path) ~= nil
end

local function python_in(environment)
  if vim.fn.has "win32" == 1 then
    return environment .. "/Scripts/python.exe"
  end

  return environment .. "/bin/python"
end

local function resolve_python()
  local candidates = {}
  local roots = { vim.fn.getcwd(), vim.fn.getcwd(0) }

  for _, environment in ipairs { vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX } do
    if environment and environment ~= "" then
      candidates[#candidates + 1] = python_in(environment)
    end
  end

  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.config.root_dir then
      roots[#roots + 1] = client.config.root_dir
    end
  end

  for _, root in ipairs(roots) do
    for _, directory in ipairs { ".venv", "venv", "env", ".env" } do
      candidates[#candidates + 1] = python_in(root .. "/" .. directory)
    end
  end

  candidates[#candidates + 1] = vim.fn.exepath "python3"
  candidates[#candidates + 1] = vim.fn.exepath "python"

  for _, candidate in ipairs(candidates) do
    if candidate ~= "" and vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end

  return "python3"
end

local function ensure_launchjson()
  local launch_dir = vim.fn.getcwd() .. "/.vscode"
  local launch_json = launch_dir .. "/launch.json"

  if not file_exists(launch_json) then
    vim.fn.mkdir(launch_dir, "p")
    vim.fn.writefile({
      "{",
      '  "version": "0.2.0",',
      '  "configurations": [',
      "    {",
      '      "name": "Python: Current File",',
      '      "type": "python",',
      '      "request": "launch",',
      '      "program": "${file}",',
      '      "console": "integratedTerminal",',
      '      "justMyCode": true',
      "    }",
      "  ]",
      "}",
    }, launch_json)
  end

  vim.cmd("edit " .. vim.fn.fnameescape(launch_json))
end

dap_view.setup {
  winbar = {
    sections = { "scopes", "watches", "threads", "breakpoints", "repl", "console" },
    default_section = "scopes",
    show_keymap_hints = true,
    controls = {
      enabled = true,
      position = "right",
    },
  },
  windows = {
    size = 0.25,
    position = "below",
  },
  virtual_text = {
    enabled = true,
    position = "inline",
  },
  auto_toggle = true,
  follow_tab = true,
  switchbuf = "useopen,usetab,newtab",
}

dap.defaults.fallback.switchbuf = "usevisible,usetab,newtab"

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })

-- Keep the adapter isolated from project environments. nvim-dap-python still
-- resolves the Python used by the debuggee from the active/project virtualenv.
dap_python.setup(debugpy_adapter)
dap_python.resolve_python = resolve_python

vim.api.nvim_create_user_command("DapEditLaunchJSON", ensure_launchjson, {
  desc = "Open or create .vscode/launch.json",
})
