local M = {}
local function get_time()
  return os.time()
end
local function add_days(timestamp, days)
  return timestamp + (days * 24 * 60 * 60)
end
local function get_week_start(timestamp)
  local date = os.date("*t", timestamp)
  local wday = date.wday
  local days_since_monday = (wday - 2) % 7
  return add_days(timestamp, -days_since_monday)
end
local function get_week_end(timestamp)
  local week_start = get_week_start(timestamp)
  return add_days(week_start, 6)
end
local function get_month_start(timestamp)
  local date = os.date("*t", timestamp)
  date.day = 1
  return os.time(date)
end
local function get_month_end(timestamp)
  local date = os.date("*t", timestamp)
  date.month = date.month + 1
  date.day = 0
  return os.time(date)
end
local function get_quarter(timestamp)
  local month = tonumber(os.date("%m", timestamp))
  return math.ceil(month / 3)
end
local variables = {
  date = function() return os.date("%Y-%m-%d") end,
  time = function() return os.date("%H:%M") end,
  datetime = function() return os.date("%Y-%m-%d %H:%M") end,
  timestamp = function() return os.date("%Y-%m-%d %H:%M:%S") end,
  year = function() return os.date("%Y") end,
  month = function() return os.date("%m") end,
  month_name = function() return os.date("%B") end,
  month_name_short = function() return os.date("%b") end,
  day = function() return os.date("%d") end,
  weekday = function() return os.date("%A") end,
  weekday_short = function() return os.date("%a") end,
  week_number = function() return os.date("%W") end,
  quarter = function() return "Q" .. get_quarter(get_time()) end,
  date_long = function() return os.date("%B %d, %Y") end,
  date_short = function() return os.date("%m/%d/%Y") end,
  date_weekday = function() return os.date("%A, %B %d, %Y") end,
  time_12h = function() return os.date("%I:%M %p") end,
  tomorrow = function() return os.date("%Y-%m-%d", add_days(get_time(), 1)) end,
  tomorrow_long = function() return os.date("%A, %B %d, %Y", add_days(get_time(), 1)) end,
  yesterday = function() return os.date("%Y-%m-%d", add_days(get_time(), -1)) end,
  yesterday_long = function() return os.date("%A, %B %d, %Y", add_days(get_time(), -1)) end,
  next_week = function() return os.date("%Y-%m-%d", add_days(get_time(), 7)) end,
  next_week_long = function() return os.date("%A, %B %d, %Y", add_days(get_time(), 7)) end,
  last_week = function() return os.date("%Y-%m-%d", add_days(get_time(), -7)) end,
  last_week_long = function() return os.date("%A, %B %d, %Y", add_days(get_time(), -7)) end,
  next_month = function()
    local date = os.date("*t")
    date.month = date.month + 1
    return os.date("%Y-%m-%d", os.time(date))
  end,
  last_month = function()
    local date = os.date("*t")
    date.month = date.month - 1
    return os.date("%Y-%m-%d", os.time(date))
  end,
  week_start = function() return os.date("%Y-%m-%d", get_week_start(get_time())) end,
  week_end = function() return os.date("%Y-%m-%d", get_week_end(get_time())) end,
  month_start = function() return os.date("%Y-%m-%d", get_month_start(get_time())) end,
  month_end = function() return os.date("%Y-%m-%d", get_month_end(get_time())) end,
  user = function() return os.getenv("USER") or os.getenv("USERNAME") or "" end,
  author = function() return os.getenv("USER") or os.getenv("USERNAME") or "" end,
}
function M.expand(template, context)
  context = context or {}
  if not template or template == "" then
    return ""
  end
  local result = template
  for key, value in pairs(context) do
    result = result:gsub("{{" .. key .. "}}", tostring(value))
  end
  for name, fn in pairs(variables) do
    result = result:gsub("{{" .. name .. "}}", function()
      local ok, val = pcall(fn)
      return ok and tostring(val) or ""
    end)
  end
  return result
end
function M.expand_file(filepath, context)
  if vim.fn.filereadable(filepath) == 0 then
    return nil, "File not found: " .. filepath
  end
  local lines = vim.fn.readfile(filepath)
  local template = table.concat(lines, "\n")
  return M.expand(template, context)
end
function M.list_variables()
  local names = {}
  for name, _ in pairs(variables) do
    table.insert(names, name)
  end
  local context_vars = { "title", "id", "topic", "tags" }
  for _, name in ipairs(context_vars) do
    if not vim.tbl_contains(names, name) then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end
function M.get_variable_help(name)
  local help = {
    date = "Current date (YYYY-MM-DD)",
    time = "Current time (HH:MM)",
    datetime = "Current date and time",
    timestamp = "Full timestamp with seconds",
    year = "4-digit year",
    month = "2-digit month (01-12)",
    month_name = "Full month name (January, etc.)",
    month_name_short = "Abbreviated month (Jan, etc.)",
    day = "2-digit day (01-31)",
    weekday = "Full weekday name (Monday, etc.)",
    weekday_short = "Abbreviated weekday (Mon, etc.)",
    week_number = "Week number of year (00-53)",
    quarter = "Quarter (Q1-Q4)",
    date_long = "Readable date (January 15, 2024)",
    date_short = "Short date (01/15/2024)",
    date_weekday = "Date with weekday",
    time_12h = "12-hour time with AM/PM",
    tomorrow = "Tomorrow's date",
    yesterday = "Yesterday's date",
    next_week = "Date 7 days from now",
    last_week = "Date 7 days ago",
    week_start = "Monday of current week",
    week_end = "Sunday of current week",
    month_start = "First day of current month",
    month_end = "Last day of current month",
    user = "System username",
    author = "Same as user",
    title = "Note title (from context)",
    id = "Note ID (from context)",
    topic = "Note topic (from context)",
  }
  return help[name]
end
function M.preview(template, context)
  context = context or { title = "[Title]", id = "[ID]", topic = "[Topic]" }
  local expanded = M.expand(template, context)
  local lines = vim.split(expanded, "\n")
  return lines
end
return M
