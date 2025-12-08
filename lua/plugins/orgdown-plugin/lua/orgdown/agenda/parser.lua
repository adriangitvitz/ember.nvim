local M = {}
local scheduler = require("orgdown.agenda.scheduler")
local default_keywords = {
  todo = { "TODO", "NEXT", "WAITING" },
  done = { "DONE", "CANCELLED" },
}
function M.parse_line(line, line_nr, file, keywords)
  keywords = keywords or default_keywords
  local item = {
    text = "",
    state = nil,
    file = file,
    line = line_nr,
    deadline = nil,
    scheduled = nil,
    priority = nil,
    tags = {},
    repeat_rule = nil,
    is_checkbox = false,
    is_checked = false,
  }
  local checkbox_match = line:match("^%s*[-*+]%s*%[([ xX])%]%s*(.*)$")
  if checkbox_match then
    item.is_checkbox = true
    item.is_checked = checkbox_match:match("[xX]") ~= nil
    item.state = item.is_checked and "DONE" or "TODO"
    item.text = line:match("^%s*[-*+]%s*%[.%]%s*(.*)$") or ""
  else
    local all_keywords = {}
    for _, kw in ipairs(keywords.todo) do
      table.insert(all_keywords, kw)
    end
    for _, kw in ipairs(keywords.done) do
      table.insert(all_keywords, kw)
    end
    for _, kw in ipairs(all_keywords) do
      local pattern = "^%s*[-*+]?%s*" .. kw .. ":%s*(.*)$"
      local rest = line:match(pattern)
      if rest then
        item.state = kw
        item.text = rest
        break
      end
    end
  end
  if not item.state then
    return nil
  end
  local priority = item.text:match("%[#([ABC])%]")
  if priority then
    item.priority = priority
    item.text = item.text:gsub("%s*%[#[ABC]%]%s*", " ")
  end
  local tags_str = item.text:match(":([%w:]+):%s*$")
  if tags_str then
    for tag in tags_str:gmatch("([^:]+)") do
      table.insert(item.tags, tag)
    end
    item.text = item.text:gsub("%s*:[%w:]+:%s*$", "")
  end
  local dates = scheduler.extract_dates(item.text)
  item.deadline = dates.deadline
  item.scheduled = dates.scheduled
  item.repeat_rule = dates.repeat_rule
  if dates.inline and not item.scheduled then
    item.scheduled = dates.inline
  end
  item.text = item.text:gsub("DEADLINE:%s*%S+", "")
  item.text = item.text:gsub("SCHEDULED:%s*%S+", "")
  item.text = item.text:gsub("<[^>]+>", "")
  item.text = item.text:match("^%s*(.-)%s*$") or item.text
  return item
end
function M.parse_file(filepath, keywords)
  local items = {}
  local file = io.open(filepath, "r")
  if not file then
    return items
  end
  local line_nr = 0
  for line in file:lines() do
    line_nr = line_nr + 1
    local item = M.parse_line(line, line_nr, filepath, keywords)
    if item then
      table.insert(items, item)
    end
  end
  file:close()
  return items
end
function M.parse_files(filepaths, keywords)
  local items = {}
  for _, filepath in ipairs(filepaths) do
    local file_items = M.parse_file(filepath, keywords)
    for _, item in ipairs(file_items) do
      table.insert(items, item)
    end
  end
  return items
end
function M.expand_globs(patterns)
  local config = require("orgdown.config")
  local filepaths = {}
  local seen = {}
  local exclude_patterns = config.get("agenda.exclude") or {}
  table.insert(exclude_patterns, "%.templates/")
  table.insert(exclude_patterns, "/%.templates/")
  for _, pattern in ipairs(patterns) do
    if pattern:sub(1, 1) == "~" then
      pattern = vim.fn.expand("~") .. pattern:sub(2)
    end
    local matches = vim.fn.glob(pattern, false, true)
    for _, match in ipairs(matches) do
      if not seen[match] then
        local excluded = false
        for _, excl in ipairs(exclude_patterns) do
          if match:match(excl) then
            excluded = true
            break
          end
        end
        if not excluded then
          seen[match] = true
          table.insert(filepaths, match)
        end
      end
    end
  end
  return filepaths
end
function M.parse_all()
  local config = require("orgdown.config")
  local patterns = config.get("agenda.files") or {}
  local keywords = config.get("agenda.todo_keywords")
  local filepaths = M.expand_globs(patterns)
  return M.parse_files(filepaths, keywords)
end
function M.filter(items, predicate)
  local filtered = {}
  for _, item in ipairs(items) do
    if predicate(item) then
      table.insert(filtered, item)
    end
  end
  return filtered
end
function M.filter_by_state(items, states)
  return M.filter(items, function(item)
    return vim.tbl_contains(states, item.state)
  end)
end
function M.filter_by_tag(items, tag)
  return M.filter(items, function(item)
    return vim.tbl_contains(item.tags, tag)
  end)
end
function M.filter_by_date_range(items, start_date, end_date)
  local date_utils = require("orgdown.utils.date")
  return M.filter(items, function(item)
    local item_date = item.deadline or item.scheduled
    if not item_date then
      return false
    end
    return date_utils.compare(item_date, start_date) >= 0 and date_utils.compare(item_date, end_date) <= 0
  end)
end
function M.sort_by_date_priority(items)
  local sorted = vim.deepcopy(items)
  local date_utils = require("orgdown.utils.date")
  table.sort(sorted, function(a, b)
    local date_a = a.deadline or a.scheduled
    local date_b = b.deadline or b.scheduled
    if date_a and not date_b then
      return true
    end
    if date_b and not date_a then
      return false
    end
    if date_a and date_b then
      local cmp = date_utils.compare(date_a, date_b)
      if cmp ~= 0 then
        return cmp < 0
      end
    end
    local pri_order = { A = 1, B = 2, C = 3 }
    local pri_a = pri_order[a.priority] or 99
    local pri_b = pri_order[b.priority] or 99
    return pri_a < pri_b
  end)
  return sorted
end
return M
