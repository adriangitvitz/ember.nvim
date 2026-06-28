-- searchr/ui.lua - Buffer and window management

local config = require("searchr.config")
local utils = require("searchr.utils")
local search = require("searchr.search")

local M = {}

-- UI state
local state = {
  bufnr = nil,
  winnr = nil,
  ns_id = nil,
  pattern = "",
  replacement = "",
  flags = "",
  results = {},
  result_count = 0,
  status = "idle",  -- "idle" | "searching" | "complete" | "error"
  debounce_timer = nil,
  current_field = "search",  -- "search" | "replace" | "flags"
  -- Cached display values: project_root involves a synchronous `git rev-parse`,
  -- which blocked the UI when called from render_title() on every streamed result.
  cached_root_display = nil,
}

-- Line numbers for input fields
local LINES = {
  title = 1,
  search = 2,
  replace = 3,
  flags = 4,
  separator = 5,
  results_start = 6,
}

-- Setup highlight groups
local function setup_highlights()
  local cfg = config.get()
  local hl = cfg.highlights

  vim.api.nvim_set_hl(0, "SearchrMatch", { link = hl.match })
  vim.api.nvim_set_hl(0, "SearchrReplace", { link = hl.replace })
  vim.api.nvim_set_hl(0, "SearchrDelete", { link = hl.delete })
  vim.api.nvim_set_hl(0, "SearchrPath", { link = hl.path })
  vim.api.nvim_set_hl(0, "SearchrLineNr", { link = hl.line_nr })
  vim.api.nvim_set_hl(0, "SearchrStatus", { link = hl.status })
  vim.api.nvim_set_hl(0, "SearchrInputLabel", { link = hl.input_label })
end

-- Get status text
local function get_status_text()
  if state.status == "searching" then
    return "[searching...]"
  elseif state.status == "complete" then
    return string.format("[%d matches]", state.result_count)
  elseif state.status == "error" then
    return "[error]"
  end
  return ""
end

-- Render title line
local function render_title()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  -- Cache project root once per session: get_project_root() forks `git`, which
  -- blocks the UI thread. Calling it on every streamed result froze Neovim.
  if not state.cached_root_display then
    state.cached_root_display = utils.shorten_path(utils.get_project_root(), 40)
  end
  local status = get_status_text()
  local title = string.format("Searchr: %s %s", state.cached_root_display, status)

  vim.api.nvim_buf_set_lines(state.bufnr, LINES.title - 1, LINES.title, false, { title })
  vim.api.nvim_buf_add_highlight(state.bufnr, state.ns_id, "SearchrStatus", LINES.title - 1, 0, -1)
end

-- Render input fields
local function render_inputs()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local lines = {
    "Search:  " .. state.pattern,
    "Replace: " .. state.replacement,
    "Flags:   " .. state.flags,
    string.rep("-", 60),
  }

  vim.api.nvim_buf_set_lines(state.bufnr, LINES.search - 1, LINES.separator, false, lines)

  -- Highlight labels
  vim.api.nvim_buf_add_highlight(state.bufnr, state.ns_id, "SearchrInputLabel", LINES.search - 1, 0, 8)
  vim.api.nvim_buf_add_highlight(state.bufnr, state.ns_id, "SearchrInputLabel", LINES.replace - 1, 0, 8)
  vim.api.nvim_buf_add_highlight(state.bufnr, state.ns_id, "SearchrInputLabel", LINES.flags - 1, 0, 8)
end

-- Render a single result line
local function render_result(result, index)
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local line_num = LINES.results_start + (index - 1)
  local display = string.format("%s:%d:%d: %s", result.file, result.lnum, result.col, result.text)

  -- Append or set line
  local line_count = vim.api.nvim_buf_line_count(state.bufnr)
  if line_num > line_count then
    vim.api.nvim_buf_set_lines(state.bufnr, -1, -1, false, { display })
  else
    vim.api.nvim_buf_set_lines(state.bufnr, line_num - 1, line_num, false, { display })
  end

  -- Highlight path
  local path_end = #result.file
  vim.api.nvim_buf_add_highlight(state.bufnr, state.ns_id, "SearchrPath", line_num - 1, 0, path_end)

  -- Highlight line number
  local lnum_start = path_end + 1
  local lnum_end = lnum_start + #tostring(result.lnum)
  vim.api.nvim_buf_add_highlight(state.bufnr, state.ns_id, "SearchrLineNr", line_num - 1, lnum_start, lnum_end)
end

-- Clear results area
local function clear_results()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(state.bufnr)
  if line_count >= LINES.results_start then
    vim.api.nvim_buf_set_lines(state.bufnr, LINES.results_start - 1, -1, false, {})
  end

  state.results = {}
  state.result_count = 0
end

