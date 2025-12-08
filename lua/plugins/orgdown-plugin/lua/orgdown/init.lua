local M = {}
M._version = "0.1.0"
local initialized = false
local function safe_require(module_path)
  local ok, module = pcall(require, module_path)
  if not ok then
    vim.notify(
      "[orgdown] Failed to load " .. module_path .. ": " .. tostring(module),
      vim.log.levels.DEBUG
    )
    return nil
  end
  return module
end
local function setup_highlights()
  local config = require("orgdown.config")
  local highlights = config.get("highlights")
  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end
local function setup_keymaps(bufnr)
  local config = require("orgdown.config")
  local keymaps = config.get("keymaps")
  local function map(lhs, rhs, desc)
    if lhs and lhs ~= false then
      vim.keymap.set("n", lhs, rhs, {
        buffer = bufnr,
        desc = desc,
        silent = true,
      })
    end
  end
  if config.is_module_enabled("preview") then
    map(keymaps.preview_toggle, function()
      require("orgdown.preview").toggle()
    end, "Toggle preview")
    map(keymaps.preview_refresh, function()
      require("orgdown.preview").refresh()
    end, "Refresh preview")
  end
  if config.is_module_enabled("agenda") then
    map(keymaps.agenda_open, function()
      require("orgdown.agenda").open()
    end, "Open agenda")
    map(keymaps.todo_cycle, function()
      require("orgdown.agenda").cycle_todo()
    end, "Cycle TODO state")
  end
  if config.is_module_enabled("babel") then
    map(keymaps.babel_execute, function()
      require("orgdown.babel").execute_current()
    end, "Execute code block")
    map(keymaps.babel_execute_all, function()
      require("orgdown.babel").execute_all()
    end, "Execute all code blocks")
  end
  if config.is_module_enabled("navigation") then
    map(keymaps.next_heading, function()
      require("orgdown.navigation").next_heading()
    end, "Next heading")
    map(keymaps.prev_heading, function()
      require("orgdown.navigation").prev_heading()
    end, "Previous heading")
    map(keymaps.outline_toggle, function()
      require("orgdown.navigation").toggle_outline()
    end, "Toggle outline")
  end
  if config.is_module_enabled("folding") then
    map(keymaps.fold_toggle, function()
      require("orgdown.folding").toggle()
    end, "Toggle fold")
  end
  if config.is_module_enabled("capture") then
    map(keymaps.capture, function()
      require("orgdown.capture").capture()
    end, "Quick capture")
  end
  if config.is_module_enabled("vault") then
    map(keymaps.vault_open, function()
      require("orgdown.vault").open()
    end, "Open vault")
    map(keymaps.vault_daily, function()
      require("orgdown.vault").daily()
    end, "Open daily note")
    map(keymaps.vault_inbox, function()
      require("orgdown.vault").inbox()
    end, "Open inbox")
    map(keymaps.vault_new, function()
      require("orgdown.vault").new()
    end, "New note")
    map(keymaps.vault_search, function()
      require("orgdown.vault").search()
    end, "Search notes")
    map(keymaps.vault_backlinks, function()
      require("orgdown.vault").backlinks()
    end, "Show backlinks")
    map(keymaps.vault_links, function()
      require("orgdown.vault").links()
    end, "Show outgoing links")
  end
  if config.is_module_enabled("agenda") then
    map(keymaps.learn_start, function()
      require("orgdown.agenda.learning").start_interactive()
    end, "Start learning session")
    map(keymaps.learn_end, function()
      require("orgdown.agenda.learning").end_interactive()
    end, "End learning session")
    map(keymaps.learn_status, function()
      require("orgdown.agenda.learning").show_status_window()
    end, "Show learning status")
    map(keymaps.learn_next, function()
      local learning = require("orgdown.agenda.learning")
      local suggestion = learning.suggest_next()
      if suggestion then
        vim.notify(suggestion.topic .. " (" .. suggestion.reason .. ")", vim.log.levels.INFO)
      end
    end, "Suggest next learning topic")
  end
end
local function setup_autocommands()
  local group = vim.api.nvim_create_augroup("orgdown", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(args)
      setup_keymaps(args.buf)
      local events = safe_require("orgdown.events")
      if events then
        events.emit(events.EVENTS.BUFFER_ENTERED, { bufnr = args.buf })
      end
    end,
  })
end
local function init_module(name)
  local module = safe_require("orgdown." .. name)
  if not module then
    return false
  end
  if type(module.setup) == "function" then
    local config = require("orgdown.config")
    local module_config = config.get(name) or {}
    local ok, err = pcall(module.setup, module_config)
    if not ok then
      vim.notify(
        "[orgdown] Module " .. name .. " failed to initialize: " .. tostring(err),
        vim.log.levels.WARN
      )
      return false
    end
  end
  return true
end
function M.setup(opts)
  opts = opts or {}
  local config = require("orgdown.config")
  config.setup(opts)
  setup_highlights()
  setup_autocommands()
  local modules = { "preview", "agenda", "babel", "navigation", "folding", "capture", "vault" }
  for _, name in ipairs(modules) do
    if config.is_module_enabled(name) then
      init_module(name)
    end
  end
  initialized = true
end
function M.is_initialized()
  return initialized
end
function M.version()
  return M._version
end
M.preview = setmetatable({}, {
  __index = function(_, key)
    return require("orgdown.preview")[key]
  end,
})
M.agenda = setmetatable({}, {
  __index = function(_, key)
    return require("orgdown.agenda")[key]
  end,
})
M.babel = setmetatable({}, {
  __index = function(_, key)
    return require("orgdown.babel")[key]
  end,
})
M.navigation = setmetatable({}, {
  __index = function(_, key)
    return require("orgdown.navigation")[key]
  end,
})
M.folding = setmetatable({}, {
  __index = function(_, key)
    return require("orgdown.folding")[key]
  end,
})
M.capture = setmetatable({}, {
  __index = function(_, key)
    return require("orgdown.capture")[key]
  end,
})
M.vault = setmetatable({}, {
  __index = function(_, key)
    return require("orgdown.vault")[key]
  end,
})
return M
