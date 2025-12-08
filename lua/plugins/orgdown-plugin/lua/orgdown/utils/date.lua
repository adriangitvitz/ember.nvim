local M = {}
local function to_timestamp(d)
  return os.time({
    year = d.year,
    month = d.month,
    day = d.day,
    hour = d.hour or 0,
    min = d.min or 0,
    sec = 0,
  })
end
local function from_timestamp(ts)
  local t = os.date("*t", ts)
  return {
    year = t.year,
    month = t.month,
    day = t.day,
    hour = t.hour,
    min = t.min,
  }
end
function M.parse(str)
  if not str or str == "" then
    return nil
  end
  local year, month, day, hour, min = str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)%s+(%d%d):(%d%d)")
  if year then
    month = tonumber(month)
    if month < 1 or month > 12 then
      return nil
    end
    return {
      year = tonumber(year),
      month = month,
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
    }
  end
  year, month, day = str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if year then
    month = tonumber(month)
    if month < 1 or month > 12 then
      return nil
    end
    return {
      year = tonumber(year),
      month = month,
      day = tonumber(day),
    }
  end
  return nil
end
function M.parse_org_date(str)
  if not str or not str:match("^<") then
    return nil, nil
  end
  local content = str:match("^<(.-)>")
  if not content then
    return nil, nil
  end
  local repeat_rule = content:match("%+%d+[dwmy]")
  if repeat_rule then
    content = content:gsub("%s*%+%d+[dwmy]%s*", " ")
    content = content:match("^%s*(.-)%s*$")
  end
  local date_obj = M.parse(content)
  return date_obj, repeat_rule
end
function M.format(d, format_str)
  format_str = format_str or "%Y-%m-%d"
  local ts = to_timestamp(d)
  return os.date(format_str, ts)
end
function M.format_org(d)
  if d.hour and d.min then
    return string.format("<%04d-%02d-%02d %02d:%02d>", d.year, d.month, d.day, d.hour, d.min)
  else
    return string.format("<%04d-%02d-%02d>", d.year, d.month, d.day)
  end
end
function M.add_days(d, days)
  local ts = to_timestamp(d)
  ts = ts + (days * 24 * 60 * 60)
  local result = from_timestamp(ts)
  if not d.hour then
    result.hour = nil
    result.min = nil
  end
  return result
end
function M.add_weeks(d, weeks)
  return M.add_days(d, weeks * 7)
end
function M.add_months(d, months)
  local new_month = d.month + months
  local new_year = d.year
  while new_month > 12 do
    new_month = new_month - 12
    new_year = new_year + 1
  end
  while new_month < 1 do
    new_month = new_month + 12
    new_year = new_year - 1
  end
  local days_in_month = M.days_in_month(new_year, new_month)
  local new_day = math.min(d.day, days_in_month)
  local result = {
    year = new_year,
    month = new_month,
    day = new_day,
    hour = d.hour,
    min = d.min,
  }
  return result
end
function M.add_years(d, years)
  local result = {
    year = d.year + years,
    month = d.month,
    day = d.day,
    hour = d.hour,
    min = d.min,
  }
  if d.month == 2 and d.day == 29 then
    local days_in_feb = M.days_in_month(result.year, 2)
    result.day = math.min(d.day, days_in_feb)
  end
  return result
end
function M.days_in_month(year, month)
  local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  if month == 2 and M.is_leap_year(year) then
    return 29
  end
  return days[month]
end
function M.is_leap_year(year)
  return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end
function M.diff_days(d1, d2)
  local ts1 = to_timestamp(M.start_of_day(d1))
  local ts2 = to_timestamp(M.start_of_day(d2))
  return math.floor((ts1 - ts2) / (24 * 60 * 60))
end
function M.today()
  local t = os.date("*t")
  return {
    year = t.year,
    month = t.month,
    day = t.day,
  }
end
function M.is_today(d)
  return M.diff_days(d, M.today()) == 0
end
function M.is_past(d)
  return M.diff_days(d, M.today()) < 0
end
function M.is_future(d)
  return M.diff_days(d, M.today()) > 0
end
function M.is_overdue(d)
  return M.is_past(d)
end
function M.days_until(d)
  return M.diff_days(d, M.today())
end
function M.days_since(d)
  return M.diff_days(M.today(), d)
end
function M.parse_repeat_rule(str)
  if not str then
    return nil
  end
  local interval, unit = str:match("^%+(%d+)([dwmy])$")
  if not interval then
    return nil
  end
  local unit_map = {
    d = "day",
    w = "week",
    m = "month",
    y = "year",
  }
  return {
    interval = tonumber(interval),
    unit = unit_map[unit],
  }
end
function M.apply_repeat(d, rule)
  if rule.unit == "day" then
    return M.add_days(d, rule.interval)
  elseif rule.unit == "week" then
    return M.add_weeks(d, rule.interval)
  elseif rule.unit == "month" then
    return M.add_months(d, rule.interval)
  elseif rule.unit == "year" then
    return M.add_years(d, rule.interval)
  end
  return d
end
function M.start_of_day(d)
  return {
    year = d.year,
    month = d.month,
    day = d.day,
    hour = 0,
    min = 0,
  }
end
function M.start_of_week(d, week_start)
  week_start = week_start or 1
  local ts = to_timestamp(d)
  local t = os.date("*t", ts)
  local current_wday = t.wday
  local days_to_subtract
  if week_start == 0 then
    days_to_subtract = current_wday - 1
  else
    days_to_subtract = current_wday - 2
    if days_to_subtract < 0 then
      days_to_subtract = days_to_subtract + 7
    end
  end
  return M.add_days(d, -days_to_subtract)
end
function M.format_relative(d)
  local days = M.days_until(d)
  if days == 0 then
    return "today"
  elseif days == 1 then
    return "tomorrow"
  elseif days == -1 then
    return "yesterday"
  elseif days > 1 and days <= 7 then
    return "in " .. days .. " days"
  elseif days < -1 and days >= -7 then
    return math.abs(days) .. " days ago"
  else
    return M.format(d)
  end
end
function M.compare(d1, d2)
  local ts1 = to_timestamp(d1)
  local ts2 = to_timestamp(d2)
  if ts1 < ts2 then
    return -1
  elseif ts1 > ts2 then
    return 1
  else
    return 0
  end
end
function M.equals(d1, d2)
  return d1.year == d2.year and d1.month == d2.month and d1.day == d2.day
end
return M
