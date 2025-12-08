local M = {}
function M.center_window(width, height)
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines
  local col = math.floor((screen_width - width) / 2)
  local row = math.floor((screen_height - height) / 2)
  return col, row
end
function M.calculate_dimensions()
  local config = require('pm.config')
  local width = math.floor(vim.o.columns * config.options.float.width)
  local height = math.floor(vim.o.lines * config.options.float.height)
  return width, height
end
return M
