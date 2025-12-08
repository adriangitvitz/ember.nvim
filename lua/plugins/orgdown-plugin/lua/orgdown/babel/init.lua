local M = {}
local executor = require("orgdown.babel.executor")
local results = require("orgdown.babel.results")
local session = require("orgdown.babel.session")
function M.execute(opts)
  local result = executor.execute_current(nil, opts)
  if result.success then
    vim.notify("Code executed successfully", vim.log.levels.INFO)
  elseif result.error then
    vim.notify("Execution failed: " .. result.error, vim.log.levels.ERROR)
  end
  return result
end
function M.execute_all(opts)
  local all_results = executor.execute_all(nil, opts)
  local success_count = 0
  local error_count = 0
  for _, item in ipairs(all_results) do
    if item.result.success then
      success_count = success_count + 1
    else
      error_count = error_count + 1
    end
  end
  local msg = string.format(
    "Executed %d blocks: %d success, %d failed",
    #all_results,
    success_count,
    error_count
  )
  local level = error_count > 0 and vim.log.levels.WARN or vim.log.levels.INFO
  vim.notify(msg, level)
  return all_results
end
function M.clear_results()
  local cleared = executor.clear_current_results()
  if cleared then
    vim.notify("Results cleared", vim.log.levels.INFO)
  else
    vim.notify("No results to clear", vim.log.levels.WARN)
  end
  return cleared
end
function M.clear_all_results()
  local count = executor.clear_all_results()
  vim.notify("Cleared " .. count .. " result blocks", vim.log.levels.INFO)
  return count
end
function M.get_current_block()
  return executor.get_block_at_cursor()
end
function M.get_blocks()
  return executor.get_all_blocks()
end
function M.is_supported(language)
  return executor.is_supported(language)
end
function M.is_available(language)
  return executor.is_available(language)
end
function M.list_languages()
  return executor.list_languages()
end
M.session = {
  create = session.create,
  get = session.get,
  get_or_create = session.get_or_create,
  clear = session.clear,
  clear_all = session.clear_all,
  list = session.list,
  get_vars = session.get_vars,
  set_var = session.set_var,
  get_var = session.get_var,
  get_history = session.get_history,
  info = session.info,
}
M.results = {
  find = results.find_results,
  insert = results.insert,
  clear = results.clear,
  clear_all = results.clear_all,
  has = results.has_results,
  get_content = results.get_content,
}
function M.setup_keymaps(bufnr)
  local config = require("orgdown.config")
  local keymaps = config.get("keymaps")
  local function map(key, fn, desc)
    if key and key ~= false then
      vim.keymap.set("n", key, fn, {
        buffer = bufnr,
        desc = desc,
        silent = true,
      })
    end
  end
  map(keymaps.babel_execute, M.execute, "Execute code block")
  map(keymaps.babel_execute_all, M.execute_all, "Execute all code blocks")
  map(keymaps.babel_clear_results, M.clear_results, "Clear results")
end
function M.setup_commands()
  vim.api.nvim_create_user_command("OrgdownExecute", function()
    M.execute()
  end, { desc = "Execute code block under cursor" })
  vim.api.nvim_create_user_command("OrgdownExecuteAll", function()
    M.execute_all()
  end, { desc = "Execute all code blocks" })
  vim.api.nvim_create_user_command("OrgdownClearResults", function()
    M.clear_results()
  end, { desc = "Clear results for current block" })
  vim.api.nvim_create_user_command("OrgdownClearAllResults", function()
    M.clear_all_results()
  end, { desc = "Clear all results in buffer" })
  vim.api.nvim_create_user_command("OrgdownListLanguages", function()
    local langs = M.list_languages()
    local available = {}
    local unavailable = {}
    for _, lang in ipairs(langs) do
      if M.is_available(lang) then
        table.insert(available, lang)
      else
        table.insert(unavailable, lang)
      end
    end
    local lines = { "Available languages:" }
    for _, lang in ipairs(available) do
      table.insert(lines, "  ✓ " .. lang)
    end
    if #unavailable > 0 then
      table.insert(lines, "")
      table.insert(lines, "Unavailable (interpreter not found):")
      for _, lang in ipairs(unavailable) do
        table.insert(lines, "  ✗ " .. lang)
      end
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "List supported languages" })
  vim.api.nvim_create_user_command("OrgdownSessions", function()
    local sessions = M.session.list()
    if #sessions == 0 then
      vim.notify("No active sessions", vim.log.levels.INFO)
      return
    end
    local lines = { "Active sessions:" }
    for _, name in ipairs(sessions) do
      local info = M.session.info(name)
      table.insert(
        lines,
        string.format(
          "  %s (%s) - %d vars, %d history",
          name,
          info.language,
          info.var_count,
          info.history_count
        )
      )
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "List active babel sessions" })
end
function M.setup()
  M.setup_commands()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "orgdown" },
    callback = function(args)
      local config = require("orgdown.config")
      if config.get("modules.babel") then
        M.setup_keymaps(args.buf)
      end
    end,
    group = vim.api.nvim_create_augroup("orgdown_babel", { clear = true }),
  })
end
return M
