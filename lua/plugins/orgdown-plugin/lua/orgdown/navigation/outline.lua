local M = {}
local outline_win = nil
local outline_buf = nil
local source_buf = nil
local ns_id = vim.api.nvim_create_namespace("orgdown_outline")
local function generate_outline(headings)
  local lines = {}
  local data = {}
  for _, heading in ipairs(headings) do
    local indent = string.rep("  ", heading.level - 1)
    local icon = heading.level == 1 and "◉" or "○"
    local line = indent .. icon .. " " .. heading.text
    table.insert(lines, line)
    table.insert(data, {
      line = heading.line,
      level = heading.level,
      text = heading.text,
    })
  end
  return lines, data
end
local function create_outline_buffer(headings)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "orgdown_outline")
  local lines, data = generate_outline(headings)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.b[bufnr].outline_data = data
  vim.b[bufnr].source_buf = source_buf
  for i, item in ipairs(data) do
    local hl_group = "OrgdownH" .. math.min(item.level, 6)
    vim.api.nvim_buf_add_highlight(bufnr, ns_id, hl_group, i - 1, 0, -1)
  end
  return bufnr
end
local function setup_outline_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "<CR>", function()
    M.goto_heading_at_cursor()
  end, opts)
  vim.keymap.set("n", "o", function()
    M.goto_heading_at_cursor()
    M.close()
  end, opts)
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
  vim.keymap.set("n", "<Tab>", function()
    M.preview_heading_at_cursor()
  end, opts)
end
function M.open(opts)
  opts = opts or {}
  local config = require("orgdown.config")
  if M.is_open() then
    M.close()
  end
  source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  local ts = require("orgdown.treesitter")
  local headings = ts.get_headings(source_buf)
  if #headings == 0 then
    vim.notify("No headings found in document", vim.log.levels.INFO)
    return
  end
  outline_buf = create_outline_buffer(headings)
  local width = opts.width or 40
  local position = opts.position or "left"
  if position == "left" then
    vim.cmd("topleft " .. width .. "vsplit")
  elseif position == "right" then
    vim.cmd("botright " .. width .. "vsplit")
  else
    vim.cmd("topleft " .. width .. "vsplit")
  end
  outline_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(outline_win, outline_buf)
  vim.api.nvim_win_set_option(outline_win, "number", false)
  vim.api.nvim_win_set_option(outline_win, "relativenumber", false)
  vim.api.nvim_win_set_option(outline_win, "signcolumn", "no")
  vim.api.nvim_win_set_option(outline_win, "foldcolumn", "0")
  vim.api.nvim_win_set_option(outline_win, "winfixwidth", true)
  vim.api.nvim_win_set_option(outline_win, "wrap", false)
  vim.api.nvim_win_set_option(outline_win, "cursorline", true)
  setup_outline_keymaps(outline_buf)
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = source_buf,
    callback = function()
      M.close()
    end,
    once = true,
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = source_buf,
    callback = function()
      if M.is_open() then
        M.refresh()
      end
    end,
  })
  local events = require("orgdown.events")
  events.emit(events.EVENTS.OUTLINE_OPENED, {
    bufnr = outline_buf,
    source_buf = source_buf,
  })
end
function M.close()
  if outline_win and vim.api.nvim_win_is_valid(outline_win) then
    vim.api.nvim_win_close(outline_win, true)
  end
  outline_win = nil
  outline_buf = nil
  local events = require("orgdown.events")
  events.emit(events.EVENTS.OUTLINE_CLOSED, {})
end
function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end
function M.is_open()
  return outline_win ~= nil and vim.api.nvim_win_is_valid(outline_win)
end
function M.refresh()
  if not M.is_open() or not source_buf then
    return
  end
  local ts = require("orgdown.treesitter")
  local headings = ts.get_headings(source_buf)
  local lines, data = generate_outline(headings)
  vim.api.nvim_buf_set_option(outline_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(outline_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(outline_buf, "modifiable", false)
  vim.b[outline_buf].outline_data = data
  vim.api.nvim_buf_clear_namespace(outline_buf, ns_id, 0, -1)
  for i, item in ipairs(data) do
    local hl_group = "OrgdownH" .. math.min(item.level, 6)
    vim.api.nvim_buf_add_highlight(outline_buf, ns_id, hl_group, i - 1, 0, -1)
  end
end
function M.goto_heading_at_cursor()
  if not M.is_open() then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(outline_win)
  local line_num = cursor[1]
  local data = vim.b[outline_buf].outline_data
  local src_buf = vim.b[outline_buf].source_buf
  if not data or line_num > #data then
    return
  end
  local heading = data[line_num]
  local target_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == src_buf then
      target_win = win
      break
    end
  end
  if target_win then
    vim.api.nvim_set_current_win(target_win)
    vim.api.nvim_win_set_cursor(target_win, { heading.line, 0 })
  end
end
function M.preview_heading_at_cursor()
  if not M.is_open() then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(outline_win)
  local line_num = cursor[1]
  local data = vim.b[outline_buf].outline_data
  local src_buf = vim.b[outline_buf].source_buf
  if not data or line_num > #data then
    return
  end
  local heading = data[line_num]
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == src_buf then
      vim.api.nvim_win_set_cursor(win, { heading.line, 0 })
      break
    end
  end
end
function M.get_buffer()
  return outline_buf
end
function M.get_source_buffer()
  return source_buf
end
return M
