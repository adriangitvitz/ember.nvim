local M = {}
local cli = require('pm.cli')
local state = require('pm.state')
local utils = require('pm.utils')
local notes = require('pm.notes')
local function format_task(task)
  local note_indicator = notes.get_note_indicator(task)
  local display = string.format('%s%s %s', note_indicator, utils.format_status_icon(task.status), task.title)
  if task.changelist and task.changelist ~= '' then
    display = display .. ' (' .. task.changelist .. ')'
  end
  return display
end
local function find_task_by_display(line, tasks)
  for _, task in ipairs(tasks) do
    if line:find(task.title, 1, true) then
      return task
    end
  end
  return nil
end
local function handle_task_action(task, action)
  state.set_last_selected_task(task.id)
  if action == 'ctrl-x' then
    require('pm.commands').task_toggle(task.id)
  elseif action == 'ctrl-v' then
    require('pm.commands').task_edit(task.id)
  elseif action == 'ctrl-t' then
    notes.open_or_create_note(task, 'current')
  else
    require('pm.commands').task_view(task.id)
  end
end
function M.tasks(opts)
  opts = opts or {}
  local ok, picker = pcall(require, 'picker')
  if not ok then
    M._tasks_fallback(opts)
    return
  end
  local workspace = state.get_workspace()
  local filters = {
    workspace = workspace,
  }
  cli.list_tasks(filters, function(tasks)
    if #tasks == 0 then
      utils.notify('No tasks found')
      return
    end
    local items = {}
    for _, task in ipairs(tasks) do
      table.insert(items, format_task(task))
    end
    local prompt = workspace and ('Tasks (' .. workspace .. ')') or 'Tasks'
    picker.run({
      prompt = prompt,
      header = 'enter=view  ctrl-x=toggle  ctrl-v=edit  ctrl-t=note',
      items = items,
      on_select = function(selection, action)
        local task = find_task_by_display(selection, tasks)
        if task then
          handle_task_action(task, action)
        end
      end,
    })
  end)
end
function M._tasks_fallback(opts)
  local workspace = state.get_workspace()
  local filters = { workspace = workspace }
  cli.list_tasks(filters, function(tasks)
    if #tasks == 0 then
      utils.notify('No tasks found')
      return
    end
    local items = {}
    for _, task in ipairs(tasks) do
      table.insert(items, format_task(task))
    end
    vim.ui.select(items, {
      prompt = 'Select task:',
    }, function(choice, idx)
      if choice and tasks[idx] then
        state.set_last_selected_task(tasks[idx].id)
        require('pm.commands').task_view(tasks[idx].id)
      end
    end)
  end)
end
function M.projects(opts)
  opts = opts or {}
  local ok, picker = pcall(require, 'picker')
  if not ok then
    M._projects_fallback(opts)
    return
  end
  cli.list_projects(function(projects)
    if #projects == 0 then
      utils.notify('No projects found')
      return
    end
    local items = {}
    for _, project in ipairs(projects) do
      table.insert(items, project.name)
    end
    picker.run({
      prompt = 'Projects',
      items = items,
      on_select = function(selection)
        utils.notify('Filtering tasks by project: ' .. selection)
      end,
    })
  end)
end
function M._projects_fallback(opts)
  cli.list_projects(function(projects)
    if #projects == 0 then
      utils.notify('No projects found')
      return
    end
    local items = {}
    for _, project in ipairs(projects) do
      table.insert(items, project.name)
    end
    vim.ui.select(items, {
      prompt = 'Select project:',
    }, function(choice)
      if choice then
        utils.notify('Filtering tasks by project: ' .. choice)
      end
    end)
  end)
end
function M.workspaces(opts)
  opts = opts or {}
  local ok, picker = pcall(require, 'picker')
  if not ok then
    M._workspaces_fallback(opts)
    return
  end
  cli.list_workspaces(function(workspaces)
    if #workspaces == 0 then
      utils.notify('No workspaces found')
      return
    end
    local current = state.get_workspace()
    local items = {}
    for _, workspace in ipairs(workspaces) do
      local display = workspace
      if workspace == current then
        display = display .. ' (current)'
      end
      table.insert(items, display)
    end
    picker.run({
      prompt = 'Workspaces',
      items = items,
      on_select = function(selection)
        local workspace = selection:gsub(' %(current%)$', '')
        state.set_workspace(workspace)
        utils.notify('Workspace set to: ' .. workspace)
      end,
    })
  end)
end
function M._workspaces_fallback(opts)
  cli.list_workspaces(function(workspaces)
    if #workspaces == 0 then
      utils.notify('No workspaces found')
      return
    end
    local current = state.get_workspace()
    local items = {}
    for _, workspace in ipairs(workspaces) do
      local display = workspace
      if workspace == current then
        display = display .. ' (current)'
      end
      table.insert(items, display)
    end
    vim.ui.select(items, {
      prompt = 'Select workspace:',
    }, function(choice)
      if choice then
        local workspace = choice:gsub(' %(current%)$', '')
        state.set_workspace(workspace)
        utils.notify('Workspace set to: ' .. workspace)
      end
    end)
  end)
end
return M
