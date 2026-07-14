local dap = require "dap"
local dapui = require "dapui"
local dap_python = require "dap-python"

local uv = vim.uv or vim.loop

local function file_exists(path)
  return path and uv.fs_stat(path) ~= nil
end

local function python_path()
  local cwd = vim.fn.getcwd()
  local candidates = {
    vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python") or nil,
    cwd .. "/.venv/bin/python",
    cwd .. "/venv/bin/python",
    vim.fn.exepath "python3",
    vim.fn.exepath "python",
  }

  for _, path in ipairs(candidates) do
    if path and path ~= "" and file_exists(path) then
      return path
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
      "  \"version\": \"0.2.0\",",
      "  \"configurations\": [",
      "    {",
      "      \"name\": \"Python: Current File\",",
      "      \"type\": \"python\",",
      "      \"request\": \"launch\",",
      "      \"program\": \"${file}\",",
      "      \"console\": \"integratedTerminal\",",
      "      \"justMyCode\": true",
      "    }",
      "  ]",
      "}",
    }, launch_json)
  end

  vim.cmd("edit " .. vim.fn.fnameescape(launch_json))
end

dapui.setup {
  expand_lines = true,
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.35 },
        { id = "breakpoints", size = 0.2 },
        { id = "stacks", size = 0.2 },
        { id = "watches", size = 0.25 },
      },
      position = "left",
      size = 45,
    },
    {
      elements = {
        { id = "repl", size = 1 },
      },
      position = "bottom",
      size = 12,
    },
  },
}

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })

dap_python.setup(python_path())
dap_python.resolve_python = python_path

vim.api.nvim_create_user_command("DapEditLaunchJSON", ensure_launchjson, {
  desc = "Open or create .vscode/launch.json",
})

vim.api.nvim_create_user_command("DapShowConsole", function()
  dapui.float_element("console", { enter = true })
end, {
  desc = "Open DAP console in a floating window",
})

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

dap.listeners.before.disconnect["dapui_config"] = function()
  dapui.close()
end
