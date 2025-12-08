local M = {}
local config = require("orgdown.config")
local state = {
  current_session = nil,
  cache_timestamp = 0,
  cache_ttl = 60,
}
local function get_store()
  local ok, store = pcall(require, "orgdown.vault.store")
  if not ok then
    return nil
  end
  return store
end
local function make_session_id(topic, timestamp)
  local date = os.date("%Y%m%d-%H%M%S", timestamp)
  local slug = topic:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
  return "learning/" .. date .. "-" .. slug
end
function M.start_session(topic, opts)
  opts = opts or {}
  if state.current_session then
    return false, "Session already active: " .. state.current_session.topic
  end
  if not topic or topic == "" then
    return false, "Topic is required"
  end
  local now = os.time()
  local session_id = make_session_id(topic, now)
  local note_path = opts.note_path
  if not note_path then
    local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
    -- local date_str = os.date("%Y-%m-%d", now)
    local topic_slug = topic:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
    note_path = vault_root .. "/topics/learning/" .. topic_slug .. ".md"
    if vim.fn.filereadable(note_path) == 0 then
      local template = {
        "# " .. topic,
        "",
        "*Started: " .. os.date("%Y-%m-%d %H:%M", now) .. "*",
        "",
        "## Notes",
        "",
        "",
        "## Resources",
        "",
        "- ",
        "",
        "## Progress",
        "",
        "- [ ] ",
        "",
      }
      local dir = vim.fn.fnamemodify(note_path, ":h")
      if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
      end
      vim.fn.writefile(template, note_path)
    end
  end
  state.current_session = {
    id = session_id,
    topic = topic,
    start_time = now,
    note_path = note_path,
  }
  local store = get_store()
  if store then
    local session_data = {
      id = session_id,
      topic = topic,
      start_time = now,
      note_path = note_path,
      status = "active",
    }
    store.notes_put(session_id, session_data)
  end
  vim.notify("[orgdown.learning] Started: " .. topic, vim.log.levels.INFO)
  return true, nil
end
function M.end_session(summary)
  if not state.current_session then
    vim.notify("[orgdown.learning] No active session", vim.log.levels.WARN)
    return false, nil
  end
  local session = state.current_session
  local now = os.time()
  local duration = now - session.start_time
  local hours = math.floor(duration / 3600)
  local minutes = math.floor((duration % 3600) / 60)
  local duration_str = string.format("%dh %dm", hours, minutes)
  local store = get_store()
  if store then
    local session_data = {
      id = session.id,
      topic = session.topic,
      start_time = session.start_time,
      end_time = now,
      duration = duration,
      note_path = session.note_path,
      summary = summary,
      status = "completed",
    }
    store.notes_put(session.id, session_data)
  end
  if session.note_path and vim.fn.filereadable(session.note_path) == 1 then
    local lines = vim.fn.readfile(session.note_path)
    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, string.format("*Session ended: %s (%s)*", os.date("%Y-%m-%d %H:%M", now), duration_str))
    if summary and summary ~= "" then
      table.insert(lines, "")
      table.insert(lines, "**Summary:** " .. summary)
    end
    vim.fn.writefile(lines, session.note_path)
  end
  vim.notify(
    string.format("[orgdown.learning] Ended: %s (%s)", session.topic, duration_str),
    vim.log.levels.INFO
  )
  local result = {
    topic = session.topic,
    duration = duration,
    duration_str = duration_str,
    note_path = session.note_path,
  }
  state.current_session = nil
  return true, result
end
function M.get_status()
  if not state.current_session then
    return nil
  end
  local session = state.current_session
  local now = os.time()
  local duration = now - session.start_time
  local hours = math.floor(duration / 3600)
  local minutes = math.floor((duration % 3600) / 60)
  return {
    topic = session.topic,
    start_time = session.start_time,
    duration = duration,
    duration_str = string.format("%dh %dm", hours, minutes),
    note_path = session.note_path,
    active = true,
  }
end
function M.is_active()
  return state.current_session ~= nil
