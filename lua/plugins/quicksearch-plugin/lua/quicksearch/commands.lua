local M = {}
local config = require("quicksearch.config")
local utils = require("quicksearch.utils")
local search = require("quicksearch.search")
local files = require("quicksearch.files")
local quickfix = require("quicksearch.quickfix")
function M.search_buffer(args)
  local pattern = args and args ~= "" and args or vim.fn.input("Search pattern: ")
  if pattern and pattern ~= "" then
    search.search_buffer(pattern)
  end
end
function M.search_project(args)
  local pattern = args and args ~= "" and args or vim.fn.input("Search pattern: ")
  if pattern and pattern ~= "" then
    search.search_project(pattern)
  end
end
function M.search_dir(args)
  local parts = vim.split(args or "", "%s+")
  local dir = parts[1]
  local pattern = table.concat(vim.list_slice(parts, 2), " ")
  if not dir or dir == "" then
    dir = vim.fn.input("Directory: ", vim.fn.getcwd(), "dir")
  end
  if not pattern or pattern == "" then
    pattern = vim.fn.input("Search pattern: ")
  end
  if dir and dir ~= "" and pattern and pattern ~= "" then
    search.search_dir(dir, pattern)
  end
end
function M.find_files(args)
  local pattern = args and args ~= "" and args or vim.fn.input("Find files: ")
  files.find_files(pattern)
end
function M.find_dirs(args)
  local pattern = args and args ~= "" and args or vim.fn.input("Find directories: ")
  files.find_dirs(pattern)
end
function M.find_all(args)
  local pattern = args and args ~= "" and args or vim.fn.input("Find: ")
  files.find_all(pattern)
end
function M.toggle_quickfix()
  quickfix.toggle()
end
function M.focus_quickfix()
  quickfix.focus()
end
function M.clear_quickfix()
  quickfix.clear()
end
function M.toggle_case()
  search.cycle_case_mode()
end
function M.toggle_hidden()
  local current = config.get().search.include_hidden
  config.set("search.include_hidden", not current)
  utils.notify("Hidden files: " .. (not current and "on" or "off"), vim.log.levels.INFO)
end
function M.toggle_regex()
  local current = config.get().search.use_regex
  config.set("search.use_regex", not current)
  utils.notify("Regex mode: " .. (not current and "on" or "off"), vim.log.levels.INFO)
end
function M.toggle_symlinks()
  local current = config.get().search.follow_symlinks
  config.set("search.follow_symlinks", not current)
  utils.notify("Follow symlinks: " .. (not current and "on" or "off"), vim.log.levels.INFO)
end
return M
