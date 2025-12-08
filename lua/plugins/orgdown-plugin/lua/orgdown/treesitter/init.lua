local M = {}
local parser_cache = {}
function M.has_parser(lang)
  local ok, _ = pcall(vim.treesitter.language.inspect, lang)
  return ok
end
function M.get_parser(bufnr, lang)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lang = lang or "markdown"
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local cache_key = bufnr .. "_" .. lang
  if parser_cache[cache_key] then
    return parser_cache[cache_key]
  end
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return nil
  end
  parser_cache[cache_key] = parser
  return parser
end
function M.invalidate_cache(bufnr)
  for key, _ in pairs(parser_cache) do
    if key:match("^" .. bufnr .. "_") then
      parser_cache[key] = nil
    end
  end
end
function M.get_root(bufnr, lang)
  local parser = M.get_parser(bufnr, lang)
  if not parser then
    return nil
  end
  local tree = parser:parse()[1]
  if not tree then
    return nil
  end
  return tree:root()
end
function M.get_node_at_cursor(bufnr, winnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  winnr = winnr or 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local row = cursor[1] - 1
  local col = cursor[2]
  local root = M.get_root(bufnr)
  if not root then
    return nil
  end
  return root:named_descendant_for_range(row, col, row, col)
end
function M.get_node_text(node, bufnr)
  if not node then
    return nil
  end
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  if not ok then
    return nil
  end
  return text
end
function M.get_node_range(node)
  return node:range()
end
function M.find_parent(node, type_name)
  local current = node
  while current do
    if current:type() == type_name then
      return current
    end
    current = current:parent()
  end
  return nil
end
function M.find_children(node, type_name)
  local children = {}
  for child in node:iter_children() do
    if child:type() == type_name then
      table.insert(children, child)
    end
  end
  return children
end
function M.get_headings(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local headings = {}
  local root = M.get_root(bufnr)
  if not root then
    return headings
  end
  local query_str = "(atx_heading) @heading"
  local ok, query = pcall(vim.treesitter.query.parse, "markdown", query_str)
  if not ok then
    return headings
  end
  for _, node, _ in query:iter_captures(root, bufnr) do
    local start_row, start_col, end_row, end_col = node:range()
    local marker_node = node:child(0)
    local level = 1
    if marker_node then
      local marker_text = M.get_node_text(marker_node, bufnr)
      if marker_text then
        level = #marker_text:gsub("[^#]", "")
      end
    end
    local content_node = node:child(1)
    local text = ""
    if content_node then
      text = M.get_node_text(content_node, bufnr) or ""
    else
      text = M.get_node_text(node, bufnr) or ""
      text = text:gsub("^#+%s*", "")
    end
    table.insert(headings, {
      level = level,
      text = text,
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
      node = node,
    })
  end
  return headings
end
function M.get_code_blocks(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local blocks = {}
  local root = M.get_root(bufnr)
  if not root then
    return blocks
  end
  local query_str = "(fenced_code_block) @block"
  local ok, query = pcall(vim.treesitter.query.parse, "markdown", query_str)
  if not ok then
    return blocks
  end
  for _, node, _ in query:iter_captures(root, bufnr) do
    local start_row, start_col, end_row, end_col = node:range()
    local language = ""
    local content = ""
    local info_string = ""
    local options = {}
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      local child_type = child:type()
      if child_type == "info_string" then
        info_string = M.get_node_text(child, bufnr) or ""
        local parts = vim.split(info_string, "%s+")
        language = parts[1] or ""
        for j = 2, #parts do
          table.insert(options, parts[j])
        end
      elseif child_type == "code_fence_content" then
        content = M.get_node_text(child, bufnr) or ""
      end
    end
    table.insert(blocks, {
      language = language,
      content = content,
      info_string = info_string,
      options = options,
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
      node = node,
    })
  end
  return blocks
end
function M.get_links(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local links = {}
  local root = M.get_root(bufnr)
  if not root then
    return links
  end
  local query_str = "(inline_link) @link"
  local ok, query = pcall(vim.treesitter.query.parse, "markdown_inline", query_str)
  if not ok then
    ok, query = pcall(vim.treesitter.query.parse, "markdown", "(inline_link) @link")
    if not ok then
      return links
    end
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    for text, url in line:gmatch("%[([^%]]+)%]%(([^%)]+)%)") do
      table.insert(links, {
        text = text,
        url = url,
        start_row = i - 1,
        start_col = line:find("%[" .. vim.pesc(text) .. "%]") or 0,
      })
    end
  end
  return links
end
function M.get_lists(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lists = {}
  local root = M.get_root(bufnr)
  if not root then
    return lists
  end
  local query_str = "[(list) (list_item)] @list"
  local ok, query = pcall(vim.treesitter.query.parse, "markdown", query_str)
  if not ok then
    return lists
  end
  for _, node, _ in query:iter_captures(root, bufnr) do
    local start_row, start_col, end_row, end_col = node:range()
    table.insert(lists, {
      type = node:type(),
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
      node = node,
    })
  end
  return lists
end
function M.get_tables(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local tables = {}
  local root = M.get_root(bufnr)
  if not root then
    return tables
  end
  local query_str = "(pipe_table) @table"
  local ok, query = pcall(vim.treesitter.query.parse, "markdown", query_str)
  if not ok then
    return tables
  end
  for _, node, _ in query:iter_captures(root, bufnr) do
    local start_row, start_col, end_row, end_col = node:range()
    table.insert(tables, {
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
      node = node,
    })
  end
  return tables
end
function M.query(bufnr, query_str, lang)
  lang = lang or "markdown"
  local captures = {}
  local root = M.get_root(bufnr, lang)
  if not root then
    return captures
  end
  local ok, query = pcall(vim.treesitter.query.parse, lang, query_str)
  if not ok then
    return captures
  end
  for id, node, _ in query:iter_captures(root, bufnr) do
    table.insert(captures, {
      name = query.captures[id],
      node = node,
      text = M.get_node_text(node, bufnr),
    })
  end
  return captures
end
return M
