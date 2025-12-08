local M = {}
local async = require("orgdown.utils.async")
local venv_cache = nil
local cache_cwd = nil
local function path_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil
end
local function find_venv_in_tree(start_path)
  local current = start_path
  local root = vim.loop.os_homedir()
  while current and current ~= root and current ~= "/" do
    local venv_path = current .. "/.venv"
    if path_exists(venv_path) then
      return venv_path
    end
    current = vim.fn.fnamemodify(current, ":h")
  end
  return nil
end
local function get_python_from_venv(venv_path)
  local python_paths = {
    venv_path .. "/bin/python",
    venv_path .. "/bin/python3",
    venv_path .. "/Scripts/python.exe",
    venv_path .. "/Scripts/python3.exe",
  }
  for _, python_path in ipairs(python_paths) do
    if path_exists(python_path) then
      return python_path
    end
  end
  return nil
end
local function get_ipython_from_venv(venv_path)
  local ipython_paths = {
    venv_path .. "/bin/ipython",
    venv_path .. "/bin/ipython3",
    venv_path .. "/Scripts/ipython.exe",
    venv_path .. "/Scripts/ipython3.exe",
  }
  for _, ipython_path in ipairs(ipython_paths) do
    if path_exists(ipython_path) then
      return ipython_path
    end
  end
  return nil
end
function M.detect_venv()
  local cwd = vim.fn.getcwd()
  if venv_cache and cache_cwd == cwd then
    return venv_cache
  end
  local result = {
    python_path = nil,
    ipython_path = nil,
    venv_path = nil,
    source = nil,
  }
  local virtual_env = vim.env.VIRTUAL_ENV
  if virtual_env and path_exists(virtual_env) then
    result.venv_path = virtual_env
    result.python_path = get_python_from_venv(virtual_env)
    result.ipython_path = get_ipython_from_venv(virtual_env)
    result.source = "VIRTUAL_ENV"
    venv_cache = result
    cache_cwd = cwd
    return result
  end
  local uv_project_env = vim.env.UV_PROJECT_ENVIRONMENT
  if uv_project_env and path_exists(uv_project_env) then
    result.venv_path = uv_project_env
    result.python_path = get_python_from_venv(uv_project_env)
    result.ipython_path = get_ipython_from_venv(uv_project_env)
    result.source = "uv"
    venv_cache = result
    cache_cwd = cwd
    return result
  end
  local venv_path = find_venv_in_tree(cwd)
  if venv_path then
    result.venv_path = venv_path
    result.python_path = get_python_from_venv(venv_path)
    result.ipython_path = get_ipython_from_venv(venv_path)
    result.source = ".venv"
    venv_cache = result
    cache_cwd = cwd
    return result
  end
  result.python_path = vim.fn.exepath("python3") ~= "" and "python3" or "python"
  result.ipython_path = vim.fn.exepath("ipython") ~= "" and "ipython" or nil
  result.source = "system"
  venv_cache = result
  cache_cwd = cwd
  return result
end
function M.get_venv_description(detection_result)
  detection_result = detection_result or M.detect_venv()
  if detection_result.source == "VIRTUAL_ENV" then
    return string.format("Active virtualenv: %s", detection_result.venv_path)
  elseif detection_result.source == "uv" then
    return string.format("UV virtualenv: %s", detection_result.venv_path)
  elseif detection_result.source == ".venv" then
    return string.format("Virtualenv: %s", detection_result.venv_path)
  else
    return "System Python"
  end
end
local function get_python_cmd()
  local config = require("orgdown.config")
  local python_config = config.get("babel.languages.python") or {}
  if python_config.auto_venv ~= false then
    local venv_info = M.detect_venv()
    if venv_info.python_path then
      return venv_info.python_path, venv_info.source
    end
  end
  local cmd = python_config.cmd or "python3"
  if vim.fn.executable(cmd) == 1 then
    return cmd, "config"
  end
  if cmd == "python3" and vim.fn.executable("python") == 1 then
    return "python", "fallback"
  end
  return nil, nil
end
function M.execute(code, opts)
  opts = opts or {}
  local python_cmd, source = get_python_cmd()
  if not python_cmd then
    return {
      success = false,
      error = "Python interpreter not found",
    }
  end
  local config = require("orgdown.config")
  local timeout = opts.timeout or config.get("babel.timeout_ms") or 30000
  local cwd = opts.cwd
  local tmpfile = vim.fn.tempname() .. ".py"
  local file = io.open(tmpfile, "w")
  if not file then
    return {
      success = false,
      error = "Failed to create temporary file",
    }
  end
  file:write(code)
  file:close()
  local cmd = python_cmd .. " " .. vim.fn.shellescape(tmpfile)
  local result = async.run_sync(cmd, { cwd = cwd }, timeout)
  os.remove(tmpfile)
  if result.timed_out then
    return {
      success = false,
      error = "Execution timed out after " .. timeout .. "ms",
      output = result.stdout or "",
    }
  end
  local success = result.exit_code == 0
  return {
    success = success,
    exit_code = result.exit_code,
    output = result.stdout or "",
    error = not success and (result.stderr or "") or nil,
    python_source = source,
  }
end
function M.is_available()
  local cmd = get_python_cmd()
  return cmd ~= nil
end
function M.get_info()
  local venv_info = M.detect_venv()
  local python_cmd, source = get_python_cmd()
  return {
    python_path = python_cmd,
    source = source,
    venv_info = venv_info,
    venv_description = M.get_venv_description(venv_info),
    ipython_available = venv_info.ipython_path ~= nil,
  }
end
function M.clear_cache()
  venv_cache = nil
  cache_cwd = nil
end
return M