-- Trigger search with debounce
local function trigger_search()
  if state.pattern == "" then
    clear_results()
    state.status = "idle"
    render_title()
    return
  end

  local delay = config.get_debounce_delay(#state.pattern)

  if state.debounce_timer then
    state.debounce_timer:stop()
  end

  state.debounce_timer = vim.defer_fn(function()
    clear_results()
    state.status = "searching"
    render_title()

    search.execute(state.pattern, {
      replacement = state.replacement,
      flags = state.flags,

      on_result = function(result, count)
        state.result_count = count
        table.insert(state.results, result)
        render_result(result, count)
        render_title()
      end,

      on_complete = function(results, count, truncated)
        state.status = "complete"
        state.result_count = count
        render_title()
      end,

      on_error = function(err)
        state.status = "error"
        render_title()
        utils.notify("Search error: " .. err, vim.log.levels.ERROR)
      end,
    })
  end, delay)
end

-- Parse input from buffer line
local function parse_input_line(line, prefix)
  if line:sub(1, #prefix) == prefix then
    return line:sub(#prefix + 1)
  end
  return ""
end

-- Handle buffer changes
local function on_lines_changed()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(state.bufnr, LINES.search - 1, LINES.flags, false)
  if #lines < 3 then return end

  local new_pattern = parse_input_line(lines[1], "Search:  ")
  local new_replacement = parse_input_line(lines[2], "Replace: ")
  local new_flags = parse_input_line(lines[3], "Flags:   ")

  local pattern_changed = new_pattern ~= state.pattern

  state.pattern = new_pattern
  state.replacement = new_replacement
  state.flags = new_flags

  if pattern_changed then
    trigger_search()
  end
end

-- Setup buffer keymaps
local function setup_keymaps()
  local opts = { buffer = state.bufnr, silent = true }

  -- Close
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)

  -- Go to result
  vim.keymap.set("n", "<CR>", function() M.goto_result() end, opts)
  vim.keymap.set("n", "<C-CR>", function() M.goto_result(true) end, opts)

  -- Navigate fields
  vim.keymap.set("i", "<Tab>", function() M.next_field() end, opts)
  vim.keymap.set("i", "<S-Tab>", function() M.prev_field() end, opts)

  -- Integration
  vim.keymap.set("n", "<C-q>", function() M.to_quickfix() end, opts)
  vim.keymap.set("n", "<C-p>", function() M.to_picker() end, opts)

  -- Replace
  vim.keymap.set("n", "R", function() require("searchr.replace").apply_all() end, opts)
  vim.keymap.set("n", "r", function() require("searchr.replace").apply_line() end, opts)
  vim.keymap.set("n", "p", function() require("searchr.replace").toggle_preview() end, opts)

  -- Refresh
  vim.keymap.set("n", "<C-r>", function() trigger_search() end, opts)

  -- Cancel
  vim.keymap.set("n", "<C-c>", function() search.cancel() end, opts)

  -- Navigate results
  vim.keymap.set("n", "]q", function() M.next_result() end, opts)
  vim.keymap.set("n", "[q", function() M.prev_result() end, opts)
end

-- Create searchr buffer
local function create_buffer()
  state.bufnr = vim.api.nvim_create_buf(false, true)
  state.ns_id = vim.api.nvim_create_namespace("searchr")

  vim.api.nvim_buf_set_name(state.bufnr, "searchr://search")
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].bufhidden = "wipe"
  vim.bo[state.bufnr].swapfile = false
  vim.bo[state.bufnr].filetype = "searchr"

  -- Initial content
  local initial_lines = {
    "Searchr: " .. utils.shorten_path(utils.get_project_root(), 40),
    "Search:  ",
    "Replace: ",
    "Flags:   ",
    string.rep("-", 60),
  }
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, initial_lines)

  -- Setup autocommand for input changes
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = state.bufnr,
    callback = on_lines_changed,
  })

  setup_keymaps()
  render_inputs()

  return state.bufnr
end

-- Create window
local function create_window()
  local cfg = config.get()

  if cfg.ui.mode == "float" then
    local width = math.floor(vim.o.columns * cfg.ui.width)
    local height = math.floor(vim.o.lines * cfg.ui.height)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    state.winnr = vim.api.nvim_open_win(state.bufnr, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = cfg.ui.border,
    })
  elseif cfg.ui.mode == "vsplit" then
    vim.cmd("vsplit")
    state.winnr = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.winnr, state.bufnr)
  else
    -- Default: horizontal split
    local height = math.floor(vim.o.lines * cfg.ui.height)
    if cfg.ui.position == "top" then
      vim.cmd("topleft " .. height .. "split")
    else
      vim.cmd("botright " .. height .. "split")
    end
    state.winnr = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.winnr, state.bufnr)
  end

  vim.wo[state.winnr].number = false
  vim.wo[state.winnr].relativenumber = false
  vim.wo[state.winnr].signcolumn = "no"
  vim.wo[state.winnr].wrap = false
