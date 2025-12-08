local M = {}
local buffer_utils = require("orgdown.utils.buffer")
local window_utils = require("orgdown.utils.window")
local events = require("orgdown.events")
local day_view = require("orgdown.agenda.views.day")
local week_view = require("orgdown.agenda.views.week")
local todo_view = require("orgdown.agenda.views.todo")
local state_mod = require("orgdown.agenda.state")
local state = {
  winnr = nil,
  bufnr = nil,
  current_view = "week",
  item_map = {},
}
function M.setup(opts)
end
function M.is_open()
  return state.winnr and vim.api.nvim_win_is_valid(state.winnr)
end
local function create_agenda_buffer()
  local bufnr = buffer_utils.create_scratch_buffer({
    filetype = "orgdown_agenda",
    name = "Orgdown Agenda",
  })
  return bufnr
end
local function setup_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "q", function()
    M.close()
  end, vim.tbl_extend("force", opts, { desc = "Close agenda" }))
  vim.keymap.set("n", "<CR>", function()
    M.goto_item()
  end, vim.tbl_extend("force", opts, { desc = "Go to item" }))
  vim.keymap.set("n", "t", function()
    M.cycle_todo()
  end, vim.tbl_extend("force", opts, { desc = "Cycle TODO state" }))
  vim.keymap.set("n", "d", function()
    M.switch_view("day")
  end, vim.tbl_extend("force", opts, { desc = "Day view" }))
  vim.keymap.set("n", "w", function()
    M.switch_view("week")
  end, vim.tbl_extend("force", opts, { desc = "Week view" }))
  vim.keymap.set("n", "T", function()
    M.switch_view("todo")
  end, vim.tbl_extend("force", opts, { desc = "TODO view" }))
  vim.keymap.set("n", "<Left>", function()
    M.navigate_prev()
  end, vim.tbl_extend("force", opts, { desc = "Previous" }))
  vim.keymap.set("n", "<Right>", function()
    M.navigate_next()
  end, vim.tbl_extend("force", opts, { desc = "Next" }))
  vim.keymap.set("n", ".", function()
    M.navigate_today()
  end, vim.tbl_extend("force", opts, { desc = "Today/This week" }))
  vim.keymap.set("n", "r", function()
    M.refresh()
  end, vim.tbl_extend("force", opts, { desc = "Refresh" }))
end
local function render_view()
  if not state.bufnr then
    return
  end
  local lines, item_map
  if state.current_view == "day" then
    lines, item_map = day_view.render()
  elseif state.current_view == "week" then
    lines, item_map = week_view.render()
  elseif state.current_view == "todo" then
    lines, item_map = todo_view.render()
  else
    lines = { "Unknown view: " .. state.current_view }
    item_map = {}
  end
  state.item_map = item_map
  vim.api.nvim_buf_set_option(state.bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.bufnr, "modifiable", false)
end
function M.open(view)
  view = view or "week"
  state.current_view = view
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    state.bufnr = create_agenda_buffer()
    setup_keymaps(state.bufnr)
  end
  if M.is_open() then
    M.close()
  end
  local winnr, _ = window_utils.open_float({
    bufnr = state.bufnr,
    width = 0.8,
    height = 0.8,
    border = "rounded",
    title = " Agenda ",
  })
  state.winnr = winnr
  render_view()
  vim.api.nvim_win_set_option(winnr, "cursorline", true)
end
function M.close()
  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    vim.api.nvim_win_close(state.winnr, true)
  end
  state.winnr = nil
end
function M.open_day()
  M.open("day")
end
function M.open_week()
  M.open("week")
end
function M.open_todos()
  M.open("todo")
end
function M.switch_view(view)
  state.current_view = view
  render_view()
end
function M.navigate_prev()
  if state.current_view == "day" then
    day_view.prev_day()
  elseif state.current_view == "week" then
    week_view.prev_week()
  end
  render_view()
end
function M.navigate_next()
  if state.current_view == "day" then
    day_view.next_day()
  elseif state.current_view == "week" then
    week_view.next_week()
  end
  render_view()
end
function M.navigate_today()
  if state.current_view == "day" then
    day_view.today()
  elseif state.current_view == "week" then
    week_view.this_week()
  end
  render_view()
end
function M.goto_item()
  local cursor = vim.api.nvim_win_get_cursor(state.winnr)
  local line_nr = cursor[1]
  local item = state.item_map[line_nr]
  if not item then
    return
  end
  M.close()
  vim.cmd("edit " .. vim.fn.fnameescape(item.file))
  vim.api.nvim_win_set_cursor(0, { item.line, 0 })
end
function M.cycle_todo()
  local cursor = vim.api.nvim_win_get_cursor(state.winnr)
  local line_nr = cursor[1]
  local item = state.item_map[line_nr]
  if not item then
    return
  end
  local new_state = state_mod.cycle_forward(item.state)
  state_mod.update_state(item, new_state)
  M.refresh()
end
function M.refresh()
  render_view()
  events.emit(events.EVENTS.AGENDA_REFRESH_NEEDED, {})
end
return M
