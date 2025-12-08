local M = {}
function M.setup()
  require("ember.core.options").setup()
  require("ember.core.keymaps").setup()
  require("ember.core.autocmds").setup()
  require("ember.core.performance").setup()
  require("ember.core.netrw").setup()
end
return M
