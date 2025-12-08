local M = {}
local bullets = {
  [0] = "•",
  [1] = "◦",
  [2] = "▪",
  [3] = "▫",
}
local checkbox = {
  unchecked = "☐",
  checked = "☑",
}
function M.get_indent_level(line)
  local indent = line:match("^(%s*)")
  return math.floor(#indent / 2)
end
function M.is_unordered(line)
  return line:match("^%s*[-*+]%s") ~= nil
end
function M.is_ordered(line)
  return line:match("^%s*%d+%.%s") ~= nil
end
function M.is_checkbox(line)
  if line:match("^%s*[-*+]%s*%[%s%]") then
    return true, false
  elseif line:match("^%s*[-*+]%s*%[[xX]%]") then
    return true, true
  end
  return false, nil
end
function M.render_unordered(line, line_nr)
  local indent_level = M.get_indent_level(line)
  local bullet = bullets[indent_level % 4]
  local rendered = line:gsub("^(%s*)[-*+](%s)", "%1" .. bullet .. "%2")
  local extmarks = {
    {
      line = line_nr,
      col = indent_level * 2,
      opts = {
        end_col = indent_level * 2 + #bullet,
        hl_group = "OrgdownBullet",
      },
    },
  }
  return rendered, extmarks
end
function M.render_ordered(line, line_nr)
  -- TODO: Add indent level
  local indent_level = M.get_indent_level(line)
  local num = line:match("^%s*(%d+)%.")
  local extmarks = {}
  if num then
    local num_start = line:find(num)
    if num_start then
      table.insert(extmarks, {
        line = line_nr,
        col = num_start - 1,
        opts = {
          end_col = num_start - 1 + #num + 1,
          hl_group = "OrgdownListNumber",
        },
      })
    end
  end
  return line, extmarks
end
function M.render_checkbox(line, line_nr)
  local is_cb, is_checked = M.is_checkbox(line)
  if not is_cb then
    return line, {}
  end
  local cb_char = is_checked and checkbox.checked or checkbox.unchecked
  local hl_group = is_checked and "OrgdownCheckboxDone" or "OrgdownCheckbox"
  local rendered = line:gsub("%[.%]", cb_char)
  local cb_pos = line:find("%[.%]")
  local extmarks = {}
  if cb_pos then
    table.insert(extmarks, {
      line = line_nr,
      col = cb_pos - 1,
      opts = {
        end_col = cb_pos - 1 + #cb_char,
        hl_group = hl_group,
      },
    })
  end
  return rendered, extmarks
end
function M.render(line, line_nr)
  local is_cb, _ = M.is_checkbox(line)
  if is_cb then
    local rendered, extmarks = M.render_checkbox(line, line_nr)
    local bullet_rendered, bullet_extmarks = M.render_unordered(rendered, line_nr)
    for _, ext in ipairs(bullet_extmarks) do
      table.insert(extmarks, ext)
    end
    return bullet_rendered, extmarks
  end
  if M.is_unordered(line) then
    return M.render_unordered(line, line_nr)
  end
  if M.is_ordered(line) then
    return M.render_ordered(line, line_nr)
  end
  return line, {}
end
return M
