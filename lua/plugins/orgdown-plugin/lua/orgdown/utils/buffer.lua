local M = {}
function M.get_lines(bufnr, start_row, end_row)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  start_row = start_row or 0
  end_row = end_row or -1
  return vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
end
function M.set_lines(bufnr, start_row, end_row, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, start_row, end_row, false, lines)
end
function M.insert_lines(bufnr, row, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, row, row, false, lines)
end
function M.delete_lines(bufnr, start_row, end_row)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, start_row, end_row, false, {})
end
function M.get_line(bufnr, row)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if row >= line_count then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)
  return lines[1]
end
function M.get_cursor(winnr)
  winnr = winnr or 0
  local pos = vim.api.nvim_win_get_cursor(winnr)
  return pos[1], pos[2]
end
function M.set_cursor(line, col, winnr)
  winnr = winnr or 0
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  line = math.max(1, math.min(line, line_count))
  local line_content = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
  col = math.max(0, math.min(col, #line_content))
  pcall(vim.api.nvim_win_set_cursor, winnr, { line, col })
end
function M.is_valid(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end
function M.is_loaded(bufnr)
  return bufnr and vim.api.nvim_buf_is_loaded(bufnr)
end
function M.is_modified(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_option(bufnr, "modified")
end
function M.line_count(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_line_count(bufnr)
end
function M.get_option(bufnr, option)
  return vim.api.nvim_buf_get_option(bufnr, option)
end
function M.set_option(bufnr, option, value)
  vim.api.nvim_buf_set_option(bufnr, option, value)
end
function M.set_extmark(bufnr, ns_id, row, col, opts)
  return vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, col, opts)
end
function M.get_extmarks(bufnr, ns_id, start, end_pos, opts)
  opts = opts or {}
  return vim.api.nvim_buf_get_extmarks(bufnr, ns_id, start, end_pos, opts)
end
function M.clear_namespace(bufnr, ns_id, start_row, end_row)
  start_row = start_row or 0
  end_row = end_row or -1
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, start_row, end_row)
end
function M.del_extmark(bufnr, ns_id, id)
  return vim.api.nvim_buf_del_extmark(bufnr, ns_id, id)
end
function M.create_scratch_buffer(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  if opts.name then
    vim.api.nvim_buf_set_name(bufnr, opts.name)
  end
  if opts.filetype then
    vim.api.nvim_buf_set_option(bufnr, "filetype", opts.filetype)
  end
  if opts.lines then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, opts.lines)
  end
  if opts.modifiable == false then
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end
  return bufnr
end
function M.get_word_under_cursor(winnr)
  winnr = winnr or 0
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return nil
  end
  return word
end
function M.get_WORD_under_cursor(winnr)
  winnr = winnr or 0
  local word = vim.fn.expand("<cWORD>")
  if word == "" then
    return nil
  end
  return word
end
function M.get_visual_selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end
  local _, start_row, start_col, _ = unpack(vim.fn.getpos("v"))
  local _, end_row, end_col, _ = unpack(vim.fn.getpos("."))
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  if #lines == 0 then
    return nil
  end
  if #lines == 1 then
    return lines[1]:sub(start_col, end_col)
  else
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
    return table.concat(lines, "\n")
  end
end
return M
