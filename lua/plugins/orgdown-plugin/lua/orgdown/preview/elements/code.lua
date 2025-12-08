local M = {}
function M.is_fence_start(line)
  local lang = line:match("^```(%w*)")
  if lang ~= nil then
    return true, lang ~= "" and lang or nil
  end
  return false, nil
end
function M.is_fence_end(line)
  return line:match("^```%s*$") ~= nil
end
function M.has_inline_code(line)
  return line:match("`[^`]+`") ~= nil
end
function M.render_code_line(line, line_nr, language)
  local rendered = "  " .. line
  local extmarks = {
    {
      line = line_nr,
      col = 0,
      opts = {
        end_row = line_nr,
        end_col = #rendered,
        hl_group = "OrgdownCodeBlock",
      },
    },
  }
  return rendered, extmarks
end
function M.render_inline(line, line_nr)
  local extmarks = {}
  local rendered = line
  local pos = 1
  while true do
    local start_pos, end_pos = rendered:find("`[^`]+`", pos)
    if not start_pos then
      break
    end
    table.insert(extmarks, {
      line = line_nr,
      col = start_pos - 1,
      opts = {
        end_col = end_pos,
        hl_group = "OrgdownCode",
      },
    })
    pos = end_pos + 1
  end
  return rendered, extmarks
end
function M.parse_block(lines, start_line)
  local first_line = lines[start_line + 1]
  if not first_line then
    return nil
  end
  local is_start, language = M.is_fence_start(first_line)
  if not is_start then
    return nil
  end
  local options = {}
  local info = first_line:match("^```(.*)$")
  if info then
    local parts = vim.split(info, "%s+")
    language = parts[1]
    for i = 2, #parts do
      table.insert(options, parts[i])
    end
  end
  local content_lines = {}
  local end_line = nil
  for i = start_line + 2, #lines do
    local line = lines[i]
    if M.is_fence_end(line) then
      end_line = i - 1
      break
    end
    table.insert(content_lines, line)
  end
  if not end_line then
    end_line = #lines - 1
  end
  return {
    language = language,
    content = table.concat(content_lines, "\n"),
    start_line = start_line,
    end_line = end_line,
    options = options,
  }
end
function M.render_block(block, line_offset)
  local lines = {}
  local extmarks = {}
  local label = block.language and ("─── " .. block.language .. " ") or "─── "
  local label_line = label .. string.rep("─", 40 - #label)
  table.insert(lines, label_line)
  table.insert(extmarks, {
    line = line_offset,
    col = 0,
    opts = {
      end_col = #label_line,
      hl_group = "OrgdownCodeBlock",
    },
  })
  local content_lines = vim.split(block.content, "\n")
  for i, line in ipairs(content_lines) do
    local rendered, line_extmarks = M.render_code_line(line, line_offset + i, block.language)
    table.insert(lines, rendered)
    for _, ext in ipairs(line_extmarks) do
      table.insert(extmarks, ext)
    end
  end
  local end_label = string.rep("─", 44)
  table.insert(lines, end_label)
  table.insert(extmarks, {
    line = line_offset + #content_lines + 1,
    col = 0,
    opts = {
      end_col = #end_label,
      hl_group = "OrgdownCodeBlock",
    },
  })
  return lines, extmarks
end
return M
