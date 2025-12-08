local M = {}
function M.notify(message, level)
  local config = require("quicksearch.config")
  if config.get().notifications.enabled then
    vim.notify(message, level or vim.log.levels.INFO)
  end
end
function M.is_executable(cmd)
  return vim.fn.executable(cmd) == 1
end
function M.check_executable(cmd, install_hint)
  if not M.is_executable(cmd) then
    local msg = string.format("'%s' is not installed or not in PATH", cmd)
    if install_hint then
      msg = msg .. "\n" .. install_hint
    end
    M.notify(msg, vim.log.levels.ERROR)
    return false
  end
  return true
end
function M.async_exec(cmd, args, opts)
  opts = opts or {}
  local stdout = {}
  local stderr = {}
  local full_cmd = vim.list_extend({ cmd }, args)
  local job_id = vim.fn.jobstart(full_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    cwd = opts.cwd,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr, data)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          local output = vim.tbl_filter(function(line)
            return line ~= ""
          end, stdout)
          if opts.on_success then
            opts.on_success(output)
          end
        else
          local error_msg = table.concat(
            vim.tbl_filter(function(line)
              return line ~= ""
            end, stderr),
            "\n"
          )
          if opts.on_error then
            opts.on_error(exit_code, error_msg)
          else
            M.notify("Command failed: " .. error_msg, vim.log.levels.ERROR)
          end
        end
      end)
    end,
  })
  if job_id == 0 then
    local error_msg = string.format("Invalid command: %s", cmd)
    if opts.on_error then
      opts.on_error(-1, error_msg)
    else
      M.notify(error_msg, vim.log.levels.ERROR)
    end
    return nil
  elseif job_id == -1 then
    local error_msg = string.format("Failed to start command: %s", cmd)
    if opts.on_error then
      opts.on_error(-1, error_msg)
    else
      M.notify(error_msg, vim.log.levels.ERROR)
    end
    return nil
  end
  return job_id
end
function M.get_project_root()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root ~= "" then
    return git_root
  end
  return vim.fn.getcwd()
end
function M.is_directory(path)
  return vim.fn.isdirectory(path) == 1
end
function M.escape_pattern(str)
  return str:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end
return M
