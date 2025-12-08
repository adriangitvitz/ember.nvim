local M = {}
function M.get_specs()
  local config = require("ember.config")
  local specs = {}
  table.insert(specs, require("ember.plugins.colorscheme"))
  if config.plugins.editor.enabled then
    vim.list_extend(specs, require("ember.plugins.editor"))
  end
  if config.plugins.lsp.enabled then
    vim.list_extend(specs, require("ember.plugins.lsp"))
  end
  if config.plugins.ui.enabled then
    vim.list_extend(specs, require("ember.plugins.ui"))
  end
  if config.plugins.tools.enabled then
    vim.list_extend(specs, require("ember.plugins.tools"))
  end
  if config.plugins.syntax.enabled then
    table.insert(specs, require("ember.plugins.syntax"))
  end
  local ok, user_plugins = pcall(require, "user.plugins")
  if ok and type(user_plugins) == "table" then
    vim.list_extend(specs, user_plugins)
  end
  return specs
end
return M
