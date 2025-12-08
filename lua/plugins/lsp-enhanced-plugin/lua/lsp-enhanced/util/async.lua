local M = {}
function M.schedule(fn, ...)
  local args = {...}
  vim.schedule(function()
    fn(unpack(args))
  end)
end
function M.schedule_delayed(fn, delay_ms, ...)
  local args = {...}
  local timer = vim.loop.new_timer()
  timer:start(delay_ms, 0, vim.schedule_wrap(function()
    fn(unpack(args))
    if not timer:is_closing() then
      timer:close()
    end
  end))
  return timer
end
function M.parallel(tasks, callback)
  local results = {}
  local completed = 0
  local total = #tasks
  if total == 0 then
    callback(results)
    return
  end
  for i, task in ipairs(tasks) do
    task(function(result)
      results[i] = result
      completed = completed + 1
      if completed == total then
        vim.schedule(function()
          callback(results)
        end)
      end
    end)
  end
end
function M.series(tasks, callback)
  local current = 1
  local function run_next(prev_result)
    if current > #tasks then
      vim.schedule(function()
        callback(prev_result)
      end)
      return
    end
    local task = tasks[current]
    current = current + 1
    task(prev_result, function(result)
      run_next(result)
    end)
  end
  run_next(nil)
end
function M.debounce(fn, delay_ms)
  local timer = nil
  return function(...)
    local args = {...}
    if timer then
      timer:stop()
      timer:close()
    end
    timer = vim.loop.new_timer()
    timer:start(delay_ms, 0, vim.schedule_wrap(function()
      fn(unpack(args))
      timer:close()
      timer = nil
    end))
  end
end
function M.throttle(fn, delay_ms)
  local last_run = 0
  local timer = nil
  local pending_args = nil
  return function(...)
    local now = vim.loop.now()
    local args = {...}
    if now - last_run >= delay_ms then
      last_run = now
      vim.schedule(function()
        fn(unpack(args))
      end)
      return
    end
    pending_args = args
    if not timer then
      local time_to_wait = delay_ms - (now - last_run)
      timer = vim.loop.new_timer()
      timer:start(time_to_wait, 0, vim.schedule_wrap(function()
        if pending_args then
          last_run = vim.loop.now()
          fn(unpack(pending_args))
          pending_args = nil
        end
        timer:close()
        timer = nil
      end))
    end
  end
end
function M.promise()
  local promise = {
    _state = 'pending',
    _value = nil,
    _callbacks = {},
  }
  function promise:resolve(value)
    if self._state ~= 'pending' then return end
    self._state = 'resolved'
    self._value = value
    vim.schedule(function()
      for _, callback in ipairs(self._callbacks) do
        if callback.on_resolve then
          callback.on_resolve(value)
        end
      end
    end)
  end
  function promise:reject(error)
    if self._state ~= 'pending' then return end
    self._state = 'rejected'
    self._value = error
    vim.schedule(function()
      for _, callback in ipairs(self._callbacks) do
        if callback.on_reject then
          callback.on_reject(error)
        end
      end
    end)
  end
  function promise:then_call(on_resolve, on_reject)
    if self._state == 'resolved' then
      if on_resolve then
        vim.schedule(function()
          on_resolve(self._value)
        end)
      end
    elseif self._state == 'rejected' then
      if on_reject then
        vim.schedule(function()
          on_reject(self._value)
        end)
      end
    else
      table.insert(self._callbacks, {
        on_resolve = on_resolve,
        on_reject = on_reject,
      })
    end
    return self
  end
  return promise
end
function M.promisify(fn)
  return function(...)
    local args = {...}
    local p = M.promise()
    table.insert(args, function(err, result)
      if err then
        p:reject(err)
      else
        p:resolve(result)
      end
    end)
    fn(unpack(args))
    return p
  end
end
return M
