local cli = require('pm.cli')
-- local utils = require('pm.utils')
-- local config = require('pm.config')
local M = {}
local function has_notelinks()
  local ok, notelinks = pcall(require, 'notelinks')
  return ok, notelinks
end
function M.has_note(task)
  if not task then
    return false
  end
  return task.has_note == true and task.note_path ~= nil and task.note_path ~= ''
end
function M.get_note_info(task)
  if not M.has_note(task) then
    return nil
  end
  return {
    note_id = task.note_id,
    note_path = task.note_path,
    note_title = M.get_note_title_from_path(task.note_path),
    note_created_at = task.note_created_at,
    note_updated_at = task.note_updated_at,
  }
end
function M.get_note_title_from_path(note_path)
  if not note_path or note_path == '' then
    return nil
  end
  local filename = vim.fn.fnamemodify(note_path, ':t:r')
  local file = io.open(note_path, 'r')
  if not file then
    return filename
  end
  local in_frontmatter = false
  for line in file:lines() do
    if line == '---' then
      in_frontmatter = not in_frontmatter
    elseif not in_frontmatter then
      local title = line:match('^#%s+(.+)$')
      if title then
        file:close()
        return title
      end
    end
  end
  file:close()
  return filename
end
function M.open_note(task, mode)
  mode = mode or 'current'
  if not M.has_note(task) then
    vim.notify('Task does not have a linked note', vim.log.levels.INFO)
    return false
  end
  local note_path = task.note_path
  if vim.fn.filereadable(note_path) ~= 1 then
    vim.notify('Note file not found: ' .. note_path, vim.log.levels.ERROR)
    return false
  end
  if mode == 'split' then
    vim.cmd('split ' .. vim.fn.fnameescape(note_path))
  elseif mode == 'vsplit' then
    vim.cmd('vsplit ' .. vim.fn.fnameescape(note_path))
  elseif mode == 'tab' then
    vim.cmd('tabnew ' .. vim.fn.fnameescape(note_path))
  else
    vim.cmd('edit ' .. vim.fn.fnameescape(note_path))
  end
  vim.notify('Opened note for task: ' .. task.title, vim.log.levels.INFO)
  return true
