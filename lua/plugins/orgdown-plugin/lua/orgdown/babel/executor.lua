local M = {}
local results = require("orgdown.babel.results")
local session = require("orgdown.babel.session")
local language_handlers = {
  lua = "orgdown.babel.languages.lua",
  vim = "orgdown.babel.languages.vim",
  vimscript = "orgdown.babel.languages.vim",
  sh = "orgdown.babel.languages.shell",
  bash = "orgdown.babel.languages.shell",
  shell = "orgdown.babel.languages.shell",
  zsh = "orgdown.babel.languages.shell",
  python = "orgdown.babel.languages.python",
  python3 = "orgdown.babel.languages.python",
  py = "orgdown.babel.languages.python",
  javascript = "orgdown.babel.languages.javascript",
  js = "orgdown.babel.languages.javascript",
  node = "orgdown.babel.languages.javascript",
}
local function parse_options(info_string)
  local options = {
    results = "value",
    session = nil,
    dir = nil,
    vars = {},
  }
  for key, value in info_string:gmatch(":(%w+)%s+([^:]+)") do
    value = vim.trim(value)
    if key == "results" then
      options.results = value
    elseif key == "session" then
      options.session = value
    elseif key == "dir" then
      options.dir = vim.fn.expand(value)
    elseif key == "var" then
      for var_name, var_value in value:gmatch("(%w+)=([^%s]+)") do
        local num = tonumber(var_value)
        if num then
          options.vars[var_name] = num
        elseif var_value == "true" then
          options.vars[var_name] = true
        elseif var_value == "false" then
          options.vars[var_name] = false
        else
          options.vars[var_name] = var_value
        end
      end
    end
  end
  if info_string:match(":silent") then
    options.results = "silent"
  end
  if info_string:match(":output") then
    options.results = "output"
  end
  return options
end
function M.get_block_at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1]
  local ts = require("orgdown.treesitter")
  local blocks = ts.get_code_blocks(bufnr)
  for _, block in ipairs(blocks) do
    local block_start = (block.start_line or block.start_row + 1)
    local block_end = (block.end_line or block.end_row + 1)
    if cursor_line >= block_start and cursor_line <= block_end then
      return {
        language = block.language,
        code = block.content,
        start_line = block_start,
        end_line = block_end,
        options = parse_options(block.info_string or block.language),
      }
    end
  end
  return nil
end
function M.get_all_blocks(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ts = require("orgdown.treesitter")
  local blocks = ts.get_code_blocks(bufnr)
  local result = {}
  for _, block in ipairs(blocks) do
    table.insert(result, {
      language = block.language,
      code = block.content,
      start_line = block.start_line or block.start_row + 1,
      end_line = block.end_line or block.end_row + 1,
      options = parse_options(block.info_string or block.language),
    })
  end
  return result
end
function M.get_handler(language)
  local handler_path = language_handlers[language:lower()]
  if not handler_path then
    return nil, "Unsupported language: " .. language
  end
  local ok, handler = pcall(require, handler_path)
  if not ok then
    return nil, "Failed to load handler for: " .. language
  end
  return handler, nil
end
function M.is_supported(language)
  return language_handlers[language:lower()] ~= nil
end
function M.is_available(language)
  local handler, err = M.get_handler(language)
  if err then
    return false
  end
  if handler.is_available then
    return handler.is_available()
  end
  return true
end
function M.execute_block(block, opts)
  opts = opts or {}
  local config = require("orgdown.config")
  local lang_config = config.get("babel.languages." .. block.language:lower())
  if lang_config and lang_config.enabled == false then
    return {
      success = false,
      error = "Language '" .. block.language .. "' is disabled in configuration",
    }
  end
  local handler, err = M.get_handler(block.language)
  if err then
    return { success = false, error = err }
  end
  if handler.is_available and not handler.is_available() then
    return {
      success = false,
      error = "Interpreter for '" .. block.language .. "' not found",
    }
  end
  local exec_opts = {
    timeout = opts.timeout or config.get("babel.timeout_ms"),
    cwd = block.options.dir or opts.cwd,
    vars = vim.tbl_extend("force", block.options.vars or {}, opts.vars or {}),
  }
  if block.options.session then
    exec_opts.session = block.options.session
    session.get_or_create(block.options.session, block.language)
  end
  local result = handler.execute(block.code, exec_opts)
  if block.options.session then
    session.add_history(block.options.session, {
      code = block.code,
      result = result,
    })
  end
  return result
end
function M.execute_current(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}
  local block = M.get_block_at_cursor(bufnr)
  if not block then
    return {
      success = false,
      error = "No code block at cursor",
    }
  end
  local config = require("orgdown.config")
  if config.get("babel.confirm_execution") and not opts.confirmed then
    local choice = vim.fn.confirm(
      "Execute " .. block.language .. " code block?",
      "&Yes\n&No",
      2
    )
    if choice ~= 1 then
      return {
        success = false,
        error = "Execution cancelled",
      }
    end
  end
  local result = M.execute_block(block, opts)
  if block.options.results ~= "silent" then
    results.insert(bufnr, block.end_line, result, {
      format = config.get("babel.results_format"),
      replace = true,
    })
  end
  local events = require("orgdown.events")
  events.emit(events.EVENTS.BABEL_EXECUTED, {
    block = block,
    result = result,
    bufnr = bufnr,
  })
  return result
end
function M.execute_all(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}
  local blocks = M.get_all_blocks(bufnr)
  local config = require("orgdown.config")
  if config.get("babel.confirm_execution") and not opts.confirmed then
    local choice = vim.fn.confirm(
      "Execute all " .. #blocks .. " code blocks?",
      "&Yes\n&No",
      2
    )
    if choice ~= 1 then
      return {}
    end
  end
  opts.confirmed = true
  local all_results = {}
  for _, block in ipairs(blocks) do
    local result = M.execute_block(block, opts)
    if block.options.results ~= "silent" then
      results.insert(bufnr, block.end_line, result, {
        format = config.get("babel.results_format"),
        replace = true,
      })
    end
    table.insert(all_results, {
      block = block,
      result = result,
    })
  end
  local events = require("orgdown.events")
  events.emit(events.EVENTS.BABEL_EXECUTED, {
    blocks = blocks,
    results = all_results,
    bufnr = bufnr,
    all = true,
  })
  return all_results
end
function M.clear_current_results(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local block = M.get_block_at_cursor(bufnr)
  if not block then
    return false
  end
  return results.clear(bufnr, block.end_line)
end
function M.clear_all_results(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return results.clear_all(bufnr)
end
function M.list_languages()
  local langs = {}
  local seen = {}
  for lang, _ in pairs(language_handlers) do
    local handler_path = language_handlers[lang]
    if not seen[handler_path] then
      seen[handler_path] = true
      table.insert(langs, lang)
    end
  end
  table.sort(langs)
  return langs
end
return M
