dofile(vim.g.base46_cache .. "nvimtree")

local function on_attach(bufnr)
  local api = require "nvim-tree.api"
  local actions = require "configs.explorer_actions"

  local function map_options(description)
    return {
      desc = "nvim-tree: " .. description,
      buffer = bufnr,
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  api.map.on_attach.default(bufnr)
  vim.keymap.set({ "n", "x" }, "d", api.fs.trash, map_options "Move to trash")
  vim.keymap.set({ "n", "x" }, "D", api.fs.remove, map_options "Delete permanently")

  local function selected_path()
    local node = api.tree.get_node_under_cursor()
    return node and node.absolute_path or nil
  end

  local function close_tree()
    api.tree.close()
  end

  vim.keymap.set("n", "<leader>oa", function()
    actions.copy_absolute(selected_path())
  end, map_options "Copy absolute path")
  vim.keymap.set("n", "<leader>or", function()
    actions.copy_relative(selected_path())
  end, map_options "Copy relative path")
  vim.keymap.set("n", "<leader>os", function()
    actions.select_for_compare(selected_path())
  end, map_options "Select for compare")
  vim.keymap.set("n", "<leader>oc", function()
    actions.compare_with_selected(selected_path(), close_tree)
  end, map_options "Compare with selected")
  vim.keymap.set("n", "<leader>oh", function()
    actions.compare_with_head(selected_path(), close_tree)
  end, map_options "Compare with HEAD")

  require("which-key").add {
    { "<leader>o", group = "File Actions", buffer = bufnr },
  }
end

local function tree_width()
  return math.min(math.max(40, math.floor(vim.o.columns * 0.75)), vim.o.columns - 4)
end

local function tree_height()
  return math.min(math.max(10, math.floor(vim.o.lines * 0.8)), vim.o.lines - 4)
end

local function float_config()
  local width = tree_width()
  local height = tree_height()

  return {
    relative = "editor",
    border = "rounded",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
  }
end

return {
  on_attach = on_attach,
  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  filters = {
    dotfiles = false,
  },
  live_filter = {
    prefix = "Filter: ",
    always_show_folders = false,
  },
  trash = {
    cmd = "trash-put",
  },
  ui = {
    confirm = {
      default_yes = false,
      remove = true,
      trash = true,
    },
  },
  view = {
    width = tree_width,
    centralize_selection = true,
    preserve_window_proportions = true,
    float = {
      enable = true,
      quit_on_focus_loss = true,
      open_win_config = float_config,
    },
  },
  renderer = {
    root_folder_label = false,
    highlight_git = true,
    special_files = {
      "README",
      "README.md",
      "README.MD",
      "Dockerfile",
      "docker-compose.yml",
      "docker-compose.yaml",
      ".github",
      "data",
    },
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = {
          unstaged = "✗",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "★",
          deleted = "",
          ignored = "◌",
        },
      },
    },
  },
}
