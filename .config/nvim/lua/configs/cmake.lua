local M = {}

M.commands = {
  "CMakeBuild",
  "CMakeClean",
  "CMakeDebug",
  "CMakeGenerate",
  "CMakeLaunchArgs",
  "CMakeQuickStart",
  "CMakeRun",
  "CMakeRunTest",
  "CMakeSelectBuildType",
  "CMakeSelectLaunchTarget",
  "CMakeSelectBuildTarget",
  "CMakeSettings",
}

M.keys = {
  { "<leader>Ci", "<cmd>CMakeQuickStart<CR>", desc = "CMake initialize project" },
  { "<leader>Cg", "<cmd>CMakeGenerate<CR>", desc = "CMake configure/generate" },
  { "<leader>Cb", "<cmd>CMakeBuild<CR>", desc = "CMake build" },
  { "<leader>Cr", "<cmd>CMakeRun<CR>", desc = "CMake run target" },
  { "<leader>Cd", "<cmd>CMakeDebug<CR>", desc = "CMake debug target" },
  { "<leader>Ct", "<cmd>CMakeRunTest<CR>", desc = "CMake run tests" },
  { "<leader>Cs", "<cmd>CMakeSettings<CR>", desc = "CMake settings" },
}

M.options = {
  cmake_command = "cmake",
  ctest_command = "ctest",
  cmake_use_preset = true,
  cmake_regenerate_on_save = true,
  cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
  cmake_build_directory = "build/${variant:buildType}",
  cmake_compile_commands_options = {
    action = "soft_link",
    target = function()
      return vim.fn.getcwd()
    end,
  },
  cmake_dap_configuration = {
    name = "CMake target",
    type = "codelldb",
    request = "launch",
    stopOnEntry = false,
    runInTerminal = true,
    console = "integratedTerminal",
  },
  cmake_executor = {
    name = "quickfix",
    opts = {
      show = "always",
      position = "belowright",
      size = 12,
      auto_close_when_success = true,
    },
  },
  cmake_runner = {
    name = "terminal",
    opts = {
      split_direction = "horizontal",
      split_size = 12,
      focus = false,
      start_insert = false,
    },
  },
}

return M
