local M = {}
local templates = require("orgdown.capture.templates")
M.templates = templates
local capture_win = nil
local capture_buf = nil
local capture_context = nil
local function create_capture_content(template)
  local expanded, cursor_pos = templates.expand(template.template)
  local lines = vim.split(expanded, "\n", { plain = true })
  local cursor_line = 1
  local cursor_col = 0
  if cursor_pos then
    local pos = 0
    for i, line in ipairs(lines) do
      if pos + #line >= cursor_pos then
        cursor_line = i
        cursor_col = cursor_pos - pos
        break
      end
      pos = pos + #line + 1
    end
  end
  return lines, cursor_line, cursor_col
end
local function get_target_file(template)
  local config = require("orgdown.config")
  if template and template.file then
    return vim.fn.expand(template.file)
  end
  return vim.fn.expand(config.get("capture.default_file"))
end
function M.open(template_key)
  local config = require("orgdown.config")
  local template
  if template_key then
    template = templates.get(template_key)
    if not template then
      vim.notify("Template not found: " .. template_key, vim.log.levels.ERROR)
      return
    end
  else
    local all_templates = templates.list()
    local keys = vim.tbl_keys(all_templates)
    if #keys == 0 then
      vim.notify("No capture templates configured", vim.log.levels.WARN)
      return
    end
    if #keys == 1 then
      template = all_templates[keys[1]]
      template_key = keys[1]
    else
      local items = {}
      for key, tmpl in pairs(all_templates) do
        table.insert(items, key .. ": " .. tmpl.name)
      end
      table.sort(items)
      vim.ui.select(items, {
        prompt = "Select template:",
      }, function(choice)
        if choice then
          local key = choice:match("^([^:]+)")
          M.open(key)
        end
      end)
      return
    end
  end
  if M.is_open() then
    M.close()
  end
  capture_context = {
    template = template,
    template_key = template_key,
    target_file = get_target_file(template),
  }
  capture_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(capture_buf, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(capture_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(capture_buf, "filetype", "markdown")
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = capture_buf,
    callback = function()
      M.save()
    end,
  })
  local lines, cursor_line, cursor_col = create_capture_content(template)
  vim.api.nvim_buf_set_lines(capture_buf, 0, -1, false, lines)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.max(10, math.min(20, #lines + 2))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  capture_win = vim.api.nvim_open_win(capture_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Capture: " .. template.name .. " ",
    title_pos = "center",
  })
  vim.api.nvim_win_set_cursor(capture_win, { cursor_line, cursor_col })
  vim.api.nvim_win_set_option(capture_win, "wrap", true)
  vim.api.nvim_win_set_option(capture_win, "cursorline", true)
  local opts = { buffer = capture_buf, silent = true }
  vim.keymap.set("n", "<CR>", function()
    M.save()
  end, opts)
  vim.keymap.set("i", "<C-c>", function()
    vim.cmd("stopinsert")
    M.close()
  end, opts)
  vim.keymap.set("n", "<Esc>", function()
    M.close()
  end, opts)
  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)
  vim.api.nvim_buf_set_name(capture_buf, "Capture")
  vim.cmd("startinsert")
  local events = require("orgdown.events")
  events.emit(events.EVENTS.CAPTURE_OPENED, {
    template = template,
    bufnr = capture_buf,
  })
end
function M.close()
  if capture_win and vim.api.nvim_win_is_valid(capture_win) then
    vim.api.nvim_win_close(capture_win, true)
  end
  capture_win = nil
  capture_buf = nil
  capture_context = nil
  local events = require("orgdown.events")
  events.emit(events.EVENTS.CAPTURE_CLOSED, {})
end
function M.save()
  if not M.is_open() or not capture_context then
    return false
  end
  local lines = vim.api.nvim_buf_get_lines(capture_buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  content = content:gsub("%s+$", "")
  if content == "" then
    vim.notify("Capture is empty, not saving", vim.log.levels.INFO)
    M.close()
    return false
  end
  local target_file = capture_context.target_file
  local target_dir = vim.fn.fnamemodify(target_file, ":h")
  if vim.fn.isdirectory(target_dir) == 0 then
    vim.fn.mkdir(target_dir, "p")
  end
  local file = io.open(target_file, "a")
  if not file then
    vim.notify("Failed to open file: " .. target_file, vim.log.levels.ERROR)
    return false
  end
  local existing_content = io.open(target_file, "r")
  if existing_content then
    local existing = existing_content:read("*a")
    existing_content:close()
    if existing and existing ~= "" and not existing:match("\n$") then
      file:write("\n")
    end
    if existing and existing ~= "" then
      file:write("\n")
    end
  end
  file:write(content)
  file:write("\n")
  file:close()
  vim.notify("Captured to: " .. target_file, vim.log.levels.INFO)
  local events = require("orgdown.events")
  events.emit(events.EVENTS.CAPTURE_SAVED, {
    file = target_file,
    content = content,
    template = capture_context.template,
  })
  M.close()
  return true
end
function M.is_open()
  return capture_win ~= nil and vim.api.nvim_win_is_valid(capture_win)
end
function M.capture(template_key)
  M.open(template_key)
end
function M.setup_keymaps(bufnr)
  local config = require("orgdown.config")
  local keymaps = config.get("keymaps")
  if keymaps.capture and keymaps.capture ~= false then
    vim.keymap.set("n", keymaps.capture, function()
      M.capture()
    end, {
      buffer = bufnr,
      desc = "Quick capture",
      silent = true,
    })
  end
end
function M.setup_commands()
  vim.api.nvim_create_user_command("OrgdownCapture", function(opts)
    local template_key = opts.args ~= "" and opts.args or nil
    M.capture(template_key)
  end, {
    desc = "Open capture window",
    nargs = "?",
    complete = function()
      return vim.tbl_keys(templates.list())
    end,
  })
end
function M.setup()
  M.setup_commands()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "orgdown" },
    callback = function(args)
      local config = require("orgdown.config")
      if config.get("modules.capture") then
        M.setup_keymaps(args.buf)
      end
    end,
    group = vim.api.nvim_create_augroup("orgdown_capture", { clear = true }),
  })
end
return M
