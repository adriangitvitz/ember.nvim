local M = {}
local cli = require('pm.cli')
local state = require('pm.state')
local utils = require('pm.utils')
local function parse_args(args)
  local title_parts = {}
  local flags = {}
  local i = 1
  while i <= #args do
    local arg = args[i]
    if arg:match('^%-%-') then
      local flag_name = arg:sub(3)
      if i < #args and not args[i + 1]:match('^%-%-') then
        flags[flag_name] = args[i + 1]
        i = i + 2
      else
        flags[flag_name] = true
        i = i + 1
      end
    else
      table.insert(title_parts, arg)
      i = i + 1
    end
  end
  return table.concat(title_parts, ' '), flags
end
function M.task_add(...)
  local args = { ... }
  local title, flags = parse_args(args)
  if flags.quick then
    if title == '' then
      utils.notify('Title is required', vim.log.levels.ERROR)
      return
    end
    local data = {
      title = title,
      workspace = state.get_workspace(),
    }
    cli.create_task(data, function()
      state.invalidate_cache('tasks')
    end)
    return
  end
  local function prompt_for_title(callback)
    if title ~= '' then
      callback(title)
    else
      vim.ui.input({ prompt = 'Task title: ' }, function(input)
        if not input or input == '' then
          return
        end
        callback(input)
      end)
    end
  end
  local function prompt_for_details(task_title)
    local task_data = {
      title = task_title,
      priority = flags.priority,
      project = flags.project,
      tags = flags.tags,
      changelist = flags.cl or flags.changelist,
      workspace = flags.ws or flags.workspace or state.get_workspace(),
      description = flags.description,
    }
    local prompts = {}
    if not task_data.priority then
      table.insert(prompts, {
        key = 'priority',
        prompt = 'Priority (l/n/h/c) [n]: ',
        default = 'n',
        transform = utils.parse_priority,
      })
    end
    if not task_data.project then
      table.insert(prompts, {
        key = 'project',
        prompt = 'Project (empty for none): ',
      })
    end
    if not task_data.tags then
      table.insert(prompts, {
        key = 'tags',
        prompt = 'Tags (comma-separated): ',
      })
    end
    if not task_data.changelist then
      table.insert(prompts, {
        key = 'changelist',
        prompt = 'Changelist: ',
      })
    end
    if not task_data.workspace then
      table.insert(prompts, {
        key = 'workspace',
        prompt = 'Workspace: ',
      })
    end
    local function execute_prompt(index)
      if index > #prompts then
        cli.create_task(task_data, function()
          state.invalidate_cache('tasks')
        end)
        return
      end
      local p = prompts[index]
      vim.ui.input({ prompt = p.prompt, default = p.default }, function(input)
        if input == nil then
          return
        end
        if input ~= '' then
          task_data[p.key] = p.transform and p.transform(input) or input
        end
        execute_prompt(index + 1)
      end)
    end
    execute_prompt(1)
  end
  prompt_for_title(prompt_for_details)
end
function M.task_edit(task_id)
  if not task_id or task_id == '' then
    utils.notify('Task ID is required', vim.log.levels.ERROR)
    return
  end
  cli.get_task(task_id, function(task)
    local updates = {}
    local function prompt_field(field, prompt_text, current_value, transform)
      return function(callback)
        local display_value = current_value or ''
        vim.ui.input({
          prompt = string.format('%s [%s]: ', prompt_text, display_value),
          default = display_value,
        }, function(input)
          if input == nil then
            return
          end
          if input ~= '' and input ~= display_value then
            updates[field] = transform and transform(input) or input
          end
          callback()
        end)
      end
    end
    local prompts = {
      prompt_field('title', 'Title', task.title),
      prompt_field('priority', 'Priority (l/n/h/c)', utils.format_priority(task.priority), utils.parse_priority),
      prompt_field('project', 'Project', task.project_id),
      prompt_field('tags', 'Tags', table.concat(task.tags or {}, ',')),
      prompt_field('changelist', 'Changelist', task.changelist),
      prompt_field('workspace', 'Workspace', task.workspace),
    }
    local function execute_prompts(index)
      if index > #prompts then
        if next(updates) == nil then
          utils.notify('No changes made')
          return
        end
        cli.update_task(task_id, updates, function()
          state.invalidate_cache('tasks')
        end)
        return
      end
      prompts[index](function()
        execute_prompts(index + 1)
      end)
    end
    execute_prompts(1)
  end)
