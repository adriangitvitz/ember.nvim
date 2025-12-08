if vim.g.loaded_orgdown then
  return
end
if vim.fn.has("nvim-0.9") ~= 1 then
  vim.notify("[orgdown.nvim] Requires Neovim 0.9 or higher", vim.log.levels.ERROR)
  return
end
vim.g.loaded_orgdown = true
vim.api.nvim_create_user_command("OrgdownPreview", function()
  require("orgdown.preview").toggle()
end, { desc = "Toggle orgdown preview" })
vim.api.nvim_create_user_command("OrgdownPreviewRefresh", function()
  require("orgdown.preview").refresh()
end, { desc = "Refresh orgdown preview" })
vim.api.nvim_create_user_command("OrgdownAgenda", function()
  require("orgdown.agenda").open()
end, { desc = "Open orgdown agenda" })
vim.api.nvim_create_user_command("OrgdownAgendaDay", function()
  require("orgdown.agenda").open_day()
end, { desc = "Open orgdown day agenda" })
vim.api.nvim_create_user_command("OrgdownAgendaWeek", function()
  require("orgdown.agenda").open_week()
end, { desc = "Open orgdown week agenda" })
vim.api.nvim_create_user_command("OrgdownAgendaTodos", function()
  require("orgdown.agenda").open_todos()
end, { desc = "Open orgdown todos view" })
vim.api.nvim_create_user_command("OrgdownExecute", function()
  require("orgdown.babel").execute_current()
end, { desc = "Execute code block under cursor" })
vim.api.nvim_create_user_command("OrgdownExecuteAll", function()
  require("orgdown.babel").execute_all()
end, { desc = "Execute all code blocks" })
vim.api.nvim_create_user_command("OrgdownClearResults", function()
  require("orgdown.babel").clear_results()
end, { desc = "Clear all babel results" })
vim.api.nvim_create_user_command("OrgdownOutline", function()
  require("orgdown.navigation").toggle_outline()
end, { desc = "Toggle document outline" })
vim.api.nvim_create_user_command("OrgdownCapture", function(opts)
  require("orgdown.capture").capture(opts.args ~= "" and opts.args or nil)
end, { nargs = "?", desc = "Quick capture" })
vim.api.nvim_create_user_command("OrgdownVault", function(opts)
  require("orgdown.vault").open(opts.args ~= "" and opts.args or nil)
end, { nargs = "?", desc = "Open vault browser" })
vim.api.nvim_create_user_command("OrgdownDaily", function()
  require("orgdown.vault").daily()
end, { desc = "Open today's daily note" })
vim.api.nvim_create_user_command("OrgdownInbox", function()
  require("orgdown.vault").inbox()
end, { desc = "Open inbox" })
vim.api.nvim_create_user_command("OrgdownSearch", function(opts)
  require("orgdown.vault").search(opts.args ~= "" and opts.args or nil)
end, { nargs = "?", desc = "Search notes" })
vim.api.nvim_create_user_command("OrgdownBacklinks", function()
  require("orgdown.vault").backlinks()
end, { desc = "Show backlinks to current note" })
vim.api.nvim_create_user_command("OrgdownLinks", function()
  require("orgdown.vault").links()
end, { desc = "Show outgoing links from current note" })
vim.api.nvim_create_user_command("OrgdownReindex", function()
  require("orgdown.vault").reindex()
end, { desc = "Reindex entire vault" })
vim.api.nvim_create_user_command("OrgdownMigrate", function(opts)
  require("orgdown.vault").migrate(opts.args ~= "" and opts.args or nil)
end, { nargs = "?", desc = "Migrate notes from another directory" })
vim.api.nvim_create_user_command("OrgdownMigrateTemplates", function(opts)
  require("orgdown.vault").migrate_templates(opts.args ~= "" and opts.args or nil)
end, { nargs = "?", desc = "Migrate templates from another directory" })
vim.api.nvim_create_user_command("OrgdownNew", function(opts)
  local args = opts.args
  local topic, title
  if args ~= "" then
    local colon = args:find(":")
    if colon then
      topic = args:sub(1, colon - 1)
      title = args:sub(colon + 1)
    else
      title = args
    end
  end
  require("orgdown.vault").new({ topic = topic, title = title })
end, { nargs = "?", desc = "Create new note (format: topic:title or just title)" })
vim.api.nvim_create_user_command("OrgdownHealth", function()
  local vault = require("orgdown.vault")
  local health = vault.health()
  local lines = {
    "Orgdown Health Check:",
    "  Store available: " .. tostring(health.store_available),
    "  Store version: " .. (health.store_version or "N/A"),
    "  Vault root: " .. health.vault_root,
    "  Vault exists: " .. tostring(health.vault_exists),
    "  Initialized: " .. tostring(health.initialized),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "Show orgdown health info" })
vim.api.nvim_create_user_command("OrgdownPythonInfo", function()
  local python = require("orgdown.babel.languages.python")
  local info = python.get_info()
  local lines = {
    "Orgdown Python Environment:",
    "  Python: " .. (info.python_path or "N/A"),
    "  Source: " .. (info.source or "N/A"),
    "  " .. info.venv_description,
    "  IPython: " .. (info.ipython_available and "available" or "not found"),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "Show Python environment info" })
vim.api.nvim_create_user_command("OrgdownLearnStart", function(opts)
  local learning = require("orgdown.agenda.learning")
  if opts.args ~= "" then
    learning.start_session(opts.args)
    local status = learning.get_status()
    if status and status.note_path then
      vim.cmd("edit " .. vim.fn.fnameescape(status.note_path))
    end
  else
    learning.start_interactive()
  end
end, { nargs = "?", desc = "Start a learning session" })
vim.api.nvim_create_user_command("OrgdownLearnEnd", function(opts)
  local learning = require("orgdown.agenda.learning")
  if opts.args ~= "" then
    learning.end_session(opts.args)
  else
    learning.end_interactive()
  end
end, { nargs = "?", desc = "End current learning session" })
vim.api.nvim_create_user_command("OrgdownLearnStatus", function()
  require("orgdown.agenda.learning").show_status_window()
end, { desc = "Show learning session status" })
vim.api.nvim_create_user_command("OrgdownLearnNext", function()
  local learning = require("orgdown.agenda.learning")
  local suggestion = learning.suggest_next()
  if suggestion then
    local choice = vim.fn.confirm(
      string.format("Suggested: %s\n(%s)\n\nStart session?", suggestion.topic, suggestion.reason),
      "&Yes\n&No",
      2
    )
    if choice == 1 then
      learning.start_session(suggestion.topic, { note_path = suggestion.note_path })
      if suggestion.note_path then
        vim.cmd("edit " .. vim.fn.fnameescape(suggestion.note_path))
      end
    end
  else
    vim.notify("[orgdown.learning] No topics need review", vim.log.levels.INFO)
  end
end, { desc = "Suggest next topic to learn" })
