local M = {}
M.defaults = {
  rg_path = "rg",
  fd_path = "fd",
  fzf_path = "fzf",
  fzf = {
    height = 0.8,
    width = 0.8,
    border = "rounded",
    preview = {
      enabled = true,
      position = "right",
      width = 0.5,
    },
    keymaps = {
      select = "<CR>",
      split = "<C-x>",
      vsplit = "<C-v>",
      tab = "<C-t>",
      cancel = "<Esc>",
    },
  },
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
  notifications = {
    enabled = true,
  },
}
M.current = {}
function M.setup(user_config)
  M.current = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end
function M.get()
  if vim.tbl_isempty(M.current) then
    M.current = vim.deepcopy(M.defaults)
  end
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
