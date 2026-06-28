-- Jump mode for emberline
-- Assigns letters to buffers for quick switching
local M = {}

-- Default letters (home row first, then others)
local DEFAULT_LETTERS = "asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP1234567890"

-- State
local active = false
local buffer_to_letter = {} -- bufnr -> letter
local letter_to_buffer = {} -- letter -> bufnr
local available_letters = {} -- Letters not yet assigned

--- Reset jump state
function M.reset()
  active = false
  buffer_to_letter = {}
  letter_to_buffer = {}
  available_letters = {}

  -- Initialize available letters
  for i = 1, #DEFAULT_LETTERS do
    local letter = DEFAULT_LETTERS:sub(i, i)
    table.insert(available_letters, letter)
  end
end

-- Initialize on load
M.reset()

--- Get the next available letter
---@return string|nil Letter or nil if none available
local function get_next_letter()
  if #available_letters == 0 then
    return nil
  end
  return table.remove(available_letters, 1)
end

--- Assign letters to a list of buffers
--- Maintains stable assignments for existing buffers
---@param buffers number[] List of buffer numbers
---@return string[] List of letters in same order as buffers
function M.assign_letters(buffers)
  local result = {}

  for _, bufnr in ipairs(buffers) do
    -- Check if buffer already has a letter
    local existing = buffer_to_letter[bufnr]
    if existing then
      table.insert(result, existing)
    else
      -- Assign new letter
      local letter = get_next_letter()
      if letter then
        buffer_to_letter[bufnr] = letter
        letter_to_buffer[letter] = bufnr
        table.insert(result, letter)
      else
        -- No more letters available, use empty string
        table.insert(result, "")
      end
    end
  end

  return result
end

--- Get the letter assigned to a buffer
---@param bufnr number Buffer number
---@return string|nil Letter or nil
function M.get_letter(bufnr)
  return buffer_to_letter[bufnr]
end

--- Get the buffer assigned to a letter
---@param letter string Letter
---@return number|nil Buffer number or nil
function M.get_buffer_for_letter(letter)
  return letter_to_buffer[letter]
end

--- Check if jump mode is active
---@return boolean
function M.is_active()
  return active
end

--- Enter jump mode
function M.enter()
  active = true
end

--- Exit jump mode
function M.exit()
  active = false
end

--- Toggle jump mode
function M.toggle()
  if active then
    M.exit()
  else
    M.enter()
  end
end

--- Remove letter assignment for a buffer
---@param bufnr number Buffer number
function M.remove_buffer(bufnr)
  local letter = buffer_to_letter[bufnr]
  if letter then
    buffer_to_letter[bufnr] = nil
    letter_to_buffer[letter] = nil
    -- Don't return letter to pool to maintain stability
  end
end

--- Set custom letters string
---@param letters string String of letters to use
function M.set_letters(letters)
  DEFAULT_LETTERS = letters
  -- Re-initialize available letters (preserving existing assignments)
  available_letters = {}
  for i = 1, #letters do
    local letter = letters:sub(i, i)
    -- Only add if not already assigned
    if not letter_to_buffer[letter] then
      table.insert(available_letters, letter)
    end
  end
end

return M
