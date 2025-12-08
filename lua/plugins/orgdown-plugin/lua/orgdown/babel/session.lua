local M = {}
local sessions = {}
function M.create(name, language)
  local session = {
    name = name,
    language = language,
    vars = {},
    history = {},
    created = os.time(),
  }
  sessions[name] = session
  return session
end
function M.get_or_create(name, language)
  if sessions[name] then
    return sessions[name]
  end
  return M.create(name, language)
end
function M.get(name)
  return sessions[name]
end
function M.get_vars(name)
  local session = sessions[name]
  if not session then
    return {}
  end
  return vim.deepcopy(session.vars)
end
function M.save_vars(name, vars)
  local session = sessions[name]
  if not session then
    return
  end
  for k, v in pairs(vars) do
    if type(v) ~= "function" and not k:match("^_") then
      if type(v) == "table" then
        local mt = getmetatable(v)
        if mt == nil or mt.__index ~= _G then
          session.vars[k] = v
        end
      else
        session.vars[k] = v
      end
    end
  end
end
function M.set_var(name, key, value)
  local session = sessions[name]
  if not session then
    return
  end
  session.vars[key] = value
end
function M.get_var(name, key)
  local session = sessions[name]
  if not session then
    return nil
  end
  return session.vars[key]
end
function M.add_history(name, entry)
  local session = sessions[name]
  if not session then
    return
  end
  entry.timestamp = entry.timestamp or os.time()
  table.insert(session.history, entry)
  local max_history = 100
  while #session.history > max_history do
    table.remove(session.history, 1)
  end
end
function M.get_history(name, limit)
  local session = sessions[name]
  if not session then
    return {}
  end
  local history = session.history
  if limit and limit < #history then
    local result = {}
    for i = #history - limit + 1, #history do
      table.insert(result, history[i])
    end
    return result
  end
  return vim.deepcopy(history)
end
function M.clear(name)
  sessions[name] = nil
end
function M.clear_all()
  sessions = {}
end
function M.list()
  local names = {}
  for name, _ in pairs(sessions) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end
function M.list_by_language(language)
  local names = {}
  for name, session in pairs(sessions) do
    if session.language == language then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end
function M.exists(name)
  return sessions[name] ~= nil
end
function M.info(name)
  local session = sessions[name]
  if not session then
    return nil
  end
  return {
    name = session.name,
    language = session.language,
    var_count = vim.tbl_count(session.vars),
    history_count = #session.history,
    created = session.created,
  }
end
return M
