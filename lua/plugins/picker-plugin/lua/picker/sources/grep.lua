local M = {}
local config = require("picker.config")
local utils = require("picker.utils")
local fzf = require("picker.fzf")
local actions = require("picker.actions")
local function get_case_flag(mode)
  if mode == "sensitive" then
    return "--case-sensitive"
  elseif mode == "insensitive" then
    return "--ignore-case"
  else
    return "--smart-case"
  end
end
local function build_rg_cmd(pattern, opts)
  opts = opts or {}
  local cfg = config.get()
  local args = { cfg.rg_path }
  table.insert(args, "--line-number")
  table.insert(args, "--column")
  table.insert(args, "--no-heading")
  table.insert(args, "--color=always")
  table.insert(args, get_case_flag(opts.case_mode or cfg.search.case_mode))
  if opts.hidden or cfg.search.include_hidden then
    table.insert(args, "--hidden")
  end
  if opts.follow or cfg.search.follow_symlinks then
    table.insert(args, "--follow")
  end
  if not (opts.regex or cfg.search.use_regex) then
    table.insert(args, "--fixed-strings")
  end
  if opts.file_type then
    table.insert(args, "--type=" .. opts.file_type)
  end
  if opts.max_count then
    table.insert(args, "--max-count=" .. opts.max_count)
  end
  if pattern and pattern ~= "" then
    table.insert(args, "--")
    table.insert(args, vim.fn.shellescape(pattern))
  end
  return table.concat(args, " ")
end
function M.live_grep(opts)
  opts = opts or {}
  local rg_path = config.get().rg_path
  if not utils.check_executable(rg_path, "Install ripgrep") then
    return
  end
  local root = opts.cwd or utils.get_project_root()
  local rg_base = build_rg_cmd("", opts)
  local fzf_cmd = string.format(
    "cd %s && %s --disabled --ansi --layout=reverse --info=inline "
      .. '--prompt="Grep> " '
      .. "--delimiter=: "
      .. '--preview="bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || head -500 {1}" '
      .. '--preview-window="right:50%%:+{2}-/2" '
      .. "--bind=ctrl-a:select-all,ctrl-d:deselect-all "
      .. '--bind="change:reload:%s {q} || true" '
      .. "--expect=ctrl-x,ctrl-v,ctrl-t "
      .. "--multi",
    vim.fn.shellescape(root),
    config.get().fzf_path,
    rg_base
  )
  local tmpfile = vim.fn.tempname()
  fzf_cmd = fzf_cmd .. " > " .. tmpfile
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
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
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.fn.termopen(fzf_cmd, {
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
          local action = lines[1]
          for i = 2, #lines do
            if lines[i] ~= "" then
              actions.open_grep_result(lines[i], action, root)
            end
          end
        end
        vim.fn.delete(tmpfile)
      end)
    end,
  })
  vim.cmd("startinsert")
end
function M.grep(pattern, opts)
  opts = opts or {}
  if not pattern or pattern == "" then
    pattern = opts.default or utils.get_word_under_cursor()
  end
  local rg_path = config.get().rg_path
  if not utils.check_executable(rg_path, "Install ripgrep") then
    return
  end
  local root = opts.cwd or utils.get_project_root()
  local rg_cmd = build_rg_cmd(pattern, opts)
  fzf.run({
    source_cmd = "cd " .. vim.fn.shellescape(root) .. " && " .. rg_cmd,
    prompt = "Grep: " .. (pattern or ""),
    delimiter = ":",
    preview_cmd = 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || head -500 {1}',
    on_select = function(selection, action)
      actions.open_grep_result(selection, action, root)
    end,
    on_multi_select = function(selections, action)
      if #selections > 5 then
        actions.send_to_quickfix(selections, "Grep: " .. pattern)
      else
        for _, sel in ipairs(selections) do
          actions.open_grep_result(sel, action, root)
        end
      end
    end,
  })
end
function M.grep_buffer(pattern, opts)
  opts = opts or {}
  if not pattern or pattern == "" then
    pattern = opts.default or utils.get_word_under_cursor()
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    utils.notify("Buffer has no name", vim.log.levels.WARN)
    return
  end
  local rg_path = config.get().rg_path
  if not utils.check_executable(rg_path, "Install ripgrep") then
    return
  end
  local rg_cmd = build_rg_cmd(pattern, opts) .. " " .. vim.fn.shellescape(bufname)
  fzf.run({
    source_cmd = rg_cmd,
    prompt = "Buffer Grep",
    delimiter = ":",
    preview_cmd = 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || head -500 {1}',
    on_select = function(selection, action)
      actions.open_grep_result(selection, action)
    end,
  })
end
return M
