-- searchr/replace.lua - Preview and apply replacements

local config = require("searchr.config")
local utils = require("searchr.utils")
local ui = require("searchr.ui")

local M = {}

-- Preview state
local preview_enabled = false

-- Group results by file
local function group_by_file(results)
  local by_file = {}
  for _, result in ipairs(results) do
    if not by_file[result.file] then
      by_file[result.file] = {}
    end
    table.insert(by_file[result.file], result)
  end
  return by_file
end

-- Apply replacement to a single file
local function replace_in_file(filepath, pattern, replacement, results, use_regex)
  local lines = vim.fn.readfile(filepath)
  if not lines then
    return 0, "Could not read file"
  end

  local count = 0
  local modified = false

  -- Sort results by line number descending (to avoid offset issues)
  table.sort(results, function(a, b) return a.lnum > b.lnum end)

  for _, result in ipairs(results) do
    local line_idx = result.lnum
    if line_idx <= #lines then
      local line = lines[line_idx]
      local new_line

      if use_regex then
        new_line = line:gsub(pattern, replacement)
      else
        -- Literal replacement
        new_line = line:gsub(utils.escape_pattern(pattern), replacement)
      end

      if new_line ~= line then
        lines[line_idx] = new_line
        count = count + 1
        modified = true
      end
    end
  end

  if modified then
    local ok, err = pcall(vim.fn.writefile, lines, filepath)
    if not ok then
      return 0, "Could not write file: " .. tostring(err)
    end
  end

  return count, nil
end

-- Apply all replacements
function M.apply_all()
  local state = ui.get_state()

  if not state.pattern or state.pattern == "" then
    utils.notify("No search pattern", vim.log.levels.WARN)
    return
  end

  if not state.replacement then
    utils.notify("No replacement text", vim.log.levels.WARN)
    return
  end

  if #state.results == 0 then
    utils.notify("No results to replace", vim.log.levels.WARN)
    return
  end

  local cfg = config.get()

  -- Confirm if enabled
  if cfg.replace.confirm then
    local file_count = 0
    local seen = {}
    for _, r in ipairs(state.results) do
      if not seen[r.file] then
        seen[r.file] = true
        file_count = file_count + 1
      end
    end

    local confirm = vim.fn.confirm(
      string.format("Replace %d occurrences in %d files?", #state.results, file_count),
      "&Yes\n&No",
      2
    )
    if confirm ~= 1 then
      return
    end
  end

  -- Group results by file
  local by_file = group_by_file(state.results)
  local total_count = 0
  local file_count = 0
  local errors = {}

  -- Check if using regex
  local use_regex = cfg.search.use_regex or state.flags:match("%-%-regexp") or state.flags:match("%-E")

  -- Apply replacements
  for filepath, file_results in pairs(by_file) do
    local count, err = replace_in_file(filepath, state.pattern, state.replacement, file_results, use_regex)
    if err then
      table.insert(errors, filepath .. ": " .. err)
    else
      total_count = total_count + count
      if count > 0 then
        file_count = file_count + 1
      end
    end
  end

  -- Report results
  if #errors > 0 then
    utils.notify("Errors: " .. table.concat(errors, ", "), vim.log.levels.ERROR)
  end

  utils.notify(string.format("Replaced %d occurrences in %d files", total_count, file_count))

  -- Refresh buffers
  vim.cmd("checktime")
end

-- Apply replacement for current line only
function M.apply_line()
  local state = ui.get_state()

  if not state.pattern or state.pattern == "" then
    utils.notify("No search pattern", vim.log.levels.WARN)
    return
  end

  if not state.replacement then
    utils.notify("No replacement text", vim.log.levels.WARN)
    return
  end

  -- Get current cursor position in searchr buffer
  local winnr = state.winnr
  if not winnr or not vim.api.nvim_win_is_valid(winnr) then
    return
  end

  local row = vim.api.nvim_win_get_cursor(winnr)[1]
  local result_index = row - 6 + 1  -- LINES.results_start = 6

  if result_index < 1 or result_index > #state.results then
    utils.notify("No result under cursor", vim.log.levels.WARN)
    return
  end

  local result = state.results[result_index]
  local cfg = config.get()
  local use_regex = cfg.search.use_regex or state.flags:match("%-%-regexp") or state.flags:match("%-E")

  local count, err = replace_in_file(result.file, state.pattern, state.replacement, { result }, use_regex)

  if err then
    utils.notify("Error: " .. err, vim.log.levels.ERROR)
  elseif count > 0 then
    utils.notify(string.format("Replaced in %s:%d", result.file, result.lnum))
    vim.cmd("checktime")
  else
    utils.notify("No replacement made", vim.log.levels.WARN)
  end
end

-- Toggle inline preview
function M.toggle_preview()
  preview_enabled = not preview_enabled

  if preview_enabled then
    utils.notify("Preview enabled")
    M.show_preview()
  else
    utils.notify("Preview disabled")
    M.hide_preview()
  end
end

-- Show preview (highlight what would change)
function M.show_preview()
  local state = ui.get_state()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  if not state.replacement or state.replacement == "" then
    return
  end

  -- Add virtual text showing replacement
  local ns_id = vim.api.nvim_create_namespace("searchr_preview")
  vim.api.nvim_buf_clear_namespace(state.bufnr, ns_id, 0, -1)

  for i, result in ipairs(state.results) do
    local line_num = 6 + (i - 1)  -- LINES.results_start = 6
    vim.api.nvim_buf_set_extmark(state.bufnr, ns_id, line_num - 1, 0, {
      virt_lines = {
        { { "  -> " .. state.replacement, "SearchrReplace" } }
      },
      virt_lines_above = false,
    })
  end
end

-- Hide preview
function M.hide_preview()
  local state = ui.get_state()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local ns_id = vim.api.nvim_create_namespace("searchr_preview")
  vim.api.nvim_buf_clear_namespace(state.bufnr, ns_id, 0, -1)
end

-- Check if preview is enabled
function M.is_preview_enabled()
  return preview_enabled
end

return M
