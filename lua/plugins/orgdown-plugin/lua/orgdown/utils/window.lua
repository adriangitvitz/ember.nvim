local M = {}
function M.calculate_float_position(opts)
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight - 1
  local width = opts.width
  local height = opts.height
  if width <= 1 then
    width = math.floor(editor_width * width)
  end
  if height <= 1 then
    height = math.floor(editor_height * height)
  end
  local position = opts.position or "center"
  if position == "center" then
    local row = math.floor((editor_height - height) / 2)
    local col = math.floor((editor_width - width) / 2)
    return math.max(0, row), math.max(0, col)
  elseif position == "top-left" then
    return 0, 0
  elseif position == "top-right" then
    return 0, editor_width - width
  elseif position == "bottom-left" then
    return editor_height - height, 0
  elseif position == "bottom-right" then
    return editor_height - height, editor_width - width
  else
    local row = math.floor((editor_height - height) / 2)
    local col = math.floor((editor_width - width) / 2)
    return math.max(0, row), math.max(0, col)
  end
end
function M.open_float(opts)
  opts = opts or {}
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight - 1
  local width = opts.width or 80
  local height = opts.height or 24
  if width <= 1 then
    width = math.floor(editor_width * width)
  end
  if height <= 1 then
    height = math.floor(editor_height * height)
  end
  local row, col = M.calculate_float_position({
    width = width,
    height = height,
    position = opts.position,
  })
  local bufnr = opts.bufnr
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  end
  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "none",
    focusable = opts.focusable ~= false,
  }
  if opts.title then
    win_config.title = opts.title
    win_config.title_pos = "center"
  end
  local winnr = vim.api.nvim_open_win(bufnr, true, win_config)
  vim.api.nvim_win_set_option(winnr, "wrap", false)
  vim.api.nvim_win_set_option(winnr, "cursorline", false)
  return winnr, bufnr
end
function M.open_split(opts)
  opts = opts or {}
  local direction = opts.direction or "right"
  local current_win = vim.api.nvim_get_current_win()
  local cmd
  if direction == "right" then
    cmd = "vsplit"
  elseif direction == "left" then
    cmd = "leftabove vsplit"
  elseif direction == "below" then
    cmd = "split"
  elseif direction == "above" then
    cmd = "leftabove split"
  else
    cmd = "vsplit"
  end
  local bufnr = opts.bufnr
  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
  end
  vim.cmd(cmd)
  local winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winnr, bufnr)
  if opts.size then
    if direction == "right" or direction == "left" then
      vim.api.nvim_win_set_width(winnr, opts.size)
    else
      vim.api.nvim_win_set_height(winnr, opts.size)
    end
  end
  return winnr
end
function M.close(winnr)
  if winnr and vim.api.nvim_win_is_valid(winnr) then
    pcall(vim.api.nvim_win_close, winnr, true)
  end
end
function M.is_valid(winnr)
  return winnr and vim.api.nvim_win_is_valid(winnr)
end
function M.is_floating(winnr)
  if not M.is_valid(winnr) then
    return false
  end
  local config = vim.api.nvim_win_get_config(winnr)
  return config.relative ~= ""
end
function M.get_dimensions(winnr)
  return vim.api.nvim_win_get_width(winnr), vim.api.nvim_win_get_height(winnr)
end
function M.get_position(winnr)
  local config = vim.api.nvim_win_get_config(winnr)
  return config.row, config.col
end
function M.focus(winnr)
  if M.is_valid(winnr) then
    vim.api.nvim_set_current_win(winnr)
  end
end
function M.set_option(winnr, option, value)
  if M.is_valid(winnr) then
    vim.api.nvim_win_set_option(winnr, option, value)
  end
end
function M.get_option(winnr, option)
  if M.is_valid(winnr) then
    return vim.api.nvim_win_get_option(winnr, option)
  end
  return nil
end
function M.resize(winnr, width, height)
  if not M.is_valid(winnr) then
    return
  end
  if width then
    vim.api.nvim_win_set_width(winnr, width)
  end
  if height then
    vim.api.nvim_win_set_height(winnr, height)
  end
end
function M.calculate_split_size(percentage, direction)
  if direction == "vertical" then
    return math.floor(vim.o.columns * percentage)
  else
    return math.floor((vim.o.lines - vim.o.cmdheight) * percentage)
  end
end
return M
