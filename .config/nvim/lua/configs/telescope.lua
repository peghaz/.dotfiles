local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local fb_actions = require "telescope._extensions.file_browser.actions"
local fb_lsp = require "telescope._extensions.file_browser.lsp"
local fb_utils = require "telescope._extensions.file_browser.utils"
local Path = require "plenary.path"
local options = require "nvchad.configs.telescope"

local function selected_path()
  local entry = action_state.get_selected_entry()
  if not entry then
    return nil
  end
  if entry.Path and entry.Path.absolute then
    return entry.Path:absolute()
  end
  return entry.path or entry.value
end

local function with_selected_path(callback)
  return function(prompt_bufnr)
    callback(selected_path(), prompt_bufnr)
  end
end

local function browser_path(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local path = picker.finder.path

  if type(path) == "table" and path.absolute then
    path = path:absolute()
  end

  return path and tostring(path) or vim.fn.getcwd()
end

local function grep_in_browser(prompt_bufnr)
  local path = browser_path(prompt_bufnr)

  actions.close(prompt_bufnr)
  vim.schedule(function()
    require("telescope.builtin").live_grep {
      cwd = path,
      additional_args = function()
        return { "--hidden" }
      end,
    }
  end)
end

local function trash_in_browser(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local finder = picker.finder
  local selections = fb_utils.get_selected_files(prompt_bufnr, true)

  if vim.tbl_isempty(selections) then
    fb_utils.notify("actions.trash", {
      msg = "No selection to move to trash!",
      level = "WARN",
      quiet = finder.quiet,
    })
    return
  end

  local items = {}
  for _, selection in ipairs(selections) do
    local path = selection:absolute()

    if selection:is_dir() then
      local protected_path = finder.files and Path:new(finder.path):parent():absolute()
        or Path:new(finder.cwd):absolute()

      if protected_path == path then
        fb_utils.notify("actions.trash", {
          msg = (finder.files and "Parent folder" or "Current folder") .. " cannot be trashed!",
          level = "WARN",
          quiet = finder.quiet,
        })
        return
      end
    end

    items[#items + 1] = {
      path = path,
      is_dir = selection:is_dir(),
      name = selection.filename:sub(#selection:parent().filename + 2),
    }
  end

  local names = vim.tbl_map(function(item)
    return item.name
  end, items)

  vim.ui.select({ "Trash", "Cancel" }, {
    prompt = string.format("Move %d item%s to trash?", #items, #items == 1 and "" or "s"),
  }, function(choice)
    if choice ~= "Trash" then
      return
    end

    local paths = vim.tbl_map(function(item)
      return item.path
    end, items)
    local command = { "trash-put" }
    vim.list_extend(command, paths)

    fb_lsp.will_delete_files(paths)
    vim.system(
      command,
      { text = true },
      vim.schedule_wrap(function(result)
        if result.code ~= 0 then
          local message = vim.trim(result.stderr or "")
          fb_utils.notify("actions.trash", {
            msg = message ~= "" and message or "trash-put failed with exit code " .. result.code,
            level = "ERROR",
            quiet = finder.quiet,
          })
          return
        end

        for _, item in ipairs(items) do
          if item.is_dir then
            fb_utils.delete_dir_buf(item.path)
          else
            fb_utils.delete_buf(item.path)
          end
        end

        fb_lsp.did_delete_files(paths)
        fb_utils.notify("actions.trash", {
          msg = "Trashed: " .. table.concat(names, ", "),
          level = "INFO",
          quiet = finder.quiet,
        })
        pcall(function()
          picker:refresh(picker.finder)
        end)
      end)
    )
  end)
end

options.defaults.layout_strategy = "horizontal"
options.defaults.layout_config.width = 0.9
options.defaults.layout_config.height = 0.85
options.defaults.layout_config.horizontal.preview_width = 0.58

options.extensions.file_browser = {
  attach_mappings = function(prompt_bufnr, map)
    require("which-key").add {
      { "<leader>o", group = "File Actions", buffer = prompt_bufnr },
    }

    map({ "i", "n" }, "<C-f>", grep_in_browser, { desc = "Search in current folder" })
    map({ "i", "n" }, "<C-b>", fb_actions.toggle_browser, { desc = "Toggle file/folder browser" })
    map("n", "d", trash_in_browser, { desc = "Move selection to trash" })
    map("n", "D", fb_actions.remove, { desc = "Delete selection permanently" })
    map("n", "<leader>oa", with_selected_path(function(path)
      require("configs.explorer_actions").copy_absolute(path)
    end), { desc = "Copy absolute path" })
    map("n", "<leader>or", with_selected_path(function(path)
      require("configs.explorer_actions").copy_relative(path)
    end), { desc = "Copy relative path" })
    map("n", "<leader>os", with_selected_path(function(path)
      require("configs.explorer_actions").select_for_compare(path)
    end), { desc = "Select for compare" })
    map("n", "<leader>oc", with_selected_path(function(path, current_prompt_bufnr)
      require("configs.explorer_actions").compare_with_selected(path, function()
        actions.close(current_prompt_bufnr)
      end)
    end), { desc = "Compare with selected" })
    map("n", "<leader>oh", with_selected_path(function(path, current_prompt_bufnr)
      require("configs.explorer_actions").compare_with_head(path, function()
        actions.close(current_prompt_bufnr)
      end)
    end), { desc = "Compare with HEAD" })

    return true
  end,
  cwd_to_path = true,
  grouped = true,
  hidden = {
    file_browser = true,
    folder_browser = true,
  },
  select_buffer = true,
  respect_gitignore = vim.fn.executable "fd" == 1,
  layout_strategy = "horizontal",
  layout_config = {
    width = 0.9,
    height = 0.85,
    preview_width = 0.58,
  },
}

options.pickers = options.pickers or {}
options.pickers.git_status = vim.tbl_deep_extend("force", options.pickers.git_status or {}, {
  attach_mappings = require("configs.telescope_git").attach_mappings,
})

if not vim.tbl_contains(options.extensions_list, "file_browser") then
  options.extensions_list[#options.extensions_list + 1] = "file_browser"
end

return options
