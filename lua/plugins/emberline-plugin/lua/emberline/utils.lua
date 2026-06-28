-- Utility functions for emberline
local M = {}

--- Get the filename from a full path
---@param path string|nil Full file path
---@return string Filename or "[No Name]"
function M.get_buffer_name(path)
  if not path or path == "" then
    return "[No Name]"
  end
  return vim.fn.fnamemodify(path, ":t")
end

--- Truncate text to fit within max_length with ellipsis
---@param text string Text to truncate
---@param max_length number Maximum display width
---@return string Truncated text
function M.truncate(text, max_length)
  if text == "" then
    return ""
  end

  local width = vim.fn.strdisplaywidth(text)
  if width <= max_length then
    return text
  end

  -- Need to truncate
  local ellipsis = "…"
  local ellipsis_width = vim.fn.strdisplaywidth(ellipsis)

  if max_length < ellipsis_width then
    -- Can't even fit ellipsis, just return empty or partial
    return ""
  end

  if max_length == ellipsis_width then
    return ellipsis
  end

  local target_width = max_length - ellipsis_width
  local result = ""
  local current_width = 0

  for char in text:gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
    local char_width = vim.fn.strdisplaywidth(char)
    if current_width + char_width > target_width then
      break
    end
    result = result .. char
    current_width = current_width + char_width
  end

  return result .. ellipsis
end

--- Generate unique name for a buffer when there are conflicts
---@param names table[] Array of { path, name } entries
---@param index number Index of the entry to make unique
---@return string Unique name
function M.unique_name(names, index)
  local entry = names[index]
  if not entry then
    return "[No Name]"
  end

  local base_name = entry.name

  -- Check if there are any conflicts
  local has_conflict = false
  for i, other in ipairs(names) do
    if i ~= index and other.name == base_name then
      has_conflict = true
      break
    end
  end

  if not has_conflict then
    return base_name
  end

  -- There are conflicts, add path components
  local path = entry.path
  local parts = vim.split(path, "/", { plain = true, trimempty = true })

  -- Start with filename, add parent directories until unique
  local depth = 1
  local unique_name = base_name

  while depth < #parts do
    -- Add parent directory
    local parent_index = #parts - depth
    if parent_index >= 1 then
      unique_name = parts[parent_index] .. "/" .. unique_name
    end

    -- Check if now unique
    local still_conflict = false
    for i, other in ipairs(names) do
      if i ~= index then
        local other_parts = vim.split(other.path, "/", { plain = true, trimempty = true })
        local other_unique = other.name
        local other_depth = 1

        while other_depth < #other_parts and other_depth <= depth do
          local other_parent_index = #other_parts - other_depth
          if other_parent_index >= 1 then
            other_unique = other_parts[other_parent_index] .. "/" .. other_unique
          end
          other_depth = other_depth + 1
        end

        if other_unique == unique_name then
          still_conflict = true
          break
        end
      end
    end

    if not still_conflict then
      break
    end

    depth = depth + 1
  end

  return unique_name
end

--- Check if a buffer is valid for display in the tabline
---@param bufnr number Buffer number
---@return boolean
function M.is_valid_buffer(bufnr)
  if not bufnr or bufnr <= 0 then
    return false
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- Must be listed
  if not vim.bo[bufnr].buflisted then
    return false
  end

  -- Skip certain buffer types
  local buftype = vim.bo[bufnr].buftype
  if buftype == "quickfix" or buftype == "nofile" or buftype == "terminal" or buftype == "prompt" then
    return false
  end

  -- Skip certain filetypes (netrw, etc.)
  local filetype = vim.bo[bufnr].filetype
  if filetype == "netrw" then
    return false
  end

  -- Skip empty unnamed buffers (no name and no content)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if line_count <= 1 then
      local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
      if first_line == "" then
        return false
      end
    end
  end

  return true
end

--- Escape text for use in tabline (escape % characters)
---@param text string Text to escape
---@return string Escaped text
function M.escape_tabline(text)
  return text:gsub("%%", "%%%%")
end

--- Create a shallow copy of a table
---@param t table Table to copy
---@return table Copy
function M.shallow_copy(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

--- Find index of element in array
---@param arr table Array to search
---@param element any Element to find
---@return number|nil Index or nil if not found
function M.index_of(arr, element)
  for i, v in ipairs(arr) do
    if v == element then
      return i
    end
  end
  return nil
end

return M
