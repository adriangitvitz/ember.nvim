local repl = require("pyeval.repl")
local M = {}
local default_markers = {
	start = "# EVAL",
	["end"] = "# END",
}
local markers = default_markers
function M.set_markers(start_marker, end_marker)
	markers = {
		start = start_marker or default_markers.start,
		["end"] = end_marker or default_markers["end"],
	}
end
local function find_eval_block_at_cursor()
	local cursor_line = vim.fn.line(".")
	local total_lines = vim.fn.line("$")
	local start_line = nil
	local mode = "cache"
	for line_num = cursor_line, 1, -1 do
		local line_text = vim.fn.getline(line_num)
		local marker_match = line_text:match("^%s*" .. vim.pesc(markers.start) .. "(.*)$")
		if marker_match then
			start_line = line_num
			local mode_suffix = marker_match:match("^:(%w+)")
			if mode_suffix then
				mode = mode_suffix:lower()
			end
			break
		end
		if line_text:match("^%s*" .. vim.pesc(markers["end"])) then
			break
		end
	end
	if not start_line then
		return nil, nil, nil, "No " .. markers.start .. " marker found above cursor"
	end
	local end_line = nil
	for line_num = cursor_line, total_lines do
		local line_text = vim.fn.getline(line_num)
		if line_text:match("^%s*" .. vim.pesc(markers["end"])) then
			end_line = line_num
			break
		end
	end
	if not end_line then
		return nil, nil, nil, "No " .. markers["end"] .. " marker found below cursor"
	end
	return start_line, end_line, mode, nil
end
local function extract_code_block(start_line, end_line)
	if start_line >= end_line then
		return nil, "Invalid block: " .. markers["end"] .. " must come after " .. markers.start
	end
	local lines = vim.fn.getline(start_line + 1, end_line - 1)
	if type(lines) == "string" then
		lines = { lines }
	end
	return lines, nil
end
local function extract_all_code_to_marker(start_line)
	if start_line <= 1 then
		return {}, nil
	end
	local lines = vim.fn.getline(1, start_line - 1)
	if type(lines) == "string" then
		lines = { lines }
	end
	return lines, nil
end
local function extract_imports(lines)
	local imports = {}
	for _, line in ipairs(lines) do
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed:match("^import%s+") or trimmed:match("^from%s+.+%s+import%s+") then
			table.insert(imports, trimmed)
		end
	end
	return imports
