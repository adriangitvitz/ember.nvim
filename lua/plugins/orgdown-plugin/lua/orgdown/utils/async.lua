local M = {}
local running_jobs = {}
function M.run(cmd, opts)
  opts = opts or {}
  local job_opts = {
    on_stdout = opts.on_stdout,
    on_stderr = opts.on_stderr,
    on_exit = function(job_id, exit_code, event)
      running_jobs[job_id] = nil
      if opts.on_exit then
        opts.on_exit(job_id, exit_code, event)
      end
    end,
    stdout_buffered = opts.stdout_buffered or false,
    stderr_buffered = opts.stderr_buffered or false,
  }
  if opts.cwd then
    job_opts.cwd = opts.cwd
  end
  if opts.env then
    job_opts.env = opts.env
  end
  local job_id = vim.fn.jobstart(cmd, job_opts)
  if job_id > 0 then
    running_jobs[job_id] = true
  end
  return job_id
end
function M.run_sync(cmd, opts, timeout_ms)
  opts = opts or {}
  timeout_ms = timeout_ms or 30000
  local stdout_data = {}
  local stderr_data = {}
  local exit_code = nil
  local done = false
  local job_opts = {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        table.insert(stdout_data, line)
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        table.insert(stderr_data, line)
      end
    end,
    on_exit = function(_, code)
      exit_code = code
      done = true
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  }
  if opts.cwd then
    job_opts.cwd = opts.cwd
  end
  if opts.env then
    job_opts.env = opts.env
  end
  local job_id = vim.fn.jobstart(cmd, job_opts)
  if job_id <= 0 then
    return {
      exit_code = -1,
      stdout = "",
      stderr = "Failed to start job",
    }
  end
  local waited = vim.wait(timeout_ms, function()
    return done
  end, 10)
  if not waited then
    vim.fn.jobstop(job_id)
    return {
      exit_code = -1,
      stdout = table.concat(stdout_data, "\n"),
      stderr = "Timeout after " .. timeout_ms .. "ms",
      timed_out = true,
    }
  end
  return {
    exit_code = exit_code,
    stdout = table.concat(stdout_data, "\n"),
    stderr = table.concat(stderr_data, "\n"),
  }
end
function M.is_running(job_id)
  if not running_jobs[job_id] then
    return false
  end
  local result = vim.fn.jobwait({ job_id }, 0)
  return result[1] == -1
end
function M.stop(job_id)
  if M.is_running(job_id) then
    pcall(vim.fn.jobstop, job_id)
  end
  running_jobs[job_id] = nil
end
function M.stop_all()
  for job_id, _ in pairs(running_jobs) do
    M.stop(job_id)
  end
  running_jobs = {}
end
function M.get_running_jobs()
  local jobs = {}
  for job_id, _ in pairs(running_jobs) do
    if M.is_running(job_id) then
      table.insert(jobs, job_id)
    end
  end
  return jobs
end
function M.send(job_id, data)
  if type(data) == "string" then
    data = { data }
  end
  vim.fn.chansend(job_id, data)
end
function M.close_stdin(job_id)
  pcall(vim.fn.chanclose, job_id, "stdin")
end
return M
