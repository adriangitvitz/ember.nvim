local M = {}
function M.is_markdown_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  return ft == "markdown"
end
function M.trim(str)
  return str:match("^%s*(.-)%s*$") or ""
end
function M.split(str, sep)
  local result = {}
  local pattern = "(.-)" .. vim.pesc(sep)
  local last_end = 1
  for part, pos in str:gmatch(pattern .. "()") do
    table.insert(result, part)
    last_end = pos
  end
  table.insert(result, str:sub(last_end))
  return result
end
function M.starts_with(str, prefix)
  return str:sub(1, #prefix) == prefix
end
function M.ends_with(str, suffix)
  return suffix == "" or str:sub(-#suffix) == suffix
end
function M.debounce(fn, ms)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
      timer:close()
    end
    timer = vim.loop.new_timer()
    timer:start(
      ms,
      0,
      vim.schedule_wrap(function()
        timer:stop()
        timer:close()
        timer = nil
        fn(unpack(args))
      end)
    )
  end
end
function M.throttle(fn, ms)
  local last_call = 0
  local timer = nil
  return function(...)
    local args = { ... }
    local now = vim.loop.now()
    if now - last_call >= ms then
      last_call = now
      fn(unpack(args))
    else
      if timer then
        timer:stop()
        timer:close()
      end
      timer = vim.loop.new_timer()
      local remaining = ms - (now - last_call)
      timer:start(
        remaining,
        0,
        vim.schedule_wrap(function()
          timer:stop()
          timer:close()
          timer = nil
          last_call = vim.loop.now()
          fn(unpack(args))
        end)
      )
    end
  end
end
function M.tbl_find(tbl, predicate)
  for i, v in ipairs(tbl) do
    if predicate(v, i) then
      return v
    end
  end
  return nil
end
function M.tbl_filter(tbl, predicate)
  local result = {}
  for i, v in ipairs(tbl) do
    if predicate(v, i) then
      table.insert(result, v)
    end
  end
  return result
end
function M.tbl_map(tbl, transform)
  local result = {}
  for i, v in ipairs(tbl) do
    table.insert(result, transform(v, i))
  end
  return result
end
function M.tbl_reduce(tbl, fn, initial)
  local acc = initial
  for i, v in ipairs(tbl) do
    acc = fn(acc, v, i)
  end
  return acc
end
function M.normalize_path(path)
  if M.starts_with(path, "~") then
    path = vim.fn.expand(path)
  end
  path = vim.fn.expand(path)
  if #path > 1 and M.ends_with(path, "/") then
    path = path:sub(1, -2)
  end
  return path
end
function M.is_absolute_path(path)
  return M.starts_with(path, "/")
end
function M.join_path(...)
  local segments = { ... }
  local result = {}
  for _, segment in ipairs(segments) do
    segment = segment:gsub("/+$", "")
    if segment ~= "" then
      table.insert(result, segment)
    end
  end
  return table.concat(result, "/")
end
function M.once(fn)
  local called = false
  local result = nil
  return function(...)
    if not called then
      called = true
      result = fn(...)
    end
    return result
  end
end
function M.memoize(fn)
  local cache = {}
  return function(...)
    local key = vim.inspect({ ... })
    if cache[key] == nil then
      cache[key] = fn(...)
    end
    return cache[key]
  end
end
function M.schedule(fn)
  vim.schedule(function()
    local ok, err = pcall(fn)
    if not ok then
      vim.notify("[orgdown] Scheduled function error: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end
function M.defer(fn, ms)
  local timer = vim.loop.new_timer()
  timer:start(
    ms,
    0,
    vim.schedule_wrap(function()
      timer:stop()
      timer:close()
      fn()
    end)
  )
  return timer
end
return M
