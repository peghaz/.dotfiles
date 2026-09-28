local M = {}

local function executable(path)
  return path and path ~= "" and vim.fn.executable(path) == 1
end

local function environment_ipython()
  local suffix = vim.fn.has "win32" == 1 and "/Scripts/ipython.exe" or "/bin/ipython"

  for _, environment in ipairs { vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX } do
    local candidate = environment and environment .. suffix or nil
    if executable(candidate) then
      return candidate
    end
  end
end

local function python_command()
  local ipython = environment_ipython()
  if ipython then
    return { ipython, "--no-autoindent" }
  end

  if vim.fn.executable "uv" == 1 then
    return { "uv", "run", "--with", "ipython", "ipython", "--no-autoindent" }
  end

  return { vim.fn.executable "python3" == 1 and "python3" or "python" }
end

function M.setup()
  local iron = require "iron.core"
  local common = require "iron.fts.common"
  local view = require "iron.view"

  iron.setup {
    config = {
      scratch_repl = true,
      close_window_on_exit = true,
      repl_definition = {
        python = {
          command = python_command,
          format = common.bracketed_paste_python,
          block_dividers = { "# %%", "#%%" },
          env = { PYTHON_BASIC_REPL = "1" },
        },
      },
      repl_open_cmd = view.split.vertical.rightbelow "40%",
    },
    keymaps = {
      toggle_repl = "<leader>Rt",
      restart_repl = "<leader>Rr",
      send_file = "<leader>RF",
      send_line = "<leader>Rl",
      visual_send = "<leader>Rv",
      send_code_block = "<leader>Rc",
      send_code_block_and_move = "<leader>Rn",
      interrupt = "<leader>Ri",
      exit = "<leader>Rq",
    },
    highlight = { italic = true },
    ignore_blank_lines = true,
  }

  vim.keymap.set("n", "<leader>Rf", "<cmd>IronFocus<cr>", { desc = "REPL focus" })
  vim.keymap.set("n", "<leader>Rh", "<cmd>IronHide<cr>", { desc = "REPL hide" })
  vim.keymap.set("x", "<S-CR>", iron.visual_send, { desc = "REPL send selection" })
end

return M
