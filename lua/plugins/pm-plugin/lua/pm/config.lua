local M = {}
M.defaults = {
  pm_bin = 'pm',
  cache_timeout = 300,
  float = {
    border = 'rounded',
    width = 0.6,
    height = 0.7,
  },
  statusline = {
    enabled = true,
    show_workspace = true,
    show_task_count = true,
    show_time_tracking = true,
    format = '[%w] [%c] [%t]',
  },
  notifications = {
    enabled = true,
    timeout = 2000,
  },
}
M.options = {}
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end
return M
