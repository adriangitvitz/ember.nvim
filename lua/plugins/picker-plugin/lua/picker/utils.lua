local M = {}
function M.notify(message, level)
  local config = require("picker.config")
  if config.get().notifications.enabled then
    vim.notify("[picker] " .. message, level or vim.log.levels.INFO)
  end
end
function M.is_executable(cmd)
  return vim.fn.executable(cmd) == 1
end
function M.check_executable(cmd, install_hint)
  if not M.is_executable(cmd) then
    local msg = string.format("'%s' is not installed or not in PATH", cmd)
    if install_hint then
      msg = msg .. "\n" .. install_hint
    end
    M.notify(msg, vim.log.levels.ERROR)
    return false
  end
  return true
end
function M.get_project_root()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root and git_root ~= "" then
    return git_root
  end
  return vim.fn.getcwd()
end
function M.is_directory(path)
  return vim.fn.isdirectory(path) == 1
end
function M.escape_pattern(str)
  return str:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end
function M.get_visual_selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" then
    return nil
  end
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]
  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return nil
  end
  if #lines == 1 then
    return lines[1]:sub(start_col, end_col)
  else
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
    return table.concat(lines, "\n")
  end
end
function M.get_word_under_cursor()
  return vim.fn.expand("<cword>")
end
function M.strip_ansi(str)
  if not str then return str end
  return str:gsub("\027%[[%d;]*m", "")
end
function M.relative_path(full_path, root)
  root = root or M.get_project_root()
  if full_path:sub(1, #root) == root then
    local rel = full_path:sub(#root + 2)
    return rel ~= "" and rel or full_path
  end
  return full_path
end
function M.tbl_filter(tbl, fn)
  local result = {}
  for _, v in ipairs(tbl) do
    if fn(v) then
      table.insert(result, v)
    end
  end
  return result
end
return M
