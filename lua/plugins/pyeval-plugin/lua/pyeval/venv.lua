local M = {}
local function exists(path)
	local stat = vim.loop.fs_stat(path)
	return stat ~= nil
end
local function find_venv_in_tree(start_path)
	local current = start_path
	local root = vim.loop.os_homedir()
	while current and current ~= root and current ~= "/" do
		local venv_path = current .. "/.venv"
		if exists(venv_path) then
			return venv_path
		end
		current = vim.fn.fnamemodify(current, ":h")
	end
	return nil
end
local function find_uv_venv()
	local cwd = vim.fn.getcwd()
	local venv_path = find_venv_in_tree(cwd)
	if venv_path then
		return venv_path
	end
	local uv_project_env = vim.env.UV_PROJECT_ENVIRONMENT
	if uv_project_env and exists(uv_project_env) then
		return uv_project_env
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
		if exists(python_path) then
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
		if exists(ipython_path) then
			return ipython_path
		end
	end
	return nil
end
function M.detect()
	local result = {
		python_path = nil,
		ipython_path = nil,
		venv_path = nil,
		source = nil,
	}
	local virtual_env = vim.env.VIRTUAL_ENV
	if virtual_env and exists(virtual_env) then
		result.venv_path = virtual_env
		result.python_path = get_python_from_venv(virtual_env)
		result.ipython_path = get_ipython_from_venv(virtual_env)
		result.source = "VIRTUAL_ENV"
		return result
	end
	local uv_venv = find_uv_venv()
	if uv_venv then
		result.venv_path = uv_venv
		result.python_path = get_python_from_venv(uv_venv)
		result.ipython_path = get_ipython_from_venv(uv_venv)
		result.source = "uv"
		return result
	end
	local cwd = vim.fn.getcwd()
	local venv_path = find_venv_in_tree(cwd)
	if venv_path then
		result.venv_path = venv_path
		result.python_path = get_python_from_venv(venv_path)
		result.ipython_path = get_ipython_from_venv(venv_path)
		result.source = ".venv"
		return result
	end
	result.python_path = vim.fn.exepath("python3") ~= "" and "python3" or "python"
	result.ipython_path = vim.fn.exepath("ipython") ~= "" and "ipython" or nil
	result.source = "system"
	return result
end
function M.get_description(detection_result)
	if not detection_result then
		detection_result = M.detect()
	end
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
return M
