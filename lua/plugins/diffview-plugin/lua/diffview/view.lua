local M = {}
local git = require("diffview.git")
M.state = nil
function M.create_scratch_buffer(content, name, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  local safe_name = name:gsub("^diffview://", "diffview:"):gsub("/([^/]+)$", ":[%1]")
  vim.api.nvim_buf_set_name(buf, safe_name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content or {})
  vim.bo[buf].modifiable = false
  if ft and ft ~= "" then
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(function()
          local lang = vim.treesitter.language.get_lang(ft) or ft
          if lang and pcall(vim.treesitter.language.inspect, lang) then
            vim.treesitter.start(buf, lang)
          end
        end)
      end
    end)
  end
  return buf
end
function M.calculate_layout(total_width, panel_width)
  local max_panel = math.floor(total_width * 0.25)
  local actual_panel = math.min(panel_width, max_panel)
  local remaining = total_width - actual_panel - 2
  local diff_width = math.floor(remaining / 2)
  return {
    panel_width = actual_panel,
    left_width = diff_width,
    right_width = diff_width,
  }
end
local function get_filetype(path)
  local ext = vim.fn.fnamemodify(path, ":e")
  local ft_map = {
    lua = "lua",
    py = "python",
    js = "javascript",
    ts = "typescript",
    jsx = "javascriptreact",
    tsx = "typescriptreact",
    rs = "rust",
    go = "go",
    c = "c",
    cpp = "cpp",
    h = "c",
    hpp = "cpp",
    md = "markdown",
    json = "json",
    yaml = "yaml",
    yml = "yaml",
    toml = "toml",
    sh = "sh",
    bash = "bash",
    zsh = "zsh",
  }
  return ft_map[ext] or ""
end
local function create_panel_buffer(files, root)
  local lines = { "  Changed Files", "" }
  local categories = {
    { name = "Conflicted", type = "conflicted", icon = "!" },
    { name = "Staged", type = "staged", icon = "✓" },
    { name = "Unstaged", type = "unstaged", icon = "●" },
    { name = "Untracked", type = "untracked", icon = "?" },
  }
  local file_map = {}
  for _, cat in ipairs(categories) do
    local cat_files = vim.tbl_filter(function(f)
      return f.type == cat.type or (f.type == "both" and (cat.type == "staged" or cat.type == "unstaged"))
    end, files)
    if #cat_files > 0 then
      table.insert(lines, string.format("  %s (%d)", cat.name, #cat_files))
      for _, file in ipairs(cat_files) do
        local icon = cat.icon
        local display = "    " .. icon .. " " .. file.path
        table.insert(lines, display)
        file_map[#lines] = file
      end
      table.insert(lines, "")
    end
  end
  local buf = M.create_scratch_buffer(lines, "diffview://panel", nil)
  vim.b[buf].file_map = file_map
  vim.b[buf].root = root
  return buf
end
function M.open_diff(file, root)
  if not file then
    return
  end
  local ft = get_filetype(file.path)
  local full_path = root .. "/" .. file.path
  local working_content
  if vim.fn.filereadable(full_path) == 1 then
    working_content = vim.fn.readfile(full_path)
  else
    working_content = {}
  end
  local base_content
  if file.staged then
    base_content = git.get_head_content(root, file.path)
  else
    base_content = git.get_staged_content(root, file.path) or git.get_head_content(root, file.path)
  end
  base_content = base_content or {}
  local left_buf = M.create_scratch_buffer(base_content, "diffview://base/" .. file.path, ft)
  local right_buf = M.create_scratch_buffer(working_content, "diffview://working/" .. file.path, ft)
  if M.state then
    M.state.left_buf = left_buf
    M.state.right_buf = right_buf
    M.state.current_file = file
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("^diffview:base:") or name:match("^diffview:working:") then
      vim.api.nvim_win_close(win, true)
    end
  end
  local total_width = vim.o.columns
  local config = require("diffview").config
  local panel_width = config.layout and config.layout.panel_width or 30
  if M.state and M.state.panel_win and vim.api.nvim_win_is_valid(M.state.panel_win) then
    vim.api.nvim_set_current_win(M.state.panel_win)
  end
  vim.cmd("rightbelow vnew")
  local left_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(left_win, left_buf)
  vim.cmd("rightbelow vnew")
  local right_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_win, right_buf)
  if M.state and M.state.panel_win and vim.api.nvim_win_is_valid(M.state.panel_win) then
    vim.api.nvim_win_set_width(M.state.panel_win, panel_width)
  end
  local diff_space = total_width - panel_width - 2
  local diff_width = math.floor(diff_space / 2)
  vim.api.nvim_win_set_width(left_win, diff_width)
  vim.api.nvim_win_set_width(right_win, diff_width)
  vim.api.nvim_win_call(left_win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_win_call(right_win, function()
    vim.cmd("diffthis")
  end)
  if M.state then
    M.state.left_win = left_win
    M.state.right_win = right_win
  end
  vim.api.nvim_set_current_win(right_win)
end
local function setup_panel_keymaps(buf)
  local opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local file_map = vim.b[buf].file_map
    local root = vim.b[buf].root
    if file_map and file_map[line] then
      M.open_diff(file_map[line], root)
    end
  end, opts)
  vim.keymap.set("n", "o", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local file_map = vim.b[buf].file_map
    local root = vim.b[buf].root
    if file_map and file_map[line] then
      M.open_diff(file_map[line], root)
    end
  end, opts)
  vim.keymap.set("n", "s", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local file_map = vim.b[buf].file_map
    local root = vim.b[buf].root
    if file_map and file_map[line] then
      local file = file_map[line]
      if file.staged then
        git.unstage_file(root, file.path)
        vim.notify("Unstaged: " .. file.path, vim.log.levels.INFO)
      else
        git.stage_file(root, file.path)
        vim.notify("Staged: " .. file.path, vim.log.levels.INFO)
      end
      M.refresh()
    end
  end, opts)
  vim.keymap.set("n", "X", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local file_map = vim.b[buf].file_map
    local root = vim.b[buf].root
    if file_map and file_map[line] then
      local file = file_map[line]
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Discard changes to " .. file.path .. "?",
      }, function(choice)
        if choice == "Yes" then
          git.restore_file(root, file.path)
          vim.notify("Restored: " .. file.path, vim.log.levels.INFO)
          M.refresh()
        end
      end)
    end
  end, opts)
  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)
  vim.keymap.set("n", "R", function()
    M.refresh()
  end, opts)
