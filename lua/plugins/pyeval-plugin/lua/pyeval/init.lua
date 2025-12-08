local repl = require("pyeval.repl")
local eval = require("pyeval.eval")
local venv = require("pyeval.venv")
local M = {}
local default_config = {
	repl_type = "auto",
	terminal = {
		dimensions = {
			height = 0.3,
			width = 1.0,
			x = 0.0,
			y = 0.7,
		},
	},
	auto_imports = true,
	markers = {
		start = "# EVAL",
		["end"] = "# END",
	},
	keymaps = {
		eval_block = "<leader>yee",
		toggle_repl = "<leader>yet",
		restart_repl = "<leader>yer",
		clear_repl = "<leader>yec",
	},
}
local config = {}
function M.setup(user_config)
	config = vim.tbl_deep_extend("force", default_config, user_config or {})
	if config.markers then
		eval.set_markers(config.markers.start, config.markers["end"])
	end
	local init_success = repl.init(config)
	if not init_success then
		vim.notify("PyEval: Failed to initialize. Make sure miniterm.nvim is installed.", vim.log.levels.ERROR)
		return
	end
	if config.keymaps then
		M.setup_keymaps(config.keymaps)
	end
	M.setup_commands()
	M.setup_autocmds()
end
function M.setup_keymaps(keymaps)
	local opts = { noremap = true, silent = true }
	if keymaps.eval_block then
		vim.keymap.set("n", keymaps.eval_block, function()
			M.eval_block()
		end, vim.tbl_extend("force", opts, { desc = "PyEval: Evaluate code block" }))
	end
	if keymaps.toggle_repl then
		vim.keymap.set("n", keymaps.toggle_repl, function()
			M.toggle_repl()
		end, vim.tbl_extend("force", opts, { desc = "PyEval: Toggle REPL" }))
	end
	if keymaps.restart_repl then
		vim.keymap.set("n", keymaps.restart_repl, function()
			M.restart_repl()
		end, vim.tbl_extend("force", opts, { desc = "PyEval: Restart REPL" }))
	end
	if keymaps.clear_repl then
		vim.keymap.set("n", keymaps.clear_repl, function()
			M.clear_repl()
		end, vim.tbl_extend("force", opts, { desc = "PyEval: Clear REPL" }))
	end
end
function M.setup_commands()
	vim.api.nvim_create_user_command("PyEval", function()
		M.eval_block()
	end, { desc = "Evaluate Python code block at cursor" })
	vim.api.nvim_create_user_command("PyToggleREPL", function()
		M.toggle_repl()
	end, { desc = "Toggle Python REPL window" })
	vim.api.nvim_create_user_command("PyRestartREPL", function()
		M.restart_repl()
	end, { desc = "Restart Python REPL" })
	vim.api.nvim_create_user_command("PyClearREPL", function()
		M.clear_repl()
	end, { desc = "Clear Python REPL output" })
	vim.api.nvim_create_user_command("PyREPLInfo", function()
		M.show_info()
	end, { desc = "Show Python REPL information" })
	vim.api.nvim_create_user_command("PyListBlocks", function()
		M.list_blocks()
	end, { desc = "List all EVAL blocks in current buffer" })
	vim.api.nvim_create_user_command("PyEvalClearCache", function()
		M.clear_code_cache()
	end, { desc = "Clear Python code cache" })
	vim.api.nvim_create_user_command("PyEvalShowCache", function()
		M.show_code_cache()
	end, { desc = "Show cached Python code" })
end
function M.setup_autocmds()
	local augroup = vim.api.nvim_create_augroup("PyEvalCache", { clear = true })
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		pattern = "*.py",
		callback = function()
			repl.clear_code_cache()
		end,
		desc = "PyEval: Clear code cache on buffer reload",
	})
	vim.api.nvim_create_autocmd("BufUnload", {
		group = augroup,
		pattern = "*.py",
		callback = function()
			repl.clear_code_cache()
		end,
		desc = "PyEval: Clear code cache on buffer unload",
	})
	vim.api.nvim_create_autocmd("FileChangedShellPost", {
		group = augroup,
		pattern = "*.py",
		callback = function()
			repl.clear_code_cache()
			vim.notify("PyEval: File changed externally, code cache cleared", vim.log.levels.INFO)
		end,
		desc = "PyEval: Clear code cache on external file change",
	})
end
function M.eval_block()
	eval.eval_block(config)
end
function M.toggle_repl()
	repl.toggle()
end
function M.restart_repl()
	repl.restart(config)
end
function M.clear_repl()
	repl.clear()
end
function M.open_repl()
	repl.open()
end
function M.close_repl()
	repl.close()
end
function M.show_info()
	local state = repl.get_state()
	local venv_info = venv.detect()
	local info_lines = {
		"PyEval Information:",
		"",
		"REPL Status:",
		"  Initialized: " .. tostring(state.is_initialized),
		"  Open: " .. tostring(state.is_open),
		"  Ready: " .. tostring(state.is_ready),
		"  Command: " .. (state.repl_cmd or "N/A"),
		"",
		"Virtual Environment:",
		"  " .. venv.get_description(venv_info),
		"  Path: " .. (venv_info.venv_path or "N/A"),
		"  Python: " .. (venv_info.python_path or "N/A"),
		"  IPython: " .. (venv_info.ipython_path or "N/A"),
		"",
		"Configuration:",
		"  REPL Type: " .. config.repl_type,
		"  Auto Imports: " .. tostring(config.auto_imports),
		"  Cached Imports: " .. state.import_count,
		"  Cached Code Blocks: " .. state.code_cache_count,
		"  Start Marker: " .. config.markers.start,
		"  End Marker: " .. config.markers["end"],
	}
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, info_lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	local width = 60
	local height = #info_lines
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
	})
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<ESC>", "<cmd>close<cr>", { buffer = buf, noremap = true, silent = true })
end
function M.list_blocks()
	local blocks = eval.list_blocks()
	if #blocks == 0 then
		vim.notify("PyEval: No EVAL blocks found in current buffer", vim.log.levels.INFO)
		return
	end
	local msg = string.format("PyEval: Found %d code block%s:\n", #blocks, #blocks > 1 and "s" or "")
	for i, block in ipairs(blocks) do
		msg = msg .. string.format("  %d. Lines %d-%d\n", i, block.start_line, block.end_line)
	end
	vim.notify(msg, vim.log.levels.INFO)
end
function M.clear_import_cache()
	repl.clear_import_cache()
	vim.notify("PyEval: Import cache cleared", vim.log.levels.INFO)
end
function M.clear_code_cache()
	repl.clear_code_cache()
	vim.notify("PyEval: Code cache cleared", vim.log.levels.INFO)
end
function M.show_code_cache()
	local cached_code = repl.get_cached_code()
	local state = repl.get_state()
	if cached_code == "" then
		vim.notify("PyEval: Code cache is empty", vim.log.levels.INFO)
		return
	end
	local lines = vim.split(cached_code, "\n", { plain = true })
	local header = string.format("=== Cached Code (%d blocks, %d lines) ===", state.code_cache_count, #lines)
	table.insert(lines, 1, header)
	table.insert(lines, 2, "")
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "python")
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(30, #lines, vim.o.lines - 4)
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
		title = " Cached Code ",
		title_pos = "center",
	})
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<ESC>", "<cmd>close<cr>", { buffer = buf, noremap = true, silent = true })
end
return M
