local M = {}
M.defaults = {
  modules = {
    preview = true,
    agenda = true,
    babel = true,
    folding = true,
    navigation = true,
    capture = true,
    vault = true,
  },
  preview = {
    mode = "float",
    position = "right",
    width = 0.5,
    height = 0.8,
    border = "rounded",
    live_update = true,
    debounce_ms = 150,
    scroll_sync = true,
  },
  agenda = {
    files = {},
    todo_keywords = {
      todo = { "TODO", "NEXT", "WAITING" },
      done = { "DONE", "CANCELLED" },
    },
    date_format = "%Y-%m-%d",
    time_format = "%H:%M",
    week_start = 1,
  },
  babel = {
    confirm_execution = true,
    timeout_ms = 30000,
    results_format = "drawer",
    languages = {
      lua = { enabled = true },
      vim = { enabled = true },
      sh = { enabled = true, shell = "bash" },
      python = { enabled = true, cmd = "python3", auto_venv = true },
      javascript = { enabled = true, cmd = "node" },
    },
  },
  folding = {
    default_state = "all_open",
  },
  navigation = {
    follow_links = true,
    create_missing = true,
  },
  capture = {
    default_file = "~/notes/inbox.md",
    templates = {
      t = { name = "Todo", template = "- [ ] %?" },
      n = { name = "Note", template = "## %?\n\n" },
    },
  },
  vault = {
    root = "~/notes",
    topics = {},
    auto_index = true,
    daily = {
      enabled = true,
      date_format = "%Y-%m-%d",
      template = nil,
    },
    inbox = {
      file = "inbox.md",
    },
    store = {
      binary = "orgdown-store",
      path = "~/.orgdown",
    },
  },
  keymaps = {
    preview_toggle = "<leader>mp",
    preview_refresh = "<leader>mr",
    agenda_open = "<leader>ma",
    agenda_day = "<leader>mad",
    agenda_week = "<leader>maw",
    agenda_todos = "<leader>mat",
    todo_cycle = "<leader>mt",
    todo_cycle_back = "<leader>mT",
    babel_execute = "<leader>me",
    babel_execute_all = "<leader>mE",
    babel_clear_results = "<leader>mc",
    next_heading = "]]",
    prev_heading = "[[",
    parent_heading = "g[",
    next_sibling = "}",
    prev_sibling = "{",
    follow_link = "<CR>",
    go_back = "<BS>",
    insert_link = "<leader>mL",
    outline_toggle = "<leader>mo",
    fold_toggle = "<Tab>",
    fold_all = "zM",
    unfold_all = "zR",
    capture = "<leader>mn",
    checkbox_toggle = "<C-Space>",
    vault_open = "<leader>mv",
    vault_daily = "<leader>md",
    vault_inbox = "<leader>mi",
    vault_new = "<leader>mN",
    vault_search = "<leader>ms",
    vault_backlinks = "<leader>mb",
    vault_links = "<leader>ml",
    learn_start = "<leader>mls",
    learn_end = "<leader>mle",
    learn_status = "<leader>mlS",
    learn_next = "<leader>mln",
  },
  highlights = {
    OrgdownH1 = { fg = "#ff79c6", bold = true },
    OrgdownH2 = { fg = "#bd93f9", bold = true },
    OrgdownH3 = { fg = "#8be9fd", bold = true },
    OrgdownH4 = { fg = "#50fa7b" },
    OrgdownH5 = { fg = "#ffb86c" },
    OrgdownH6 = { fg = "#ff5555" },
    OrgdownTodo = { fg = "#ff5555", bold = true },
    OrgdownDone = { fg = "#50fa7b", bold = true },
    OrgdownLink = { fg = "#8be9fd", underline = true },
    OrgdownCode = { bg = "#44475a" },
    OrgdownBlockquote = { fg = "#6272a4", italic = true },
    OrgdownCheckbox = { fg = "#ffb86c" },
    OrgdownCheckboxDone = { fg = "#50fa7b" },
  },
}
local current_config = nil
local change_listeners = {}
local valid_values = {
  ["preview.mode"] = { "float", "split", "tab" },
  ["preview.position"] = { "right", "left", "top", "bottom" },
  ["babel.results_format"] = { "drawer", "block", "inline" },
  ["folding.default_state"] = { "all_open", "all_closed", "top_level" },
}
local function deep_merge(t1, t2)
  local result = vim.deepcopy(t1)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end
