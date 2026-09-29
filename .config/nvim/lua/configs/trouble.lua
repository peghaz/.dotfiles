local M = {}

M.options = {
  auto_close = false,
  auto_open = false,
  auto_preview = true,
  auto_refresh = true,
  focus = true,
  follow = true,
  multiline = true,
  restore = true,
  win = {
    type = "split",
    position = "bottom",
    size = 0.3,
  },
}

M.keys = {
  {
    "<leader>qq",
    "<cmd>Trouble diagnostics toggle focus=true<cr>",
    desc = "Problems: project diagnostics",
  },
  {
    "<leader>qb",
    "<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>",
    desc = "Problems: buffer diagnostics",
  },
  {
    "<leader>ql",
    "<cmd>Trouble loclist toggle focus=true<cr>",
    desc = "Problems: location list",
  },
  {
    "<leader>qf",
    "<cmd>Trouble qflist toggle focus=true<cr>",
    desc = "Problems: quickfix list",
  },
}

return M
