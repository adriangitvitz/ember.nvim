local M = {}
local config = require("quicksearch.config")
local utils = require("quicksearch.utils")
local quickfix = require("quicksearch.quickfix")
function M.build_fd_args(pattern, opts)
  opts = opts or {}
  local args = {}
  if pattern and pattern ~= "" then
    table.insert(args, pattern)
  end
  if opts.type == "file" then
    table.insert(args, "--type=f")
  elseif opts.type == "directory" then
    table.insert(args, "--type=d")
  elseif opts.type == "both" then
  end
  if opts.include_hidden or (opts.include_hidden == nil and config.get().search.include_hidden) then
    table.insert(args, "--hidden")
  end
  if opts.follow_symlinks or (opts.follow_symlinks == nil and config.get().search.follow_symlinks) then
    table.insert(args, "--follow")
  end
  if opts.no_ignore then
    table.insert(args, "--no-ignore")
  end
  table.insert(args, "--absolute-path")
  local max_results = opts.max_results or config.get().search.max_results
  if max_results then
    table.insert(args, "--max-results=" .. max_results)
  end
  return args
end
function M.parse_fd_output(lines)
  local results = {}
  for _, filepath in ipairs(lines) do
    if filepath and filepath ~= "" then
      local is_dir = utils.is_directory(filepath)
      local display_name = vim.fn.fnamemodify(filepath, ":t")
      table.insert(results, {
        filename = filepath,
        lnum = 1,
        col = 1,
        text = is_dir and "[DIR] " .. display_name or display_name,
        type = "I",
      })
    end
  end
  return results
end
function M.find_files(pattern, opts)
  opts = opts or {}
  opts.type = "file"
  if not pattern or pattern == "" then
    pattern = "."
  end
  local fd_path = config.get().fd_path
  if not utils.check_executable(fd_path, "Install fd: https://github.com/sharkdp/fd") then
    return
  end
  local root = utils.get_project_root()
  local args = M.build_fd_args(pattern, opts)
  utils.async_exec(fd_path, args, {
    cwd = root,
    on_success = function(lines)
      local results = M.parse_fd_output(lines)
      if #results == 0 then
        utils.notify("No files found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        quickfix.populate(results, {
          title = "Find Files: " .. pattern,
          auto_open = true,
        })
        utils.notify(string.format("Found %d files", #results), vim.log.levels.INFO)
      end
    end,
    on_error = function(exit_code, error_msg)
      if exit_code == 1 then
        utils.notify("No files found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        utils.notify("Find failed: " .. error_msg, vim.log.levels.ERROR)
      end
    end,
  })
end
function M.find_dirs(pattern, opts)
  opts = opts or {}
  opts.type = "directory"
  if not pattern or pattern == "" then
    pattern = "."
  end
  local fd_path = config.get().fd_path
  if not utils.check_executable(fd_path, "Install fd: https://github.com/sharkdp/fd") then
    return
  end
  local root = utils.get_project_root()
  local args = M.build_fd_args(pattern, opts)
  utils.async_exec(fd_path, args, {
    cwd = root,
    on_success = function(lines)
      local results = M.parse_fd_output(lines)
      if #results == 0 then
        utils.notify("No directories found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        quickfix.populate(results, {
          title = "Find Directories: " .. pattern,
          auto_open = true,
        })
        utils.notify(string.format("Found %d directories", #results), vim.log.levels.INFO)
      end
    end,
    on_error = function(exit_code, error_msg)
      if exit_code == 1 then
        utils.notify("No directories found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        utils.notify("Find failed: " .. error_msg, vim.log.levels.ERROR)
      end
    end,
  })
end
function M.find_all(pattern, opts)
  opts = opts or {}
  opts.type = "both"
  if not pattern or pattern == "" then
    pattern = "."
  end
  local fd_path = config.get().fd_path
  if not utils.check_executable(fd_path, "Install fd: https://github.com/sharkdp/fd") then
    return
  end
  local root = utils.get_project_root()
  local args = M.build_fd_args(pattern, opts)
  utils.async_exec(fd_path, args, {
    cwd = root,
    on_success = function(lines)
      local results = M.parse_fd_output(lines)
      if #results == 0 then
        utils.notify("No files or directories found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        quickfix.populate(results, {
          title = "Find: " .. pattern,
          auto_open = true,
        })
        utils.notify(string.format("Found %d items", #results), vim.log.levels.INFO)
      end
    end,
    on_error = function(exit_code, error_msg)
      if exit_code == 1 then
        utils.notify("No files or directories found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        utils.notify("Find failed: " .. error_msg, vim.log.levels.ERROR)
      end
    end,
  })
end
return M