end
function M.get_recent(limit)
  limit = limit or 10
  local store = get_store()
  if not store then
    return {}
  end
  local all_sessions = store.notes_find("status", "completed") or {}
  local learning_sessions = {}
  for _, session in ipairs(all_sessions) do
    if session.id and session.id:match("^learning/") then
      table.insert(learning_sessions, session)
    end
  end
  table.sort(learning_sessions, function(a, b)
    return (a.end_time or 0) > (b.end_time or 0)
  end)
  local results = {}
  for i = 1, math.min(limit, #learning_sessions) do
    table.insert(results, learning_sessions[i])
  end
  return results
end
function M.get_stale_topics(days_threshold)
  days_threshold = days_threshold or 7
  local threshold_time = os.time() - (days_threshold * 24 * 60 * 60)
  local store = get_store()
  if not store then
    return {}
  end
  local all_sessions = store.notes_find("status", "completed") or {}
  local topic_last_studied = {}
  for _, session in ipairs(all_sessions) do
    if session.id and session.id:match("^learning/") and session.topic then
      local topic = session.topic
      local end_time = session.end_time or session.start_time or 0
      if not topic_last_studied[topic] or end_time > topic_last_studied[topic].end_time then
        topic_last_studied[topic] = {
          topic = topic,
          end_time = end_time,
          note_path = session.note_path,
        }
      end
    end
  end
  local stale = {}
  for _, info in pairs(topic_last_studied) do
    if info.end_time < threshold_time then
      local days_ago = math.floor((os.time() - info.end_time) / (24 * 60 * 60))
      table.insert(stale, {
        topic = info.topic,
        days_since = days_ago,
        note_path = info.note_path,
      })
    end
  end
  table.sort(stale, function(a, b)
    return a.days_since > b.days_since
  end)
  return stale
end
function M.suggest_next()
  local stale = M.get_stale_topics(7)
  if #stale > 0 then
    local suggestion = stale[1]
    return {
      topic = suggestion.topic,
      reason = string.format("Not studied for %d days", suggestion.days_since),
      note_path = suggestion.note_path,
    }
  end
  return nil
end
function M.statusline()
  local status = M.get_status()
  if not status then
    return ""
  end
  local topic = status.topic
  if #topic > 15 then
    topic = topic:sub(1, 12) .. "..."
  end
  return string.format("📚 %s %s", topic, status.duration_str)
end
function M.show_status_window()
  local lines = {}
  local status = M.get_status()
  if status then
    table.insert(lines, "Current Learning Session")
    table.insert(lines, string.rep("─", 40))
    table.insert(lines, "Topic: " .. status.topic)
    table.insert(lines, "Duration: " .. status.duration_str)
    table.insert(lines, "Started: " .. os.date("%H:%M", status.start_time))
    if status.note_path then
      table.insert(lines, "Note: " .. vim.fn.fnamemodify(status.note_path, ":t"))
    end
  else
    table.insert(lines, "No Active Learning Session")
    table.insert(lines, string.rep("─", 40))
    local suggestion = M.suggest_next()
    if suggestion then
      table.insert(lines, "")
      table.insert(lines, "Suggested next: " .. suggestion.topic)
      table.insert(lines, "Reason: " .. suggestion.reason)
    end
  end
  local recent = M.get_recent(5)
  if #recent > 0 then
    table.insert(lines, "")
    table.insert(lines, "Recent Sessions")
    table.insert(lines, string.rep("─", 40))
    for _, session in ipairs(recent) do
      local date = os.date("%m/%d", session.end_time or session.start_time)
      local hours = math.floor((session.duration or 0) / 3600)
      local mins = math.floor(((session.duration or 0) % 3600) / 60)
      table.insert(lines, string.format("%s  %s (%dh %dm)", date, session.topic, hours, mins))
    end
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  local width = 50
  local height = math.min(#lines + 2, 25)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Learning ",
    title_pos = "center",
  })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })
end
function M.start_interactive()
  if state.current_session then
    vim.notify(
      "[orgdown.learning] Session active: " .. state.current_session.topic .. ". End it first.",
      vim.log.levels.WARN
    )
    return
  end
  vim.ui.input({ prompt = "Topic: " }, function(topic)
    if topic and topic ~= "" then
      M.start_session(topic)
      if state.current_session and state.current_session.note_path then
        vim.cmd("edit " .. vim.fn.fnameescape(state.current_session.note_path))
      end
    end
  end)
end
function M.end_interactive()
  if not state.current_session then
    vim.notify("[orgdown.learning] No active session", vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = "Summary (optional): " }, function(summary)
    M.end_session(summary)
  end)
end
return M
