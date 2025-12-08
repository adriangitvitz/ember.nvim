local M = {}
M.cache = {
  tasks = {},
  projects = {},
  workspaces = {},
  last_refresh = {
    tasks = 0,
    projects = 0,
    workspaces = 0,
  },
}
M.globals = {
  current_workspace = nil,
  last_selected_task_id = nil,
  tracking_task_id = nil,
}
function M.init()
  vim.g.pm_current_workspace = nil
  vim.g.pm_last_selected_task_id = nil
  vim.g.pm_tracking_task_id = nil
end
function M.set_workspace(workspace)
  M.globals.current_workspace = workspace
  vim.g.pm_current_workspace = workspace
  M.invalidate_cache('tasks')
end
function M.get_workspace()
  return vim.g.pm_current_workspace
end
function M.set_last_selected_task(task_id)
  M.globals.last_selected_task_id = task_id
  vim.g.pm_last_selected_task_id = task_id
end
function M.get_last_selected_task()
  return vim.g.pm_last_selected_task_id
end
function M.set_tracking_task(task_id)
  M.globals.tracking_task_id = task_id
  vim.g.pm_tracking_task_id = task_id
end
function M.get_tracking_task()
  return vim.g.pm_tracking_task_id
end
function M.clear_tracking_task()
  M.globals.tracking_task_id = nil
  vim.g.pm_tracking_task_id = nil
end
function M.should_refresh(cache_key)
  local config = require('pm.config')
  local last_refresh = M.cache.last_refresh[cache_key] or 0
  local now = os.time()
  return (now - last_refresh) >= config.options.cache_timeout
end
function M.update_cache(cache_key, data)
  M.cache[cache_key] = data
  M.cache.last_refresh[cache_key] = os.time()
end
function M.get_cache(cache_key)
  if M.should_refresh(cache_key) then
    return nil
  end
  return M.cache[cache_key]
end
function M.invalidate_cache(cache_key)
  if cache_key then
    M.cache[cache_key] = {}
    M.cache.last_refresh[cache_key] = 0
  else
    M.cache.tasks = {}
    M.cache.projects = {}
    M.cache.workspaces = {}
    M.cache.last_refresh = {
      tasks = 0,
      projects = 0,
      workspaces = 0,
    }
  end
end
function M.clear_cache()
  M.invalidate_cache()
  require('pm.utils').notify('Cache cleared')
end
return M
