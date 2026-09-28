local M = {}

local function buffer_map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
end

M.options = {
  on_attach = function(bufnr)
    buffer_map(bufnr, "n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", "Markdown preview toggle")
    buffer_map(bufnr, "n", "<leader>mo", "<cmd>MDToc<cr>", "Markdown table of contents")
    buffer_map(bufnr, { "n", "x" }, "<leader>mi", ":MDInsertToc<cr>", "Markdown insert table of contents")
    buffer_map(bufnr, { "n", "x" }, "<leader>mc", ":MDTaskToggle<cr>", "Markdown toggle task")
    buffer_map(bufnr, "n", "<leader>mj", "<cmd>MDListItemBelow<cr>", "Markdown list item below")
    buffer_map(bufnr, "n", "<leader>mk", "<cmd>MDListItemAbove<cr>", "Markdown list item above")
    buffer_map(bufnr, { "n", "x" }, "<leader>mr", ":MDResetListNumbering<cr>", "Markdown renumber list")
  end,
}

function M.setup_preview()
  vim.g.mkdp_auto_start = 0
  vim.g.mkdp_auto_close = 1
  vim.g.mkdp_refresh_slow = 0
  vim.g.mkdp_open_to_the_world = 0
  vim.g.mkdp_filetypes = { "markdown" }
end

return M
