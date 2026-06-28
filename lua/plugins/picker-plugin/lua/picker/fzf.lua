local M = {}
local config = require("picker.config")
local utils = require("picker.utils")
M.state = {
  buf = nil,
  win = nil,
  preview_buf = nil,
  preview_win = nil,
  on_select = nil,
  on_multi_select = nil,
  items = nil,
  input_file = nil,
  output_file = nil,
}
local function get_win_opts()
  local cfg = config.get().fzf
  local width = math.floor(vim.o.columns * cfg.width)
  local height = math.floor(vim.o.lines * cfg.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  return {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = cfg.border,
  }
end
local function cleanup()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  if M.state.preview_win and vim.api.nvim_win_is_valid(M.state.preview_win) then
    vim.api.nvim_win_close(M.state.preview_win, true)
  end
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.api.nvim_buf_delete(M.state.buf, { force = true })
  end
  if M.state.preview_buf and vim.api.nvim_buf_is_valid(M.state.preview_buf) then
    vim.api.nvim_buf_delete(M.state.preview_buf, { force = true })
  end
  if M.state.input_file then
    vim.fn.delete(M.state.input_file)
  end
  if M.state.output_file then
    vim.fn.delete(M.state.output_file)
  end
  M.state = {
    buf = nil,
    win = nil,
    preview_buf = nil,
    preview_win = nil,
    on_select = nil,
    on_multi_select = nil,
    items = nil,
    input_file = nil,
    output_file = nil,
  }
end
local function build_fzf_args(opts)
  local cfg = config.get().fzf
  local args = {
    "--ansi",
    "--layout=reverse",
    "--info=inline",
    "--multi",
  }
  if opts.prompt then
    table.insert(args, string.format("--prompt='%s '", opts.prompt:gsub("'", "\\'")))
  end
  if opts.header then
    table.insert(args, string.format("--header='%s'", opts.header:gsub("'", "\\'")))
  end
  if cfg.preview.enabled and opts.preview_cmd then
    local preview_pos = cfg.preview.position == "right" and "right" or "up"
    local preview_size = math.floor(cfg.preview.width * 100) .. "%"
    table.insert(args, "--preview=" .. vim.fn.shellescape(opts.preview_cmd))
    table.insert(args, "--preview-window=" .. preview_pos .. ":" .. preview_size)
  end
  if opts.delimiter then
    table.insert(args, "--delimiter=" .. vim.fn.shellescape(opts.delimiter))
  end
  table.insert(args, "--bind=ctrl-a:select-all,ctrl-d:deselect-all")
  table.insert(args, "--expect=ctrl-x,ctrl-v,ctrl-t")
  return args
end
function M.run(opts)
  opts = opts or {}
  local fzf_path = config.get().fzf_path
  if not utils.check_executable(fzf_path, "Install fzf: https://github.com/junegunn/fzf") then
    return
  end
  cleanup()
  M.state.output_file = vim.fn.tempname()
  M.state.on_select = opts.on_select
  M.state.on_multi_select = opts.on_multi_select
  M.state.items = opts.items
  local fzf_args = build_fzf_args(opts)
  local fzf_cmd
  if opts.source_cmd then
    fzf_cmd = opts.source_cmd .. " | " .. fzf_path .. " " .. table.concat(fzf_args, " ")
      .. " | tee " .. M.state.output_file
  elseif opts.items then
    M.state.input_file = vim.fn.tempname()
    vim.fn.writefile(opts.items, M.state.input_file)
    fzf_cmd = fzf_path .. " " .. table.concat(fzf_args, " ") .. " < " .. M.state.input_file
      .. " | tee " .. M.state.output_file
  else
    vim.notify("[picker] No source provided", vim.log.levels.ERROR)
    return
  end
  M.state.buf = vim.api.nvim_create_buf(false, true)
  if not M.state.buf or M.state.buf == 0 then
    vim.notify("[picker] Failed to create buffer", vim.log.levels.ERROR)
    return
  end
  vim.bo[M.state.buf].bufhidden = "wipe"
  local win_opts = get_win_opts()
  M.state.win = vim.api.nvim_open_win(M.state.buf, true, win_opts)
  if not M.state.win or M.state.win == 0 then
    vim.notify("[picker] Failed to create window", vim.log.levels.ERROR)
    vim.api.nvim_buf_delete(M.state.buf, { force = true })
    return
  end
  vim.wo[M.state.win].winhl = "Normal:Normal,FloatBorder:FloatBorder"
  vim.wo[M.state.win].cursorline = false
  vim.wo[M.state.win].number = false
  vim.wo[M.state.win].relativenumber = false
  vim.wo[M.state.win].signcolumn = "no"
  local job_id = vim.fn.termopen(fzf_cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        local selections = {}
        local action = nil
        if exit_code == 0 and M.state.output_file then
          local lines = vim.fn.readfile(M.state.output_file)
          if #lines > 0 then
            action = lines[1]
            for i = 2, #lines do
              if lines[i] ~= "" then
                table.insert(selections, lines[i])
              end
            end
          end
        end
        local callback_select = M.state.on_select
        local callback_multi = M.state.on_multi_select
        cleanup()
        if #selections > 0 then
          if #selections == 1 and callback_select then
            callback_select(selections[1], action)
          elseif callback_multi then
            callback_multi(selections, action)
          elseif callback_select then
            for _, sel in ipairs(selections) do
              callback_select(sel, action)
            end
          end
        end
      end)
    end,
  })
  if job_id == 0 then
    vim.notify("[picker] Failed to start fzf (invalid command)", vim.log.levels.ERROR)
    cleanup()
    return
  elseif job_id == -1 then
    vim.notify("[picker] Failed to start fzf (not executable)", vim.log.levels.ERROR)
    cleanup()
    return
  end
  vim.api.nvim_set_current_win(M.state.win)
  vim.cmd("startinsert")
end
function M.file_preview_cmd()
  if utils.is_executable("bat") then
    return "bat --style=numbers --color=always --line-range :500 {}"
  else
    return "head -500 {}"
  end
end
function M.grep_preview_cmd()
  if utils.is_executable("bat") then
    return "bat --style=numbers --color=always --highlight-line {2} {1}"
  else
    return "head -500 {1}"
  end
end
return M
