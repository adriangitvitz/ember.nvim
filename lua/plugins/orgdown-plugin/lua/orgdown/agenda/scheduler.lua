local M = {}
local date_utils = require("orgdown.utils.date")
function M.parse_deadline(text)
  local date_str = text:match("DEADLINE:%s*(%d%d%d%d%-%d%d%-%d%d%s*%d?%d?:?%d?%d?)")
  if date_str then
    return date_utils.parse(date_str:match("^%s*(.-)%s*$"))
  end
  return nil
end
function M.parse_scheduled(text)
  local date_str = text:match("SCHEDULED:%s*(%d%d%d%d%-%d%d%-%d%d%s*%d?%d?:?%d?%d?)")
  if date_str then
    return date_utils.parse(date_str:match("^%s*(.-)%s*$"))
  end
  return nil
end
function M.parse_inline_date(text)
  return date_utils.parse_org_date(text:match("(<[^>]+>)"))
end
function M.extract_dates(text)
  local dates = {}
  dates.deadline = M.parse_deadline(text)
  dates.scheduled = M.parse_scheduled(text)
  local inline, repeat_rule = M.parse_inline_date(text)
  if inline then
    dates.inline = inline
    dates.repeat_rule = repeat_rule
  end
  return dates
end
function M.get_primary_date(dates)
  return dates.deadline or dates.scheduled or dates.inline
end
function M.is_due_on(item_dates, target_date)
  local primary = M.get_primary_date(item_dates)
  if not primary then
    return false
  end
  if date_utils.equals(primary, target_date) then
    return true
  end
  if item_dates.repeat_rule then
    local rule = date_utils.parse_repeat_rule(item_dates.repeat_rule)
    if rule then
      local current = primary
      local today = date_utils.today()
      while date_utils.compare(current, target_date) <= 0 do
        if date_utils.equals(current, target_date) then
          return true
        end
        current = date_utils.apply_repeat(current, rule)
        if date_utils.diff_days(current, today) > 365 * 10 then
          break
        end
      end
    end
  end
  return false
end
function M.get_next_occurrence(item_dates)
  local primary = M.get_primary_date(item_dates)
  if not primary then
    return nil
  end
  if not item_dates.repeat_rule then
    return primary
  end
  local rule = date_utils.parse_repeat_rule(item_dates.repeat_rule)
  if not rule then
    return primary
  end
  local today = date_utils.today()
  local current = primary
  while date_utils.compare(current, today) < 0 do
    current = date_utils.apply_repeat(current, rule)
  end
  return current
end
function M.is_overdue(item_dates)
  local primary = M.get_primary_date(item_dates)
  if not primary then
    return false
  end
  if item_dates.repeat_rule then
    local next_occ = M.get_next_occurrence(item_dates)
    if next_occ then
      return date_utils.is_past(next_occ)
    end
  end
  return date_utils.is_past(primary)
end
function M.days_until_due(item_dates)
  local primary = M.get_primary_date(item_dates)
  if not primary then
    return nil
  end
  if item_dates.repeat_rule then
    primary = M.get_next_occurrence(item_dates) or primary
  end
  return date_utils.days_until(primary)
end
return M
