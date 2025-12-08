local M = {}
function M.execute(code, opts)
  opts = opts or {}
  local output = {}
  local original_print = print
  print = function(...)
    local args = { ... }
    local str_args = {}
    for _, arg in ipairs(args) do
      table.insert(str_args, tostring(arg))
    end
    table.insert(output, table.concat(str_args, "\t"))
  end
  local env = setmetatable({}, { __index = _G })
  if opts.session then
    local session = require("orgdown.babel.session")
    local session_vars = session.get_vars(opts.session)
    for k, v in pairs(session_vars) do
      env[k] = v
    end
  end
  if opts.vars then
    for k, v in pairs(opts.vars) do
      env[k] = v
    end
  end
  local chunk, load_err = load(code, "babel", "t", env)
  if not chunk then
    print = original_print
    return {
      success = false,
      error = "Syntax error: " .. tostring(load_err),
      output = table.concat(output, "\n"),
    }
  end
  local ok, result = pcall(chunk)
  print = original_print
  if opts.session then
    local session = require("orgdown.babel.session")
    session.save_vars(opts.session, env)
  end
  if not ok then
    return {
      success = false,
      error = "Runtime error: " .. tostring(result),
      output = table.concat(output, "\n"),
    }
  end
  return {
    success = true,
    value = result,
    output = table.concat(output, "\n"),
  }
end
function M.is_available()
  return true
end
return M