end
local function normalize_indentation(lines)
	if #lines == 0 then
		return lines
	end
	local min_indent = math.huge
	for _, line in ipairs(lines) do
		if line:match("%S") then
			local indent = line:match("^(%s*)")
			min_indent = math.min(min_indent, #indent)
		end
	end
	if min_indent == math.huge then
		return lines
	end
	local normalized = {}
	for _, line in ipairs(lines) do
		if line:match("%S") then
			table.insert(normalized, line:sub(min_indent + 1))
		else
			table.insert(normalized, "")
		end
	end
	return normalized
end
local function prepare_code_for_repl(lines)
	local code = table.concat(lines, "\n")
	return code .. "\n\n"
end
local function get_all_blocks_silent()
	local total_lines = vim.fn.line("$")
	local blocks = {}
	local in_block = false
	local block_start = nil
	for line_num = 1, total_lines do
		local line_text = vim.fn.getline(line_num)
		if line_text:match("^%s*" .. vim.pesc(markers.start)) then
			if not in_block then
				in_block = true
				block_start = line_num
			end
		elseif line_text:match("^%s*" .. vim.pesc(markers["end"])) then
			if in_block then
				table.insert(blocks, {
					start_line = block_start,
					end_line = line_num,
				})
				in_block = false
				block_start = nil
			end
		end
	end
	return blocks
end
local function get_block_number(target_start_line)
	local blocks = get_all_blocks_silent()
	for i, block in ipairs(blocks) do
		if block.start_line == target_start_line then
			return i, #blocks
		end
	end
	return nil, #blocks
end
function M.eval_block(config)
	local start_line, end_line, mode, err = find_eval_block_at_cursor()
	if not start_line then
		vim.notify("PyEval: " .. (err or "No EVAL block found at cursor"), vim.log.levels.WARN)
		return
	end
	local lines, extract_err
	local all_code_lines = nil
	if mode == "all" then
		all_code_lines, extract_err = extract_all_code_to_marker(start_line)
		if not all_code_lines then
			vim.notify("PyEval: " .. extract_err, vim.log.levels.ERROR)
			return
		end
	end
	lines, extract_err = extract_code_block(start_line, end_line)
	if not lines then
		vim.notify("PyEval: " .. extract_err, vim.log.levels.ERROR)
		return
	end
	local has_code = false
	for _, line in ipairs(lines) do
		if line:match("%S") then
			has_code = true
			break
		end
	end
	if not has_code then
		vim.notify("PyEval: Code block is empty", vim.log.levels.WARN)
		return
	end
	local normalized_lines = normalize_indentation(lines)
	if config.auto_imports then
		local imports = extract_imports(normalized_lines)
		for _, import_stmt in ipairs(imports) do
			repl.send_import(import_stmt)
		end
	end
	local code_to_send = prepare_code_for_repl(normalized_lines)
	local repl_state = repl.get_state()
	local was_open = repl_state.is_open
	local block_num, total_blocks = get_block_number(start_line)
	local send_options = {}
	if mode == "cache" then
		send_options.use_cache = true
	elseif mode == "isolated" then
		send_options.use_cache = false
	elseif mode == "all" then
		send_options.use_cache = false
		if all_code_lines and #all_code_lines > 0 then
			local normalized_all = normalize_indentation(all_code_lines)
			local all_code = prepare_code_for_repl(normalized_all)
			code_to_send = all_code .. code_to_send
		end
	elseif mode == "nocache" then
		send_options.use_cache = true
	end
	repl.send(code_to_send, true, send_options)
	if mode == "cache" then
		repl.add_to_code_cache(prepare_code_for_repl(normalized_lines))
	end
	local line_count = #normalized_lines
	local status = was_open and "→" or "↗"
	local action = was_open and "Sent" or "Opened & sent"
	local block_info = block_num and string.format("[%d/%d] ", block_num, total_blocks) or ""
	local mode_indicator = mode ~= "cache" and string.format(" [%s]", mode) or ""
	vim.notify(
		string.format(
			"PyEval %s: %s %s%d line%s (lines %d-%d)%s",
			status,
			action,
			block_info,
			line_count,
			line_count > 1 and "s" or "",
			start_line + 1,
			end_line - 1,
			mode_indicator
		),
		vim.log.levels.INFO
	)
end
function M.list_blocks()
	local total_lines = vim.fn.line("$")
	local blocks = {}
	local in_block = false
	local block_start = nil
	for line_num = 1, total_lines do
		local line_text = vim.fn.getline(line_num)
		if line_text:match("^%s*" .. vim.pesc(markers.start)) then
			if in_block then
				vim.notify(
					string.format("PyEval: Nested %s markers found at line %d", markers.start, line_num),
					vim.log.levels.WARN
				)
			else
				in_block = true
				block_start = line_num
			end
		elseif line_text:match("^%s*" .. vim.pesc(markers["end"])) then
			if in_block then
				table.insert(blocks, {
					start_line = block_start,
					end_line = line_num,
				})
				in_block = false
				block_start = nil
			else
				vim.notify(
					string.format("PyEval: Unmatched %s marker at line %d", markers["end"], line_num),
					vim.log.levels.WARN
				)
			end
		end
	end
	if in_block then
		vim.notify(
			string.format("PyEval: Unclosed %s marker at line %d", markers.start, block_start),
			vim.log.levels.WARN
		)
	end
	return blocks
end
return M
