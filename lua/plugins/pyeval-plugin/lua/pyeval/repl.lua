local venv = require("pyeval.venv")
local M = {}
local state = {
	terminal = nil,
	venv_info = nil,
	repl_cmd = nil,
	import_cache = {},
	code_cache = {},
	is_ready = false,
}
local function is_channel_valid(job_id)
	if not job_id or job_id <= 0 then
		return false
	end
	local result = vim.fn.jobwait({ job_id }, 0)
	return result[1] == -1
end
local function determine_repl_cmd(config)
	local venv_info = venv.detect()
	state.venv_info = venv_info
	if config.repl_type == "python" then
		return venv_info.python_path or "python3"
	elseif config.repl_type == "ipython" then
		return venv_info.ipython_path or "ipython"
	else
		if venv_info.ipython_path then
			return venv_info.ipython_path
		else
			return venv_info.python_path or "python3"
		end
	end
end
local function is_ipython()
	return state.repl_cmd and state.repl_cmd:match("ipython") ~= nil
end
function M.init(config)
	local ok, miniterm = pcall(require, "miniterm")
	if not ok then
		vim.notify("pyeval.nvim requires miniterm.nvim. Please install it first.", vim.log.levels.ERROR)
		return false
	end
	state.repl_cmd = determine_repl_cmd(config)
	local success, result = pcall(function()
		return miniterm.new({
			cmd = state.repl_cmd,
			dimensions = config.terminal.dimensions or {
				height = 0.3,
				width = 1.0,
				x = 0.0,
				y = 0.7,
			},
		})
	end)
	if not success then
		vim.notify("PyEval: Failed to create terminal: " .. tostring(result), vim.log.levels.ERROR)
		return false
	end
	state.terminal = result
	local venv_desc = venv.get_description(state.venv_info)
	return true
end
function M.open(callback)
	if not state.terminal then
		vim.notify("PyEval: REPL not initialized", vim.log.levels.ERROR)
		return
	end
	state.terminal:open()
	local attempts = 0
	local max_attempts = 20
	local function check_ready()
		attempts = attempts + 1
		if is_channel_valid(state.terminal.job_id) then
			state.is_ready = true
			if is_ipython() then
				vim.fn.chansend(state.terminal.job_id, "%autoindent\n")
			end
			if callback then
				callback()
			end
		elseif attempts < max_attempts then
			vim.defer_fn(check_ready, 100)
		else
			vim.notify("PyEval: REPL failed to start within 2 seconds", vim.log.levels.ERROR)
			state.is_ready = false
		end
	end
	vim.defer_fn(check_ready, 100)
end
function M.close()
	if state.terminal then
		state.terminal:close()
	end
end
function M.toggle()
	if not state.terminal then
		vim.notify("PyEval: REPL not initialized", vim.log.levels.ERROR)
		return
	end
	state.terminal:toggle()
	if state.terminal.is_open then
		local attempts = 0
		local max_attempts = 20
		local function check_ready()
			attempts = attempts + 1
			if is_channel_valid(state.terminal.job_id) then
				state.is_ready = true
				if is_ipython() then
					vim.fn.chansend(state.terminal.job_id, "%autoindent\n")
				end
			elseif attempts < max_attempts then
				vim.defer_fn(check_ready, 100)
			else
				vim.notify("PyEval: REPL failed to become ready", vim.log.levels.ERROR)
				state.is_ready = false
			end
		end
		vim.defer_fn(check_ready, 100)
	end
end
function M.send(text, ensure_open, options)
	if not state.terminal then
		vim.notify("PyEval: REPL not initialized", vim.log.levels.ERROR)
		return
	end
	options = options or {}
	if ensure_open and not state.terminal.is_open then
		M.open(function()
			M.send(text, false, options)
		end)
		return
	end
	if not is_channel_valid(state.terminal.job_id) then
		vim.notify("PyEval: REPL channel is not valid or has been closed", vim.log.levels.ERROR)
		state.is_ready = false
		return
	end
	local text_to_send = text
	if options.use_cache then
		local cached = M.get_cached_code()
		if cached ~= "" then
			text_to_send = cached .. text
		end
	end
	local ok, err = pcall(vim.fn.chansend, state.terminal.job_id, text_to_send)
	if not ok then
		vim.notify("PyEval: Failed to send to REPL: " .. tostring(err), vim.log.levels.ERROR)
		state.is_ready = false
	end
end
function M.send_import(import_stmt)
	if not import_stmt or import_stmt == "" then
		return
	end
	if not vim.tbl_contains(state.import_cache, import_stmt) then
		table.insert(state.import_cache, import_stmt)
	end
	M.send(import_stmt .. "\n", true)
end
function M.add_to_code_cache(code)
	if not code or code == "" then
		return
	end
	table.insert(state.code_cache, code)
end
function M.get_cached_code()
	if #state.code_cache == 0 then
		return ""
	end
	return table.concat(state.code_cache, "\n") .. "\n"
end
function M.clear_code_cache()
	state.code_cache = {}
end
function M.clear()
	if not state.terminal then
		vim.notify("PyEval: REPL not initialized", vim.log.levels.ERROR)
		return
	end
	if not is_channel_valid(state.terminal.job_id) then
		vim.notify("PyEval: REPL channel is not valid or has been closed", vim.log.levels.ERROR)
		return
	end
	local ok, err = pcall(vim.fn.chansend, state.terminal.job_id, "\x0c")
	if not ok then
		vim.notify("PyEval: Failed to clear REPL: " .. tostring(err), vim.log.levels.ERROR)
	end
end
function M.restart(config)
	if state.terminal then
		state.terminal:close()
	end
	state.is_ready = false
	M.clear_code_cache()
	M.init(config)
	M.open(function()
		if #state.import_cache > 0 then
			vim.notify(string.format("PyEval: Resending %d cached imports", #state.import_cache), vim.log.levels.INFO)
			for _, import_stmt in ipairs(state.import_cache) do
				M.send(import_stmt .. "\n", false)
			end
		end
	end)
end
function M.get_state()
	return {
		is_initialized = state.terminal ~= nil,
		is_open = state.terminal and state.terminal.is_open or false,
		is_ready = state.is_ready,
		repl_cmd = state.repl_cmd,
		venv_info = state.venv_info,
		import_count = #state.import_cache,
		code_cache_count = #state.code_cache,
	}
end
function M.clear_import_cache()
	state.import_cache = {}
end
return M
