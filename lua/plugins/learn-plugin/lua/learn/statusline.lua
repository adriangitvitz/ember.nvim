local M = {}
local cache = {
  data = nil,
  timestamp = 0,
  ttl = 60,
}
local function parse_status(output)
  local status = {
    active = false,
    topic = nil,
    progress = nil,
  }
  for _, line in ipairs(output) do
    if line:match("^Current:") or line:match("^Session:") then
      status.active = true
      local topic = line:match("Current:%s*(.+)") or line:match("Session:%s*(.+)")
      if topic then
        status.topic = topic:gsub("%s+$", "")
      end
    end
    local progress = line:match("Progress:%s*(%d+/%d+)")
    if progress then
      status.progress = progress
    end
  end
  return status
end
local function get_session_status()
  local now = os.time()
  if cache.data and (now - cache.timestamp) < cache.ttl then
    return cache.data
  end
  local learn = require('learn')
  local learn_bin = learn.config.learn_bin or "learn"
  local handle = io.popen(learn_bin .. " status 2>&1")
  if not handle then
    return nil
  end
  local output = {}
  for line in handle:lines() do
    table.insert(output, line)
  end
  handle:close()
  local status = parse_status(output)
  cache.data = status
  cache.timestamp = now
  return status
end
function M.statusline()
  local status = get_session_status()
  if not status or not status.active then
    return ""
  end
  local parts = {}
  table.insert(parts, "📚")
  if status.topic then
    local topic = status.topic
    if #topic > 20 then
      topic = topic:sub(1, 17) .. "..."
    end
    table.insert(parts, topic)
  end
  if status.progress then
    table.insert(parts, status.progress)
  end
  return table.concat(parts, " ")
end
function M.clear_cache()
  cache.data = nil
  cache.timestamp = 0
end
function M.is_active()
  local status = get_session_status()
  return status and status.active or false
end
return M
