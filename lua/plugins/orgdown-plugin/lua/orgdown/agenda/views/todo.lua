local M = {}
local parser = require("orgdown.agenda.parser")
local state_mod = require("orgdown.agenda.state")
local state = {
  filter_state = nil,
  filter_tag = nil,
}
local function format_item(item)
  local parts = {}
  local filename = vim.fn.fnamemodify(item.file, ":t")
  table.insert(parts, string.format("%-15s", filename .. ":" .. item.line))
  if item.priority then
    table.insert(parts, "[#" .. item.priority .. "]")
  else
    table.insert(parts, "    ")
  end
  table.insert(parts, item.text)
  local item_date = item.deadline or item.scheduled
  if item_date then
    table.insert(parts, "<" .. require("orgdown.utils.date").format(item_date) .. ">")
  end
  if #item.tags > 0 then
    table.insert(parts, ":" .. table.concat(item.tags, ":") .. ":")
  end
  return table.concat(parts, " ")
end
function M.render(opts)
  opts = opts or {}
  state.filter_state = opts.filter_state
  state.filter_tag = opts.filter_tag
  local lines = {}
  local item_map = {}
  local header = string.rep("═", 60)
  table.insert(lines, header)
  table.insert(lines, string.format("%sTODO List", string.rep(" ", 25)))
  table.insert(lines, header)
  table.insert(lines, "")
  local all_items = parser.parse_all()
  local filtered_items = all_items
  if opts.filter_state then
    filtered_items = parser.filter_by_state(filtered_items, { opts.filter_state })
  end
  if opts.filter_tag then
    filtered_items = parser.filter_by_tag(filtered_items, opts.filter_tag)
  end
  local config = require("orgdown.config")
  local keywords = config.get("agenda.todo_keywords") or {
    todo = { "TODO", "NEXT", "WAITING" },
    done = { "DONE", "CANCELLED" },
  }
  for _, kw in ipairs(keywords.todo) do
    local state_items = parser.filter_by_state(filtered_items, { kw })
    if #state_items > 0 then
      local sorted = parser.sort_by_date_priority(state_items)
      table.insert(lines, kw .. " (" .. #sorted .. "):")
      table.insert(lines, string.rep("─", 40))
      for _, item in ipairs(sorted) do
        table.insert(lines, "  " .. format_item(item))
        item_map[#lines] = item
      end
      table.insert(lines, "")
    end
  end
  local show_done = not opts.filter_state or state_mod.is_done(opts.filter_state)
  if show_done then
    for _, kw in ipairs(keywords.done) do
      local state_items = parser.filter_by_state(filtered_items, { kw })
      if #state_items > 0 then
        local sorted = parser.sort_by_date_priority(state_items)
        table.insert(lines, kw .. " (" .. #sorted .. "):")
        table.insert(lines, string.rep("─", 40))
        for _, item in ipairs(sorted) do
          table.insert(lines, "  " .. format_item(item))
          item_map[#lines] = item
        end
        table.insert(lines, "")
      end
    end
  end
  if #item_map == 0 then
    table.insert(lines, "No TODO items found.")
    table.insert(lines, "")
  end
  table.insert(lines, string.rep("─", 60))
  table.insert(lines, "Press: d day  w week  /t filter tag  /s filter state  q quit  <CR> goto")
  return lines, item_map
end
function M.set_filter_state(filter_state)
  state.filter_state = filter_state
end
function M.set_filter_tag(filter_tag)
  state.filter_tag = filter_tag
end
function M.clear_filters()
  state.filter_state = nil
  state.filter_tag = nil
end
function M.get_filters()
  return {
    filter_state = state.filter_state,
    filter_tag = state.filter_tag,
  }
end
return M
