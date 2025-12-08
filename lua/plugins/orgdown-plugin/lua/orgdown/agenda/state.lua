local M = {}
local buffer_utils = require("orgdown.utils.buffer")
local events = require("orgdown.events")
local function get_keywords()
  local config = require("orgdown.config")
  return config.get("agenda.todo_keywords") or {
    todo = { "TODO", "NEXT", "WAITING" },
    done = { "DONE", "CANCELLED" },
  }
end
local function get_all_keywords()
  local keywords = get_keywords()
  local all = {}
  for _, kw in ipairs(keywords.todo) do
    table.insert(all, kw)
  end
  for _, kw in ipairs(keywords.done) do
    table.insert(all, kw)
  end
  return all
end
function M.is_done(state)
  local keywords = get_keywords()
  return vim.tbl_contains(keywords.done, state)
end
function M.is_todo(state)
  local keywords = get_keywords()
  return vim.tbl_contains(keywords.todo, state)
end
function M.cycle_forward(current_state)
  local all = get_all_keywords()
  local pos = 0
  for i, kw in ipairs(all) do
    if kw == current_state then
      pos = i
      break
    end
  end
  local next_pos = pos % #all + 1
  return all[next_pos]
end
function M.cycle_backward(current_state)
  local all = get_all_keywords()
  local pos = 0
  for i, kw in ipairs(all) do
    if kw == current_state then
      pos = i
      break
    end
  end
  local prev_pos = (pos - 2) % #all + 1
  return all[prev_pos]
end
function M.update_state(item, new_state)
  local bufnr = vim.fn.bufnr(item.file, true)
  if bufnr == -1 then
    return false
  end
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end
  local line = buffer_utils.get_line(bufnr, item.line - 1)
  if not line then
    return false
  end
  local new_line
  if item.is_checkbox then
    local check_char = M.is_done(new_state) and "x" or " "
    new_line = line:gsub("%[.%]", "[" .. check_char .. "]", 1)
  else
    local old_state = item.state
    if old_state then
      new_line = line:gsub(old_state .. ":", new_state .. ":", 1)
    else
      new_line = new_state .. ": " .. line
    end
  end
  buffer_utils.set_lines(bufnr, item.line - 1, item.line, { new_line })
  vim.api.nvim_buf_set_option(bufnr, "modified", true)
  events.emit(events.EVENTS.TODO_STATE_CHANGED, {
    item = item,
    old_state = item.state,
    new_state = new_state,
  })
  return true
end
function M.toggle_checkbox(item)
  if not item.is_checkbox then
    return false
  end
  local new_state = item.is_checked and "TODO" or "DONE"
  return M.update_state(item, new_state)
end
function M.cycle_at_cursor(forward)
  forward = forward ~= false
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_nr = cursor[1]
  local file = vim.api.nvim_buf_get_name(bufnr)
  local line = buffer_utils.get_line(bufnr, line_nr - 1)
  if not line then
    return false
  end
  local parser = require("orgdown.agenda.parser")
  local item = parser.parse_line(line, line_nr, file)
  if not item then
    vim.notify("[orgdown] No TODO item on current line", vim.log.levels.INFO)
    return false
  end
  local new_state
  if forward then
    new_state = M.cycle_forward(item.state)
  else
    new_state = M.cycle_backward(item.state)
  end
  return M.update_state(item, new_state)
end
return M
