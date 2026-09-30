local M = {}

local function selection_context(prompt_bufnr)
  local action_state = require "telescope.actions.state"
  local picker = action_state.get_current_picker(prompt_bufnr)
  local selection = action_state.get_selected_entry()

  if not selection then
    vim.notify("No Git status item selected", vim.log.levels.WARN, { title = "Git status" })
    return nil
  end

  return selection, picker, picker.cwd or vim.fn.getcwd()
end

local function refresh(picker, cwd)
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local row = picker:get_selection_row()
  local finder = finders.new_oneshot_job({ "git", "status", "-z", "-uall", "--", "." }, {
    cwd = cwd,
    entry_maker = make_entry.gen_from_git_status { cwd = cwd },
    split_char = "\0",
  })

  local callbacks = { unpack(picker._completion_callbacks) }
  picker:register_completion_callback(function(current_picker)
    current_picker:set_selection(row)
    current_picker._completion_callbacks = callbacks
  end)
  picker:refresh(finder, { reset_prompt = false })
end

local function run_git(cwd, arguments)
  local command = { "git" }
  vim.list_extend(command, arguments)
  local result = vim.system(command, { cwd = cwd, text = true }):wait()

  if result.code ~= 0 then
    local message = vim.trim(result.stderr or "")
    vim.notify(message ~= "" and message or "Git command failed", vim.log.levels.ERROR, { title = "Git status" })
    return false
  end

  return true
end

local function stage(prompt_bufnr)
  local selection, picker, cwd = selection_context(prompt_bufnr)
  if not selection then
    return
  end

  if run_git(cwd, { "add", "--", selection.value }) then
    refresh(picker, cwd)
  end
end

local function unstage(prompt_bufnr)
  local selection, picker, cwd = selection_context(prompt_bufnr)
  if not selection then
    return
  end

  local index_status = selection.status:sub(1, 1)
  if index_status == " " or index_status == "?" then
    vim.notify("The selected file has no staged changes", vim.log.levels.INFO, { title = "Git status" })
    return
  end

  local arguments = index_status == "A" and { "rm", "--cached", "-f", "--", selection.value }
    or { "restore", "--staged", "--", selection.value }
  if run_git(cwd, arguments) then
    refresh(picker, cwd)
  end
end

local function discard(prompt_bufnr)
  local selection, picker, cwd = selection_context(prompt_bufnr)
  if not selection then
    return
  end

  local index_status = selection.status:sub(1, 1)
  local worktree_status = selection.status:sub(2, 2)
  local unmerged = {
    AA = true,
    AU = true,
    DD = true,
    DU = true,
    UA = true,
    UD = true,
    UU = true,
  }
  if
    unmerged[selection.status]
    or index_status == "R"
    or index_status == "C"
    or worktree_status == "R"
    or worktree_status == "C"
  then
    vim.notify(
      "Use Neogit or Diffview to discard conflicts, renames, and copies safely",
      vim.log.levels.WARN,
      { title = "Git status" }
    )
    return
  end

  local display_path = vim.fn.fnamemodify(selection.value, ":~:.")
  vim.ui.select({ "Discard", "Cancel" }, {
    prompt = "Discard all changes to " .. display_path .. "?",
  }, function(choice)
    if choice ~= "Discard" then
      return
    end

    local is_untracked = index_status == "?" and worktree_status == "?"
    local is_added = index_status == "A"

    if (is_untracked or is_added) and vim.fn.executable "trash-put" == 0 then
      vim.notify("trash-put is required to discard untracked files safely", vim.log.levels.ERROR, {
        title = "Git status",
      })
      return
    end

    if is_added and not run_git(cwd, { "rm", "--cached", "-f", "--", selection.value }) then
      return
    end

    if is_untracked or is_added then
      local absolute_path = vim.fs.joinpath(cwd, selection.value)
      if vim.uv.fs_stat(absolute_path) then
        local result = vim.system({ "trash-put", absolute_path }, { text = true }):wait()
        if result.code ~= 0 then
          local message = vim.trim(result.stderr or "")
          vim.notify(
            message ~= "" and message or "trash-put failed",
            vim.log.levels.ERROR,
            { title = "Git status" }
          )
          return
        end
      end
    elseif not run_git(cwd, { "restore", "--source=HEAD", "--staged", "--worktree", "--", selection.value }) then
      return
    end

    vim.notify("Discarded changes to " .. display_path, vim.log.levels.INFO, { title = "Git status" })
    refresh(picker, cwd)
  end)
end

function M.attach_mappings(_, map)
  map("n", "s", stage, { desc = "Stage selected file" })
  map("n", "u", unstage, { desc = "Unstage selected file" })
  map("n", "x", discard, { desc = "Discard selected file changes" })
  return true
end

return M
