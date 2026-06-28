-- searchr/utils.lua - Shared utilities

local M = {}

-- Find project root (git root or cwd)
function M.get_project_root()
  local cwd = vim.fn.getcwd()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if vim.v.shell_error == 0 and git_root and git_root ~= "" then
    return git_root
  end
  return cwd
end

-- Parse ripgrep output line (file:line:col:text)
function M.parse_result_line(line)
  if not line or line == "" then
    return nil
  end

  -- rg --vimgrep format: file:line:col:text
  local file, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
  if file and lnum and col then
    return {
      file = file,
      lnum = tonumber(lnum),
      col = tonumber(col),
      text = text or "",
    }
  end

  -- Fallback: file:line:text (without column)
  file, lnum, text = line:match("^(.+):(%d+):(.*)$")
  if file and lnum then
    return {
      file = file,
      lnum = tonumber(lnum),
      col = 1,
      text = text or "",
    }
  end

  return nil
end

-- Escape pattern for literal search
function M.escape_pattern(str)
  return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "\\%1")
end

-- Notification wrapper
function M.notify(msg, level)
  level = level or vim.log.levels.INFO
  vim.notify(msg, level, { title = "Searchr" })
end

-- Check if command is executable
function M.is_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Get visual selection text
function M.get_visual_selection()
  local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
  local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))

  if start_row ~= end_row then
    return nil -- Multi-line not supported
  end

  local line = vim.fn.getline(start_row)
  return line:sub(start_col, end_col)
end

-- Shorten path for display
function M.shorten_path(path, max_len)
  max_len = max_len or 50
  if #path <= max_len then
    return path
  end

  local home = os.getenv("HOME")
  if home and path:sub(1, #home) == home then
    path = "~" .. path:sub(#home + 1)
  end

  if #path <= max_len then
    return path
  end

  return "..." .. path:sub(-(max_len - 3))
end

-- Debounce function
function M.debounce(fn, delay)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
    end
    timer = vim.defer_fn(function()
      fn(unpack(args))
    end, delay)
  end
end

return M
