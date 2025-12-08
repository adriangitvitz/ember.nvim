local M = {}
local date_utils = require("orgdown.utils.date")
local scheduler = require("orgdown.agenda.scheduler")
local parser = require("orgdown.agenda.parser")
local state = {
  week_start = nil,
}
local function get_items_by_day(all_items, start_date, num_days)
  local day_items = {}
  for i = 0, num_days - 1 do
    local day = date_utils.add_days(start_date, i)
    local key = date_utils.format(day)
    day_items[key] = {
      date = day,
      items = {},
    }
  end
  for _, item in ipairs(all_items) do
    local item_dates = {
      deadline = item.deadline,
      scheduled = item.scheduled,
      inline = item.scheduled,
      repeat_rule = item.repeat_rule,
    }
    for i = 0, num_days - 1 do
      local day = date_utils.add_days(start_date, i)
      if scheduler.is_due_on(item_dates, day) then
        local key = date_utils.format(day)
        table.insert(day_items[key].items, item)
      end
    end
  end
  return day_items
end
local function format_item_short(item)
  local parts = {}
  local item_date = item.deadline or item.scheduled
  if item_date and item_date.hour then
    table.insert(parts, string.format("%02d:%02d", item_date.hour, item_date.min))
  end
  local state_char = require("orgdown.agenda.state").is_done(item.state) and "✓" or "○"
  table.insert(parts, state_char)
  local text = item.text
  if #text > 40 then
    text = text:sub(1, 37) .. "..."
  end
  table.insert(parts, text)
  return table.concat(parts, " ")
end
function M.render(start_date)
  local config = require("orgdown.config")
  local week_start_day = config.get("agenda.week_start") or 1
  if not start_date then
    start_date = date_utils.start_of_week(date_utils.today(), week_start_day)
  end
  state.week_start = start_date
  local lines = {}
  local item_map = {}
  local end_date = date_utils.add_days(start_date, 6)
  local header_text = string.format(
    "Week: %s - %s",
    date_utils.format(start_date, "%b %d"),
    date_utils.format(end_date, "%b %d, %Y")
  )
  local header = string.rep("═", 60)
  table.insert(lines, header)
  table.insert(lines, string.format("%s%s", string.rep(" ", 15), header_text))
  table.insert(lines, header)
  table.insert(lines, "")
  local all_items = parser.parse_all()
  local day_items = get_items_by_day(all_items, start_date, 7)
  local today = date_utils.today()
  for i = 0, 6 do
    local day = date_utils.add_days(start_date, i)
    local key = date_utils.format(day)
    local data = day_items[key]
    local day_name = date_utils.format(day, "%A %d %B")
    local is_today = date_utils.equals(day, today)
    local marker = is_today and " ◀ TODAY" or ""
    table.insert(lines, string.format("%s%s", day_name, marker))
    table.insert(lines, string.rep("─", 50))
    if data and #data.items > 0 then
      local sorted = parser.sort_by_date_priority(data.items)
      for _, item in ipairs(sorted) do
        table.insert(lines, "  " .. format_item_short(item))
        item_map[#lines] = item
      end
    else
      table.insert(lines, "  (no items)")
    end
    table.insert(lines, "")
  end
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "Press: ← prev week  → next week  d day  t todos  q quit  <CR> goto")
  return lines, item_map
end
function M.next_week()
  if state.week_start then
    state.week_start = date_utils.add_days(state.week_start, 7)
  end
  return state.week_start
end
function M.prev_week()
  if state.week_start then
    state.week_start = date_utils.add_days(state.week_start, -7)
  end
  return state.week_start
end
function M.this_week()
  local config = require("orgdown.config")
  local week_start_day = config.get("agenda.week_start") or 1
  state.week_start = date_utils.start_of_week(date_utils.today(), week_start_day)
  return state.week_start
end
function M.get_week_start()
  return state.week_start or M.this_week()
end
return M
