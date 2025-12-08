local ember_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local plugins_path = ember_path .. "/lua/plugins"
local bundled_plugins = {
  "slimline-plugin",
  "autopairs-plugin",
  "lsp-enhanced-plugin",
  "miniterm-plugin",
  "pm-plugin",
  "learn-plugin",
  "pyeval-plugin",
  "quicksearch-plugin",
  "notelinks-plugin",
  "telescope-pm-plugin",
  "telescope-learn-plugin",
  "orgdown-plugin",
  "picker-plugin",
  "gitsigns-plugin",
  "format-plugin",
  "diffview-plugin",
  "which-key-plugin",
  "dashboard-plugin",
  "bookmarks-plugin",
}
for _, plugin in ipairs(bundled_plugins) do
  local lua_path = plugins_path .. "/" .. plugin .. "/lua"
  package.path = lua_path .. "/?.lua;" .. lua_path .. "/?/init.lua;" .. package.path
end
if vim.loader then
  vim.loader.reset()
end
vim.g.mapleader = " "
vim.g.maplocalleader = " "
require("ember").setup()
