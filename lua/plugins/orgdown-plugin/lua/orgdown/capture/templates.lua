local M = {}
function M.expand(template, context)
  context = context or {}
  local cursor_pos = nil
  local result = template
  local cursor_start = result:find("%%?")
  if cursor_start then
    result = result:gsub("%%?", "", 1)
    cursor_pos = cursor_start - 1
  end
  result = result:gsub("%%t", os.date("%Y-%m-%d"))
  result = result:gsub("%%T", os.date("%Y-%m-%d %H:%M"))
  local filename = vim.fn.expand("%:t")
  result = result:gsub("%%f", filename or "")
  local filepath = vim.fn.expand("%:p")
  result = result:gsub("%%F", filepath or "")
  local dirname = vim.fn.expand("%:p:h")
  result = result:gsub("%%d", dirname or "")
  local username = os.getenv("USER") or os.getenv("USERNAME") or ""
  result = result:gsub("%%u", username)
  result = result:gsub("%%^{([^}]+)}", function(prompt)
    local input = vim.fn.input(prompt .. ": ")
    return input
  end)
  for key, value in pairs(context) do
    result = result:gsub("%%" .. key, tostring(value))
  end
  return result, cursor_pos
end
function M.get(key)
  local config = require("orgdown.config")
  local templates = config.get("capture.templates")
  return templates[key]
end
function M.list()
  local config = require("orgdown.config")
  return config.get("capture.templates") or {}
end
function M.add(key, template)
  local config = require("orgdown.config")
  local templates = config.get("capture.templates") or {}
  templates[key] = template
  config.set("capture.templates", templates)
end
function M.remove(key)
  local config = require("orgdown.config")
  local templates = config.get("capture.templates") or {}
  templates[key] = nil
  config.set("capture.templates", templates)
end
function M.validate(template)
  if type(template) ~= "table" then
    return false, "Template must be a table"
  end
  if not template.name or type(template.name) ~= "string" then
    return false, "Template must have a name"
  end
  if not template.template or type(template.template) ~= "string" then
    return false, "Template must have template text"
  end
  return true, nil
end
return M
