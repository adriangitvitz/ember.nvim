local M = {}
local colors = {
  amber_bright = "#e9bd47",
  amber_medium = "#ECB365",
  amber_deep = "#efaf56",
  fg = "#c1c1c1",
  fg_soft = "#d2bf98",
  green_success = "#88c4a8",
  comment = "#b8b8b8",
  comment_dim = "#8a8a8a",
}
M.config = {
  header = {
    "",
    "  ┏━╸┏┳┓┏┓ ┏━╸┏━┓",
    "  ┣╸ ┃┃┃┣┻┓┣╸ ┣┳┛",
    "  ┗━╸╹ ╹┗━┛┗━╸╹┗╸",
    "",
  },
  buttons = {
    { icon = "󰈞 ", key = "f", desc = "Find file" },
    { icon = "󰈔 ", key = "n", desc = "New file" },
    { icon = "󰋚 ", key = "r", desc = "Recent files" },
    { icon = "󰒓 ", key = "c", desc = "Config" },
    { icon = "󰊄 ", key = "g", desc = "Grep" },
    { icon = "󰩈 ", key = "q", desc = "Quit" },
  },
  show_recent = false,
  recent_count = 5,
}
local ns = vim.api.nvim_create_namespace("dashboard")
local buf = nil
local win = nil
local function fzf_files()
  local root = vim.fn.getcwd()
  local tmpfile = vim.fn.tempname()
  local cmd = string.format("fd --type f --hidden --exclude .git | fzf > %s", tmpfile)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        if exit_code == 0 then
          local lines = vim.fn.readfile(tmpfile)
          if #lines > 0 and lines[1] ~= "" then
            local file = root .. "/" .. lines[1]
            if vim.fn.filereadable(file) == 1 then
              vim.cmd("edit " .. vim.fn.fnameescape(file))
            end
          end
        end
        vim.fn.delete(tmpfile)
      end)
    end,
  })
  vim.cmd("startinsert")
end
local function fzf_grep(pattern)
  local tmpfile = vim.fn.tempname()
  local cmd = string.format("rg --line-number --color=always '%s' | fzf --ansi > %s", pattern, tmpfile)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        if exit_code == 0 then
          local lines = vim.fn.readfile(tmpfile)
          if #lines > 0 and lines[1] ~= "" then
            local file, lnum = lines[1]:match("^(.+):(%d+):")
            if file and lnum then
              vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(file))
            end
          end
        end
        vim.fn.delete(tmpfile)
      end)
    end,
  })
  vim.cmd("startinsert")
