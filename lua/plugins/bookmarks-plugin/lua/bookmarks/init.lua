local M = {}
M.config = {
  sign = {
    text = "●",
    hl = "BookmarkSign",
  },
  save_file = vim.fn.stdpath("data") .. "/bookmarks.json",
  auto_save = true,
}
local bookmarks = {}
local sign_group = "Bookmarks"
local ns = vim.api.nvim_create_namespace("bookmarks")
local function get_file_key(path)
  return vim.fn.fnamemodify(path, ":p")
end
local function save_bookmarks()
  if not M.config.auto_save then
    return
  end
  local data = vim.fn.json_encode(bookmarks)
  local file = io.open(M.config.save_file, "w")
  if file then
    file:write(data)
    file:close()
  end
end
local function load_bookmarks()
  local file = io.open(M.config.save_file, "r")
  if file then
    local content = file:read("*all")
    file:close()
    if content and content ~= "" then
      local ok, data = pcall(vim.fn.json_decode, content)
      if ok and data then
        bookmarks = data
      end
    end
  end
end
local function place_sign(bufnr, line)
  vim.fn.sign_place(0, sign_group, "BookmarkSign", bufnr, { lnum = line, priority = 10 })
end
local function remove_sign(bufnr, line)
  vim.fn.sign_unplace(sign_group, { buffer = bufnr, id = line })
end
local function clear_signs(bufnr)
  vim.fn.sign_unplace(sign_group, { buffer = bufnr })
end
local function update_signs(bufnr)
  clear_signs(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local key = get_file_key(path)
  local file_bookmarks = bookmarks[key]
  if file_bookmarks then
    for line, _ in pairs(file_bookmarks) do
      place_sign(bufnr, tonumber(line))
    end
  end
end
function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if not path or path == "" then
    vim.notify("Cannot bookmark unnamed buffer", vim.log.levels.WARN)
    return
  end
  local key = get_file_key(path)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local line_key = tostring(line)
  if not bookmarks[key] then
    bookmarks[key] = {}
  end
  if bookmarks[key][line_key] then
    bookmarks[key][line_key] = nil
    remove_sign(bufnr, line)
    vim.notify("Bookmark removed", vim.log.levels.INFO)
  else
    local content = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
    content = content:gsub("^%s+", ""):sub(1, 50)
    bookmarks[key][line_key] = {
      line = line,
      content = content,
      created = os.time(),
    }
    place_sign(bufnr, line)
    vim.notify("Bookmark added", vim.log.levels.INFO)
  end
  if vim.tbl_isempty(bookmarks[key]) then
    bookmarks[key] = nil
  end
  save_bookmarks()
end
function M.clear_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local key = get_file_key(path)
  if bookmarks[key] then
    bookmarks[key] = nil
    clear_signs(bufnr)
    save_bookmarks()
    vim.notify("Cleared buffer bookmarks", vim.log.levels.INFO)
  end
end
function M.clear_all()
  bookmarks = {}
  save_bookmarks()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      clear_signs(bufnr)
    end
  end
  vim.notify("Cleared all bookmarks", vim.log.levels.INFO)
end
function M.next()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local key = get_file_key(path)
  local file_bookmarks = bookmarks[key]
  if not file_bookmarks or vim.tbl_isempty(file_bookmarks) then
    vim.notify("No bookmarks in buffer", vim.log.levels.INFO)
    return
  end
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = {}
  for line_key, _ in pairs(file_bookmarks) do
    table.insert(lines, tonumber(line_key))
  end
  table.sort(lines)
  for _, line in ipairs(lines) do
    if line > current_line then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end
  vim.api.nvim_win_set_cursor(0, { lines[1], 0 })
end
function M.prev()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local key = get_file_key(path)
  local file_bookmarks = bookmarks[key]
  if not file_bookmarks or vim.tbl_isempty(file_bookmarks) then
    vim.notify("No bookmarks in buffer", vim.log.levels.INFO)
    return
  end
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = {}
  for line_key, _ in pairs(file_bookmarks) do
    table.insert(lines, tonumber(line_key))
  end
  table.sort(lines, function(a, b)
    return a > b
  end)
  for _, line in ipairs(lines) do
    if line < current_line then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end
  vim.api.nvim_win_set_cursor(0, { lines[1], 0 })
end
function M.list()
  local items = {}
  for file_path, file_bookmarks in pairs(bookmarks) do
    for _, bm in pairs(file_bookmarks) do
      local relative_path = vim.fn.fnamemodify(file_path, ":~:.")
      table.insert(items, {
        file = file_path,
        relative = relative_path,
        line = bm.line,
        content = bm.content,
        display = string.format("%s:%d: %s", relative_path, bm.line, bm.content or ""),
      })
    end
  end
  if #items == 0 then
    vim.notify("No bookmarks", vim.log.levels.INFO)
    return
  end
  local ok, picker = pcall(require, "picker")
  if ok then
    local display_items = {}
    for _, item in ipairs(items) do
      table.insert(display_items, item.display)
    end
    picker.run({
      items = display_items,
      prompt = "Bookmarks",
      on_select = function(selection)
        for _, item in ipairs(items) do
          if item.display == selection then
            vim.cmd("edit " .. vim.fn.fnameescape(item.file))
            vim.api.nvim_win_set_cursor(0, { item.line, 0 })
            break
          end
        end
      end,
    })
  else
    local qf_items = {}
    for _, item in ipairs(items) do
      table.insert(qf_items, {
        filename = item.file,
        lnum = item.line,
        text = item.content or "",
      })
    end
    vim.fn.setqflist({}, " ", {
      title = "Bookmarks",
      items = qf_items,
    })
    vim.cmd("copen")
  end
end
function M.annotate()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local key = get_file_key(path)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local line_key = tostring(line)
  if not bookmarks[key] or not bookmarks[key][line_key] then
    vim.notify("No bookmark at cursor", vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = "Annotation: " }, function(input)
    if input then
      bookmarks[key][line_key].annotation = input
      save_bookmarks()
      vim.notify("Annotation saved", vim.log.levels.INFO)
    end
  end)
