-- Node-based rendering system for emberline
-- Each node is { hl = "HighlightGroup", text = "content" }
local M = {}

--- Create a new node
---@param hl string|nil Highlight group name
---@param text string Text content
---@param raw boolean|nil If true, don't escape % characters
---@return table Node
function M.create(hl, text, raw)
  return {
    hl = hl or "",
    text = text or "",
    raw = raw or false,
  }
end

--- Create a raw node (for tabline format strings like click handlers)
---@param text string Raw format string
---@return table Node
function M.raw(text)
  return {
    hl = "",
    text = text or "",
    raw = true,
  }
end

--- Calculate display width of a single node
---@param node table Node
---@return number Width in cells
function M.width(node)
  return vim.fn.strdisplaywidth(node.text)
end

--- Calculate total width of a node list
---@param list table[] List of nodes
---@return number Total width in cells
function M.list_width(list)
  local total = 0
  for _, node in ipairs(list) do
    total = total + M.width(node)
  end
  return total
end

--- Insert a node at the end of a list
---@param list table[] Node list
---@param node table Node to insert
function M.insert(list, node)
  table.insert(list, node)
end

--- Insert multiple nodes at the end of a list
---@param list table[] Node list
---@param new_nodes table[] Nodes to insert
function M.insert_many(list, new_nodes)
  for _, node in ipairs(new_nodes) do
    table.insert(list, node)
  end
end

--- Convert node list to tabline string
---@param list table[] Node list
---@return string Tabline syntax string
function M.to_string(list)
  if #list == 0 then
    return ""
  end

  local parts = {}
  for _, node in ipairs(list) do
    if node.raw then
      -- Raw nodes are inserted as-is (for click handlers, etc.)
      table.insert(parts, node.text)
    else
      local text = node.text:gsub("%%", "%%%%") -- Escape percent signs
      if node.hl and node.hl ~= "" then
        table.insert(parts, string.format("%%#%s#%s", node.hl, text))
      else
        table.insert(parts, text)
      end
    end
  end
  return table.concat(parts)
end

--- Slice nodes from left, keeping up to max_width
---@param list table[] Node list
---@param max_width number Maximum width to keep
---@return table[] Sliced node list
function M.slice_left(list, max_width)
  if max_width <= 0 then
    return {}
  end

  local result = {}
  local current_width = 0

  for _, node in ipairs(list) do
    local node_width = M.width(node)
    if current_width + node_width <= max_width then
      -- Whole node fits
      table.insert(result, node)
      current_width = current_width + node_width
    else
      -- Partial node needed
      local remaining = max_width - current_width
      if remaining > 0 then
        -- Truncate the text to fit
        local truncated = M.truncate_text(node.text, remaining)
        if truncated ~= "" then
          table.insert(result, M.create(node.hl, truncated))
        end
      end
      break
    end
  end

  return result
end

--- Slice nodes from right, keeping up to max_width from the end
---@param list table[] Node list
---@param max_width number Maximum width to keep
---@return table[] Sliced node list
function M.slice_right(list, max_width)
  if max_width <= 0 then
    return {}
  end

  local total_width = M.list_width(list)
  if total_width <= max_width then
    return list
  end

  local result = {}
  local skip_width = total_width - max_width
  local skipped = 0

  for _, node in ipairs(list) do
    local node_width = M.width(node)

    if skipped >= skip_width then
      -- Past the skip zone, include whole node
      table.insert(result, node)
    elseif skipped + node_width > skip_width then
      -- This node is partially in skip zone
      local chars_to_skip = skip_width - skipped
      local truncated = M.skip_chars(node.text, chars_to_skip)
      if truncated ~= "" then
        table.insert(result, M.create(node.hl, truncated))
      end
      skipped = skip_width
    else
      -- Whole node is in skip zone
      skipped = skipped + node_width
    end
  end

  return result
end

--- Truncate text to fit within max_width display columns
---@param text string Text to truncate
---@param max_width number Maximum display width
---@return string Truncated text
function M.truncate_text(text, max_width)
  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end

  local result = ""
  local width = 0

  for char in text:gmatch(".") do
    local char_width = vim.fn.strdisplaywidth(char)
    if width + char_width > max_width then
      break
    end
    result = result .. char
    width = width + char_width
  end

  return result
end

--- Skip characters from the beginning of text
---@param text string Text
---@param skip_width number Number of display columns to skip
---@return string Remaining text
function M.skip_chars(text, skip_width)
  local skipped = 0
  local result_start = 1

  for i = 1, #text do
    local char = text:sub(i, i)
    local char_width = vim.fn.strdisplaywidth(char)
    if skipped >= skip_width then
      result_start = i
      break
    end
    skipped = skipped + char_width
    result_start = i + 1
  end

  return text:sub(result_start)
end

return M