end

-- Open searchr UI
function M.open(opts)
  opts = opts or {}
  setup_highlights()

  -- Invalidate the cached project root so a fresh `git rev-parse` runs once
  -- per session (cheap), instead of once per result (was UI-blocking).
  state.cached_root_display = nil

  -- Close existing if open
  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    vim.api.nvim_set_current_win(state.winnr)
  else
    create_buffer()
    create_window()
  end

  -- Pre-fill pattern if provided
  if opts.pattern then
    state.pattern = opts.pattern
    render_inputs()
    trigger_search()
  end

  -- Position cursor in search field
  vim.api.nvim_win_set_cursor(state.winnr, { LINES.search, 9 })
  vim.cmd("startinsert!")
end

-- Close searchr UI
function M.close()
  search.cancel()

  if state.debounce_timer then
    state.debounce_timer:stop()
    state.debounce_timer = nil
  end

  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    vim.api.nvim_win_close(state.winnr, true)
  end

  state.winnr = nil
  state.bufnr = nil
end

-- Toggle UI
function M.toggle()
  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then
    M.close()
  else
    M.open()
  end
end

-- Navigate to next input field
function M.next_field()
  local row = vim.api.nvim_win_get_cursor(state.winnr)[1]
  if row == LINES.search then
    vim.api.nvim_win_set_cursor(state.winnr, { LINES.replace, 9 })
  elseif row == LINES.replace then
    vim.api.nvim_win_set_cursor(state.winnr, { LINES.flags, 9 })
  else
    vim.api.nvim_win_set_cursor(state.winnr, { LINES.search, 9 })
  end
end

-- Navigate to previous input field
function M.prev_field()
  local row = vim.api.nvim_win_get_cursor(state.winnr)[1]
  if row == LINES.flags then
    vim.api.nvim_win_set_cursor(state.winnr, { LINES.replace, 9 })
  elseif row == LINES.replace then
    vim.api.nvim_win_set_cursor(state.winnr, { LINES.search, 9 })
  else
    vim.api.nvim_win_set_cursor(state.winnr, { LINES.flags, 9 })
  end
end

-- Go to result under cursor
function M.goto_result(close_after)
  local row = vim.api.nvim_win_get_cursor(state.winnr)[1]
  local result_index = row - LINES.results_start + 1

  if result_index < 1 or result_index > #state.results then
    return
  end

  local result = state.results[result_index]
  if not result then return end

  if close_after then
    M.close()
  end

  vim.cmd("edit " .. vim.fn.fnameescape(result.file))
  vim.api.nvim_win_set_cursor(0, { result.lnum, result.col - 1 })
  vim.cmd("normal! zz")
end

-- Navigate to next result
function M.next_result()
  local row = vim.api.nvim_win_get_cursor(state.winnr)[1]
  if row < LINES.results_start then
    row = LINES.results_start
  else
    row = row + 1
  end

  local max_row = LINES.results_start + #state.results - 1
  if row <= max_row then
    vim.api.nvim_win_set_cursor(state.winnr, { row, 0 })
  end
end

-- Navigate to previous result
function M.prev_result()
  local row = vim.api.nvim_win_get_cursor(state.winnr)[1]
  if row > LINES.results_start then
    vim.api.nvim_win_set_cursor(state.winnr, { row - 1, 0 })
  end
end

-- Send results to quickfix
function M.to_quickfix()
  local qf_items = {}
  for _, result in ipairs(state.results) do
    table.insert(qf_items, {
      filename = result.file,
      lnum = result.lnum,
      col = result.col,
      text = result.text,
    })
  end

  vim.fn.setqflist(qf_items, "r")
  vim.fn.setqflist({}, "a", { title = "Searchr: " .. state.pattern })
  vim.cmd("copen")
  utils.notify(string.format("Sent %d results to quickfix", #qf_items))
end

-- Send results to picker-plugin
function M.to_picker()
  local ok, picker = pcall(require, "picker")
  if not ok then
    utils.notify("picker-plugin not available", vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, result in ipairs(state.results) do
    table.insert(items, string.format("%s:%d:%d:%s", result.file, result.lnum, result.col, result.text))
  end

  picker.run({
    items = items,
    prompt = "Search Results: " .. state.pattern,
  })
end

-- Get current state (for replace module)
function M.get_state()
  return {
    pattern = state.pattern,
    replacement = state.replacement,
    flags = state.flags,
    results = state.results,
    result_count = state.result_count,
    bufnr = state.bufnr,
    winnr = state.winnr,
  }
end

-- Refresh display
function M.refresh()
  render_title()
  render_inputs()
end

return M
