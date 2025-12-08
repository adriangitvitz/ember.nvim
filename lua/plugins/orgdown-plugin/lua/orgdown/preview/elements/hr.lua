local M = {}
function M.is_hr(line)
  local trimmed = line:match("^%s*(.*)$") or line
  return trimmed:match("^[-*_][-*_%s]*$") ~= nil and #trimmed:gsub("%s", "") >= 3
end
function M.render(line, line_nr, width)
  width = width or 80
  local rendered = string.rep("─", width)
  local extmarks = {
    {
      line = line_nr,
      col = 0,
      opts = {
        end_col = width,
        hl_group = "OrgdownHR",
      },
    },
  }
  return rendered, extmarks
end
return M
