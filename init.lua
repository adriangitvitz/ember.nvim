local ember_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local plugins_path = ember_path .. "/lua/plugins"

local bundled_plugins = {
  "slimline-plugin",
  "autopairs-plugin",
  "lsp-enhanced-plugin",
  "miniterm-plugin",
  "pm-plugin",
  "pyeval-plugin",
  "quicksearch-plugin",
  "notelinks-plugin",
  "orgdown-plugin",
  "picker-plugin",
  "gitsigns-plugin",
  "format-plugin",
  "which-key-plugin",
  "bookmarks-plugin",
  "bento-plugin",
  "searchr-plugin",
  "render-markdown-plugin",
  "git-extras-plugin",
  "kb-plugin",
  "plenary.nvim",
  "nui.nvim",
  "nvim-web-devicons",
  "avante.nvim",
  "telescope.nvim",
  "leetcode-plugin",
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
