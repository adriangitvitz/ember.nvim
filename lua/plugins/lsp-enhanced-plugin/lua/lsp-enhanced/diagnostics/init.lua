local M = {}
local display = require('lsp-enhanced.diagnostics.display')
local navigation = require('lsp-enhanced.diagnostics.navigation')
local default_config = {
  enabled = true,
  virtual_text = {
    enabled = true,
    max_length = 50,
    prefix = '■ ',
    spacing = 4,
  },
  signs = {
    enabled = true,
    error = '✘',
    warn = '▲',
    hint = '⚑',
    info = '»',
  },
  underline = {
    enabled = true,
  },
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'always',
  },
}
local config = vim.deepcopy(default_config)
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', default_config, user_config or {})
  if not config.enabled then
    return
  end
  display.update_config(config)
end
function M.get_config()
  return vim.deepcopy(config)
end
function M.goto_next(opts)
  navigation.goto_next(opts)
end
function M.goto_prev(opts)
  navigation.goto_prev(opts)
end
function M.goto_first_error(opts)
  navigation.goto_first_error(opts)
end
function M.show_float(opts)
  opts = vim.tbl_extend('force', config.float or {}, opts or {})
  display.show_diagnostic_float(opts)
end
function M.get_counts(bufnr)
  return navigation.get_diagnostic_counts(bufnr)
end
function M.has_diagnostics_at_cursor()
  return navigation.has_diagnostics_at_cursor()
end
function M.get_sorted(bufnr, opts)
  return navigation.get_sorted_diagnostics(bufnr, opts)
end
function M.enable()
  config.enabled = true
  display.update_config(config)
end
function M.disable()
  config.enabled = false
  vim.diagnostic.config({
    virtual_text = false,
    signs = false,
    underline = false,
  })
end
function M.toggle()
  if config.enabled then
    M.disable()
  else
    M.enable()
  end
  return config.enabled
end
return M
