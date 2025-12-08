local M = {}
local window_utils = require("orgdown.utils.window")
local buffer_utils = require("orgdown.utils.buffer")
local state = {
  winnr = nil,
  bufnr = nil,
  source_bufnr = nil,
  mode = nil,
}
function M.get_state()
  return vim.deepcopy(state)
end
function M.is_open()
  return state.winnr and vim.api.nvim_win_is_valid(state.winnr)
end
function M.get_winnr()
  if M.is_open() then
    return state.winnr
  end
  return nil
end
function M.get_bufnr()
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    return state.bufnr
  end
  return nil
end
function M.get_source_bufnr()
  return state.source_bufnr
end
local function create_preview_buffer()
  local bufnr = buffer_utils.create_scratch_buffer({
    filetype = "orgdown_preview",
    name = "Orgdown Preview",
  })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  return bufnr
end
function M.open(opts)
  opts = opts or {}
  local mode = opts.mode or "float"
  local position = opts.position or "right"
  local width = opts.width or 0.5
  local height = opts.height or 0.8
  local border = opts.border or "rounded"
  local bufnr = state.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = create_preview_buffer()
  end
  if M.is_open() then
    M.close()
  end
  local winnr
  if mode == "float" then
    winnr, _ = window_utils.open_float({
      bufnr = bufnr,
      width = width,
      height = height,
      border = border,
      title = " Preview ",
      position = "center",
    })
  elseif mode == "split" then
    local direction
    if position == "right" then
      direction = "right"
    elseif position == "left" then
      direction = "left"
    elseif position == "top" then
      direction = "above"
    elseif position == "bottom" then
      direction = "below"
    else
      direction = "right"
    end
    local size
    if direction == "right" or direction == "left" then
      size = width <= 1 and math.floor(vim.o.columns * width) or width
    else
      size = height <= 1 and math.floor(vim.o.lines * height) or height
    end
    winnr = window_utils.open_split({
      bufnr = bufnr,
      direction = direction,
      size = size,
    })
  elseif mode == "tab" then
    vim.cmd("tabnew")
    winnr = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(winnr, bufnr)
  else
    winnr, _ = window_utils.open_float({
      bufnr = bufnr,
      width = width,
      height = height,
      border = border,
    })
  end
  vim.api.nvim_win_set_option(winnr, "wrap", true)
  vim.api.nvim_win_set_option(winnr, "linebreak", true)
  vim.api.nvim_win_set_option(winnr, "cursorline", false)
  vim.api.nvim_win_set_option(winnr, "number", false)
  vim.api.nvim_win_set_option(winnr, "relativenumber", false)
  vim.api.nvim_win_set_option(winnr, "signcolumn", "no")
  vim.api.nvim_win_set_option(winnr, "foldcolumn", "0")
  state.winnr = winnr
  state.bufnr = bufnr
  state.mode = mode
  return winnr, bufnr
end
function M.close()
  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    pcall(vim.api.nvim_win_close, state.winnr, true)
  end
  state.winnr = nil
  state.source_bufnr = nil
end
function M.toggle(opts)
  if M.is_open() then
    M.close()
    return false
  else
    M.open(opts)
    return true
  end
end
function M.set_source(bufnr)
  state.source_bufnr = bufnr
end
function M.resize(width, height)
  if not M.is_open() then
    return
  end
  window_utils.resize(state.winnr, width, height)
end
function M.sync_scroll(source_winnr, source_line)
  if not M.is_open() then
    return
  end
  local bufnr = state.bufnr
  if not bufnr then
    return
  end
  local line_map = vim.b[bufnr].orgdown_line_map
  if not line_map then
    return
  end
  local preview_line = line_map[source_line]
  if type(preview_line) ~= "number" then
    preview_line = nil
  end
  if not preview_line then
    local nearest_source = 0
    local nearest_preview = 1
    for src, prv in pairs(line_map) do
      if type(src) == "number" and type(prv) == "number" then
        if src <= source_line and src > nearest_source then
          nearest_source = src
          nearest_preview = prv
        end
      end
    end
    preview_line = nearest_preview
  end
  local preview_line_count = vim.api.nvim_buf_line_count(bufnr)
  preview_line = math.max(1, math.min(preview_line, preview_line_count))
  pcall(vim.api.nvim_win_set_cursor, state.winnr, { preview_line, 0 })
end
function M.focus()
  if M.is_open() then
    vim.api.nvim_set_current_win(state.winnr)
  end
end
function M.focus_source()
  local source_bufnr = state.source_bufnr
  if not source_bufnr then
    return
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == source_bufnr then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end
return M