end
local function setup_highlights()
  vim.api.nvim_set_hl(0, "BookmarkSign", { fg = "#7aa2f7", bold = true, default = true })
  vim.api.nvim_set_hl(0, "BookmarkAnnotation", { fg = "#bb9af7", italic = true, default = true })
end
local function define_signs()
  vim.fn.sign_define("BookmarkSign", {
    text = M.config.sign.text,
    texthl = M.config.sign.hl,
  })
end
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  setup_highlights()
  define_signs()
  load_bookmarks()
  vim.api.nvim_create_user_command("BookmarkToggle", M.toggle, { desc = "Toggle bookmark" })
  vim.api.nvim_create_user_command("BookmarkNext", M.next, { desc = "Next bookmark" })
  vim.api.nvim_create_user_command("BookmarkPrev", M.prev, { desc = "Previous bookmark" })
  vim.api.nvim_create_user_command("BookmarkList", M.list, { desc = "List bookmarks" })
  vim.api.nvim_create_user_command("BookmarkClear", M.clear_buffer, { desc = "Clear buffer bookmarks" })
  vim.api.nvim_create_user_command("BookmarkClearAll", M.clear_all, { desc = "Clear all bookmarks" })
  vim.api.nvim_create_user_command("BookmarkAnnotate", M.annotate, { desc = "Annotate bookmark" })
  vim.keymap.set("n", "<leader>bmm", M.toggle, { desc = "Toggle bookmark" })
  vim.keymap.set("n", "<leader>bmn", M.next, { desc = "Next bookmark" })
  vim.keymap.set("n", "<leader>bmp", M.prev, { desc = "Previous bookmark" })
  vim.keymap.set("n", "<leader>bml", M.list, { desc = "List bookmarks" })
  vim.keymap.set("n", "<leader>bmc", M.clear_buffer, { desc = "Clear buffer bookmarks" })
  vim.keymap.set("n", "<leader>bma", M.annotate, { desc = "Annotate bookmark" })
  vim.keymap.set("n", "]m", M.next, { desc = "Next bookmark" })
  vim.keymap.set("n", "[m", M.prev, { desc = "Previous bookmark" })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("Bookmarks", { clear = true }),
    callback = function(args)
      vim.schedule(function()
        update_signs(args.buf)
      end)
    end,
  })
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      update_signs(bufnr)
    end
  end
end
return M
