require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<leader>tt", function()
  require("base46").toggle_theme()
end, { desc = "Toggle light/dark GitHub theme" })

map("n", "<F5>", "<cmd>DapContinue<CR>", { desc = "Debug start/continue" })
map("n", "<S-F5>", "<cmd>DapTerminate<CR>", { desc = "Debug stop" })
map("n", "<F9>", "<cmd>DapToggleBreakpoint<CR>", { desc = "Debug toggle breakpoint" })
map("n", "<F10>", "<cmd>DapStepOver<CR>", { desc = "Debug step over" })
map("n", "<F11>", "<cmd>DapStepInto<CR>", { desc = "Debug step into" })
map("n", "<S-F11>", "<cmd>DapStepOut<CR>", { desc = "Debug step out" })

map("n", "<leader>dc", "<cmd>DapContinue<CR>", { desc = "Debug continue" })
map("n", "<leader>dx", "<cmd>DapTerminate<CR>", { desc = "Debug terminate" })
map("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Debug toggle breakpoint" })
map("n", "<leader>dB", function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(input)
    if input and input ~= "" then
      require("dap").set_breakpoint(input)
    end
  end)
end, { desc = "Debug conditional breakpoint" })
map("n", "<leader>di", "<cmd>DapStepInto<CR>", { desc = "Debug step into" })
map("n", "<leader>do", "<cmd>DapStepOver<CR>", { desc = "Debug step over" })
map("n", "<leader>dO", "<cmd>DapStepOut<CR>", { desc = "Debug step out" })
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
map("n", "<leader>dj", "<cmd>DapEditLaunchJSON<CR>", { desc = "Debug open launch.json" })
