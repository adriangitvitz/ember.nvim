local M = {}
local ui = require('pm.ui')
local config = require('pm.config')
function M.create(opts)
  opts = opts or {}
  local width, height = ui.calculate_dimensions()
  if opts.width then
    width = opts.width
  end
  if opts.height then
    height = opts.height
  end
  local col, row = ui.center_window(width, height)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = opts.border or config.options.float.border,
  }
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_win_set_option(win, 'winblend', 0)
  return buf, win
end
function M.close(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end
return M
