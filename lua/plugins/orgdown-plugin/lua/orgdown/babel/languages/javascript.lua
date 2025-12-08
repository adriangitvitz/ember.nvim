local M = {}
local async = require("orgdown.utils.async")
local function get_node_cmd()
  local config = require("orgdown.config")
  local cmd = config.get("babel.languages.javascript.cmd") or "node"
  if vim.fn.executable(cmd) == 1 then
    return cmd
  end
  return nil
end
function M.execute(code, opts)
  opts = opts or {}
  local node_cmd = get_node_cmd()
  if not node_cmd then
    return {
      success = false,
      error = "Node.js interpreter not found",
    }
  end
  local config = require("orgdown.config")
  local timeout = opts.timeout or config.get("babel.timeout_ms") or 30000
  local cwd = opts.cwd
  local tmpfile = vim.fn.tempname() .. ".js"
  local file = io.open(tmpfile, "w")
  if not file then
    return {
      success = false,
      error = "Failed to create temporary file",
    }
  end
  file:write(code)
  file:close()
  local cmd = node_cmd .. " " .. vim.fn.shellescape(tmpfile)
  local result = async.run_sync(cmd, { cwd = cwd }, timeout)
  os.remove(tmpfile)
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
function M.is_available()
  return get_node_cmd() ~= nil
end
return M
