local M = {}
function M.is_blockquote(line)
  return line:match("^%s*>") ~= nil
end
function M.get_level(line)
  local level = 0
  local trimmed = line:match("^%s*(.*)$") or line
  while trimmed:match("^>") do
    level = level + 1
    trimmed = trimmed:gsub("^>%s*", "")
  end
  return level
end
function M.get_content(line)
  local content = line:gsub("^%s*", "")
  while content:match("^>") do
    content = content:gsub("^>%s*", "")
  end
  return content
end
function M.render(line, line_nr)
  if not M.is_blockquote(line) then
    return line, {}
  end
  local level = M.get_level(line)
  local content = M.get_content(line)
  local border = string.rep("│ ", level)
  local rendered = border .. content
  local extmarks = {
    {
      line = line_nr,
      col = 0,
      opts = {
        end_col = #border,
        hl_group = "OrgdownBlockquoteBorder",
      },
    },
    {
      line = line_nr,
      col = #border,
      opts = {
        end_col = #rendered,
        hl_group = "OrgdownBlockquote",
      },
    },
  }
  return rendered, extmarks
end
return M
