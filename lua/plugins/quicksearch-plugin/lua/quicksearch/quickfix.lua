local M = {}
local config = require("quicksearch.config")
local utils = require("quicksearch.utils")
local state = {
  last_height = nil,
  was_open = false,
}
function M.populate(items, opts)
  opts = opts or {}
  local qf_items = {}
  for _, item in ipairs(items) do
    table.insert(qf_items, {
      filename = item.filename,
      lnum = item.lnum or 1,
      col = item.col or 1,
      text = item.text or "",
      type = item.type or "I",
    })
  end
  vim.fn.setqflist(qf_items, "r")
  if opts.title then
    vim.fn.setqflist({}, "a", { title = opts.title })
  end
  if opts.auto_open or (opts.auto_open == nil and config.get().quickfix.auto_open) then
    M.open(opts)
  end
end
function M.calculate_height()
  local qf_list = vim.fn.getqflist()
  local item_count = #qf_list
  local max_height = config.get().quickfix.max_height or 15
  local min_height = config.get().quickfix.min_height or 3
  return math.max(min_height, math.min(item_count, max_height))
end
function M.open(opts)
  opts = opts or {}
  local height = opts.height or state.last_height or M.calculate_height()
  vim.cmd("copen " .. height)
  state.last_height = height
  state.was_open = true
  if opts.auto_focus or (opts.auto_focus == nil and config.get().quickfix.auto_focus) then
  else
    vim.cmd("wincmd p")
  end
end
function M.close()
  if M.is_open() then
    state.last_height = vim.fn.winheight(M.get_window_nr())
    vim.cmd("cclose")
    state.was_open = false
  end
end
function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end
function M.focus()
  if M.is_open() then
    for i = 1, vim.fn.winnr("$") do
      if vim.fn.getwinvar(i, "&buftype") == "quickfix" then
        vim.cmd(i .. "wincmd w")
        return true
      end
    end
  else
    M.open({ auto_focus = true })
  end
  return false
end
function M.is_open()
  for i = 1, vim.fn.winnr("$") do
    if vim.fn.getwinvar(i, "&buftype") == "quickfix" then
      return true
    end
  end
  return false
end
function M.get_window_nr()
  for i = 1, vim.fn.winnr("$") do
    if vim.fn.getwinvar(i, "&buftype") == "quickfix" then
      return i
    end
  end
  return nil
end
function M.clear()
  vim.fn.setqflist({}, "r")
  if M.is_open() then
    M.close()
  end
  utils.notify("Quickfix list cleared", vim.log.levels.INFO)
end
function M.handle_enter()
  local winid = vim.fn.win_getid()
  local is_loclist = vim.fn.getwininfo(winid)[1].loclist == 1
  local qf_list = is_loclist and vim.fn.getloclist(0) or vim.fn.getqflist()
  local idx = vim.fn.line(".")
  local item = qf_list[idx]
  if not item or not item.bufnr or item.bufnr == 0 then
    if item and item.filename and item.filename ~= "" then
      local filepath = item.filename
      vim.cmd("wincmd p")
      if utils.is_directory(filepath) and config.get().netrw.open_dirs then
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
      else
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        if item.lnum and item.lnum > 0 then
          vim.api.nvim_win_set_cursor(0, { item.lnum, (item.col or 1) - 1 })
        end
      end
    end
    return
  end
  local filepath = vim.fn.bufname(item.bufnr)
  vim.cmd("wincmd p")
  if utils.is_directory(filepath) and config.get().netrw.open_dirs then
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  else
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    if item.lnum and item.lnum > 0 then
      vim.api.nvim_win_set_cursor(0, { item.lnum, (item.col or 1) - 1 })
    end
  end
end
function M.setup_keymaps()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
      vim.keymap.set("n", "<CR>", function()
        M.handle_enter()
      end, { buffer = true, desc = "Open file or directory" })
    end,
  })
end
return M
