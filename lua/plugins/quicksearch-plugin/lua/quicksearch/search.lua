local M = {}
local config = require("quicksearch.config")
local utils = require("quicksearch.utils")
local quickfix = require("quicksearch.quickfix")
function M.get_case_flags(mode)
  mode = mode or config.get().search.case_mode
  if mode == "sensitive" then
    return { "--case-sensitive" }
  elseif mode == "insensitive" then
    return { "--ignore-case" }
  else
    return { "--smart-case" }
  end
end
function M.build_rg_args(pattern, opts)
  opts = opts or {}
  local args = {
    "--vimgrep",
    "--no-heading",
    "--color=never",
  }
  vim.list_extend(args, M.get_case_flags(opts.case_mode))
  if opts.include_hidden or (opts.include_hidden == nil and config.get().search.include_hidden) then
    table.insert(args, "--hidden")
  end
  if opts.follow_symlinks or (opts.follow_symlinks == nil and config.get().search.follow_symlinks) then
    table.insert(args, "--follow")
  end
  if opts.file_type or config.get().file_types.default then
    local ft = opts.file_type or config.get().file_types.default
    table.insert(args, "--type=" .. ft)
  end
  local max_count = opts.max_count or config.get().search.max_results
  if max_count then
    table.insert(args, "--max-count=" .. max_count)
  end
  if not (opts.use_regex or config.get().search.use_regex) then
    table.insert(args, "--fixed-strings")
  end
  table.insert(args, pattern)
  return args
end
function M.parse_rg_output(lines)
  local results = {}
  for _, line in ipairs(lines) do
    local filename, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
    if filename then
      table.insert(results, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
      })
    end
  end
  return results
end
function M.search_buffer(pattern, opts)
  opts = opts or {}
  if not pattern or pattern == "" then
    utils.notify("No search pattern provided", vim.log.levels.WARN)
    return
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname or bufname == "" then
    utils.notify("Current buffer has no name", vim.log.levels.WARN)
    return
  end
  local rg_path = config.get().rg_path
  if not utils.check_executable(rg_path, "Install ripgrep") then
    return
  end
  local args = M.build_rg_args(pattern, opts)
  table.insert(args, bufname)
  utils.async_exec(rg_path, args, {
    cwd = vim.fn.getcwd(),
    on_success = function(lines)
      local results = M.parse_rg_output(lines)
      if #results == 0 then
        utils.notify("No matches found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        quickfix.populate(results, {
          title = "Buffer Search: " .. pattern,
          auto_open = true,
        })
        utils.notify(string.format("Found %d matches", #results), vim.log.levels.INFO)
      end
    end,
    on_error = function(exit_code, error_msg)
      if exit_code == 1 then
        utils.notify("No matches found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        utils.notify("Search failed: " .. error_msg, vim.log.levels.ERROR)
      end
    end,
  })
end
function M.search_project(pattern, opts)
  opts = opts or {}
  if not pattern or pattern == "" then
    utils.notify("No search pattern provided", vim.log.levels.WARN)
    return
  end
  local project_config = require("quicksearch.project_config")
  local merged_config = project_config.get_merged_config()
  local original_config = config.get()
  config.current = merged_config
  local rg_path = config.get().rg_path
  if not utils.check_executable(rg_path, "Install ripgrep") then
    config.current = original_config
    return
  end
  local root = utils.get_project_root()
  local args = M.build_rg_args(pattern, opts)
  table.insert(args, root)
  utils.async_exec(rg_path, args, {
    cwd = root,
    on_success = function(lines)
      config.current = original_config
      local results = M.parse_rg_output(lines)
      if #results == 0 then
        utils.notify("No matches found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        quickfix.populate(results, {
          title = "Project Search: " .. pattern,
          auto_open = true,
        })
        utils.notify(string.format("Found %d matches", #results), vim.log.levels.INFO)
      end
    end,
    on_error = function(exit_code, error_msg)
      config.current = original_config
      if exit_code == 1 then
        utils.notify("No matches found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        utils.notify("Search failed: " .. error_msg, vim.log.levels.ERROR)
      end
    end,
  })
end
function M.search_dir(dir, pattern, opts)
  opts = opts or {}
  if not pattern or pattern == "" then
    utils.notify("No search pattern provided", vim.log.levels.WARN)
    return
  end
  if not dir or dir == "" then
    utils.notify("No directory provided", vim.log.levels.WARN)
    return
  end
  dir = vim.fn.expand(dir)
  if not utils.is_directory(dir) then
    utils.notify("Not a valid directory: " .. dir, vim.log.levels.ERROR)
    return
  end
  local rg_path = config.get().rg_path
  if not utils.check_executable(rg_path, "Install ripgrep") then
    return
  end
  local args = M.build_rg_args(pattern, opts)
  table.insert(args, dir)
  utils.async_exec(rg_path, args, {
    cwd = dir,
    on_success = function(lines)
      local results = M.parse_rg_output(lines)
      if #results == 0 then
        utils.notify("No matches found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        quickfix.populate(results, {
          title = "Directory Search (" .. dir .. "): " .. pattern,
          auto_open = true,
        })
        utils.notify(string.format("Found %d matches", #results), vim.log.levels.INFO)
      end
    end,
    on_error = function(exit_code, error_msg)
      if exit_code == 1 then
        utils.notify("No matches found for: " .. pattern, vim.log.levels.INFO)
        quickfix.clear()
      else
        utils.notify("Search failed: " .. error_msg, vim.log.levels.ERROR)
      end
    end,
  })
end
function M.cycle_case_mode()
  local modes = { "smart", "sensitive", "insensitive" }
  local current = config.get().search.case_mode
  local idx = 1
  for i, mode in ipairs(modes) do
    if mode == current then
      idx = i
      break
    end
  end
  local next_mode = modes[(idx % #modes) + 1]
  config.set("search.case_mode", next_mode)
  utils.notify("Case mode: " .. next_mode, vim.log.levels.INFO)
end
return M
