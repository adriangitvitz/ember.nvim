local M = {}
local heading_icons = {
  [1] = "◉ ",
  [2] = "○ ",
  [3] = "◆ ",
  [4] = "◇ ",
  [5] = "▸ ",
  [6] = "▹ ",
}
function M.get_level(line)
  local markers = line:match("^(#+)")
  if markers then
    return #markers
  end
  return nil
end
function M.render(line, line_nr)
  local level = M.get_level(line)
  if not level then
    return line, {}
  end
  local text = line:gsub("^#+%s*", "")
  local icon = heading_icons[level] or ""
  local indent = string.rep("  ", level - 1)
  local rendered = indent .. icon .. text
  local extmarks = {
    {
      line = line_nr,
      col = 0,
      opts = {
        end_col = #rendered,
        hl_group = "OrgdownH" .. level,
      },
    },
  }
  return rendered, extmarks
end
function M.is_heading(line)
  return line:match("^#+%s") ~= nil
end
function M.parse_node(node, bufnr)
  local ts = require("orgdown.treesitter")
  local text = ts.get_node_text(node, bufnr)
  if not text then
    return nil
  end
  local level = M.get_level(text)
  if not level then
    return nil
  end
  local start_row = node:range()
  return {
    level = level,
    text = text:gsub("^#+%s*", ""),
    line = start_row,
    raw = text,
  }
end
return M