local function get_path(tbl, path)
  local current = tbl
  for part in path:gmatch("[^%.]+") do
    if type(current) ~= "table" then
      return nil
    end
    current = current[part]
  end
  return current
end
local function set_path(tbl, path, value)
  local parts = {}
  for part in path:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  local current = tbl
  for i = 1, #parts - 1 do
    local part = parts[i]
    if type(current[part]) ~= "table" then
      current[part] = {}
    end
    current = current[part]
  end
  current[parts[#parts]] = value
end
function M.validate(user_config)
  if user_config.preview and user_config.preview.mode then
    local valid = valid_values["preview.mode"]
    if not vim.tbl_contains(valid, user_config.preview.mode) then
      return false, "Invalid preview.mode: " .. user_config.preview.mode .. ". Must be one of: " .. table.concat(valid, ", ")
    end
  end
  if user_config.preview and user_config.preview.position then
    local valid = valid_values["preview.position"]
    if not vim.tbl_contains(valid, user_config.preview.position) then
      return false, "Invalid preview.position: " .. user_config.preview.position .. ". Must be one of: " .. table.concat(valid, ", ")
    end
  end
  if user_config.preview and user_config.preview.debounce_ms then
    if user_config.preview.debounce_ms < 0 then
      return false, "Invalid preview.debounce_ms: must be non-negative"
    end
  end
  if user_config.babel and user_config.babel.results_format then
    local valid = valid_values["babel.results_format"]
    if not vim.tbl_contains(valid, user_config.babel.results_format) then
      return false, "Invalid babel.results_format: " .. user_config.babel.results_format
    end
  end
  if user_config.babel and user_config.babel.timeout_ms then
    if user_config.babel.timeout_ms < 0 then
      return false, "Invalid babel.timeout_ms: must be non-negative"
    end
  end
  return true, nil
end
function M.setup(user_config)
  user_config = user_config or {}
  local ok, err = M.validate(user_config)
  if not ok then
    vim.notify("[orgdown] Configuration error: " .. err, vim.log.levels.ERROR)
    current_config = vim.deepcopy(M.defaults)
    return
  end
  current_config = deep_merge(M.defaults, user_config)
end
function M.get(path)
  if not current_config then
    return path and get_path(M.defaults, path) or vim.deepcopy(M.defaults)
  end
  if not path then
    return vim.deepcopy(current_config)
  end
  return get_path(current_config, path)
end
function M.set(path, value)
  if not current_config then
    current_config = vim.deepcopy(M.defaults)
  end
  local test_config = vim.deepcopy(current_config)
  set_path(test_config, path, value)
  local parts = {}
  for part in path:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  local validate_config = {}
  if #parts >= 2 then
    validate_config[parts[1]] = { [parts[2]] = value }
  end
  local ok, err = M.validate(validate_config)
  if not ok then
    vim.notify("[orgdown] Invalid value for " .. path .. ": " .. err, vim.log.levels.WARN)
    return false
  end
  set_path(current_config, path, value)
  for _, listener in ipairs(change_listeners) do
    pcall(listener, path, value)
  end
  return true
end
function M.reset(path)
  if not path then
    current_config = vim.deepcopy(M.defaults)
    return
  end
  local default_value = get_path(M.defaults, path)
  if default_value ~= nil then
    set_path(current_config, path, vim.deepcopy(default_value))
  end
end
function M.is_module_enabled(module_name)
  return M.get("modules." .. module_name) == true
end
function M.on_change(callback)
  table.insert(change_listeners, callback)
  return function()
    for i, cb in ipairs(change_listeners) do
      if cb == callback then
        table.remove(change_listeners, i)
        return
      end
    end
  end
end
return M