end
function M.open(opts)
  opts = opts or {}
  local root = git.get_root()
  if not root then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end
  local files = git.get_status(root)
  if #files == 0 then
    vim.notify("No changes to show", vim.log.levels.INFO)
    return
  end
  M.close()
  M.state = {
    root = root,
    files = files,
    original_win = vim.api.nvim_get_current_win(),
    original_buf = vim.api.nvim_get_current_buf(),
  }
  vim.cmd("tabnew")
  local panel_buf = create_panel_buffer(files, root)
  vim.api.nvim_win_set_buf(0, panel_buf)
  local config = require("diffview").config
  local panel_width = config.layout and config.layout.panel_width or 30
  vim.cmd("vertical resize " .. panel_width)
  M.state.panel_buf = panel_buf
  M.state.panel_win = vim.api.nvim_get_current_win()
  M.state.tab = vim.api.nvim_get_current_tabpage()
  setup_panel_keymaps(panel_buf)
  vim.wo[M.state.panel_win].number = false
  vim.wo[M.state.panel_win].relativenumber = false
  vim.wo[M.state.panel_win].signcolumn = "no"
  vim.wo[M.state.panel_win].foldcolumn = "0"
  vim.wo[M.state.panel_win].cursorline = true
  vim.wo[M.state.panel_win].winfixwidth = true
  if #files > 0 then
    M.open_diff(files[1], root)
  end
end
function M.refresh()
  if not M.state or not M.state.root then
    return
  end
  local files = git.get_status(M.state.root)
  M.state.files = files
  if M.state.panel_win and vim.api.nvim_win_is_valid(M.state.panel_win) then
    local panel_buf = create_panel_buffer(files, M.state.root)
    vim.api.nvim_win_set_buf(M.state.panel_win, panel_buf)
    setup_panel_keymaps(panel_buf)
    M.state.panel_buf = panel_buf
  end
end
function M.close()
  if not M.state then
    return
  end
  if M.state.tab and vim.api.nvim_tabpage_is_valid(M.state.tab) then
    local tabs = vim.api.nvim_list_tabpages()
    if #tabs > 1 then
      vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(M.state.tab))
    end
  end
  M.state = nil
end
function M.is_open()
  return M.state ~= nil
end
function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end
return M
