local M = {}

local selected_for_compare
local title = "File explorer"

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = title })
end

local function normalized(path)
  return path and path ~= "" and vim.fs.normalize(path) or nil
end

local function file_exists(path)
  local stat = path and (vim.uv or vim.loop).fs_stat(path)
  return stat and stat.type == "file"
end

local function workspace_root(path)
  local start = file_exists(path) and vim.fs.dirname(path) or path
  return vim.fs.root(start, ".git") or vim.fn.getcwd()
end

local function copy(value, description)
  vim.fn.setreg('"', value)
  vim.fn.setreg("+", value)
  notify(description .. ": " .. value)
end

local function validate_file(path, action)
  path = normalized(path)
  if not file_exists(path) then
    notify(action .. " requires a file", vim.log.levels.WARN)
    return nil
  end
  return path
end

local function after_close(close_source, callback)
  if close_source then
    close_source()
  end
  vim.schedule(callback)
end

function M.copy_absolute(path)
  path = normalized(path)
  if not path then
    notify("No file or directory selected", vim.log.levels.WARN)
    return
  end
  copy(path, "Copied absolute path")
end

function M.copy_relative(path)
  path = normalized(path)
  if not path then
    notify("No file or directory selected", vim.log.levels.WARN)
    return
  end

  local root = workspace_root(path)
  local relative = vim.fs.relpath(root, path) or path
  copy(relative, "Copied workspace-relative path")
end

function M.select_for_compare(path)
  path = validate_file(path, "Select for Compare")
  if not path then
    return
  end

  selected_for_compare = path
  notify("Selected for comparison: " .. vim.fn.fnamemodify(path, ":~:."))
end

function M.compare_with_selected(path, close_source)
  path = validate_file(path, "Compare with Selected")
  if not path then
    return
  end
  if not selected_for_compare then
    notify("Choose Select for Compare on another file first", vim.log.levels.WARN)
    return
  end
  if not file_exists(selected_for_compare) then
    selected_for_compare = nil
    notify("The previously selected file no longer exists", vim.log.levels.WARN)
    return
  end
  if path == selected_for_compare then
    notify("Choose a different file to compare", vim.log.levels.WARN)
    return
  end

  local first = selected_for_compare
  after_close(close_source, function()
    vim.cmd("tabedit " .. vim.fn.fnameescape(first))
    vim.cmd("vertical diffsplit " .. vim.fn.fnameescape(path))
  end)
end

function M.compare_with_head(path, close_source)
  path = validate_file(path, "Compare with HEAD")
  if not path then
    return
  end

  local root = vim.fs.root(vim.fs.dirname(path), ".git")
  if not root then
    notify("The selected file is not inside a Git repository", vim.log.levels.WARN)
    return
  end

  local relative = vim.fs.relpath(root, path)
  if not relative then
    notify("Could not resolve the selected file inside its Git repository", vim.log.levels.WARN)
    return
  end

  local tracked = vim
    .system({ "git", "-C", root, "ls-files", "--error-unmatch", "--", relative }, { text = true })
    :wait()
  if tracked.code ~= 0 then
    notify("The selected file is not tracked by Git", vim.log.levels.WARN)
    return
  end

  after_close(close_source, function()
    local command = table.concat({
      "DiffviewOpen HEAD",
      "-C" .. vim.fn.fnameescape(root),
      "--selected-file=" .. vim.fn.fnameescape(relative),
      "--",
      vim.fn.fnameescape(relative),
    }, " ")
    vim.cmd(command)
  end)
end

return M
