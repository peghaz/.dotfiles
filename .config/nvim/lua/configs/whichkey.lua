local M = {}

local function filetype_is(filetype)
  return function()
    return vim.bo.filetype == filetype
  end
end

function M.options(_, options)
  options = options or {}
  options.spec = options.spec or {}

  vim.list_extend(options.spec, {
    { "<leader>C", group = "CMake" },
    { "<leader>d", group = "Debug" },
    { "<leader>g", group = "Git" },
    { "<leader>q", group = "Problems" },
    { "<leader>R", group = "Python REPL" },
    { "<leader>l", group = "LaTeX", cond = filetype_is "tex" },
    { "<leader>m", group = "Markdown", cond = filetype_is "markdown" },
  })

  return options
end

return M
