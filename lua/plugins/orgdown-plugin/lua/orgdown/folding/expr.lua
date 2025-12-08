local M = {}
function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  local level = line:match("^(#+)%s")
  if level then
    return ">" .. #level
  end
  local next_line = vim.fn.getline(lnum + 1)
  if next_line then
    if next_line:match("^=+%s*$") then
      return ">1"
    elseif next_line:match("^%-+%s*$") and line ~= "" and not line:match("^%s*$") then
      if #next_line >= 3 and not line:match("^%s*%-") then
        return ">2"
      end
    end
  end
  if line:match("^```") then
    local prev_fold = vim.fn.foldlevel(lnum - 1)
    return tostring(prev_fold)
  end
  return "="
end
function M.foldtext()
  local foldstart = vim.v.foldstart
  local foldend = vim.v.foldend
  local line = vim.fn.getline(foldstart)
  local text = line:gsub("^#+%s*", "")
  local line_count = foldend - foldstart + 1
  local fold_icon = "▸ "
  local suffix = " (" .. line_count .. " lines)"
  return fold_icon .. text .. suffix
end
return M
