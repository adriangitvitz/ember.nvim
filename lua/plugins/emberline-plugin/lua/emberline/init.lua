-- Emberline - A self-contained bufferline for ember.nvim
-- Inspired by barbar.nvim
local M = {}

local config = require("emberline.config")
local state = require("emberline.state")
local render = require("emberline.render")
local jump = require("emberline.jump")
local utils = require("emberline.utils")
local highlights = require("emberline.highlights")

-- Track recently closed buffers for restore
local recently_closed = {}
local MAX_RECENTLY_CLOSED = 10

--- Setup emberline
---@param user_config table|nil User configuration
function M.setup(user_config)
  config.setup(user_config)
  local cfg = config.get()

  -- Set custom jump letters if provided
  if cfg.jump_letters then
    jump.set_letters(cfg.jump_letters)
  end

  -- Setup highlights
  highlights.setup()

  -- Setup autocommands
  M.setup_autocmds()

  -- Set tabline
  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.require'emberline'.render()"

  -- Initial buffer sync
  M.sync_buffers()
end

--- Setup autocommands for buffer tracking
function M.setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("Emberline", { clear = true })

  -- Track new buffers
  vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, {
    group = augroup,
    callback = function(ev)
      if utils.is_valid_buffer(ev.buf) then
        M.add_buffer(ev.buf)
      end
    end,
  })

  -- Track buffer deletion
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = augroup,
    callback = function(ev)
      M.remove_buffer(ev.buf)
    end,
  })

  -- Clean up invalid buffers (handles netrw leaving empty buffers, etc.)
  vim.api.nvim_create_autocmd({ "BufHidden", "BufLeave" }, {
    group = augroup,
    callback = function()
      vim.schedule(function()
        M.sync_buffers()
        vim.cmd.redrawtabline()
      end)
    end,
  })

  -- Update modified state
  vim.api.nvim_create_autocmd({ "BufModifiedSet" }, {
    group = augroup,
    callback = function(ev)
      local data = state.get_data(ev.buf)
      if data then
        state.set_modified(ev.buf, vim.bo[ev.buf].modified)
        vim.cmd.redrawtabline()
      end
    end,
  })

  -- Update names when buffer is written
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    callback = function()
      M.update_names()
      vim.cmd.redrawtabline()
    end,
  })

  -- Colorscheme changes
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = function()
      highlights.setup()
    end,
  })
end

--- Sync tracked buffers with actual buffers
function M.sync_buffers()
  local current_buffers = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if utils.is_valid_buffer(bufnr) then
      current_buffers[bufnr] = true
      M.add_buffer(bufnr)
    end
  end

  -- Remove buffers that no longer exist
  for _, bufnr in ipairs(state.get_buffers()) do
    if not current_buffers[bufnr] then
      state.remove_buffer(bufnr)
    end
  end

  M.update_names()
end

--- Add a buffer to the tabline
---@param bufnr number Buffer number
function M.add_buffer(bufnr)
  if not utils.is_valid_buffer(bufnr) then
    return
  end

  state.add_buffer(bufnr)
  M.update_names()
  vim.cmd.redrawtabline()
end

--- Remove a buffer from the tabline
---@param bufnr number Buffer number
function M.remove_buffer(bufnr)
  -- Store for restore
  local data = state.get_data(bufnr)
  if data and data.name then
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path and path ~= "" then
      table.insert(recently_closed, 1, path)
      if #recently_closed > MAX_RECENTLY_CLOSED then
        table.remove(recently_closed)
      end
    end
  end

  state.remove_buffer(bufnr)
  jump.remove_buffer(bufnr)
  vim.cmd.redrawtabline()
end

--- Update display names for all buffers
function M.update_names()
  local buffers = state.get_buffers()
  local names = {}

  -- Gather all names and paths
  for _, bufnr in ipairs(buffers) do
    local path = vim.api.nvim_buf_get_name(bufnr)
    local name = utils.get_buffer_name(path)
    table.insert(names, { path = path, name = name })
  end

  -- Assign unique names
  for i, bufnr in ipairs(buffers) do
    local unique_name = utils.unique_name(names, i)
    local cfg = config.get()
    if cfg.max_name_length and #unique_name > cfg.max_name_length then
      unique_name = utils.truncate(unique_name, cfg.max_name_length)
    end
    state.set_name(bufnr, unique_name)
  end
end

--- Main render function (called by tabline)
---@return string Tabline string
function M.render()
  return render.render()
end

-- Public API functions

