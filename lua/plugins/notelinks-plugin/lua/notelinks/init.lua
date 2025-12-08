local M = {}
local config = require("notelinks.config")
local utils = require("notelinks.utils")
local ui = require("notelinks.ui")
function M.setup(user_config)
  config.setup(user_config or {})
  local opts = config.get()
  vim.api.nvim_create_user_command("DailyNote", function()
    utils.open_daily_note()
  end, { desc = "Open or create today's daily note" })
  vim.api.nvim_create_user_command("WeeklyNote", function()
    utils.open_weekly_note()
  end, { desc = "Open or create this week's note" })
  vim.api.nvim_create_user_command("MonthlyNote", function()
    utils.open_monthly_note()
  end, { desc = "Open or create this month's note" })
  vim.api.nvim_create_user_command("NoteNew", function(cmd_opts)
    if cmd_opts.args and cmd_opts.args ~= "" then
      utils.create_and_open_note(cmd_opts.args, nil)
    else
      ui.create_note_with_template()
    end
  end, { desc = "Create a new note", nargs = "?" })
  vim.api.nvim_create_user_command("NoteFind", function()
    ui.find_notes()
  end, { desc = "Find notes with fuzzy search" })
  vim.api.nvim_create_user_command("NoteSearch", function(cmd_opts)
    if cmd_opts.args and cmd_opts.args ~= "" then
      local commands = require("notelinks.commands")
      local notes, err = commands.search_notes(cmd_opts.args)
      if err then
        vim.notify("Search failed: " .. err, vim.log.levels.ERROR)
        return
      end
      utils.show_in_quickfix(notes, "Search Results: " .. cmd_opts.args)
    else
      ui.search_notes()
    end
  end, { desc = "Search notes", nargs = "?" })
  vim.api.nvim_create_user_command("NoteLink", function()
    ui.select_note_to_link()
  end, { desc = "Create link to another note" })
  vim.api.nvim_create_user_command("NoteBacklinks", function()
    ui.show_backlinks()
  end, { desc = "Show backlinks for current note" })
  vim.api.nvim_create_user_command("NoteGrep", function(cmd_opts)
    if cmd_opts.args and cmd_opts.args ~= "" then
      ui.grep_notes(cmd_opts.args)
    else
      vim.notify("Usage: :NoteGrep <pattern>", vim.log.levels.ERROR)
    end
  end, { desc = "Grep through notes", nargs = "?" })
  if opts.mappings then
    local function map(mode, lhs, rhs, desc)
      if lhs and lhs ~= false then
        vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
      end
    end
    map("n", opts.mappings.daily_note, utils.open_daily_note, "Open daily note")
    map("n", opts.mappings.weekly_note, utils.open_weekly_note, "Open weekly note")
    map("n", opts.mappings.monthly_note, utils.open_monthly_note, "Open monthly note")
    map("n", opts.mappings.new_note, ui.create_note_with_template, "Create new note")
    map("n", opts.mappings.find_note, ui.find_notes, "Find notes")
    map("n", opts.mappings.search_notes, ui.search_notes, "Search notes")
    map("n", opts.mappings.insert_link, ui.select_note_to_link, "Insert link to note")
    map("n", opts.mappings.show_backlinks, ui.show_backlinks, "Show backlinks")
  end
  local augroup = vim.api.nvim_create_augroup("Notelinks", { clear = true })
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = augroup,
    pattern = opts.notes_dir .. "/*.md",
    callback = function()
      vim.bo.filetype = "markdown"
      vim.wo.conceallevel = 2
    end,
  })
end
M.daily_note = utils.open_daily_note
M.weekly_note = utils.open_weekly_note
M.monthly_note = utils.open_monthly_note
M.new_note = ui.create_note_with_template
M.find_notes = ui.find_notes
M.search_notes = ui.search_notes
M.insert_link = ui.select_note_to_link
M.show_backlinks = ui.show_backlinks
return M
