local M = {}
local config = require("notelinks.config")
local commands = require("notelinks.commands")
local buffer_cache = {}
local function detect_note_type(filepath)
  local filename = vim.fn.fnamemodify(filepath, ":t:r")
  if filename:match("^%d%d%d%d%-%d%d%-%d%d$") then
    return "D"
  end
  if filename:match("^%d%d%d%d%-W%d%d$") then
    return "W"
  end
  if filename:match("^%d%d%d%d%-%d%d$") then
    return "M"
  end
  if filename:match("^%d%d%d%d%-Q%d$") then
    return "Q"
  end
  if filename:match("^%d%d%d%d$") then
    return "Y"
  end
  return nil
end
local function is_note_file(filepath)
  if filepath == "" then
    return false
  end
  local notes_dir = config.get().notes_dir
  return vim.startswith(filepath, vim.fn.expand(notes_dir))
end
local function get_backlink_count(note_id)
  if not note_id then
    return 0
  end
  local backlinks, err = commands.get_backlinks(note_id)
  if err or not backlinks then
    return 0
  end
  return #backlinks
end
local function get_note_info(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cached = buffer_cache[bufnr]
  if cached and (os.time() - cached.timestamp) < 300 then
    return cached.info
  end
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if not is_note_file(filepath) then
    buffer_cache[bufnr] = {
      info = nil,
      timestamp = os.time()
    }
    return nil
  end
  local info = {
    is_note = true,
    note_type = detect_note_type(filepath),
    backlinks = 0,
  }
  local note_id, err = commands.get_current_note_id()
  if not err and note_id then
    info.note_id = note_id
    info.backlinks = get_backlink_count(note_id)
  end
  buffer_cache[bufnr] = {
    info = info,
    timestamp = os.time()
  }
  return info
end
function M.statusline()
  local info = get_note_info()
  if not info or not info.is_note then
    return ""
  end
  local parts = {}
  table.insert(parts, "📝")
  if info.note_type then
    table.insert(parts, info.note_type)
  end
  if info.backlinks > 0 then
    table.insert(parts, "⟵" .. info.backlinks)
  end
  return table.concat(parts, " ")
end
function M.clear_cache(bufnr)
  if bufnr then
    buffer_cache[bufnr] = nil
  else
    buffer_cache = {}
  end
end
function M.is_note()
  local info = get_note_info()
  return info and info.is_note or false
end
function M.setup_autocmd()
  local augroup = vim.api.nvim_create_augroup("NotelinkStatusline", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    pattern = "*.md",
    callback = function(ev)
      M.clear_cache(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(ev)
      buffer_cache[ev.buf] = nil
    end,
  })
end
return M
