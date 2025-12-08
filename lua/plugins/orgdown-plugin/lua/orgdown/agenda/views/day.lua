local M = {}
local date_utils = require("orgdown.utils.date")
local scheduler = require("orgdown.agenda.scheduler")
local parser = require("orgdown.agenda.parser")
local state = {
  current_date = nil,
  items = {},
}
local function get_items_for_date(all_items, target_date)
  local items = {}
  for _, item in ipairs(all_items) do
    local item_dates = {
      deadline = item.deadline,
      scheduled = item.scheduled,
      inline = item.scheduled,
      repeat_rule = item.repeat_rule,
    }
    if scheduler.is_due_on(item_dates, target_date) then
      table.insert(items, item)
    end
  end
  return items
end
local function get_overdue_items(all_items, target_date)
  local items = {}
  for _, item in ipairs(all_items) do
    if not require("orgdown.agenda.state").is_done(item.state) then
      local item_date = item.deadline or item.scheduled
      if item_date and date_utils.compare(item_date, target_date) < 0 then
        table.insert(items, item)
      end
    end
  end
  return items
end
local function format_item(item)
  local parts = {}
  local filename = vim.fn.fnamemodify(item.file, ":t")
  table.insert(parts, string.format("%-15s", filename .. ":" .. item.line))
  local item_date = item.deadline or item.scheduled
  if item_date and item_date.hour then
    table.insert(parts, string.format("%02d:%02d", item_date.hour, item_date.min))
  else
    table.insert(parts, "     ")
  end
  table.insert(parts, string.format("%-8s", item.state))
  if item.priority then
    table.insert(parts, "[#" .. item.priority .. "]")
  else
    table.insert(parts, "    ")
  end
  table.insert(parts, item.text)
  if #item.tags > 0 then
    table.insert(parts, ":" .. table.concat(item.tags, ":") .. ":")
  end
  return table.concat(parts, " ")
end
function M.render(target_date)
  target_date = target_date or date_utils.today()
  state.current_date = target_date
  local lines = {}
  local item_map = {}
  local date_str = date_utils.format(target_date, "%A %d %B %Y")
  local header = string.rep("═", 60)
  table.insert(lines, header)
  table.insert(lines, string.format("%s%s", string.rep(" ", 20), date_str))
  table.insert(lines, header)
  table.insert(lines, "")
  local all_items = parser.parse_all()
  local overdue = get_overdue_items(all_items, target_date)
  if #overdue > 0 then
    table.insert(lines, "OVERDUE:")
    local sorted_overdue = parser.sort_by_date_priority(overdue)
    for _, item in ipairs(sorted_overdue) do
      table.insert(lines, "  " .. format_item(item))
      item_map[#lines] = item
    end
    table.insert(lines, "")
  end
  local today_items = get_items_for_date(all_items, target_date)
  local sorted_items = parser.sort_by_date_priority(today_items)
  if #sorted_items > 0 then
    table.insert(lines, "SCHEDULED:")
    for _, item in ipairs(sorted_items) do
      table.insert(lines, "  " .. format_item(item))
      item_map[#lines] = item
    end
  else
    table.insert(lines, "No items scheduled for this day.")
  end
  table.insert(lines, "")
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "Press: ← prev day  → next day  t today  w week  q quit  <CR> goto")
  state.items = sorted_items
  return lines, item_map
end
function M.next_day()
  if state.current_date then
    state.current_date = date_utils.add_days(state.current_date, 1)
  end
  return state.current_date
end
function M.prev_day()
  if state.current_date then
    state.current_date = date_utils.add_days(state.current_date, -1)
  end
  return state.current_date
end
function M.today()
  state.current_date = date_utils.today()
  return state.current_date
end
function M.get_current_date()
  return state.current_date or date_utils.today()
end
return M
