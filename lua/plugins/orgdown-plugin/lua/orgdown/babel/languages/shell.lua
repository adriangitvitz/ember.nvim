local M = {}
local async = require("orgdown.utils.async")
function M.execute(code, opts)
  opts = opts or {}
  local config = require("orgdown.config")
  local shell = opts.shell or config.get("babel.languages.sh.shell") or "bash"
  local timeout = opts.timeout or config.get("babel.timeout_ms") or 30000
  local cwd = opts.cwd
  local cmd = shell .. " -c " .. vim.fn.shellescape(code)
  local result = async.run_sync(cmd, { cwd = cwd }, timeout)
  if result.timed_out then
    return {
      success = false,
      error = "Execution timed out after " .. timeout .. "ms",
      output = result.stdout or "",
    }
  end
  local success = result.exit_code == 0
  return {
    success = success,
    exit_code = result.exit_code,
    output = result.stdout or "",
    error = not success and (result.stderr or "") or nil,
  }
end
function M.execute_async(code, opts)
  opts = opts or {}
  local config = require("orgdown.config")
  local shell = opts.shell or config.get("babel.languages.sh.shell") or "bash"
  local cwd = opts.cwd
  local cmd = shell .. " -c " .. vim.fn.shellescape(code)
  local stdout = {}
  local stderr = {}
  local job_id = async.run(cmd, {
    cwd = cwd,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(stdout, line)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(stderr, line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      if opts.on_complete then
        opts.on_complete({
          success = exit_code == 0,
          exit_code = exit_code,
          output = table.concat(stdout, "\n"),
          error = exit_code ~= 0 and table.concat(stderr, "\n") or nil,
        })
      end
    end,
  })
  return job_id
end
function M.is_available()
  return true
end
return M
