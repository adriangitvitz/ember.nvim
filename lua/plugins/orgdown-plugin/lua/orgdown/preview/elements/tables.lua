local M = {}
local box = {
  top_left = "┌",
  top_right = "┐",
  bottom_left = "└",
  bottom_right = "┘",
  horizontal = "─",
  vertical = "│",
  cross = "┼",
  top_tee = "┬",
  bottom_tee = "┴",
  left_tee = "├",
  right_tee = "┤",
}
function M.is_table_row(line)
  return line:match("^%s*|") ~= nil
end
function M.is_separator_row(line)
  return line:match("^%s*|[-%s:|]+|%s*$") ~= nil
end
function M.parse_alignment(line)
  local alignments = {}
  for cell in line:gmatch("|([^|]+)") do
    cell = cell:match("^%s*(.-)%s*$")
    if cell:match("^:.*:$") then
      table.insert(alignments, "center")
    elseif cell:match(":$") then
      table.insert(alignments, "right")
    else
      table.insert(alignments, "left")
    end
  end
  return alignments
end
function M.parse_cells(line)
  local cells = {}
  for cell in line:gmatch("|([^|]*)") do
    cell = cell:match("^%s*(.-)%s*$") or ""
    table.insert(cells, cell)
  end
  if #cells > 0 and cells[#cells] == "" then
    table.remove(cells)
  end
  return cells
end
function M.calculate_widths(rows)
  local widths = {}
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row) do
      widths[i] = math.max(widths[i] or 0, vim.fn.strdisplaywidth(cell))
    end
  end
  return widths
end
function M.pad_cell(content, width, alignment)
  local content_width = vim.fn.strdisplaywidth(content)
  local padding = width - content_width
  if padding <= 0 then
    return content
  end
  if alignment == "right" then
    return string.rep(" ", padding) .. content
  elseif alignment == "center" then
    local left = math.floor(padding / 2)
    local right = padding - left
    return string.rep(" ", left) .. content .. string.rep(" ", right)
  else
    return content .. string.rep(" ", padding)
  end
end
function M.render_border(widths, left_char, mid_char, right_char)
  local parts = {}
  for _, width in ipairs(widths) do
    table.insert(parts, string.rep(box.horizontal, width + 2))
  end
  return left_char .. table.concat(parts, mid_char) .. right_char
end
function M.render_data_row(cells, widths, alignments)
  local parts = {}
  for i, cell in ipairs(cells) do
    local width = widths[i] or 0
    local alignment = alignments[i] or "left"
    local padded = M.pad_cell(cell, width, alignment)
    table.insert(parts, " " .. padded .. " ")
  end
  return box.vertical .. table.concat(parts, box.vertical) .. box.vertical
end
function M.render_table(lines, start_line)
  local rendered = {}
  local extmarks = {}
  local table_rows = {}
  local alignments = {}
  local separator_index = nil
  local end_line = start_line
  for i = start_line + 1, #lines do
    local line = lines[i]
    if not M.is_table_row(line) then
      end_line = i - 2
      break
    end
    if M.is_separator_row(line) then
      separator_index = #table_rows + 1
      alignments = M.parse_alignment(line)
    else
      table.insert(table_rows, M.parse_cells(line))
    end
    end_line = i - 1
  end
  local widths = M.calculate_widths(table_rows)
  if #alignments == 0 then
    for i = 1, #widths do
      alignments[i] = "left"
    end
  end
  local line_offset = 0
  table.insert(rendered, M.render_border(widths, box.top_left, box.top_tee, box.top_right))
  table.insert(extmarks, {
    line = start_line + line_offset,
    col = 0,
    opts = { hl_group = "OrgdownTableBorder" },
  })
  line_offset = line_offset + 1
  for i, row in ipairs(table_rows) do
    local row_line = M.render_data_row(row, widths, alignments)
    table.insert(rendered, row_line)
    if i == 1 and separator_index == 2 then
      table.insert(extmarks, {
        line = start_line + line_offset,
        col = 0,
        opts = {
          end_col = #row_line,
          hl_group = "OrgdownTableHeader",
        },
      })
    end
    line_offset = line_offset + 1
    if i == 1 and separator_index == 2 then
      table.insert(rendered, M.render_border(widths, box.left_tee, box.cross, box.right_tee))
      table.insert(extmarks, {
        line = start_line + line_offset,
        col = 0,
        opts = { hl_group = "OrgdownTableBorder" },
      })
      line_offset = line_offset + 1
    end
  end
  table.insert(rendered, M.render_border(widths, box.bottom_left, box.bottom_tee, box.bottom_right))
  table.insert(extmarks, {
    line = start_line + line_offset,
    col = 0,
    opts = { hl_group = "OrgdownTableBorder" },
  })
  return rendered, extmarks, end_line
end
return M
