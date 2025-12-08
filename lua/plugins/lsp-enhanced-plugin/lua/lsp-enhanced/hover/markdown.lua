local M = {}
function M.extract_code_blocks(markdown)
  local blocks = {}
  local current_block = nil
  for line in markdown:gmatch('[^\n]+') do
    if line:match('^```') then
      if current_block then
        table.insert(blocks, current_block)
        current_block = nil
      else
        local lang = line:match('^```(%w+)')
        current_block = {
          lang = lang or 'text',
          lines = {},
        }
      end
    elseif current_block then
      table.insert(current_block.lines, line)
    end
  end
  return blocks
end
function M.render_simple(markdown)
  local lines = {}
  for line in markdown:gmatch('[^\n]+') do
    line = line:gsub('%*%*(.-)%*%*', '%1')
    line = line:gsub('%*(.-)%*', '%1')
    line = line:gsub('__(.-)__', '%1')
    line = line:gsub('_(.-)_', '%1')
    line = line:gsub('`([^`]+)`', '%1')
    table.insert(lines, line)
  end
  return lines
end
function M.render_enhanced(markdown)
  local lines = {}
  local in_code_block = false
  local code_lang = nil
  local code_start_line = 0
  local line_num = 0
  for line in markdown:gmatch('[^\n]+') do
    line_num = line_num + 1
    if line:match('^```') then
      if in_code_block then
        table.insert(lines, {
          text = '```',
          type = 'code_fence',
          line = line_num,
        })
        in_code_block = false
        code_lang = nil
      else
        code_lang = line:match('^```(%S+)') or 'text'
        code_start_line = line_num
        table.insert(lines, {
          text = line,
          type = 'code_fence',
          lang = code_lang,
          line = line_num,
        })
        in_code_block = true
      end
    elseif in_code_block then
      table.insert(lines, {
        text = line,
        type = 'code',
        lang = code_lang,
        line = line_num,
        block_start = code_start_line,
      })
    else
      local line_type = 'text'
      local processed_line = line
      local header_level = line:match('^(#+)%s')
      if header_level then
        line_type = 'header'
        processed_line = line:gsub('^#+%s*', '')
      end
      if line:match('^%s*[*+-]%s') or line:match('^%s*%d+%.%s') then
        line_type = 'list'
      end
      if line:match('^%-%-%-+$') or line:match('^%*%*%*+$') then
        line_type = 'hr'
      end
      table.insert(lines, {
        text = processed_line,
        type = line_type,
        line = line_num,
        header_level = header_level and #header_level or nil,
      })
    end
  end
  return lines
end
function M.apply_highlights(bufnr, lines)
  local ns = vim.api.nvim_create_namespace('lsp_enhanced_hover_md')
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, line_info in ipairs(lines) do
    local line_idx = i - 1
    if line_info.type == 'header' then
      local hl_group = string.format('markdownH%d', math.min(line_info.header_level or 1, 6))
      vim.api.nvim_buf_add_highlight(bufnr, ns, hl_group, line_idx, 0, -1)
    elseif line_info.type == 'code_fence' then
      vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownCodeDelimiter', line_idx, 0, -1)
    elseif line_info.type == 'code' and line_info.lang then
      vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownCode', line_idx, 0, -1)
    elseif line_info.type == 'list' then
      vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownListMarker', line_idx, 0, 3)
    elseif line_info.type == 'hr' then
      vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownRule', line_idx, 0, -1)
    end
    M._apply_inline_highlights(bufnr, ns, line_idx, line_info.text)
  end
  return { ns }
end
function M._apply_inline_highlights(bufnr, ns, line_idx, text)
  for start_pos, code, end_pos in text:gmatch('()%`([^`]+)%`()') do
    vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownCodeDelimiter', line_idx, start_pos - 1, start_pos)
    vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownCodeDelimiter', line_idx, end_pos - 2, end_pos - 1)
    vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownCode', line_idx, start_pos, end_pos - 2)
  end
  for start_pos, bold_text, end_pos in text:gmatch('()%*%*([^*]+)%*%*()') do
    vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownBold', line_idx, start_pos - 1, end_pos - 1)
  end
  for start_pos, bold_text, end_pos in text:gmatch('()__([^_]+)__()') do
    vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownBold', line_idx, start_pos - 1, end_pos - 1)
  end
  for start_pos, italic_text, end_pos in text:gmatch('()%*([^*]+)%*()') do
    if not text:sub(start_pos - 1, start_pos - 1):match('%*') and
       not text:sub(end_pos - 1, end_pos - 1):match('%*') then
      vim.api.nvim_buf_add_highlight(bufnr, ns, 'markdownItalic', line_idx, start_pos - 1, end_pos - 1)
    end
  end
end
function M.apply_code_block_highlighting(bufnr, lines)
  local has_ts, _ = pcall(require, 'nvim-treesitter')
  if not has_ts then
    return false
  end
  local code_blocks = {}
  local current_block = nil
  for i, line_info in ipairs(lines) do
    if line_info.type == 'code' then
      if not current_block or current_block.lang ~= line_info.lang then
        current_block = {
          lang = line_info.lang,
          start_line = i - 1,
          lines = {},
        }
        table.insert(code_blocks, current_block)
      end
      table.insert(current_block.lines, line_info.text)
      current_block.end_line = i - 1
    elseif line_info.type ~= 'code_fence' then
      current_block = nil
    end
  end
  for _, block in ipairs(code_blocks) do
    M._highlight_code_block(bufnr, block)
  end
  return true
end
function M._highlight_code_block(bufnr, block)
  local ok, ts_highlighter = pcall(require, 'vim.treesitter.highlighter')
  if not ok then return end
  local temp_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, block.lines)
  local ft_map = {
    js = 'javascript',
    ts = 'typescript',
    py = 'python',
    rs = 'rust',
    go = 'go',
    lua = 'lua',
    c = 'c',
    cpp = 'cpp',
    java = 'java',
    rb = 'ruby',
    sh = 'bash',
    bash = 'bash',
    vim = 'vim',
    json = 'json',
    yaml = 'yaml',
    xml = 'xml',
    html = 'html',
    css = 'css',
  }
  local filetype = ft_map[block.lang] or block.lang
  vim.api.nvim_buf_set_option(temp_buf, 'filetype', filetype)
  vim.api.nvim_buf_delete(temp_buf, { force = true })
end
function M.parse(markdown)
  return {
    raw = markdown,
    lines = M.render_simple(markdown),
    enhanced_lines = M.render_enhanced(markdown),
    code_blocks = M.extract_code_blocks(markdown),
  }
end
return M
