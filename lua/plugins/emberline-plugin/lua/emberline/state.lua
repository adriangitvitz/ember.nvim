-- State management for emberline
-- Tracks buffer order, pinned state, and metadata
local M = {}

-- Internal state
local buffers = {} -- Ordered list of buffer numbers
local data_by_bufnr = {} -- Metadata indexed by buffer number

--- Reset all state (for testing)
function M.reset()
  buffers = {}
  data_by_bufnr = {}
end

--- Initialize metadata for a buffer
---@param bufnr number Buffer number
local function init_data(bufnr)
  if not data_by_bufnr[bufnr] then
    data_by_bufnr[bufnr] = {
      pinned = false,
      modified = false,
      name = "",
    }
  end
end

--- Add a buffer to the tracked list
---@param bufnr number Buffer number
function M.add_buffer(bufnr)
  -- Check if already tracked
  for _, b in ipairs(buffers) do
    if b == bufnr then
      return
    end
  end

  table.insert(buffers, bufnr)
  init_data(bufnr)
end

--- Remove a buffer from the tracked list
---@param bufnr number Buffer number
function M.remove_buffer(bufnr)
  for i, b in ipairs(buffers) do
    if b == bufnr then
      table.remove(buffers, i)
      data_by_bufnr[bufnr] = nil
      break
    end
  end
end

--- Get the ordered list of buffers
---@return number[] Buffer numbers
function M.get_buffers()
  return buffers
end

--- Move a buffer in the list
---@param bufnr number Buffer number to move
---@param direction number -1 for left, 1 for right
function M.move_buffer(bufnr, direction)
  local index = nil
  for i, b in ipairs(buffers) do
    if b == bufnr then
      index = i
      break
    end
  end

  if not index then
    return
  end

  local new_index = index + direction
  if new_index < 1 or new_index > #buffers then
    return
  end

  -- Swap
  buffers[index], buffers[new_index] = buffers[new_index], buffers[index]
end

--- Toggle pinned state for a buffer
---@param bufnr number Buffer number
function M.toggle_pin(bufnr)
  init_data(bufnr)
  data_by_bufnr[bufnr].pinned = not data_by_bufnr[bufnr].pinned
end

--- Sort buffers so pinned ones are at the left
function M.sort_pins_to_left()
  local pinned = {}
  local unpinned = {}

  for _, bufnr in ipairs(buffers) do
    local data = data_by_bufnr[bufnr]
    if data and data.pinned then
      table.insert(pinned, bufnr)
    else
      table.insert(unpinned, bufnr)
    end
  end

  -- Rebuild buffers list: pinned first, then unpinned
  buffers = {}
  for _, bufnr in ipairs(pinned) do
    table.insert(buffers, bufnr)
  end
  for _, bufnr in ipairs(unpinned) do
    table.insert(buffers, bufnr)
  end
end

--- Get metadata for a buffer
---@param bufnr number Buffer number
---@return table|nil Buffer data or nil
function M.get_data(bufnr)
  return data_by_bufnr[bufnr]
end

--- Set modified state for a buffer
---@param bufnr number Buffer number
---@param modified boolean Modified state
function M.set_modified(bufnr, modified)
  init_data(bufnr)
  data_by_bufnr[bufnr].modified = modified
end

--- Set display name for a buffer
---@param bufnr number Buffer number
---@param name string Display name
function M.set_name(bufnr, name)
  init_data(bufnr)
  data_by_bufnr[bufnr].name = name
end

--- Get the index of a buffer in the list
---@param bufnr number Buffer number
---@return number|nil Index or nil if not found
function M.get_index(bufnr)
  for i, b in ipairs(buffers) do
    if b == bufnr then
      return i
    end
  end
  return nil
end

--- Get buffer at a given position
---@param index number Position (1-based)
---@return number|nil Buffer number or nil
function M.get_buffer_at(index)
  return buffers[index]
end

--- Get count of buffers
---@return number Count
function M.count()
  return #buffers
end

--- Check if buffer is pinned
---@param bufnr number Buffer number
---@return boolean
function M.is_pinned(bufnr)
  local data = data_by_bufnr[bufnr]
  return data and data.pinned or false
end

--- Get count of pinned buffers
---@return number Count
function M.pinned_count()
  local count = 0
  for _, data in pairs(data_by_bufnr) do
    if data.pinned then
      count = count + 1
    end
  end
  return count
end

return M