end
local actions = {
  f = function()
    if vim.fn.executable("fzf") == 1 and vim.fn.executable("fd") == 1 then
      fzf_files()
    else
      vim.cmd("Explore")
    end
  end,
  n = function()
    vim.cmd("enew")
  end,
  r = function()
    local files = {}
    for i, file in ipairs(vim.v.oldfiles) do
      if i > 20 then break end
      if vim.fn.filereadable(file) == 1 then
        table.insert(files, file)
      end
    end
    if #files == 0 then
      vim.notify("No recent files", vim.log.levels.INFO)
      return
    end
    vim.ui.select(files, {
      prompt = "Recent Files:",
      format_item = function(item)
        return item:gsub(vim.fn.expand("~"), "~")
      end,
    }, function(choice)
      if choice then
        vim.cmd("edit " .. vim.fn.fnameescape(choice))
      end
    end)
  end,
  c = function()
    vim.cmd("edit $MYVIMRC")
  end,
  g = function()
    if vim.fn.executable("fzf") == 1 and vim.fn.executable("rg") == 1 then
      vim.ui.input({ prompt = "Grep: " }, function(pattern)
        if pattern and pattern ~= "" then
          fzf_grep(pattern)
        end
      end)
    else
      vim.ui.input({ prompt = "Grep: " }, function(pattern)
        if pattern and pattern ~= "" then
          vim.cmd("vimgrep /" .. pattern .. "/j **/*")
          vim.cmd("copen")
        end
      end)
    end
  end,
  q = function()
    vim.cmd("qa")
  end,
}
local function shorten_path(path)
  local home = vim.fn.expand("~")
  path = path:gsub("^" .. vim.pesc(home), "~")
  if #path <= 50 then
    return path
  end
  local parts = vim.split(path, "/")
  if #parts <= 3 then
    return path
  end
  return parts[1] .. "/.../" .. parts[#parts - 1] .. "/" .. parts[#parts]
end
local function get_icon(filename)
  local ok, icons = pcall(require, "ember.icons")
  if ok and icons.get_icon then
    return icons.get_icon(filename) or ""
  end
  return ""
end
local function get_recent_files(count)
  local files = {}
  for _, file in ipairs(vim.v.oldfiles) do
    if #files >= count then
      break
    end
    if
      vim.fn.filereadable(file) == 1
      and not file:match("^term://")
      and not file:match("^fugitive://")
      and not file:match("%.git/")
      and not file:match("COMMIT_EDITMSG")
    then
      local display = shorten_path(file)
      local icon = get_icon(file)
      table.insert(files, { path = file, display = display, icon = icon })
    end
  end
  return files
end
local function render()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  local lines = {}
  local highlights = {}
  local function add_line(text, hl_group, extra_hls)
    local pad = math.floor((width - vim.fn.strdisplaywidth(text)) / 2)
    local line = string.rep(" ", math.max(0, pad)) .. text
    table.insert(lines, line)
    if hl_group then
      table.insert(highlights, { line = #lines, hl = hl_group, col_start = 0, col_end = -1 })
    end
    if extra_hls then
      for _, ehl in ipairs(extra_hls) do
        table.insert(highlights, {
          line = #lines,
          hl = ehl.hl,
          col_start = pad + ehl.col_start,
          col_end = pad + ehl.col_end,
        })
      end
    end
  end
  local header_height = #M.config.header
  local buttons_height = #M.config.buttons + 2
  local recent_height = M.config.show_recent and (M.config.recent_count + 4) or 0
  local footer_height = 2
  local content_height = header_height + buttons_height + recent_height + footer_height + 4
  local top_padding = math.max(1, math.floor((height - content_height) / 2))
  for _ = 1, top_padding do
    table.insert(lines, "")
  end
  for _, line in ipairs(M.config.header) do
    add_line(line, "DashboardHeader")
  end
  table.insert(lines, "")
  local max_desc_len = 0
  for _, btn in ipairs(M.config.buttons) do
    if #btn.desc > max_desc_len then
      max_desc_len = #btn.desc
    end
  end
  for _, btn in ipairs(M.config.buttons) do
    local padding = max_desc_len - #btn.desc
    local text = string.format("%s %s%s  %s", btn.icon, btn.desc, string.rep(" ", padding), btn.key)
    local icon_len = vim.fn.strdisplaywidth(btn.icon)
    local desc_start = icon_len + 1
    local key_start = vim.fn.strdisplaywidth(text) - 1
    add_line(text, nil, {
      { hl = "DashboardIcon", col_start = 0, col_end = icon_len },
      { hl = "DashboardButton", col_start = desc_start, col_end = key_start },
      { hl = "DashboardKey", col_start = key_start, col_end = vim.fn.strdisplaywidth(text) },
    })
  end
  if M.config.show_recent then
    table.insert(lines, "")
    table.insert(lines, "")
    add_line("Recent Files", "DashboardSection")
    table.insert(lines, "")
    local recent = get_recent_files(M.config.recent_count)
    if #recent == 0 then
      add_line("No recent files", "DashboardComment")
    else
      for i, file in ipairs(recent) do
        local text = string.format(" %d  %s  %s", i, file.icon, file.display)
        add_line(text, "DashboardRecent")
      end
    end
  end
  table.insert(lines, "")
  local version = vim.version()
  local version_str = string.format("v%d.%d.%d", version.major, version.minor, version.patch)
  add_line(version_str, "DashboardFooter")
  while #lines < height do
    table.insert(lines, "")
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, hl.hl, hl.line - 1, hl.col_start or 0, hl.col_end or -1)
  end
end
local function setup_keymaps()
  local opts = { buffer = buf, silent = true, nowait = true }
  for key, action in pairs(actions) do
    vim.keymap.set("n", key, function()
      M.close()
      vim.schedule(function()
        local ok, err = pcall(action)
        if not ok then
          vim.notify("Dashboard action failed: " .. tostring(err), vim.log.levels.ERROR)
        end
      end)
    end, opts)
  end
  if M.config.show_recent then
    local recent = get_recent_files(M.config.recent_count)
    for i, file in ipairs(recent) do
      vim.keymap.set("n", tostring(i), function()
        M.close()
        vim.cmd("edit " .. vim.fn.fnameescape(file.path))
      end, opts)
    end
  end
  vim.keymap.set("n", "<Esc>", function()
    M.close()
    vim.cmd("qa")
  end, opts)
end
local function setup_highlights()
  vim.api.nvim_set_hl(0, "DashboardHeader", { fg = colors.fg, default = true })
  vim.api.nvim_set_hl(0, "DashboardIcon", { fg = colors.amber_bright, default = true })
  vim.api.nvim_set_hl(0, "DashboardButton", { fg = colors.fg_soft, default = true })
  vim.api.nvim_set_hl(0, "DashboardKey", { fg = colors.amber_medium, bold = true, default = true })
  vim.api.nvim_set_hl(0, "DashboardSection", { fg = colors.amber_medium, bold = true, default = true })
  vim.api.nvim_set_hl(0, "DashboardRecent", { fg = colors.green_success, default = true })
  vim.api.nvim_set_hl(0, "DashboardComment", { fg = colors.comment_dim, italic = true, default = true })
  vim.api.nvim_set_hl(0, "DashboardFooter", { fg = colors.comment_dim, default = true })
end
function M.open()
  M.close()
  buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "dashboard"
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].colorcolumn = ""
  vim.wo[win].cursorline = false
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].spell = false
  vim.wo[win].list = false
  vim.wo[win].wrap = false
  render()
  setup_keymaps()
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buf,
    callback = render,
  })
end
function M.close()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    if win and vim.api.nvim_win_is_valid(win) then
      vim.wo[win].number = vim.o.number
      vim.wo[win].relativenumber = vim.o.relativenumber
      vim.wo[win].signcolumn = vim.o.signcolumn
      vim.wo[win].wrap = vim.o.wrap
      vim.wo[win].cursorline = vim.o.cursorline
    end
    vim.api.nvim_buf_delete(buf, { force = true })
    buf = nil
    win = nil
  end
end
local function should_show()
  if vim.fn.argc() > 0 then
    return false
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    return false
  end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if #lines > 1 or (#lines == 1 and lines[1] ~= "") then
    return false
  end
  return true
end
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  setup_highlights()
  vim.api.nvim_create_user_command("Dashboard", M.open, { desc = "Open dashboard" })
  vim.api.nvim_create_user_command("DashboardClose", M.close, { desc = "Close dashboard" })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("Dashboard", { clear = true }),
    callback = function()
      if should_show() then
        vim.schedule(M.open)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufReadPre", {
    group = vim.api.nvim_create_augroup("DashboardClose", { clear = true }),
    callback = function()
      if buf and vim.api.nvim_buf_is_valid(buf) then
        M.close()
      end
    end,
  })
end
return M
