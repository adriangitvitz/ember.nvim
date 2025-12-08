local M = {}
local float = require('pm.ui.float')
local utils = require('pm.utils')
local state = require('pm.state')
local current_win = nil
local current_buf = nil
local current_task = nil
local function format_task(task)
  local lines = {}
  local notes = require('pm.notes')
  local priority_str = string.format('[%s]', utils.format_priority(task.priority or 1))
  table.insert(lines, string.format('%s %s', priority_str, task.title))
  table.insert(lines, string.rep('-', 60))
  table.insert(lines, string.format('Status: %s', task.status or 'todo'))
  if task.project_id and task.project_id ~= '' then
    table.insert(lines, string.format('Project: %s', task.project_id))
  end
  if task.changelist and task.changelist ~= '' then
    table.insert(lines, string.format('Changelist: %s', task.changelist))
  end
  if task.workspace and task.workspace ~= '' then
    table.insert(lines, string.format('Workspace: %s', task.workspace))
  end
  if task.tags and type(task.tags) == 'table' and #task.tags > 0 then
    table.insert(lines, string.format('Tags: %s', table.concat(task.tags, ', ')))
  end
  if task.due_date and type(task.due_date) == 'string' and task.due_date ~= '' then
    table.insert(lines, string.format('Due: %s', task.due_date))
  end
  table.insert(lines, '')
  table.insert(lines, string.rep('-', 60))
  if notes.has_note(task) then
    local note_info = notes.get_note_info(task)
    local filename = vim.fn.fnamemodify(note_info.note_path, ':t')
    table.insert(lines, string.format('[NOTE] %s', filename))
    table.insert(lines, "Press 'n' to open note")
  else
    table.insert(lines, "No note linked")
    table.insert(lines, "Press 'n' to create note")
  end
  table.insert(lines, string.rep('-', 60))
  if task.description and type(task.description) == 'string' and task.description ~= '' then
    table.insert(lines, '')
    table.insert(lines, 'Description:')
    for line in task.description:gmatch('[^\r\n]+') do
      table.insert(lines, '  ' .. line)
    end
  end
  table.insert(lines, '')
  if task.created_at then
    table.insert(lines, string.format('Created: %s', task.created_at))
  end
  if task.updated_at then
    table.insert(lines, string.format('Updated: %s', task.updated_at))
  end
  table.insert(lines, '')
  table.insert(lines, string.rep('-', 60))
  table.insert(lines, 'e: edit | t: toggle | d: delete | n: note | y: yank ID | q: close')
  return lines
end
local function setup_keybindings(buf, task)
  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function()
    M.close()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    M.close()
  end, opts)
  vim.keymap.set('n', 'e', function()
    M.close()
    require('pm.commands').task_edit(task.id)
  end, opts)
  vim.keymap.set('n', 't', function()
    require('pm.commands').task_toggle(task.id)
    vim.defer_fn(function()
      M.refresh(task.id)
    end, 100)
  end, opts)
  vim.keymap.set('n', 'd', function()
    M.close()
    require('pm.commands').task_delete(task.id)
  end, opts)
  vim.keymap.set('n', 'y', function()
    vim.fn.setreg('+', task.id)
    utils.notify('Task ID copied to clipboard')
  end, opts)
  vim.keymap.set('n', 'Y', function()
    local json = utils.encode_json(task)
    if json then
      vim.fn.setreg('+', json)
      utils.notify('Task JSON copied to clipboard')
    end
  end, opts)
  vim.keymap.set('n', 'n', function()
    local notes = require('pm.notes')
    M.close()
    notes.open_or_create_note(task, 'current')
  end, opts)
  vim.keymap.set('n', '<C-n>', function()
    local notes = require('pm.notes')
    if notes.has_note(task) then
      local choice = vim.fn.confirm(
        'Task already has a note. Create another one?',
        '&Yes\n&No',
        2
      )
      if choice ~= 1 then
        return
      end
    end
    notes.create_note_for_task(task.id, function()
      vim.defer_fn(function()
        M.refresh(task.id)
      end, 500)
    end)
  end, opts)
end
function M.show(task)
  current_task = task
  local buf, win = float.create()
  current_buf = buf
  current_win = win
  local lines = format_task(task)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'pm-detail')
  setup_keybindings(buf, task)
  state.set_last_selected_task(task.id)
end
function M.refresh(task_id)
  if not current_win or not vim.api.nvim_win_is_valid(current_win) then
    return
  end
  local cli = require('pm.cli')
  cli.get_task(task_id, function(task)
    current_task = task
    vim.api.nvim_buf_set_option(current_buf, 'modifiable', true)
    local lines = format_task(task)
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(current_buf, 'modifiable', false)
  end)
end
function M.close()
  if current_win then
    float.close(current_win)
    current_win = nil
    current_buf = nil
    current_task = nil
  end
end
return M