end
function M.create_note_for_task(task_id, callback)
  local ok, notelinks = has_notelinks()
  if not ok then
    vim.notify('notelinks.nvim is not installed', vim.log.levels.ERROR)
    return
  end
  cli.get_task(task_id, function(task)
    if not task then
      vim.notify('Task not found: ' .. task_id, vim.log.levels.ERROR)
      return
    end
    local note_title = string.format('Task: %s', task.title)
    local commands = require('notelinks.commands')
    local note_path, err = commands.create_note(note_title, 'task-note')
    if err then
      vim.notify('Failed to create note: ' .. err, vim.log.levels.ERROR)
      return
    end
    local function populate_template_variables(path, task_data)
      local file = io.open(path, 'r')
      if not file then
        return false
      end
      local content = file:read('*all')
      file:close()
      content = content:gsub('{{task_id}}', task_data.id)
      content = content:gsub('{{task_title}}', task_data.title)
      file = io.open(path, 'w')
      if not file then
        return false
      end
      file:write(content)
      file:close()
      return true
    end
    if not populate_template_variables(note_path, task) then
      vim.notify('Warning: Failed to populate template variables', vim.log.levels.WARN)
    end
    local function extract_note_id(path)
      local file = io.open(path, 'r')
      if not file then
        return nil
      end
      local in_frontmatter = false
      local note_id = nil
      for line in file:lines() do
        if line == '---' then
          if in_frontmatter then
            break
          else
            in_frontmatter = true
          end
        elseif in_frontmatter then
          local id_match = line:match('^id:%s*(.+)$')
          if id_match then
            note_id = vim.trim(id_match)
            break
          end
        end
      end
      file:close()
      return note_id
    end
    local note_id = extract_note_id(note_path)
    if not note_id then
      vim.notify('Failed to extract note ID from created note', vim.log.levels.ERROR)
      return
    end
    local pm_config = require('pm.config')
    local pm_bin = pm_config.options.pm_bin or 'pm'
    local link_cmd = string.format('%s task note link %s %s', pm_bin, task_id, note_id)
    vim.fn.system(link_cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to link note to task', vim.log.levels.ERROR)
      return
    end
    vim.notify('Note created and linked to task', vim.log.levels.INFO)
    require('notelinks.utils').open_note(note_path)
    if callback then
      vim.defer_fn(callback, 500)
    end
  end)
end
function M.open_or_create_note(task, mode)
  if M.has_note(task) then
    return M.open_note(task, mode)
  else
    local choice = vim.fn.confirm(
      string.format("Task '%s' has no linked note. Create one?", task.title),
      '&Yes\n&No',
      1
    )
    if choice == 1 then
      M.create_note_for_task(task.id, function()
        vim.notify('Note created successfully', vim.log.levels.INFO)
      end)
    end
    return false
  end
end
function M.open_task_with_note(task_id)
  cli.get_task(task_id, function(task)
    if not task then
      vim.notify('Task not found: ' .. task_id, vim.log.levels.ERROR)
      return
    end
    local detail = require('pm.ui.detail')
    detail.close()
    vim.cmd('vsplit')
    detail.show(task)
    vim.cmd('wincmd l')
    if M.has_note(task) then
      M.open_note(task, 'current')
    else
      M.create_note_for_task(task.id, function()
      end)
    end
  end)
end
function M.get_note_indicator(task)
  if M.has_note(task) then
    return '[NOTE] '
  end
  return ''
end
function M.format_note_status(task)
  if not M.has_note(task) then
    return 'No note linked'
  end
  local note_info = M.get_note_info(task)
  local filename = vim.fn.fnamemodify(note_info.note_path, ':t')
  return string.format('[NOTE] %s', filename)
end
function M.validate_note_link(task)
  if not M.has_note(task) then
    return true
  end
  local note_path = task.note_path
  if vim.fn.filereadable(note_path) ~= 1 then
    local choice = vim.fn.confirm(
      string.format("Note file for task '%s' not found:\n%s\n\nUnlink this note from the task?",
        task.title, note_path),
      '&Yes\n&No',
      1
    )
    if choice == 1 then
      local pm_config = require('pm.config')
      local pm_bin = pm_config.options.pm_bin or 'pm'
      local unlink_cmd = string.format('%s task note unlink %s', pm_bin, task.id)
      vim.fn.system(unlink_cmd)
      if vim.v.shell_error == 0 then
        vim.notify('Note unlinked from task', vim.log.levels.INFO)
        return false
      else
        vim.notify('Failed to unlink note', vim.log.levels.ERROR)
        return false
      end
    end
    return false
  end
  return true
end
function M.cleanup_missing_notes()
  local pm_config = require('pm.config')
  local pm_bin = pm_config.options.pm_bin or 'pm'
  local export_cmd = string.format('%s export tasks --format json', pm_bin)
  local output = vim.fn.system(export_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to export tasks', vim.log.levels.ERROR)
    return
  end
  local ok, tasks = pcall(vim.fn.json_decode, output)
  if not ok or not tasks then
    vim.notify('Failed to parse tasks', vim.log.levels.ERROR)
    return
  end
  local missing_count = 0
  local unlinked_count = 0
  for _, task in ipairs(tasks) do
    if task.has_note and task.note_path then
      if vim.fn.filereadable(task.note_path) ~= 1 then
        missing_count = missing_count + 1
        local unlink_cmd = string.format('%s task note unlink %s', pm_bin, task.id)
        vim.fn.system(unlink_cmd)
        if vim.v.shell_error == 0 then
          unlinked_count = unlinked_count + 1
        end
      end
    end
  end
  if missing_count > 0 then
    vim.notify(
      string.format('Found %d missing notes, unlinked %d', missing_count, unlinked_count),
      vim.log.levels.INFO
    )
  else
    vim.notify('No missing notes found', vim.log.levels.INFO)
  end
end
return M
