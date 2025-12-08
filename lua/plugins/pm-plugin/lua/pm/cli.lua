local M = {}
local utils = require('pm.utils')
local config = require('pm.config')
function M.execute(args, on_success, on_error)
  local stdout = {}
  local stderr = {}
  local cmd = vim.list_extend({ config.options.pm_bin }, args)
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr, data)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        local output = table.concat(stdout, '\n')
        if on_success then
          on_success(output)
        end
      else
        local error_msg = table.concat(stderr, '\n')
        if on_error then
          on_error(exit_code, error_msg)
        else
          utils.notify('PM CLI error: ' .. error_msg, vim.log.levels.ERROR)
        end
      end
    end,
  })
end
function M.execute_json(args, on_success, on_error)
  M.execute(args, function(output)
    local data = utils.parse_json(output)
    if data and type(data) == 'table' and on_success then
      on_success(data)
    elseif on_error then
      on_error(1, 'Failed to parse JSON response')
    end
  end, on_error)
end
function M.list_tasks(filters, on_success, on_error)
  local args = { 'task', 'list', '--minimal' }
  if filters.workspace then
    vim.list_extend(args, { '--workspace', filters.workspace })
  end
  if filters.project then
    vim.list_extend(args, { '--project', filters.project })
  end
  if filters.status then
    vim.list_extend(args, { '--status', filters.status })
  end
  M.execute(args, function(output)
    local tasks = {}
    for line in output:gmatch('[^\r\n]+') do
      if not line:match('^Tasks:') and vim.trim(line) ~= '' then
        local task = utils.parse_minimal_task(line)
        if task then
          table.insert(tasks, task)
        end
      end
    end
    if on_success then
      on_success(tasks)
    end
  end, on_error)
end
function M.get_task(task_id, on_success, on_error)
  M.execute_json({ 'export', 'tasks', '--format', 'json' }, function(tasks)
    if type(tasks) == 'table' then
      for _, task in ipairs(tasks) do
        if task.id == task_id then
          if on_success then
            on_success(task)
          end
          return
        end
      end
    end
    if on_error then
      on_error(1, 'Task not found')
    end
  end, on_error)
end
function M.create_task(data, on_success, on_error)
  local args = { 'task', 'add', data.title }
  if data.priority then
    vim.list_extend(args, { '--priority', data.priority })
  end
  if data.project then
    vim.list_extend(args, { '--project', data.project })
  end
  if data.tags then
    vim.list_extend(args, { '--tags', data.tags })
  end
  if data.changelist then
    vim.list_extend(args, { '--cl', data.changelist })
  end
  if data.workspace then
    vim.list_extend(args, { '--ws', data.workspace })
  end
  if data.description then
    vim.list_extend(args, { '--description', data.description })
  end
  M.execute(args, function(output)
    local task_id = output:match('%(ID: (.-)%)')
    if on_success then
      on_success(task_id)
    end
    utils.notify('Task created successfully')
  end, on_error)
end
function M.update_task(task_id, data, on_success, on_error)
  local args = { 'task', 'update', task_id }
  if data.title then
    vim.list_extend(args, { '--title', data.title })
  end
  if data.status then
    vim.list_extend(args, { '--status', data.status })
  end
  if data.priority then
    vim.list_extend(args, { '--priority', data.priority })
  end
  if data.project then
    vim.list_extend(args, { '--project', data.project })
  end
  if data.tags then
    vim.list_extend(args, { '--tags', data.tags })
  end
  if data.changelist then
    vim.list_extend(args, { '--cl', data.changelist })
  end
  if data.workspace then
    vim.list_extend(args, { '--ws', data.workspace })
  end
  if data.description then
    vim.list_extend(args, { '--description', data.description })
  end
  M.execute(args, function()
    if on_success then
      on_success()
    end
    utils.notify('Task updated successfully')
  end, on_error)
end
function M.delete_task(task_id, on_success, on_error)
  M.execute({ 'task', 'delete', task_id }, function()
    if on_success then
      on_success()
    end
    utils.notify('Task deleted successfully')
  end, on_error)
end
function M.list_projects(on_success, on_error)
  M.execute({ 'project', 'list' }, function(output)
    local projects = {}
    for line in output:gmatch('[^\r\n]+') do
      if not line:match('^Projects:') and vim.trim(line) ~= '' then
        local name, id = line:match('^%s*(.-)%s+%(ID:%s*(.-)%)$')
        if name and id then
          table.insert(projects, { id = id, name = name })
        end
      end
    end
    if on_success then
      on_success(projects)
    end
  end, on_error)
end
function M.list_workspaces(on_success, on_error)
  M.execute_json({ 'export', 'tasks', '--format', 'json' }, function(tasks)
    local workspaces = {}
    local seen = {}
    if type(tasks) == 'table' then
      for _, task in ipairs(tasks) do
        if task.workspace and task.workspace ~= '' and not seen[task.workspace] then
          seen[task.workspace] = true
          table.insert(workspaces, task.workspace)
        end
      end
    end
    table.sort(workspaces)
    if on_success then
      on_success(workspaces)
    end
  end, on_error)
end
function M.start_time_tracking(task_id, on_success, on_error)
  M.execute({ 'time', 'start', '--task', task_id }, function()
    if on_success then
      on_success()
    end
    utils.notify('Time tracking started')
  end, on_error)
end
function M.stop_time_tracking(on_success, on_error)
  M.execute({ 'time', 'stop' }, function(output)
    if on_success then
      on_success()
    end
    local duration = output:match('Duration: (.-)%s')
    if duration then
      utils.notify('Time tracking stopped: ' .. duration)
    else
      utils.notify('Time tracking stopped')
    end
  end, on_error)
end
function M.time_report(period, on_success, on_error)
  local args = { 'time', 'report' }
  if period then
    table.insert(args, '--' .. period)
  end
  M.execute(args, on_success, on_error)
end
return M
