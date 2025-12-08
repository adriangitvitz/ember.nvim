local M = {}
M.config = {
  keymaps = {
    panel = {
      open = { "<CR>", "o" },
      stage = "s",
      restore = "X",
      refresh = "R",
      quit = "q",
    },
    diff = {
      next_hunk = "]c",
      prev_hunk = "[c",
      focus_panel = "<C-w>h",
    },
  },
  layout = {
    panel_width = 30,
  },
}
local function setup_highlights()
  vim.api.nvim_set_hl(0, "DiffviewHeader", { fg = "#7aa2f7", bold = true, default = true })
  vim.api.nvim_set_hl(0, "DiffviewStaged", { fg = "#9ece6a", default = true })
  vim.api.nvim_set_hl(0, "DiffviewUnstaged", { fg = "#e0af68", default = true })
  vim.api.nvim_set_hl(0, "DiffviewUntracked", { fg = "#565f89", default = true })
  vim.api.nvim_set_hl(0, "DiffviewConflicted", { fg = "#f7768e", default = true })
end
function M.open(opts)
  require("diffview.view").open(opts)
end
function M.close()
  require("diffview.view").close()
end
function M.toggle()
  require("diffview.view").toggle()
end
function M.file_history(opts)
  opts = opts or {}
  local git = require("diffview.git")
  local root = git.get_root()
  if not root then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end
  local path = opts.path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = nil
  end
  local commits = git.get_file_history(root, path, { max_count = opts.max_count or 50 })
  if #commits == 0 then
    vim.notify("No commits found", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, commit in ipairs(commits) do
    local display = string.format("%s %s - %s (%s)", commit.short_hash, commit.date, commit.subject, commit.author)
    table.insert(items, display)
  end
  local ok, picker = pcall(require, "picker")
  if ok then
    picker.run({
      items = items,
      prompt = "File History",
      on_select = function(selection)
        local hash = selection:match("^(%x+)")
        if hash then
          for _, commit in ipairs(commits) do
            if commit.short_hash == hash then
              vim.notify(string.format("Commit: %s\nAuthor: %s\nDate: %s\n\n%s", commit.hash, commit.author, commit.date, commit.subject), vim.log.levels.INFO)
              break
            end
          end
        end
      end,
    })
  else
    local qf_items = {}
    for _, commit in ipairs(commits) do
      table.insert(qf_items, {
        text = string.format("%s %s - %s (%s)", commit.short_hash, commit.date, commit.subject, commit.author),
      })
    end
    vim.fn.setqflist({}, " ", {
      title = "File History",
      items = qf_items,
    })
    vim.cmd("copen")
  end
end
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  setup_highlights()
  vim.api.nvim_create_user_command("DiffviewOpen", function(args)
    M.open({ args = args.args })
  end, { nargs = "*", desc = "Open diffview" })
  vim.api.nvim_create_user_command("DiffviewClose", function()
    M.close()
  end, { desc = "Close diffview" })
  vim.api.nvim_create_user_command("DiffviewToggle", function()
    M.toggle()
  end, { desc = "Toggle diffview" })
  vim.api.nvim_create_user_command("DiffviewFileHistory", function(args)
    local path = args.args ~= "" and args.args or nil
    M.file_history({ path = path })
  end, { nargs = "?", complete = "file", desc = "File history" })
  vim.keymap.set("n", "<leader>gd", M.open, { desc = "Open diffview" })
  vim.keymap.set("n", "<leader>gD", M.close, { desc = "Close diffview" })
  vim.keymap.set("n", "<leader>gh", M.file_history, { desc = "File history" })
end
return M
