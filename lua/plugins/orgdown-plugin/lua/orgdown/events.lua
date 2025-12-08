local M = {}
M.EVENTS = {
  CONFIG_CHANGED = "config_changed",
  MODULE_ENABLED = "module_enabled",
  MODULE_DISABLED = "module_disabled",
  BUFFER_ENTERED = "buffer_entered",
  BUFFER_MODIFIED = "buffer_modified",
  BUFFER_SAVED = "buffer_saved",
  TODO_STATE_CHANGED = "todo_state_changed",
  AGENDA_REFRESH_NEEDED = "agenda_refresh_needed",
  CODE_EXECUTED = "code_executed",
  RESULTS_INSERTED = "results_inserted",
  EXECUTION_STARTED = "execution_started",
  EXECUTION_FINISHED = "execution_finished",
  PREVIEW_OPENED = "preview_opened",
  PREVIEW_CLOSED = "preview_closed",
  PREVIEW_SCROLLED = "preview_scrolled",
  PREVIEW_RENDERED = "preview_rendered",
  HEADING_JUMPED = "heading_jumped",
  LINK_FOLLOWED = "link_followed",
  OUTLINE_TOGGLED = "outline_toggled",
  OUTLINE_OPENED = "outline_opened",
  OUTLINE_CLOSED = "outline_closed",
  CAPTURE_OPENED = "capture_opened",
  CAPTURE_CLOSED = "capture_closed",
  CAPTURE_SAVED = "capture_saved",
  BABEL_EXECUTED = "babel_executed",
}
local subscribers = {}
function M.subscribe(event, callback)
  if not subscribers[event] then
    subscribers[event] = {}
  end
  table.insert(subscribers[event], callback)
  return function()
    M.unsubscribe(event, callback)
  end
end
function M.unsubscribe(event, callback)
  if not subscribers[event] then
    return
  end
  for i, cb in ipairs(subscribers[event]) do
    if cb == callback then
      table.remove(subscribers[event], i)
      return
    end
  end
end
function M.emit(event, data)
  if not subscribers[event] then
    return
  end
  for _, callback in ipairs(subscribers[event]) do
    local ok, err = pcall(callback, data)
    if not ok then
      vim.notify(
        "[orgdown] Event handler error for '" .. event .. "': " .. tostring(err),
        vim.log.levels.WARN
      )
    end
  end
end
function M.emit_async(event, data)
  vim.schedule(function()
    M.emit(event, data)
  end)
end
function M.clear(event)
  if event then
    subscribers[event] = nil
  else
    subscribers = {}
  end
end
function M.subscriber_count(event)
  if not subscribers[event] then
    return 0
  end
  return #subscribers[event]
end
function M.once(event, callback)
  local unsubscribe
  unsubscribe = M.subscribe(event, function(data)
    unsubscribe()
    callback(data)
  end)
  return unsubscribe
end
return M
