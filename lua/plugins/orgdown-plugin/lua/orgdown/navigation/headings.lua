local M = {}
local function get_headings(bufnr)
  local ts = require("orgdown.treesitter")
  local raw_headings = ts.get_headings(bufnr)
  local headings = {}
  for _, h in ipairs(raw_headings) do
    table.insert(headings, {
      line = h.start_row + 1,
      level = h.level,
      text = h.text,
    })
  end
  return headings
end
function M.next_heading(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local headings = get_headings(bufnr)
  for _, heading in ipairs(headings) do
    if heading.line > current_line then
      vim.api.nvim_win_set_cursor(0, { heading.line, 0 })
      return true
    end
  end
  return false
end
function M.prev_heading(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local headings = get_headings(bufnr)
  for i = #headings, 1, -1 do
    local heading = headings[i]
    if heading.line < current_line then
      vim.api.nvim_win_set_cursor(0, { heading.line, 0 })
      return true
    end
  end
  return false
end
function M.get_current(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local headings = get_headings(bufnr)
  local current_heading = nil
  for _, heading in ipairs(headings) do
    if heading.line <= current_line then
      current_heading = heading
    else
      break
    end
  end
  return current_heading
end
function M.parent_heading(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local headings = get_headings(bufnr)
  local current_heading = M.get_current(bufnr)
  if not current_heading then
    return false
  end
  local target_level = current_heading.level - 1
  if target_level < 1 then
    return false
  end
  for i = #headings, 1, -1 do
    local heading = headings[i]
    if heading.line < current_line and heading.level < current_heading.level then
      vim.api.nvim_win_set_cursor(0, { heading.line, 0 })
      return true
    end
  end
  return false
end
function M.next_sibling(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local current_heading = M.get_current(bufnr)
  if not current_heading then
    return false
  end
  local headings = get_headings(bufnr)
  local found_current = false
  for _, heading in ipairs(headings) do
    if heading.line == current_heading.line then
      found_current = true
    elseif found_current then
      if heading.level < current_heading.level then
        return false
      end
      if heading.level == current_heading.level then
        vim.api.nvim_win_set_cursor(0, { heading.line, 0 })
        return true
      end
    end
  end
  return false
end
function M.prev_sibling(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local current_heading = M.get_current(bufnr)
  if not current_heading then
    return false
  end
  local headings = get_headings(bufnr)
  local prev_sibling = nil
  for _, heading in ipairs(headings) do
    if heading.line >= current_heading.line then
      break
    end
    if heading.level < current_heading.level then
      prev_sibling = nil
    elseif heading.level == current_heading.level then
      prev_sibling = heading
    end
  end
  if prev_sibling then
    vim.api.nvim_win_set_cursor(0, { prev_sibling.line, 0 })
    return true
  end
  return false
end
function M.get_hierarchy(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local headings = get_headings(bufnr)
  local hierarchy = {}
  for _, heading in ipairs(headings) do
    if heading.line > current_line then
      break
    end
    while #hierarchy > 0 and hierarchy[#hierarchy].level >= heading.level do
      table.remove(hierarchy)
    end
    table.insert(hierarchy, heading)
  end
  return hierarchy
end
function M.goto_heading(index, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local headings = get_headings(bufnr)
  if index < 1 or index > #headings then
    return false
  end
  local heading = headings[index]
  vim.api.nvim_win_set_cursor(0, { heading.line, 0 })
  return true
end
function M.count(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return #get_headings(bufnr)
end
return M