end
function M.task_toggle(task_id)
  task_id = task_id or state.get_last_selected_task()
  if not task_id or task_id == '' then
    utils.notify('No task selected', vim.log.levels.ERROR)
    return
  end
  cli.get_task(task_id, function(task)
    local new_status
    if task.status == 'todo' then
      new_status = 'doing'
    elseif task.status == 'doing' then
      new_status = 'done'
    elseif task.status == 'done' then
      new_status = 'todo'
    elseif task.status == 'blocked' then
      new_status = 'todo'
    else
      new_status = 'doing'
    end
    cli.update_task(task_id, { status = new_status }, function()
      state.invalidate_cache('tasks')
    end)
  end)
end
function M.task_delete(task_id)
  if not task_id or task_id == '' then
    utils.notify('Task ID is required', vim.log.levels.ERROR)
    return
  end
  vim.ui.input({ prompt = 'Delete task? (y/n): ' }, function(input)
    if input and input:lower() == 'y' then
      cli.delete_task(task_id, function()
        state.invalidate_cache('tasks')
      end)
    end
  end)
end
function M.task_view(task_id)
  task_id = task_id or state.get_last_selected_task()
  if not task_id or task_id == '' then
    utils.notify('No task selected', vim.log.levels.ERROR)
    return
  end
  cli.get_task(task_id, function(task)
    local notes = require('pm.notes')
    notes.validate_note_link(task)
    require('pm.ui.detail').show(task)
  end)
end
function M.workspace(workspace_name)
  if not workspace_name or workspace_name == '' then
    local current = state.get_workspace()
    if current then
      utils.notify('Current workspace: ' .. current)
    else
      utils.notify('No workspace selected')
    end
    vim.ui.input({ prompt = 'Workspace: ', default = current or '' }, function(input)
      if input and input ~= '' then
        state.set_workspace(input)
        utils.notify('Workspace set to: ' .. input)
      end
    end)
  else
    state.set_workspace(workspace_name)
    utils.notify('Workspace set to: ' .. workspace_name)
  end
end
function M.time_start(task_id)
  task_id = task_id or state.get_last_selected_task()
  if not task_id or task_id == '' then
    utils.notify('No task selected', vim.log.levels.ERROR)
    return
  end
  cli.start_time_tracking(task_id, function()
    state.set_tracking_task(task_id)
  end)
end
function M.time_stop()
  cli.stop_time_tracking(function()
    state.clear_tracking_task()
  end)
end
function M.time_report(period)
  period = period or 'today'
  cli.time_report(period, function(output)
    vim.cmd('new')
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_name(buf, 'PM Time Report')
    local lines = vim.split(output, '\n')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end)
end
function M.task_with_note(task_id)
  task_id = task_id or state.get_last_selected_task()
  if not task_id or task_id == '' then
    utils.notify('No task selected', vim.log.levels.ERROR)
    return
  end
  local notes = require('pm.notes')
  notes.open_task_with_note(task_id)
end
function M.task_note(task_id)
  task_id = task_id or state.get_last_selected_task()
  if not task_id or task_id == '' then
    utils.notify('No task selected', vim.log.levels.ERROR)
    return
  end
  cli.get_task(task_id, function(task)
    local notes = require('pm.notes')
    notes.open_or_create_note(task, 'current')
  end)
end
function M.notes_cleanup()
  local notes = require('pm.notes')
  notes.cleanup_missing_notes()
end
return M
