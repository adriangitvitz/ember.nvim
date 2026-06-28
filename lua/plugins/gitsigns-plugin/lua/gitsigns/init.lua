local M = {}
M.config = {
  signs = {
    add = { text = "│", hl = "GitSignsAdd" },
    change = { text = "│", hl = "GitSignsChange" },
    delete = { text = "_", hl = "GitSignsDelete" },
    topdelete = { text = "‾", hl = "GitSignsDelete" },
    changedelete = { text = "~", hl = "GitSignsChangedelete" },
    untracked = { text = "┆", hl = "GitSignsUntracked" },
  },
  update_debounce = 100,
  attach_to_untracked = true,
}
local ns = vim.api.nvim_create_namespace("gitsigns")
local sign_group = "GitSigns"
local attached = {}
local cache = {}
local debounce_timers = {}
local function has_git()
  return vim.fn.executable("git") == 1
end
local root_cache = {}
local function get_git_root(path)
  if root_cache[path] ~= nil then
    return root_cache[path] or nil
  end
  local result = vim.fn.systemlist({ "git", "-C", vim.fn.fnamemodify(path, ":h"), "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and result[1] then
    root_cache[path] = result[1]
    return result[1]
  end
  root_cache[path] = false
  return nil
end
local function is_tracked(path)
  local root = get_git_root(path)
  if not root then
    return false
  end
  vim.fn.system({ "git", "-C", root, "ls-files", "--error-unmatch", path })
  return vim.v.shell_error == 0
end
local function parse_diff(diff_output)
  local hunks = {}
  for _, line in ipairs(diff_output) do
    local old_start, old_count, new_start, new_count = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
    if old_start then
      old_count = tonumber(old_count) or 1
      new_count = tonumber(new_count) or 1
      old_start = tonumber(old_start)
      new_start = tonumber(new_start)
      table.insert(hunks, {
        old_start = old_start,
        old_count = old_count,
        new_start = new_start,
        new_count = new_count,
      })
    end
  end
  return hunks
end
local function get_hunks_async(bufnr, callback)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if not path or path == "" then return callback({}) end
  local root = get_git_root(path)
  if not root then return callback({}) end
  vim.system(
    { "git", "-C", root, "diff", "--no-color", "-U0", "--", path },
    { text = true },
    function(obj)
      vim.schedule(function()
        if obj.code ~= 0 or not obj.stdout then return callback({}) end
        callback(parse_diff(vim.split(obj.stdout, "\n", { plain = true })))
      end)
    end
  )
end
local function hunks_to_signs(hunks)
  local signs = {}
  for _, hunk in ipairs(hunks) do
    if hunk.old_count == 0 then
      for i = 0, hunk.new_count - 1 do
        table.insert(signs, {
          line = hunk.new_start + i,
          type = "add",
        })
      end
    elseif hunk.new_count == 0 then
      table.insert(signs, {
        line = math.max(1, hunk.new_start),
        type = hunk.new_start == 0 and "topdelete" or "delete",
      })
    else
      local change_count = math.min(hunk.old_count, hunk.new_count)
      for i = 0, change_count - 1 do
        table.insert(signs, {
          line = hunk.new_start + i,
          type = "change",
        })
      end
      if hunk.new_count > hunk.old_count then
        for i = change_count, hunk.new_count - 1 do
          table.insert(signs, {
            line = hunk.new_start + i,
            type = "add",
          })
        end
      end
      if hunk.old_count > hunk.new_count then
        local last_line = hunk.new_start + hunk.new_count - 1
        if signs[#signs] and signs[#signs].line == last_line then
          signs[#signs].type = "changedelete"
        end
      end
    end
  end
  return signs
end
local function place_signs(bufnr, signs)
  vim.fn.sign_unplace(sign_group, { buffer = bufnr })
  for i, sign in ipairs(signs) do
    local sign_name = "GitSigns" .. sign.type:gsub("^%l", string.upper)
    vim.fn.sign_place(0, sign_group, sign_name, bufnr, { lnum = sign.line, priority = 6 })
  end
end
local function update_signs(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  get_hunks_async(bufnr, function(hunks)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    local signs = hunks_to_signs(hunks)
    cache[bufnr] = { hunks = hunks, signs = signs }
    place_signs(bufnr, signs)
  end)
end
local function update_debounced(bufnr)
  if debounce_timers[bufnr] then
    vim.fn.timer_stop(debounce_timers[bufnr])
  end
  debounce_timers[bufnr] = vim.fn.timer_start(M.config.update_debounce, function()
    debounce_timers[bufnr] = nil
    vim.schedule(function()
      update_signs(bufnr)
    end)
  end)
end
function M.next_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local data = cache[bufnr]
  if not data or #data.hunks == 0 then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  for _, hunk in ipairs(data.hunks) do
    if hunk.new_start > line then
      vim.api.nvim_win_set_cursor(0, { hunk.new_start, 0 })
      return
    end
  end
  vim.api.nvim_win_set_cursor(0, { data.hunks[1].new_start, 0 })
end
function M.prev_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local data = cache[bufnr]
  if not data or #data.hunks == 0 then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  for i = #data.hunks, 1, -1 do
    local hunk = data.hunks[i]
    if hunk.new_start < line then
      vim.api.nvim_win_set_cursor(0, { hunk.new_start, 0 })
      return
    end
  end
  vim.api.nvim_win_set_cursor(0, { data.hunks[#data.hunks].new_start, 0 })
end
function M.preview_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local data = cache[bufnr]
  if not data or #data.hunks == 0 then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = get_git_root(path)
  if not root then
    return
  end
  local hunk
  for _, h in ipairs(data.hunks) do
    if line >= h.new_start and line < h.new_start + math.max(h.new_count, 1) then
      hunk = h
      break
    end
  end
  if not hunk then
    vim.notify("No hunk at cursor", vim.log.levels.INFO)
    return
  end
  local result = vim.fn.systemlist({
    "git",
    "-C",
    root,
    "diff",
    "--no-color",
    "-U3",
    "--",
    path,
  })
  local preview_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, result)
  vim.bo[preview_buf].filetype = "diff"
  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#result, 20)
  vim.api.nvim_open_win(preview_buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = preview_buf,
    once = true,
    callback = function()
      vim.api.nvim_buf_delete(preview_buf, { force = true })
    end,
  })
end
local function find_hunk_at(bufnr, line)
  local data = cache[bufnr]
  if not data or #data.hunks == 0 then return nil end
  for _, h in ipairs(data.hunks) do
    local start = h.new_start
    local count = math.max(h.new_count, 1)
    if h.new_count == 0 then
      if line == start or line == start + 1 then return h end
    elseif line >= start and line < start + count then
      return h
    end
  end
  return nil
end

local function build_hunk_patch(rel_path, hunk_text)
  return table.concat({
    "--- a/" .. rel_path,
    "+++ b/" .. rel_path,
    hunk_text,
  }, "\n") .. "\n"
end

local function extract_hunk_text(diff_lines, target_hunk)
  local out, capturing = {}, false
  for _, line in ipairs(diff_lines) do
    local old_start, _, new_start, _ = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
    if old_start then
      old_start, new_start = tonumber(old_start), tonumber(new_start)
      capturing = (old_start == target_hunk.old_start and new_start == target_hunk.new_start)
      if capturing then table.insert(out, line) end
    elseif capturing then
      if line:sub(1, 1) == "+" or line:sub(1, 1) == "-" or line:sub(1, 1) == " " then
        table.insert(out, line)
      else
        break
      end
    end
  end
  return table.concat(out, "\n")
end

local function get_full_diff(root, path, reverse)
  local args = { "git", "-C", root, "diff", "--no-color", "-U0" }
  if reverse then table.insert(args, "-R") end
  table.insert(args, "--")
  table.insert(args, path)
  return vim.fn.systemlist(args)
end

local function apply_patch(root, patch, args)
  local cmd = { "git", "-C", root, "apply", "--unidiff-zero", "--whitespace=nowarn" }
  for _, a in ipairs(args or {}) do table.insert(cmd, a) end
  table.insert(cmd, "-")
  vim.fn.system(cmd, patch)
  return vim.v.shell_error == 0
end

function M.stage_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = get_git_root(path)
  if not root then return end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local hunk = find_hunk_at(bufnr, line)
  if not hunk then
    vim.notify("No hunk at cursor", vim.log.levels.INFO); return
  end
  local diff_lines = get_full_diff(root, path, false)
  local hunk_text = extract_hunk_text(diff_lines, hunk)
  if hunk_text == "" then
    vim.notify("Could not extract hunk", vim.log.levels.ERROR); return
  end
  local rel_path = vim.fn.fnamemodify(path, ":." .. ":~"):gsub("^" .. vim.pesc(root) .. "/", "")
  local patch = build_hunk_patch(rel_path, hunk_text)
  if apply_patch(root, patch, { "--cached" }) then
    vim.notify("Staged hunk", vim.log.levels.INFO)
    update_signs(bufnr)
  else
    vim.notify("Failed to stage hunk", vim.log.levels.ERROR)
  end
end

function M.reset_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = get_git_root(path)
  if not root then return end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local hunk = find_hunk_at(bufnr, line)
  if not hunk then
    vim.notify("No hunk at cursor", vim.log.levels.INFO); return
  end
  local diff_lines = get_full_diff(root, path, false)
  local hunk_text = extract_hunk_text(diff_lines, hunk)
  if hunk_text == "" then
    vim.notify("Could not extract hunk", vim.log.levels.ERROR); return
  end
  local rel_path = vim.fn.fnamemodify(path, ":."):gsub("^" .. vim.pesc(root) .. "/", "")
  local patch = build_hunk_patch(rel_path, hunk_text)
  if apply_patch(root, patch, { "--reverse" }) then
    vim.cmd("edit!")
    vim.notify("Reset hunk", vim.log.levels.INFO)
  else
    vim.notify("Failed to reset hunk", vim.log.levels.ERROR)
  end
end

function M.undo_stage_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = get_git_root(path)
  if not root then return end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local staged = vim.fn.systemlist({ "git", "-C", root, "diff", "--cached", "--no-color", "-U0", "--", path })
  if vim.v.shell_error ~= 0 or #staged == 0 then
    vim.notify("Nothing staged for this file", vim.log.levels.INFO); return
  end
  local target, capturing = nil, false
  local out = {}
  for _, l in ipairs(staged) do
    local old_start, _, new_start, _ = l:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
    if old_start then
      new_start = tonumber(new_start)
      if not target and new_start <= line then target = { header = l, new_start = new_start } end
      capturing = (target and target.header == l)
      if capturing then table.insert(out, l) end
    elseif capturing then
      if l:sub(1, 1):match("[+%- ]") then table.insert(out, l) else break end
    end
  end
  if #out == 0 then
    vim.notify("No staged hunk near cursor", vim.log.levels.INFO); return
  end
  local rel_path = vim.fn.fnamemodify(path, ":."):gsub("^" .. vim.pesc(root) .. "/", "")
  local patch = build_hunk_patch(rel_path, table.concat(out, "\n"))
  if apply_patch(root, patch, { "--cached", "--reverse" }) then
    vim.notify("Unstaged hunk", vim.log.levels.INFO)
    update_signs(bufnr)
  else
    vim.notify("Failed to unstage hunk", vim.log.levels.ERROR)
  end
end
local blame_ns = vim.api.nvim_create_namespace("gitsigns_inline_blame")
local blame_state = {
  enabled = false,
  cache = {},
  pending = {},
  timer = nil,
}

local function relative_time(ts)
  local diff = os.time() - tonumber(ts)
  if diff < 60 then return "just now" end
  if diff < 3600 then return math.floor(diff / 60) .. "m ago" end
  if diff < 86400 then return math.floor(diff / 3600) .. "h ago" end
  if diff < 86400 * 30 then return math.floor(diff / 86400) .. "d ago" end
  if diff < 86400 * 365 then return math.floor(diff / (86400 * 30)) .. "mo ago" end
  return math.floor(diff / (86400 * 365)) .. "y ago"
end

local function clear_blame(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, blame_ns, 0, -1)
  end
end

local function show_blame(bufnr, lnum, text)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  clear_blame(bufnr)
  vim.api.nvim_buf_set_extmark(bufnr, blame_ns, lnum - 1, 0, {
    virt_text = { { "    " .. text, "Comment" } },
    virt_text_pos = "eol",
    hl_mode = "combine",
  })
end

local function line_in_hunk(bufnr, lnum)
  local data = cache[bufnr]
  if not data then return false end
  for _, h in ipairs(data.hunks) do
    if lnum >= h.new_start and lnum < h.new_start + math.max(h.new_count, 1) then
      return true
    end
  end
  return false
end

local function fetch_blame(bufnr, lnum)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = get_git_root(path)
  if not root then return end

  if line_in_hunk(bufnr, lnum) then
    vim.schedule(function()
      if blame_state.enabled
          and vim.api.nvim_get_current_buf() == bufnr
          and vim.api.nvim_win_get_cursor(0)[1] == lnum then
        show_blame(bufnr, lnum, "(uncommitted change)")
      end
    end)
    return
  end

  blame_state.pending[bufnr] = lnum
  local stdout_chunks = {}
  vim.fn.jobstart(
    { "git", "-C", root, "blame", "-L", lnum .. "," .. lnum, "--porcelain", "--", path },
    {
      stdout_buffered = true,
      on_stdout = function(_, lines)
        if lines then for _, l in ipairs(lines) do table.insert(stdout_chunks, l) end end
      end,
      on_exit = function(_, code)
        blame_state.pending[bufnr] = nil
        if code ~= 0 or #stdout_chunks == 0 then return end
        local commit = stdout_chunks[1]:match("^(%x+)")
        if not commit then return end
        if commit:match("^0+$") then
          vim.schedule(function()
            if blame_state.enabled
                and vim.api.nvim_get_current_buf() == bufnr
                and vim.api.nvim_win_get_cursor(0)[1] == lnum then
              show_blame(bufnr, lnum, "(uncommitted change)")
            end
          end)
          return
        end
        local author, when, summary
        for _, l in ipairs(stdout_chunks) do
          if l:match("^author ") then author = (l:gsub("^author ", ""))
          elseif l:match("^author%-time ") then when = relative_time((l:gsub("^author%-time ", "")))
          elseif l:match("^summary ") then summary = (l:gsub("^summary ", "")) end
        end
        local text = string.format("%s, %s — %s", author or "?", when or "?", summary or "")
        blame_state.cache[bufnr] = blame_state.cache[bufnr] or {}
        blame_state.cache[bufnr][lnum] = text
        vim.schedule(function()
          if blame_state.enabled
              and vim.api.nvim_get_current_buf() == bufnr
              and vim.api.nvim_win_get_cursor(0)[1] == lnum then
            show_blame(bufnr, lnum, text)
          end
        end)
      end,
    }
  )
end

local function on_cursor_moved()
  if not blame_state.enabled then return end
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  clear_blame(bufnr)
  if blame_state.timer then pcall(function() blame_state.timer:stop() end) end
  blame_state.timer = vim.defer_fn(function()
    if not blame_state.enabled then return end
    if vim.api.nvim_get_current_buf() ~= bufnr then return end
    if vim.api.nvim_win_get_cursor(0)[1] ~= lnum then return end
    local cached = blame_state.cache[bufnr] and blame_state.cache[bufnr][lnum]
    if cached then
      show_blame(bufnr, lnum, cached)
    else
      fetch_blame(bufnr, lnum)
    end
  end, 300)
end

function M.toggle_inline_blame()
  blame_state.enabled = not blame_state.enabled
  if blame_state.enabled then
    vim.api.nvim_create_augroup("GitSignsInlineBlame", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
      group = "GitSignsInlineBlame",
      callback = on_cursor_moved,
    })
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = "GitSignsInlineBlame",
      callback = function(args) blame_state.cache[args.buf] = nil end,
    })
    on_cursor_moved()
    vim.notify("Inline blame ON", vim.log.levels.INFO)
  else
    pcall(vim.api.nvim_del_augroup_by_name, "GitSignsInlineBlame")
    for bufnr in pairs(blame_state.cache) do clear_blame(bufnr) end
    blame_state.cache = {}
    vim.notify("Inline blame OFF", vim.log.levels.INFO)
  end
end

function M.blame_line()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if not path or path == "" then
    vim.notify("Buffer has no file", vim.log.levels.WARN); return
  end
  local root = get_git_root(path)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  if not root then
    vim.notify("Not in a git repository", vim.log.levels.WARN); return
  end

  local porcelain = vim.fn.systemlist({
    "git", "-C", root, "blame",
    "-L", line .. "," .. line, "--porcelain", "--", path,
  })
  if vim.v.shell_error ~= 0 or #porcelain == 0 then
    vim.notify("git blame failed", vim.log.levels.ERROR); return
  end
  local commit = porcelain[1]:match("^(%x+)")
  if not commit or commit:match("^0+$") then
    vim.notify("Line not yet committed", vim.log.levels.INFO); return
  end

  local author, time, summary
  for _, l in ipairs(porcelain) do
    if l:match("^author ") then author = (l:gsub("^author ", ""))
    elseif l:match("^author%-time ") then time = os.date("%Y-%m-%d", tonumber((l:gsub("^author%-time ", ""))))
    elseif l:match("^summary ") then summary = (l:gsub("^summary ", "")) end
  end

  local body = vim.fn.systemlist({ "git", "-C", root, "show", "-s", "--format=%B", commit })
  local lines = {
    string.format("commit %s", commit:sub(1, 12)),
    string.format("Author: %s", author or "?"),
    string.format("Date:   %s", time or "?"),
    "",
  }
  if #body > 0 then
    for _, l in ipairs(body) do table.insert(lines, l) end
  elseif summary then
    table.insert(lines, summary)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "git"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  width = math.min(math.max(width + 2, 40), vim.o.columns - 4)
  local height = math.min(#lines, math.floor(vim.o.lines * 0.5))

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor", row = 1, col = 0,
    width = width, height = height,
    style = "minimal", border = "rounded",
    title = " blame ", title_pos = "left",
  })
  vim.wo[win].wrap = true

  local moved = 0
  local group = vim.api.nvim_create_augroup("GitsignsBlamePopup_" .. win, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave", "InsertEnter" }, {
    group = group,
    callback = function()
      moved = moved + 1
      if moved < 2 then return end
      pcall(vim.api.nvim_win_close, win, true)
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
end
local function attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if attached[bufnr] then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if not path or path == "" then
    return
  end
  local root = get_git_root(path)
  if not root then
    return
  end
  if not M.config.attach_to_untracked and not is_tracked(path) then
    return
  end
  attached[bufnr] = true
  update_signs(bufnr)
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    buffer = bufnr,
    callback = function()
      update_debounced(bufnr)
    end,
  })
  local opts = { buffer = bufnr }
  vim.keymap.set("n", "]h", M.next_hunk, vim.tbl_extend("force", opts, { desc = "Next hunk" }))
  vim.keymap.set("n", "[h", M.prev_hunk, vim.tbl_extend("force", opts, { desc = "Previous hunk" }))
  vim.keymap.set("n", "<leader>gp", M.preview_hunk, vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
  vim.keymap.set("n", "<leader>gs", M.stage_hunk, vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
  vim.keymap.set("n", "<leader>gu", M.undo_stage_hunk, vim.tbl_extend("force", opts, { desc = "Undo stage hunk" }))
  vim.keymap.set("n", "<leader>gr", M.reset_hunk, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
  vim.keymap.set("n", "<leader>gb", M.blame_line, vim.tbl_extend("force", opts, { desc = "Blame line (popup)" }))
  vim.keymap.set("n", "<leader>gB", M.toggle_inline_blame, vim.tbl_extend("force", opts, { desc = "Toggle inline blame" }))
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = bufnr,
    once = true,
    callback = function()
      attached[bufnr] = nil
      cache[bufnr] = nil
      if debounce_timers[bufnr] then
        vim.fn.timer_stop(debounce_timers[bufnr])
        debounce_timers[bufnr] = nil
      end
    end,
  })
end
local function setup_highlights()
  vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#9ece6a", default = true })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#7aa2f7", default = true })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#f7768e", default = true })
  vim.api.nvim_set_hl(0, "GitSignsChangedelete", { fg = "#e0af68", default = true })
  vim.api.nvim_set_hl(0, "GitSignsUntracked", { fg = "#565f89", default = true })
end
local function define_signs()
  for name, opts in pairs(M.config.signs) do
    local sign_name = "GitSigns" .. name:gsub("^%l", string.upper)
    vim.fn.sign_define(sign_name, {
      text = opts.text,
      texthl = opts.hl,
    })
  end
end
function M.setup(opts)
  opts = opts or {}
  if not has_git() then
    vim.notify("[gitsigns] git not found in PATH", vim.log.levels.WARN)
    return
  end
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  setup_highlights()
  define_signs()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("GitSigns", { clear = true }),
    callback = function(args)
      vim.schedule(function()
        attach(args.buf)
      end)
    end,
  })
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      attach(bufnr)
    end
  end
end
return M
