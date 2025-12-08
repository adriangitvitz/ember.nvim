local M = {}
M.defaults = {
  cli_path = "dn-tui",
  notes_dir = vim.fn.expand("~/.debug-notes"),
  mappings = {
    daily_note = "<leader>dn",
    weekly_note = "<leader>dw",
    monthly_note = "<leader>dm",
    new_note = "<leader>nn",
    find_note = "<leader>nf",
    search_notes = "<leader>ns",
    insert_link = "<leader>nl",
    show_backlinks = "<leader>nb",
  },
  telescope = {
    enabled = true,
    theme = "dropdown",
  },
  auto_save = true,
  open_mode = "current",
}
M.options = {}
function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end
function M.get()
  return M.options
end
return M
