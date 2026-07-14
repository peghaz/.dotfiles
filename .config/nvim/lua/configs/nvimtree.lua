return {
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
