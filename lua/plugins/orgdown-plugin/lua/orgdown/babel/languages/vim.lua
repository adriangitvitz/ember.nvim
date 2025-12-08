local M = {}
function M.execute(code, opts)
  opts = opts or {}
  local output = ""
  local ok, result = pcall(function()
    vim.cmd("redir => g:_orgdown_babel_output")
    vim.cmd("silent " .. code)
    vim.cmd("redir END")
    output = vim.g._orgdown_babel_output or ""
    vim.g._orgdown_babel_output = nil
    return output
  end)
  if not ok then
    return {
      success = false,
      error = tostring(result),
      output = output,
    }
  end
  return {
    success = true,
    output = result:gsub("^\n", ""),
  }
end
function M.is_available()
  return true
end
return M
