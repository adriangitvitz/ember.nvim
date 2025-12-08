local M = {}
function M.setup(user_config)
  local config = require("quicksearch.config")
  local quickfix = require("quicksearch.quickfix")
  config.setup(user_config or {})
  quickfix.setup_keymaps()
  vim.api.nvim_set_hl(0, "QSearchDirectory", { link = "Directory", default = true })
  vim.api.nvim_set_hl(0, "QSearchMatch", { link = "Search", default = true })
end
M.search_buffer = function(pattern)
  require("quicksearch.search").search_buffer(pattern)
end
M.search_project = function(pattern)
  require("quicksearch.search").search_project(pattern)
end
M.search_dir = function(dir, pattern)
  require("quicksearch.search").search_dir(dir, pattern)
end
M.find_files = function(pattern)
  require("quicksearch.files").find_files(pattern)
end
M.find_dirs = function(pattern)
  require("quicksearch.files").find_dirs(pattern)
end
M.find_all = function(pattern)
  require("quicksearch.files").find_all(pattern)
end
M.toggle = function()
  require("quicksearch.quickfix").toggle()
end
M.focus = function()
  require("quicksearch.quickfix").focus()
end
M.clear = function()
  require("quicksearch.quickfix").clear()
end
M.toggle_case = function()
  require("quicksearch.search").cycle_case_mode()
end
M.toggle_hidden = function()
  local config = require("quicksearch.config")
  local utils = require("quicksearch.utils")
  local current = config.get().search.include_hidden
  config.set("search.include_hidden", not current)
  utils.notify("Hidden files: " .. (not current and "on" or "off"), vim.log.levels.INFO)
end
M.toggle_regex = function()
  local config = require("quicksearch.config")
  local utils = require("quicksearch.utils")
  local current = config.get().search.use_regex
  config.set("search.use_regex", not current)
  utils.notify("Regex mode: " .. (not current and "on" or "off"), vim.log.levels.INFO)
end
M.toggle_symlinks = function()
  local config = require("quicksearch.config")
  local utils = require("quicksearch.utils")
  local current = config.get().search.follow_symlinks
  config.set("search.follow_symlinks", not current)
  utils.notify("Follow symlinks: " .. (not current and "on" or "off"), vim.log.levels.INFO)
end
return M
