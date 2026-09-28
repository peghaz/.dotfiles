local M = {}

M.lsp = {
  settings = {
    texlab = {
      build = {
        onSave = false,
      },
    },
  },
}

local function buffer_map(bufnr, lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
end

local function map_latex_keys(args)
  buffer_map(args.buf, "<leader>lb", "<cmd>VimtexCompile<cr>", "LaTeX build continuously")
  buffer_map(args.buf, "<leader>ls", "<cmd>VimtexStop<cr>", "LaTeX stop build")
  buffer_map(args.buf, "<leader>lv", "<cmd>VimtexView<cr>", "LaTeX view PDF")
  buffer_map(args.buf, "<leader>le", "<cmd>VimtexErrors<cr>", "LaTeX build errors")
  buffer_map(args.buf, "<leader>lc", "<cmd>VimtexClean<cr>", "LaTeX clean build files")
  buffer_map(args.buf, "<leader>lt", "<cmd>VimtexTocOpen<cr>", "LaTeX table of contents")
  buffer_map(args.buf, "<leader>li", "<cmd>VimtexInfo<cr>", "LaTeX project information")
end

function M.setup()
  vim.g.vimtex_compiler_method = "latexmk"

  if vim.fn.executable "zathura" == 1 then
    vim.g.vimtex_view_method = "zathura"
  else
    vim.g.vimtex_view_method = "general"
    vim.g.vimtex_view_general_viewer = "xdg-open"
    vim.g.vimtex_view_general_options = "@pdf"
  end

  local group = vim.api.nvim_create_augroup("local_vimtex_mappings", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "tex",
    callback = map_latex_keys,
  })
end

return M
