local M = {}
local config = require('pm.config')
function M.setup(opts)
  config.setup(opts)
  require('pm.state').init()
end
function M.statusline()
  return require('pm.statusline').get()
end
function M.tasks(opts)
  require('pm.picker').tasks(opts)
end
function M.projects(opts)
  require('pm.picker').projects(opts)
end
function M.workspaces(opts)
  require('pm.picker').workspaces(opts)
end
return M
