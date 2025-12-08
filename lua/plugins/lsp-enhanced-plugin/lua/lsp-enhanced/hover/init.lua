local M = {}
local markdown = require('lsp-enhanced.hover.markdown')
local window = require('lsp-enhanced.hover.window')
local default_config = {
  enabled = true,
  border = 'rounded',
  max_width = 80,
  max_height = 20,
  focusable = true,
  syntax_highlighting = true,
}
local config = vim.deepcopy(default_config)
local original_hover_handler = nil
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', default_config, user_config or {})
end
function M.show_hover(opts)
  if not config.enabled then
    vim.lsp.buf.hover()
    return
  end
  opts = vim.tbl_extend('force', config, opts or {})
  vim.lsp.buf.hover()
end
function M.process_hover_result(result)
  if not result or not result.contents then
    return nil
  end
  local contents = result.contents
  if type(contents) == 'string' then
    return markdown.parse(contents)
  elseif contents.kind == 'markdown' then
    return markdown.parse(contents.value)
  elseif contents.kind == 'plaintext' then
    return { lines = vim.split(contents.value, '\n') }
  elseif type(contents) == 'table' and #contents > 0 then
    local all_lines = {}
    for _, item in ipairs(contents) do
      if type(item) == 'string' then
        local parsed = markdown.parse(item)
        vim.list_extend(all_lines, parsed.lines)
      elseif item.value then
        local parsed = markdown.parse(item.value)
        vim.list_extend(all_lines, parsed.lines)
      end
    end
    return { lines = all_lines }
  end
  return nil
end
function M.setup_handler_override()
  if not config.enabled then
    return
  end
  if not original_hover_handler then
    original_hover_handler = vim.lsp.handlers['textDocument/hover']
  end
  vim.lsp.handlers['textDocument/hover'] = function(err, result, ctx, cfg)
    if err or not result or not result.contents then
      if original_hover_handler then
        return original_hover_handler(err, result, ctx, cfg)
      end
      return
    end
    local processed = M.process_hover_result(result)
    if not processed then
      if original_hover_handler then
        return original_hover_handler(err, result, ctx, cfg)
      end
      return
    end
    local lines = {}
    if processed.enhanced_lines then
      for _, line_info in ipairs(processed.enhanced_lines) do
        table.insert(lines, line_info.text)
      end
    elseif processed.lines then
      lines = processed.lines
    end
    if #lines == 0 then
      return
    end
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
    if config.syntax_highlighting and processed.enhanced_lines then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          markdown.apply_highlights(bufnr, processed.enhanced_lines)
          if config.treesitter_highlighting then
            markdown.apply_code_block_highlighting(bufnr, processed.enhanced_lines)
          end
        end
      end)
    end
    local max_width = config.max_width or 80
    local max_height = config.max_height or 20
    local width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    width = math.min(width, max_width)
    local height = math.min(#lines, max_height)
    local win_config = window.calculate_position(width, height)
    win_config.border = config.border or 'rounded'
    win_config.focusable = config.focusable
    win_config.style = 'minimal'
    local win = vim.api.nvim_open_win(bufnr, false, win_config)
    vim.api.nvim_win_set_option(win, 'wrap', true)
    vim.api.nvim_win_set_option(win, 'linebreak', true)
    vim.api.nvim_win_set_option(win, 'conceallevel', 2)
    vim.api.nvim_win_set_option(win, 'concealcursor', 'n')
    if not config.focusable then
      vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI', 'BufLeave'}, {
        buffer = vim.api.nvim_get_current_buf(),
        once = true,
        callback = function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end,
      })
    else
      vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', '', {
        noremap = true,
        silent = true,
        callback = function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end,
      })
    end
  end
end
function M.restore_handler()
  if original_hover_handler then
    vim.lsp.handlers['textDocument/hover'] = original_hover_handler
    original_hover_handler = nil
  end
end
function M.enable()
  config.enabled = true
  M.setup_handler_override()
end
function M.disable()
  config.enabled = false
  M.restore_handler()
end
function M.toggle()
  if config.enabled then
    M.disable()
  else
    M.enable()
  end
end
function M.is_enabled()
  return config.enabled
end
return M
