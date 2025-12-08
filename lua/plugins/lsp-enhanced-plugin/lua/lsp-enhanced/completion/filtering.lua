local M = {}
function M.get_completion_context(bufnr, line, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  line = line or vim.api.nvim_win_get_cursor(0)[1]
  col = col or vim.api.nvim_win_get_cursor(0)[2]
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
  local before_cursor = line_text:sub(1, col)
  local after_cursor = line_text:sub(col + 1)
  local prefix = before_cursor:match('([%w_]*)$') or ''
  local context_type = M.detect_context_type(before_cursor, after_cursor)
  return {
    bufnr = bufnr,
    line = line,
    col = col,
    prefix = prefix,
    before_cursor = before_cursor,
    after_cursor = after_cursor,
    context_type = context_type,
    buffer_uri = vim.uri_from_bufnr(bufnr),
    buffer_path = vim.api.nvim_buf_get_name(bufnr),
    project_root = M.get_project_root(bufnr),
  }
end
function M.detect_context_type(before, after)
  if before:match('%.$') then
    return 'member_access'
  elseif before:match('%:$') or before:match(':%s*$') then
    return 'method_call'
  elseif before:match('import%s+$') or before:match('from%s+[%w_.]+%s+import%s+$') then
    return 'import'
  elseif before:match('require%s*%(?%s*["\']$') then
    return 'require'
  elseif before:match('function%s+$') or before:match('def%s+$') then
    return 'function_name'
  elseif before:match('%(%s*$') then
    return 'parameter'
  elseif before:match('%[%s*$') then
    return 'index_access'
  elseif before:match('^%s*$') then
    return 'statement_start'
  elseif before:match('class%s+$') or before:match('struct%s+$') then
    return 'type_name'
  elseif before:match('extends%s+$') or before:match('implements%s+$') then
    return 'inheritance'
  end
  return 'general'
end
function M.filter_by_context(items, context)
  if context.context_type == 'general' then
    return items
  end
  local filtered = {}
  for _, item in ipairs(items) do
    if M.item_matches_context(item, context) then
      table.insert(filtered, item)
    end
  end
  return #filtered > 0 and filtered or items
end
function M.item_matches_context(item, context)
  local kind = item.kind
  if context.context_type == 'member_access' then
    return kind == 2 or kind == 3 or kind == 5 or kind == 10
  elseif context.context_type == 'method_call' then
    return kind == 2 or kind == 3
  elseif context.context_type == 'import' or context.context_type == 'require' then
    return kind == 9 or kind == 7 or kind == 8
  elseif context.context_type == 'statement_start' then
    return kind ~= 5 and kind ~= 10
  elseif context.context_type == 'type_name' or context.context_type == 'inheritance' then
    return kind == 7 or kind == 8 or kind == 25
  elseif context.context_type == 'function_name' then
    return true
  elseif context.context_type == 'parameter' then
    return kind == 6 or kind == 21 or kind == 5
  end
  return true
end
function M.deduplicate(items)
  local seen = {}
  local unique = {}
  for _, item in ipairs(items) do
    local key = item.label
    if not seen[key] then
      seen[key] = true
      table.insert(unique, item)
    end
  end
  return unique
end
function M.limit_items(items, max_items)
  max_items = max_items or 100
  if #items <= max_items then
    return items
  end
  local limited = {}
  for i = 1, max_items do
    table.insert(limited, items[i])
  end
  return limited
end
function M.filter_by_prefix(items, prefix)
  if not prefix or prefix == '' then
    return items
  end
  local filtered = {}
  local prefix_lower = prefix:lower()
  for _, item in ipairs(items) do
    local label_lower = item.label:lower()
    if label_lower:find(prefix_lower, 1, true) then
      table.insert(filtered, item)
    end
  end
  return #filtered > 0 and filtered or items
end
function M.get_project_root(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    if client.config and client.config.root_dir then
      return client.config.root_dir
    end
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    return nil
  end
  local found = vim.fs.find({
    '.git',
    '.hg',
    '.svn',
    'package.json',
    'Cargo.toml',
    'go.mod',
    'pyproject.toml',
    'setup.py',
  }, {
    upward = true,
    path = path,
  })
  if #found > 0 then
    return vim.fs.dirname(found[1])
  end
  return nil
end
function M.filter_by_kind(items, allowed_kinds)
  if not allowed_kinds or #allowed_kinds == 0 then
    return items
  end
  local kind_set = {}
  for _, kind in ipairs(allowed_kinds) do
    kind_set[kind] = true
  end
  local filtered = {}
  for _, item in ipairs(items) do
    if kind_set[item.kind] then
      table.insert(filtered, item)
    end
  end
  return filtered
end
return M
