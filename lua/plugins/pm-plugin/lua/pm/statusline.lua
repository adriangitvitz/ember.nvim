local M = {}
local state = require('pm.state')
local utils = require('pm.utils')
local config = require('pm.config')
local cache = {
  task_count = 0,
  last_update = 0,
  tracking_start_time = nil,
  high_priority_count = 0,
}
local function get_task_info()
  local now = os.time()
  if now - cache.last_update < 60 then
    return {
      total = cache.task_count,
      high_priority = cache.high_priority_count
    }
  end
  local workspace = state.get_workspace()
  if not workspace then
    return { total = 0, high_priority = 0 }
  end
  local cli = require('pm.cli')
  cli.list_tasks({ workspace = workspace }, function(tasks)
    cache.task_count = #tasks
    local high_count = 0
    for _, task in ipairs(tasks) do
      if task.priority == 'high' or task.priority == 'critical' then
        high_count = high_count + 1
      end
    end
    cache.high_priority_count = high_count
    cache.last_update = now
  end)
  return {
    total = cache.task_count,
    high_priority = cache.high_priority_count
  }
end
local function get_elapsed_time()
  if not cache.tracking_start_time then
    return "0:00"
  end
  local elapsed = os.difftime(os.time(), cache.tracking_start_time)
  local hours = math.floor(elapsed / 3600)
  local minutes = math.floor((elapsed % 3600) / 60)
  if hours > 0 then
    return string.format("%d:%02d", hours, minutes)
  else
    return string.format("%d:%02d", minutes, math.floor(elapsed % 60))
  end
end
function M.get()
  local opts = config.options.statusline
  if not opts.enabled then
    return ''
  end
  local components = {}
  if opts.show_workspace then
    local workspace = state.get_workspace()
    if workspace then
      table.insert(components, workspace)
    end
  end
  if opts.show_task_count then
    local task_info = get_task_info()
    local count_str = tostring(task_info.total)
    if task_info.high_priority > 0 then
      count_str = count_str .. " (!" .. task_info.high_priority .. ")"
    end
    table.insert(components, count_str)
  end
  if opts.show_time_tracking then
    local tracking_task = state.get_tracking_task()
    if tracking_task then
      if not cache.tracking_start_time then
        cache.tracking_start_time = os.time()
      end
      local elapsed = get_elapsed_time()
      table.insert(components, '⏳' .. elapsed)
    else
      cache.tracking_start_time = nil
    end
  end
  if #components == 0 then
    return ''
  end
  return string.format('[PM: %s]', table.concat(components, ' | '))
end
function M.refresh()
  cache.last_update = 0
  vim.cmd('redrawstatus')
end
return M
