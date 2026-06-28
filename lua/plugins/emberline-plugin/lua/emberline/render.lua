-- Render module for emberline
-- Builds the tabline string from buffer state
local M = {}

local nodes = require("emberline.nodes")
local state = require("emberline.state")
local config = require("emberline.config")
local layout = require("emberline.layout")
local jump = require("emberline.jump")
local highlights = require("emberline.highlights")

-- Powerline-style separator characters
local SEP_RIGHT = ""  -- U+E0B0
local SEP_RIGHT_THIN = ""  -- U+E0B1

--- Build click handler string for tabline
---@param bufnr number Buffer number
---@return string Click handler syntax
function M.build_click_handler(bufnr)
  return string.format("%%%d@v:lua.EmberlineClick@", bufnr)
end

--- Reset click handler
---@return string Reset syntax
function M.reset_click_handler()
  return "%0@v:lua.EmberlineClick@"
end

--- Get separator highlight based on adjacent buffer states
---@param left_active boolean Is left buffer active/current
---@param right_active boolean Is right buffer active/current
---@param to_fill boolean Is transitioning to fill area
---@return string Highlight group name
local function get_sep_hl(left_active, right_active, to_fill)
  if to_fill then
    return left_active and "EmberlineSepActiveToFill" or "EmberlineSepInactiveToFill"
  end
  if left_active and not right_active then
    return "EmberlineSepActiveToInactive"
  elseif not left_active and right_active then
    return "EmberlineSepInactiveToActive"
  else
    return "EmberlineSepInactiveToInactive"
  end
end

--- Render jump letter for a buffer
---@param letter string Letter to display
---@param hl string Highlight group
---@return table[] Node list
function M.render_jump_letter(letter, hl)
  return {
    nodes.create(hl, " "),
    nodes.create(hl, letter),
    nodes.create(hl, " "),
  }
end

--- Build nodes for a single buffer segment (slanted style)
---@param opts table Options
---@return table[] Node list
function M.build_buffer_segment(opts)
  local bufnr = opts.bufnr
  local name = opts.name or "[No Name]"
  local hl = opts.hl or "EmberlineInactive"
  local modified = opts.modified
  local pinned = opts.pinned
  local show_close = opts.show_close
  local close_icon = opts.close_icon or "x"
  local modified_icon = opts.modified_icon or "+"
  local pinned_icon = opts.pinned_icon or ""
  local padding = opts.padding or 1
  local clickable = opts.clickable ~= false
  local is_current = opts.is_current
  local close_hl = is_current and "EmberlineCloseCurrent" or "EmberlineClose"

  local result = {}

  -- Click handler start (if clickable)
  if clickable and bufnr then
    nodes.insert(result, nodes.raw(M.build_click_handler(bufnr)))
  end

  -- Left padding
  local pad = string.rep(" ", padding)
  nodes.insert(result, nodes.create(hl, pad))

  -- Pinned indicator
  if pinned and pinned_icon and pinned_icon ~= "" then
    nodes.insert(result, nodes.create(hl, pinned_icon .. " "))
  end

  -- Buffer name
  nodes.insert(result, nodes.create(hl, name))

  -- Modified indicator
  if modified and modified_icon and modified_icon ~= "" then
    nodes.insert(result, nodes.create(hl, " " .. modified_icon))
  end

  -- Right padding
  nodes.insert(result, nodes.create(hl, pad))

  -- Close button
  if show_close then
    nodes.insert(result, nodes.create(close_hl, close_icon .. " "))
  end

  -- Reset click handler
  if clickable and bufnr then
    nodes.insert(result, nodes.raw(M.reset_click_handler()))
  end

  return result
end

--- Generate the full tabline string
---@return string Tabline string
function M.generate_tabline()
  local cfg = config.get()
  local buffers = state.get_buffers()
  local result = {}

  -- Get current and visible buffers
  local current_buf = vim.api.nvim_get_current_buf()
  local visible_bufs = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    visible_bufs[buf] = true
  end

  -- Check if jump mode is active
  local jump_active = jump.is_active()
  if jump_active then
    jump.assign_letters(buffers)
  end

  -- Pre-calculate which buffers are current
  local buffer_states = {}
  for i, bufnr in ipairs(buffers) do
    buffer_states[i] = {
      bufnr = bufnr,
      is_current = bufnr == current_buf,
      is_visible = visible_bufs[bufnr],
    }
  end

  -- Build buffer segments with slanted separators
  for i, bufnr in ipairs(buffers) do
    local data = state.get_data(bufnr) or {}
    local name = data.name or "[No Name]"

    local is_current = buffer_states[i].is_current
    local is_visible = buffer_states[i].is_visible
    local is_modified = data.modified or vim.bo[bufnr].modified
    local is_pinned = data.pinned

    local hl = highlights.get_buffer_hl({
      current = is_current,
      visible = is_visible,
      modified = is_modified,
      pinned = is_pinned,
    })

    -- Add leading separator (slant from previous to current)
    if i == 1 then
      -- First buffer: separator from fill to this buffer
      local sep_hl = get_sep_hl(false, is_current, false)
      nodes.insert(result, nodes.create(sep_hl, SEP_RIGHT))
    else
      -- Between buffers
      local prev_current = buffer_states[i - 1].is_current
      local sep_hl = get_sep_hl(prev_current, is_current, false)
      nodes.insert(result, nodes.create(sep_hl, SEP_RIGHT))
    end

    if jump_active then
      -- Show jump letters instead of names
      local letter = jump.get_letter(bufnr)
      if letter then
        local jump_nodes = M.render_jump_letter(letter, cfg.highlights.jump)
        nodes.insert_many(result, jump_nodes)
      end
    else
      -- Normal buffer segment
      local segment = M.build_buffer_segment({
        bufnr = bufnr,
        name = name,
        hl = hl,
        modified = is_modified,
        pinned = is_pinned,
        is_current = is_current,
        show_close = cfg.icons.close and cfg.icons.close ~= "",
        close_icon = cfg.icons.close,
        modified_icon = cfg.icons.modified,
        pinned_icon = cfg.icons.pinned,
        padding = cfg.padding,
        clickable = cfg.clickable,
      })
      nodes.insert_many(result, segment)
    end
  end

  -- Add trailing separator (from last buffer to fill)
  if #buffers > 0 then
    local last_current = buffer_states[#buffers].is_current
    local sep_hl = get_sep_hl(last_current, false, true)
    nodes.insert(result, nodes.create(sep_hl, SEP_RIGHT))
  end

  -- Add fill at the end
  nodes.insert(result, nodes.raw("%#" .. cfg.highlights.fill .. "#%="))

  return nodes.to_string(result)
end

--- Main render function called by tabline
---@return string Tabline string
function M.render()
  -- Ensure highlights are set up
  highlights.setup()

  return M.generate_tabline()
end

return M
