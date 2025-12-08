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
local function get_git_root(path)
  local result = vim.fn.systemlist({ "git", "-C", vim.fn.fnamemodify(path, ":h"), "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and result[1] then
    return result[1]
  end
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
local function get_hunks(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if not path or path == "" then
    return {}
  end
  local root = get_git_root(path)
  if not root then
    return {}
  end
  local result = vim.fn.systemlist({
    "git",
    "-C",
    root,
    "diff",
    "--no-color",
    "-U0",
    "--",
    path,
  })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return parse_diff(result)
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
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local hunks = get_hunks(bufnr)
  local signs = hunks_to_signs(hunks)
  cache[bufnr] = {
    hunks = hunks,
    signs = signs,
  }
  place_signs(bufnr, signs)
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
function M.stage_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = get_git_root(path)
  if not root then
    return
  end
  vim.fn.system({ "git", "-C", root, "add", path })
  if vim.v.shell_error == 0 then
    vim.notify("Staged file", vim.log.levels.INFO)
    update_signs(bufnr)
  else
    vim.notify("Failed to stage", vim.log.levels.ERROR)
  end
end
function M.reset_hunk()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = get_git_root(path)
  if not root then
    return
  end
  vim.fn.system({ "git", "-C", root, "checkout", "--", path })
  if vim.v.shell_error == 0 then
    vim.cmd("edit!")
    vim.notify("Reset file", vim.log.levels.INFO)
  else
    vim.notify("Failed to reset", vim.log.levels.ERROR)
  end
end
function M.blame_line()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = get_git_root(path)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  if not root then
    return
  end
  local result = vim.fn.systemlist({
    "git",
    "-C",
    root,
    "blame",
    "-L",
    line .. "," .. line,
    "--porcelain",
    "--",
    path,
  })
  if vim.v.shell_error ~= 0 or #result == 0 then
    vim.notify("Failed to get blame", vim.log.levels.ERROR)
    return
  end
  local commit = result[1]:match("^(%x+)")
  local author, time, summary
  for _, l in ipairs(result) do
    if l:match("^author ") then
      author = l:gsub("^author ", "")
    elseif l:match("^author%-time ") then
      time = os.date("%Y-%m-%d", tonumber(l:gsub("^author%-time ", "")))
    elseif l:match("^summary ") then
      summary = l:gsub("^summary ", "")
    end
  end
  local msg = string.format("%s (%s, %s): %s", commit:sub(1, 8), author or "?", time or "?", summary or "")
  vim.notify(msg, vim.log.levels.INFO)
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
  vim.keymap.set("n", "<leader>gr", M.reset_hunk, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
  vim.keymap.set("n", "<leader>gb", M.blame_line, vim.tbl_extend("force", opts, { desc = "Blame line" }))
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
