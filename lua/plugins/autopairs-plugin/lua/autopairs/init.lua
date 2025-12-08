local M = {}
local config = {
  pairs = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['"'] = '"',
    ["'"] = "'",
    ['`'] = '`',
  },
  enable_check_bracket_line = true,
  ignored_next_char = "[%w%.]",
}
local function is_end_of_line()
  local col = vim.fn.col('.')
  local line = vim.fn.getline('.')
  return col >= #line
end
local function get_char_after_cursor()
  local col = vim.fn.col('.')
  local line = vim.fn.getline('.')
  return line:sub(col, col)
end
local function get_char_before_cursor()
  local col = vim.fn.col('.') - 1
  local line = vim.fn.getline('.')
  if col < 1 then return '' end
  return line:sub(col, col)
end
local function should_skip_char(char)
  if is_end_of_line() then
    return false
  end
  local next_char = get_char_after_cursor()
  if config.ignored_next_char and next_char:match(config.ignored_next_char) then
    return true
  end
  return false
end
local function handle_open_pair(open_char, close_char)
  if should_skip_char(open_char) then
    return open_char
  end
  return open_char .. close_char .. '<Left>'
end
local function handle_close_pair(close_char)
  local next_char = get_char_after_cursor()
  if next_char == close_char then
    return '<Right>'
  end
  return close_char
end
local function handle_backspace()
  local before = get_char_before_cursor()
  local after = get_char_after_cursor()
  if config.pairs[before] == after then
    return '<BS><Del>'
  end
  return '<BS>'
end
local function handle_cr()
  local before = get_char_before_cursor()
  local after = get_char_after_cursor()
  if before == '{' and after == '}' then
    return '<CR><Esc>O'
  elseif before == '[' and after == ']' then
    return '<CR><Esc>O'
  elseif before == '(' and after == ')' then
    return '<CR><Esc>O'
  end
  return '<CR>'
end
local function handle_space()
  local before = get_char_before_cursor()
  local after = get_char_after_cursor()
  if (before == '{' and after == '}') or
     (before == '[' and after == ']') or
     (before == '(' and after == ')') then
    return '<Space><Space><Left>'
  end
  return '<Space>'
end
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
  local keymap_opts = { expr = true, noremap = true, silent = true }
  for open_char, close_char in pairs(config.pairs) do
    if open_char == close_char then
      vim.keymap.set('i', open_char, function()
        local next_char = get_char_after_cursor()
        if next_char == open_char then
          return '<Right>'
        elseif should_skip_char(open_char) then
          return open_char
        else
          return open_char .. close_char .. '<Left>'
        end
      end, keymap_opts)
    else
      vim.keymap.set('i', open_char, function()
        return handle_open_pair(open_char, close_char)
      end, keymap_opts)
      vim.keymap.set('i', close_char, function()
        return handle_close_pair(close_char)
      end, keymap_opts)
    end
  end
  vim.keymap.set('i', '<BS>', handle_backspace, keymap_opts)
  vim.keymap.set('i', '<CR>', handle_cr, keymap_opts)
  vim.keymap.set('i', '<Space>', handle_space, keymap_opts)
end
return M
