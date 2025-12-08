local M = {}
M.defaults = {
  rg_path = "rg",
  fd_path = "fd",
  search = {
    case_mode = "smart",
    use_regex = false,
    include_hidden = false,
    follow_symlinks = false,
    max_results = 1000,
  },
  file_types = {
    default = nil,
  },
  quickfix = {
    auto_open = true,
    auto_focus = false,
    auto_close = false,
    max_height = 15,
    min_height = 3,
    preserve_on_close = true,
    position = "bottom",
  },
  netrw = {
    open_dirs = true,
  },
  notifications = {
    enabled = true,
    timeout = 2000,
  },
}
M.current = {}
function M.setup(user_config)
  M.current = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end
function M.get()
  return M.current
end
function M.set(key, value)
  local keys = vim.split(key, ".", { plain = true })
  local tbl = M.current
  for i = 1, #keys - 1 do
    if not tbl[keys[i]] then
      tbl[keys[i]] = {}
    end
    tbl = tbl[keys[i]]
  end
  tbl[keys[#keys]] = value
end
return M
