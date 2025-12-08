local config = require("notelinks.config")
local M = {}
function M.open_note(path, mode)
  mode = mode or config.get().open_mode
  if config.get().auto_save then
    vim.cmd("silent! write")
  end
  if mode == "split" then
    vim.cmd("split " .. vim.fn.fnameescape(path))
  elseif mode == "vsplit" then
    vim.cmd("vsplit " .. vim.fn.fnameescape(path))
  elseif mode == "tab" then
    vim.cmd("tabnew " .. vim.fn.fnameescape(path))
  else
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end
end
function M.create_and_open_note(title, template)
  local commands = require("notelinks.commands")
  local path, err = commands.create_note(title, template)
  if err then
    vim.notify("Failed to create note: " .. err, vim.log.levels.ERROR)
    return
  end
  M.open_note(path)
  vim.notify("Created note: " .. title, vim.log.levels.INFO)
end
function M.open_daily_note()
  local commands = require("notelinks.commands")
  local path, err = commands.daily_note()
  if err then
    vim.notify("Failed to create daily note: " .. err, vim.log.levels.ERROR)
    return
  end
  M.open_note(path)
end
function M.open_weekly_note()
  local commands = require("notelinks.commands")
  local path, err = commands.weekly_note()
  if err then
    vim.notify("Failed to create weekly note: " .. err, vim.log.levels.ERROR)
    return
  end
  M.open_note(path)
end
function M.open_monthly_note()
  local commands = require("notelinks.commands")
  local path, err = commands.monthly_note()
  if err then
    vim.notify("Failed to create monthly note: " .. err, vim.log.levels.ERROR)
    return
  end
  M.open_note(path)
end
function M.show_in_quickfix(notes, title)
  if not notes or #notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end
  local qf_list = {}
  for _, note in ipairs(notes) do
    table.insert(qf_list, {
      filename = note.path,
      text = note.title,
      type = "I",
    })
  end
  vim.fn.setqflist(qf_list)
  vim.cmd("copen")
  if title then
    vim.api.nvim_buf_set_name(0, title)
  end
end
function M.insert_link_at_cursor(note_id, note_title)
  local link_text = string.format("[[%s|%s]]", note_id, note_title)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, col) .. link_text .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)
  vim.api.nvim_win_set_cursor(0, { row, col + #link_text })
end
function M.format_date(iso_date)
  if not iso_date or iso_date == "" then
    return "Unknown"
  end
  local year, month, day = iso_date:match("^(%d+)-(%d+)-(%d+)")
  if year and month and day then
    return string.format("%s-%s-%s", year, month, day)
  end
  return iso_date
end
function M.get_note_title(path)
  local file = io.open(path, "r")
  if not file then
    return vim.fn.fnamemodify(path, ":t:r")
  end
  local in_frontmatter = false
  for line in file:lines() do
    if line == "---" then
      in_frontmatter = not in_frontmatter
    elseif not in_frontmatter then
      local title = line:match("^#%s+(.+)$")
      if title then
        file:close()
        return title
      end
    end
  end
  file:close()
  return vim.fn.fnamemodify(path, ":t:r")
end
return M
