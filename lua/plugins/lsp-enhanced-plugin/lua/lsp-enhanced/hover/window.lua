local M = {}
function M.calculate_position(width, height)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1]
  local cursor_col = cursor[2]
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return { relative = 'cursor', row = 1, col = 0, width = width, height = height }
  end
  -- local editor_width = ui.width
  -- local editor_height = ui.height
  -- local win_pos = vim.api.nvim_win_get_position(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local win_width = vim.api.nvim_win_get_width(0)
  local row = 1
  local col = 0
  local space_below = win_height - cursor_row
  local space_above = cursor_row - 1
  if space_below < height and space_above > space_below then
    row = -(height + 1)
  end
  if cursor_col + width > win_width then
    col = -(width - (win_width - cursor_col))
  end
  return {
    relative = 'cursor',
    row = row,
    col = col,
    width = width,
    height = height,
  }
end
function M.show_hover(content, opts)
  opts = vim.tbl_extend('force', {
    border = 'rounded',
    focusable = true,
    max_width = 80,
    max_height = 20,
  }, opts or {})
  local buf = vim.api.nvim_create_buf(false, true)
  local lines
  if type(content) == 'string' then
    lines = vim.split(content, '\n')
  else
    lines = content
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  local win_width = vim.api.nvim_win_get_width(0)
  local width = math.min(opts.max_width, win_width - 4)
  local content_width = 0
  for _, line in ipairs(lines) do
    content_width = math.max(content_width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width, content_width + 2)
  local height = math.min(opts.max_height, #lines)
  local win_config = M.calculate_position(width, height)
  win_config.border = opts.border
  win_config.focusable = opts.focusable
  win_config.style = 'minimal'
  local ok, win = pcall(vim.api.nvim_open_win, buf, false, win_config)
  if not ok then
    return nil, nil
  end
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  if not opts.focusable then
    local current_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI', 'BufLeave'}, {
      buffer = current_buf,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end,
    })
  end
  return win, buf
end
return M
