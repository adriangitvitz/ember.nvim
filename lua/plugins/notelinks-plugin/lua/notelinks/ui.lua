-- local config = require("notelinks.config")
local commands = require("notelinks.commands")
local utils = require("notelinks.utils")
local M = {}
local function format_note(note)
  local title = note.title or note.filename
  local date = utils.format_date(note.created) or ""
  if date ~= "" then
    return title .. " (" .. date .. ")"
  end
  return title
end
local function find_note_by_display(line, notes)
  for _, note in ipairs(notes) do
    local title = note.title or note.filename
    if line:find(title, 1, true) then
      return note
    end
  end
  return nil
end
local function run_notes_picker(opts)
  local ok, picker = pcall(require, "picker")
  if not ok then
    local items = {}
    for _, note in ipairs(opts.notes) do
      table.insert(items, format_note(note))
    end
    vim.ui.select(items, {
      prompt = opts.prompt .. ":",
    }, function(choice, idx)
      if choice and opts.notes[idx] then
        opts.on_select(opts.notes[idx])
      end
    end)
    return
  end
  local items = {}
  for _, note in ipairs(opts.notes) do
    table.insert(items, format_note(note))
  end
  local header = nil
  if opts.action_type == "open" then
    header = "enter=open  ctrl-x=split  ctrl-v=vsplit"
  end
  picker.run({
    prompt = opts.prompt,
    header = header,
    items = items,
    on_select = function(selection, action)
      local note = find_note_by_display(selection, opts.notes)
      if note then
        if opts.action_type == "open" then
          local mode = nil
          if action == "ctrl-x" then
            mode = "split"
          elseif action == "ctrl-v" then
            mode = "vsplit"
          end
          utils.open_note(note.path or note.filename, mode)
        else
          opts.on_select(note, action)
        end
      end
    end,
  })
end
function M.find_notes()
  local notes, err = commands.list_notes()
  if err then
    vim.notify("Failed to list notes: " .. err, vim.log.levels.ERROR)
    return
  end
  if not notes or #notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end
  run_notes_picker({
    prompt = "Find Notes",
    notes = notes,
    action_type = "open",
    on_select = function(note)
      utils.open_note(note.path or note.filename)
    end,
  })
end
function M.search_notes()
  local notes, err = commands.list_notes()
  if err then
    vim.notify("Failed to list notes: " .. err, vim.log.levels.ERROR)
    return
  end
  if not notes or #notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end
  run_notes_picker({
    prompt = "Search Notes",
    notes = notes,
    action_type = "open",
    on_select = function(note)
      utils.open_note(note.path or note.filename)
    end,
  })
end
function M.select_note_to_link()
  local current_note_id, err = commands.get_current_note_id()
  if err then
    vim.notify("Not in a note file", vim.log.levels.ERROR)
    return
  end
  local notes, list_err = commands.list_notes()
  if list_err then
    vim.notify("Failed to list notes: " .. list_err, vim.log.levels.ERROR)
    return
  end
  local filtered_notes = {}
  -- FIX: unkwon|nil to parameter
  for _, note in ipairs(notes) do
    if note.id ~= current_note_id then
      table.insert(filtered_notes, note)
    end
  end
  if #filtered_notes == 0 then
    vim.notify("No other notes available", vim.log.levels.INFO)
    return
  end
  local current_file = vim.fn.expand("%:p")
  run_notes_picker({
    prompt = "Select Note to Link",
    notes = filtered_notes,
    action_type = "link",
    on_select = function(note)
      local success, link_err = commands.create_link(current_file, note.id)
      if not success then
        vim.notify("Failed to create link: " .. link_err, vim.log.levels.ERROR)
        return
      end
      utils.insert_link_at_cursor(note.id, note.title)
      vim.notify("Linked to: " .. note.title, vim.log.levels.INFO)
      vim.cmd("edit!")
    end,
  })
end
function M.show_backlinks()
  local current_note_id, err = commands.get_current_note_id()
  if err then
    vim.notify("Not in a note file", vim.log.levels.ERROR)
    return
  end
  local backlinks, backlink_err = commands.get_backlinks(current_note_id)
  if backlink_err then
    vim.notify("Failed to get backlinks: " .. backlink_err, vim.log.levels.ERROR)
    return
  end
  if not backlinks or #backlinks == 0 then
    vim.notify("No backlinks found", vim.log.levels.INFO)
    return
  end
  run_notes_picker({
    prompt = "Backlinks",
    notes = backlinks,
    action_type = "open",
    on_select = function(note)
      utils.open_note(note.path or note.filename)
    end,
  })
end
function M.create_note_with_template()
  local templates, err = commands.list_templates()
  if err then
    vim.notify("Failed to list templates: " .. err, vim.log.levels.ERROR)
    return
  end
  if not templates or #templates == 0 then
    vim.notify("No templates found", vim.log.levels.INFO)
    return
  end
  table.insert(templates, 1, { Name = "[blank]", Description = "Empty note" })
  vim.ui.input({ prompt = "Note title: " }, function(title)
    if not title or title == "" then
      return
    end
    local template_names = {}
    for _, tmpl in ipairs(templates) do
      local name = tmpl.Name
      if tmpl.Description and tmpl.Description ~= "" then
        name = name .. " - " .. tmpl.Description
      end
      table.insert(template_names, name)
    end
    local ok, picker = pcall(require, "picker")
    if ok then
      picker.run({
        prompt = "Select Template",
        items = template_names,
        on_select = function(selection)
          local template_name = selection:match("^([^%-]+)"):gsub("%s+$", "")
          if template_name == "[blank]" then
            template_name = nil
          end
          utils.create_and_open_note(title, template_name)
        end,
      })
    else
      vim.ui.select(template_names, {
        prompt = "Select template:",
      }, function(choice)
        if not choice then
          return
        end
        local template_name = choice:match("^([^%-]+)"):gsub("%s+$", "")
        if template_name == "[blank]" then
          template_name = nil
        end
        utils.create_and_open_note(title, template_name)
      end)
    end
  end)
end
return M
