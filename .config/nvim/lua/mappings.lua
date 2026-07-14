require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<leader>tt", function()
  require("base46").toggle_theme()
end, { desc = "Toggle light/dark GitHub theme" })

map("n", "<F12>", vim.lsp.buf.definition, { desc = "Go to definition" })

map("n", "<C-t>", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", {
  desc = "Search workspace symbols",
})

map("n", "<leader>o", function()
  require("oil").open_float()
end, { desc = "Open centered file browser" })

local function with_gitsigns(cb)
  local ok, gs = pcall(require, "gitsigns")
  if not ok then
    vim.notify("gitsigns is not available", vim.log.levels.WARN)
    return
  end

  cb(gs)
end

map("n", "<leader>gg", function()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit is not installed. Install it to use the Git menu.", vim.log.levels.WARN)
    return
  end

  vim.cmd "LazyGit"
end, { desc = "Git menu (Lazygit)" })

map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "Git status files" })
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "Git commits" })

map("n", "]h", function()
  with_gitsigns(function(gs)
    gs.nav_hunk "next"
  end)
end, { desc = "Next git hunk" })

map("n", "[h", function()
  with_gitsigns(function(gs)
    gs.nav_hunk "prev"
  end)
end, { desc = "Previous git hunk" })

map("n", "<leader>ga", function()
  with_gitsigns(function(gs)
    gs.stage_hunk()
  end)
end, { desc = "Git stage hunk" })

map("n", "<leader>gr", function()
  with_gitsigns(function(gs)
    gs.reset_hunk()
  end)
end, { desc = "Git reset hunk" })

map("n", "<leader>gA", function()
  with_gitsigns(function(gs)
    gs.stage_buffer()
  end)
end, { desc = "Git stage buffer" })

map("n", "<leader>gR", function()
  with_gitsigns(function(gs)
    gs.reset_buffer()
  end)
end, { desc = "Git reset buffer" })

map("n", "<leader>gh", function()
  with_gitsigns(function(gs)
    gs.preview_hunk()
  end)
end, { desc = "Git preview hunk" })

map("n", "<leader>gd", function()
  with_gitsigns(function(gs)
    gs.diffthis()
  end)
end, { desc = "Git diff this" })

map("n", "<F5>", "<cmd>DapContinue<CR>", { desc = "Debug start/continue" })
map("n", "<S-F5>", "<cmd>DapTerminate<CR>", { desc = "Debug stop" })
map("n", "<F9>", "<cmd>DapToggleBreakpoint<CR>", { desc = "Debug toggle breakpoint" })
map("n", "<F10>", "<cmd>DapStepOver<CR>", { desc = "Debug step over" })
map("n", "<F11>", "<cmd>DapStepInto<CR>", { desc = "Debug step into" })
map("n", "<S-F11>", "<cmd>DapStepOut<CR>", { desc = "Debug step out" })

map("n", "<leader>dc", "<cmd>DapContinue<CR>", { desc = "Debug continue" })
map("n", "<leader>di", "<cmd>DapStepInto<CR>", { desc = "Debug step into" })
map("n", "<leader>do", "<cmd>DapStepOver<CR>", { desc = "Debug step over" })
map("n", "<leader>dO", "<cmd>DapStepOut<CR>", { desc = "Debug step out" })
map("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Debug toggle breakpoint" })
map("n", "<leader>dl", function()
  require("dap").run_last()
end, { desc = "Debug run last" })
map("n", "<leader>dr", function()
  require("dap").repl.toggle()
end, { desc = "Debug REPL" })
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Debug UI toggle" })
map("n", "<leader>dC", "<cmd>DapShowConsole<CR>", { desc = "Debug open console" })
map("n", "<leader>dx", "<cmd>DapTerminate<CR>", { desc = "Debug terminate" })
map("n", "<leader>dj", "<cmd>DapEditLaunchJSON<CR>", { desc = "Debug open launch.json" })
map("n", "<leader>dB", function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(input)
    if input and input ~= "" then
      require("dap").set_breakpoint(input)
    end
  end)
end, { desc = "Debug conditional breakpoint" })

map("i", "<C-l>", function()
  return vim.fn["copilot#Accept"]("<C-l>")
end, {
  desc = "Copilot accept suggestion",
  expr = true,
  silent = true,
  replace_keycodes = false,
})
