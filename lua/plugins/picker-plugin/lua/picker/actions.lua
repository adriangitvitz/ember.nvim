local M = {}
function M.open_file(path, line, col, action)
  if not path or path == "" then
    return
  end
  if action == "ctrl-x" then
    vim.cmd("split " .. vim.fn.fnameescape(path))
  elseif action == "ctrl-v" then
    vim.cmd("vsplit " .. vim.fn.fnameescape(path))
  elseif action == "ctrl-t" then
    vim.cmd("tabedit " .. vim.fn.fnameescape(path))
  else
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end
  if line then
    vim.api.nvim_win_set_cursor(0, { tonumber(line), (col and tonumber(col) - 1) or 0 })
    vim.cmd("normal! zz")
  end
end
function M.parse_grep_result(line)
  local file, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
  if file then
    return {
      file = file,
      line = tonumber(lnum),
      col = tonumber(col),
      text = text,
    }
  end
  file, lnum, text = line:match("^(.+):(%d+):(.*)$")
  if file then
    return {
      file = file,
      line = tonumber(lnum),
      col = 1,
      text = text,
    }
  end
  return nil
end
function M.open_grep_result(line, action)
  local parsed = M.parse_grep_result(line)
  if parsed then
    M.open_file(parsed.file, parsed.line, parsed.col, action)
  end
end
function M.parse_lsp_location(line)
  local file, lnum, col = line:match("^(.+):(%d+):(%d+)")
  if file then
    return {
      file = file,
      line = tonumber(lnum),
      col = tonumber(col),
    }
  end
  return nil
end
function M.open_buffer(buf_info, action)
  local bufnr = tonumber(buf_info:match("^(%d+)"))
  if bufnr then
    if action == "ctrl-x" then
      vim.cmd("sbuffer " .. bufnr)
    elseif action == "ctrl-v" then
      vim.cmd("vertical sbuffer " .. bufnr)
    elseif action == "ctrl-t" then
      vim.cmd("tab sbuffer " .. bufnr)
    else
      vim.cmd("buffer " .. bufnr)
    end
  end
end
function M.open_help(tag, action)
  if action == "ctrl-v" then
    vim.cmd("vertical help " .. tag)
  elseif action == "ctrl-t" then
    vim.cmd("tab help " .. tag)
  else
    vim.cmd("help " .. tag)
  end
end
function M.send_to_quickfix(items, title)
  local qf_items = {}
  for _, item in ipairs(items) do
    local parsed = M.parse_grep_result(item)
    if parsed then
      table.insert(qf_items, {
        filename = parsed.file,
        lnum = parsed.line,
        col = parsed.col,
        text = parsed.text,
      })
    else
      table.insert(qf_items, {
        filename = item,
        lnum = 1,
        col = 1,
        text = "",
      })
    end
  end
  vim.fn.setqflist({}, " ", {
    title = title or "Picker Results",
    items = qf_items,
  })
  vim.cmd("copen")
end
return M
