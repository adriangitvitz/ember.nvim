local M = {}
function M.find_results(bufnr, code_block_end)
  local lines = vim.api.nvim_buf_get_lines(bufnr, code_block_end, -1, false)
  local results_start = nil
  local results_end = nil
  local format = nil
  for i, line in ipairs(lines) do
    local line_num = code_block_end + i
    if not results_start and line:match("^%s*$") then
    elseif not results_start then
      if line:match("^:RESULTS:") then
        results_start = line_num
        format = "drawer"
      elseif line:match("^```") then
        results_start = line_num
        format = "block"
      else
        break
      end
    else
      if format == "drawer" and line:match("^:END:") then
        results_end = line_num
        break
      elseif format == "block" and line:match("^```") then
        results_end = line_num
        break
      end
    end
  end
  if results_start and results_end then
    return {
      start_line = results_start,
      end_line = results_end,
      format = format,
    }
  end
  return nil
end
function M.format_result(result, format)
  local content = ""
  if result.error then
    content = "Error: " .. result.error
  elseif result.output and result.output ~= "" then
    content = result.output
  elseif result.value ~= nil then
    content = vim.inspect(result.value)
  else
    content = ""
  end
  content = content:gsub("\n$", "")
  local lines = {}
  if format == "drawer" then
    table.insert(lines, ":RESULTS:")
    for _, line in ipairs(vim.split(content, "\n", { plain = true })) do
      table.insert(lines, line)
    end
    table.insert(lines, ":END:")
  elseif format == "block" then
    table.insert(lines, "```")
    for _, line in ipairs(vim.split(content, "\n", { plain = true })) do
      table.insert(lines, line)
    end
    table.insert(lines, "```")
  elseif format == "inline" then
    lines = vim.split(content, "\n", { plain = true })
  end
  return lines
end
function M.insert(bufnr, code_block_end, result, opts)
  opts = opts or {}
  local config = require("orgdown.config")
  local format = opts.format or config.get("babel.results_format") or "drawer"
  local existing = M.find_results(bufnr, code_block_end)
  if existing and opts.replace ~= false then
    local new_lines = M.format_result(result, format)
    vim.api.nvim_buf_set_lines(
      bufnr,
      existing.start_line - 1,
      existing.end_line,
      false,
      new_lines
    )
  else
    local insert_line = code_block_end
    if existing then
      insert_line = existing.end_line
    end
    local new_lines = M.format_result(result, format)
    local prev_line = vim.api.nvim_buf_get_lines(bufnr, insert_line - 1, insert_line, false)[1]
    if prev_line and not prev_line:match("^%s*$") then
      table.insert(new_lines, 1, "")
    end
    vim.api.nvim_buf_set_lines(bufnr, insert_line, insert_line, false, new_lines)
  end
end
function M.clear(bufnr, code_block_end)
  local existing = M.find_results(bufnr, code_block_end)
  if existing then
    local start_line = existing.start_line
    local prev_line = vim.api.nvim_buf_get_lines(bufnr, start_line - 2, start_line - 1, false)[1]
    if prev_line and prev_line:match("^%s*$") then
      start_line = start_line - 1
    end
    vim.api.nvim_buf_set_lines(bufnr, start_line - 1, existing.end_line, false, {})
    return true
  end
  return false
end
function M.clear_all(bufnr)
  local ts = require("orgdown.treesitter")
  local code_blocks = ts.get_code_blocks(bufnr)
  table.sort(code_blocks, function(a, b)
    return a.end_line > b.end_line
  end)
  local cleared = 0
  for _, block in ipairs(code_blocks) do
    if M.clear(bufnr, block.end_line) then
      cleared = cleared + 1
    end
  end
  return cleared
end
function M.has_results(bufnr, code_block_end)
  return M.find_results(bufnr, code_block_end) ~= nil
end
function M.get_content(bufnr, code_block_end)
  local existing = M.find_results(bufnr, code_block_end)
  if not existing then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(
    bufnr,
    existing.start_line,
    existing.end_line - 1,
    false
  )
  return table.concat(lines, "\n")
end
return M
