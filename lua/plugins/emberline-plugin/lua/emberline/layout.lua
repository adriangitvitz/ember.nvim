-- Layout calculations for emberline
-- Handles width calculations, scrolling, and visible range
local M = {}

--- Calculate layout information
---@param opts table Options
---@return table Layout data
function M.calculate(opts)
  local total_width = opts.total_width or vim.o.columns
  local buffer_widths = opts.buffer_widths or {}
  local pinned_count = opts.pinned_count or 0
  local left_offset = opts.left_offset or 0
  local right_offset = opts.right_offset or 0

  local available_width = total_width - left_offset - right_offset

  -- Calculate total buffer width
  local total_buffer_width = 0
  for _, w in ipairs(buffer_widths) do
    total_buffer_width = total_buffer_width + w
  end

  -- Calculate pinned vs unpinned width
  local pinned_width = 0
  local unpinned_width = 0
  for i, w in ipairs(buffer_widths) do
    if i <= pinned_count then
      pinned_width = pinned_width + w
    else
      unpinned_width = unpinned_width + w
    end
  end

  local overflow = total_buffer_width > available_width

  return {
    total_width = total_width,
    available_width = available_width,
    left_offset = left_offset,
    right_offset = right_offset,
    total_buffer_width = total_buffer_width,
    pinned_width = pinned_width,
    unpinned_width = unpinned_width,
    pinned_count = pinned_count,
    overflow = overflow,
    buffer_widths = buffer_widths,
  }
end

--- Get maximum scroll offset
---@param opts table Layout data with available_width and total_buffer_width
---@return number Maximum scroll offset
function M.get_scroll_max(opts)
  local available = opts.available_width or 0
  local total = opts.total_buffer_width or 0

  if total <= available then
    return 0
  end

  return total - available
end

--- Get visible buffer range based on scroll
---@param opts table Options with buffer_widths, available_width, scroll_offset
---@return number, number Start index, end index (1-based)
function M.get_visible_range(opts)
  local buffer_widths = opts.buffer_widths or {}
  local available_width = opts.available_width or 0
  local scroll_offset = opts.scroll_offset or 0

  if #buffer_widths == 0 or available_width <= 0 then
    return 1, 0 -- Empty range
  end

  local start_idx = 1
  local end_idx = #buffer_widths
  local accumulated_width = 0

  -- Find start index based on scroll offset
  for i, w in ipairs(buffer_widths) do
    if accumulated_width + w > scroll_offset then
      start_idx = i
      break
    end
    accumulated_width = accumulated_width + w
  end

  -- Find end index based on available width
  local visible_width = 0
  -- Adjust for partial first buffer if scrolled into it
  local first_buffer_offset = scroll_offset - (accumulated_width)
  if first_buffer_offset > 0 and start_idx <= #buffer_widths then
    visible_width = -first_buffer_offset
  end

  for i = start_idx, #buffer_widths do
    visible_width = visible_width + buffer_widths[i]
    if visible_width > available_width then
      end_idx = i
      break
    end
    end_idx = i
  end

  return start_idx, end_idx
end

--- Calculate width needed for a single buffer
---@param opts table Options
---@return number Width in columns
function M.calculate_buffer_width(opts)
  local name = opts.name or ""
  local padding = opts.padding or 1
  local show_close = opts.show_close
  local close_width = opts.close_width or 0
  local separator_width = opts.separator_width or 0

  local name_width = vim.fn.strdisplaywidth(name)
  local width = name_width + (padding * 2)

  if show_close then
    width = width + close_width
  end

  width = width + separator_width

  return width
end

--- Calculate scroll offset to ensure buffer is visible
---@param opts table Options
---@return number New scroll offset
function M.scroll_to_buffer(opts)
  local buffer_widths = opts.buffer_widths or {}
  local buffer_index = opts.buffer_index or 1
  local available_width = opts.available_width or 0
  local current_scroll = opts.current_scroll or 0
  local pinned_count = opts.pinned_count or 0

  -- Pinned buffers are always visible
  if buffer_index <= pinned_count then
    return current_scroll
  end

  -- Calculate buffer position
  local buffer_start = 0
  for i = 1, buffer_index - 1 do
    if i > pinned_count then
      buffer_start = buffer_start + (buffer_widths[i] or 0)
    end
  end
  local buffer_end = buffer_start + (buffer_widths[buffer_index] or 0)

  -- Calculate pinned width
  local pinned_width = 0
  for i = 1, pinned_count do
    pinned_width = pinned_width + (buffer_widths[i] or 0)
  end

  local unpinned_available = available_width - pinned_width

  -- Adjust scroll if buffer is out of view
  if buffer_start < current_scroll then
    return buffer_start
  elseif buffer_end > current_scroll + unpinned_available then
    return buffer_end - unpinned_available
  end

  return current_scroll
end

--- Get sidebar offset for a given side
---@param side string "left" or "right"
---@param sidebar_filetypes string[] Filetypes to check
---@return number Offset width
function M.get_sidebar_offset(side, sidebar_filetypes)
  sidebar_filetypes = sidebar_filetypes or {}

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local config = vim.api.nvim_win_get_config(win)

    -- Skip floating windows
    if config.relative == "" then
      for _, sidebar_ft in ipairs(sidebar_filetypes) do
        if ft == sidebar_ft then
          local pos = vim.api.nvim_win_get_position(win)
          local width = vim.api.nvim_win_get_width(win)

          if side == "left" and pos[2] == 0 then
            return width
          elseif side == "right" then
            local total_width = vim.o.columns
            if pos[2] + width >= total_width - 1 then
              return width
            end
          end
        end
      end
    end
  end

  return 0
end

return M
