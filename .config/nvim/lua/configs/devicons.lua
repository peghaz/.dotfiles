local M = {}

M.override = {}

M.override_by_filename = {
  ["README"] = { icon = "󰂺", color = "#519aba", name = "Readme" },
  ["README.md"] = { icon = "󰂺", color = "#519aba", name = "Readme" },
  ["README.MD"] = { icon = "󰂺", color = "#519aba", name = "Readme" },
  ["README.txt"] = { icon = "󰂺", color = "#519aba", name = "Readme" },
  ["Dockerfile"] = { icon = "󰡨", color = "#458ee6", name = "Dockerfile" },
  ["docker-compose.yml"] = { icon = "󰡨", color = "#458ee6", name = "DockerCompose" },
  ["docker-compose.yaml"] = { icon = "󰡨", color = "#458ee6", name = "DockerCompose" },
  ["compose.yml"] = { icon = "󰡨", color = "#458ee6", name = "DockerCompose" },
  ["compose.yaml"] = { icon = "󰡨", color = "#458ee6", name = "DockerCompose" },
  [".github"] = { icon = "", color = "#f1502f", name = "GithubDir" },
  ["data"] = { icon = "󰆼", color = "#e0af68", name = "DataDir" },
}

M.override_by_extension = {
  md = { icon = "󰍔", color = "#519aba", name = "Markdown" },
  markdown = { icon = "󰍔", color = "#519aba", name = "Markdown" },
  toml = { icon = "󰕲", color = "#6d8086", name = "Toml" },
  yaml = { icon = "󰈙", color = "#6d8086", name = "Yaml" },
  yml = { icon = "󰈙", color = "#6d8086", name = "Yaml" },
  json = { icon = "󰘦", color = "#cbcb41", name = "Json" },
  jsonc = { icon = "󰘦", color = "#cbcb41", name = "Json" },
}

return M
