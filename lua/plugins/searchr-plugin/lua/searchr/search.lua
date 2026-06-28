-- searchr/search.lua - Ripgrep execution with streaming results

local config = require("searchr.config")
local utils = require("searchr.utils")

local M = {}

-- Search state
local state = {
  job_id = nil,
  results = {},
  result_count = 0,
  partial_line = "",
  pattern = "",
  replacement = "",
  flags = "",
  cwd = nil,
  is_searching = false,
  on_result = nil,      -- Callback for each result
  on_complete = nil,    -- Callback when search completes
  on_error = nil,       -- Callback for errors
}

-- Build ripgrep arguments
function M.build_rg_args(pattern, opts)
  opts = opts or {}
  local cfg = config.get()

  local args = {
    cfg.rg_path,
    "--vimgrep",
    "--color=never",
    "--no-heading",
  }

  -- Case sensitivity
  if cfg.search.case_mode == "smart" then
    table.insert(args, "--smart-case")
  elseif cfg.search.case_mode == "insensitive" then
    table.insert(args, "-i")
  end

  -- Hidden files
  if cfg.search.include_hidden or opts.include_hidden then
    table.insert(args, "--hidden")
  end

  -- Follow symlinks
  if cfg.search.follow_symlinks or opts.follow_symlinks then
    table.insert(args, "-L")
  end

  -- Max results
  if cfg.search.max_results then
    table.insert(args, "-m")
    table.insert(args, tostring(cfg.search.max_results))
  end

  -- Context lines
  if cfg.search.context_lines and cfg.search.context_lines > 0 then
    table.insert(args, "-C")
    table.insert(args, tostring(cfg.search.context_lines))
  end

  -- Fixed strings (literal) vs regex
  if not cfg.search.use_regex and not opts.use_regex then
    table.insert(args, "-F")
  end

  -- Additional flags from user input
  if opts.flags and opts.flags ~= "" then
    for flag in opts.flags:gmatch("%S+") do
      table.insert(args, flag)
    end
  end

  -- Pattern
  table.insert(args, "--")
  table.insert(args, pattern)

  -- Paths (default to current directory)
  if opts.paths and #opts.paths > 0 then
    for _, path in ipairs(opts.paths) do
      table.insert(args, path)
    end
  else
    table.insert(args, ".")
  end

  return args
end

-- Cancel running search
function M.cancel()
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end
  state.is_searching = false
end

-- Execute search with streaming results
function M.execute(pattern, opts)
  opts = opts or {}

  -- Cancel any existing search
  M.cancel()

  -- Validate pattern
  if not pattern or pattern == "" then
    return
  end

  -- Reset state
  state.results = {}
  state.result_count = 0
  state.partial_line = ""
  state.pattern = pattern
  state.replacement = opts.replacement or ""
  state.flags = opts.flags or ""
  state.cwd = opts.cwd or utils.get_project_root()
  state.is_searching = true
  state.on_result = opts.on_result
  state.on_complete = opts.on_complete
  state.on_error = opts.on_error

  local args = M.build_rg_args(pattern, opts)
  local cfg = config.get()

  state.job_id = vim.fn.jobstart(args, {
    cwd = state.cwd,
    stdout_buffered = false,  -- Stream results as they arrive
    stderr_buffered = true,

    on_stdout = function(_, data)
      if not data then return end

      vim.schedule(function()
        -- Join with partial line from previous chunk
        data[1] = state.partial_line .. (data[1] or "")
        state.partial_line = ""

        -- Last element may be incomplete (not newline-terminated)
        -- Save it for next chunk
        state.partial_line = data[#data]
        data[#data] = nil

        for _, line in ipairs(data) do
          if line and line ~= "" then
            local parsed = utils.parse_result_line(line)
            if parsed then
              state.result_count = state.result_count + 1
              table.insert(state.results, parsed)
              if state.on_result then
                state.on_result(parsed, state.result_count)
              end

              -- Check max results
              if state.result_count >= cfg.search.max_results then
                M.cancel()
                utils.notify(
                  string.format("Results truncated at %d matches", cfg.search.max_results),
                  vim.log.levels.WARN
                )
                if state.on_complete then
                  state.on_complete(state.results, state.result_count, true)
                end
                return
              end
            end
          end
        end
      end)
    end,

    on_stderr = function(_, data)
      if data then
        local err = table.concat(data, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
        if err ~= "" and state.on_error then
          vim.schedule(function()
            state.on_error(err)
          end)
        end
      end
    end,

    on_exit = function(_, exit_code)
      vim.schedule(function()
        state.job_id = nil
        state.is_searching = false

        -- Handle remaining partial line
        if state.partial_line ~= "" then
          local parsed = utils.parse_result_line(state.partial_line)
          if parsed then
            state.result_count = state.result_count + 1
            table.insert(state.results, parsed)
            if state.on_result then
              state.on_result(parsed, state.result_count)
            end
          end
          state.partial_line = ""
        end

        if state.on_complete then
          -- exit_code 0 = matches found, 1 = no matches, 2+ = error
          local truncated = false
          state.on_complete(state.results, state.result_count, truncated)
        end
      end)
    end,
  })
end

-- Get current search state
function M.get_state()
  return {
    pattern = state.pattern,
    replacement = state.replacement,
    flags = state.flags,
    cwd = state.cwd,
    results = state.results,
    result_count = state.result_count,
    is_searching = state.is_searching,
  }
end

-- Get results
function M.get_results()
  return state.results
end

-- Get result count
function M.get_result_count()
  return state.result_count
end

-- Check if searching
function M.is_searching()
  return state.is_searching
end

return M