--- Go to next buffer
function M.next_buffer()
  local buffers = state.get_buffers()
  if #buffers == 0 then
    return
  end

  local current = vim.api.nvim_get_current_buf()
  local idx = state.get_index(current)

  if not idx then
    -- Not in list, go to first
    vim.api.nvim_set_current_buf(buffers[1])
  else
    local next_idx = idx + 1
    if next_idx > #buffers then
      next_idx = 1
    end
    vim.api.nvim_set_current_buf(buffers[next_idx])
  end
end

--- Go to previous buffer
function M.prev_buffer()
  local buffers = state.get_buffers()
  if #buffers == 0 then
    return
  end

  local current = vim.api.nvim_get_current_buf()
  local idx = state.get_index(current)

  if not idx then
    vim.api.nvim_set_current_buf(buffers[#buffers])
  else
    local prev_idx = idx - 1
    if prev_idx < 1 then
      prev_idx = #buffers
    end
    vim.api.nvim_set_current_buf(buffers[prev_idx])
  end
end

--- Go to buffer at position
---@param position number 1-based position
function M.goto_buffer(position)
  local bufnr = state.get_buffer_at(position)
  if bufnr then
    vim.api.nvim_set_current_buf(bufnr)
  end
end

--- Close current buffer
---@param bufnr number|nil Buffer number (defaults to current)
function M.close_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cfg = config.get()
  local buffers = state.get_buffers()
  local idx = state.get_index(bufnr)

  -- Find next buffer to focus
  local next_buf = nil
  if idx and #buffers > 1 then
    if cfg.focus_on_close == "left" then
      next_buf = buffers[idx - 1] or buffers[idx + 1]
    elseif cfg.focus_on_close == "right" then
      next_buf = buffers[idx + 1] or buffers[idx - 1]
    else -- previous
      next_buf = vim.fn.bufnr("#")
      if next_buf == bufnr or next_buf == -1 then
        next_buf = buffers[idx - 1] or buffers[idx + 1]
      end
    end
  end

  -- Switch to next buffer first
  if next_buf and vim.api.nvim_buf_is_valid(next_buf) then
    vim.api.nvim_set_current_buf(next_buf)
  end

  -- Delete the buffer
  vim.api.nvim_buf_delete(bufnr, { force = false })
end

--- Close all buffers except current
function M.close_other_buffers()
  local current = vim.api.nvim_get_current_buf()
  local buffers = vim.tbl_filter(function(b)
    return b ~= current
  end, state.get_buffers())

  for _, bufnr in ipairs(buffers) do
    local data = state.get_data(bufnr)
    if not data or not data.pinned then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
    end
  end
end

--- Move buffer left
function M.move_buffer_left()
  local current = vim.api.nvim_get_current_buf()
  state.move_buffer(current, -1)
  vim.cmd.redrawtabline()
end

--- Move buffer right
function M.move_buffer_right()
  local current = vim.api.nvim_get_current_buf()
  state.move_buffer(current, 1)
  vim.cmd.redrawtabline()
end

--- Toggle pin for current buffer
---@param bufnr number|nil Buffer number (defaults to current)
function M.toggle_pin(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  state.toggle_pin(bufnr)
  state.sort_pins_to_left()
  vim.cmd.redrawtabline()
end

--- Enter jump mode
function M.pick_buffer()
  jump.enter()
  vim.cmd.redrawtabline()

  -- Wait for keypress
  local ok, char = pcall(vim.fn.getcharstr)
  jump.exit()

  if ok and char then
    local bufnr = jump.get_buffer_for_letter(char)
    if bufnr then
      vim.api.nvim_set_current_buf(bufnr)
    end
  end

  vim.cmd.redrawtabline()
end

--- Restore most recently closed buffer
function M.restore_buffer()
  if #recently_closed == 0 then
    vim.notify("No recently closed buffers", vim.log.levels.INFO)
    return
  end

  local path = table.remove(recently_closed, 1)
  if vim.fn.filereadable(path) == 1 then
    vim.cmd.edit(path)
  else
    vim.notify("File no longer exists: " .. path, vim.log.levels.WARN)
  end
end

--- Click handler for tabline
---@param minwid number Buffer number from click handler
---@param clicks number Number of clicks
---@param button string Button pressed (l/m/r)
function M.click(minwid, clicks, button)
  local bufnr = minwid

  if button == "l" then
    -- Left click: switch to buffer
    vim.api.nvim_set_current_buf(bufnr)
  elseif button == "m" then
    -- Middle click: close buffer
    M.close_buffer(bufnr)
  end
end

-- Register click handler globally for tabline
_G.EmberlineClick = function(minwid, clicks, button, mods)
  M.click(minwid, clicks, button)
  return ""
end

return M
