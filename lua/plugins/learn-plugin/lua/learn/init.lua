local M = {}
M.config = {
  learn_bin = vim.fn.expand("~/Projects/organized/learn/bin/learn"),
  notes_vault = vim.fn.expand("~/.learn-notes"),
  auto_open_notes = true,
  floating_status = true,
  status_width = 60,
  status_height = 20,
}
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end
local function run_learn(args, callback)
  local cmd = {M.config.learn_bin}
  vim.list_extend(cmd, args)
  local output = {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(output, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(output, data)
      end
    end,
    on_exit = function(_, exit_code)
      if callback then
        callback(output, exit_code)
      end
    end,
  })
end
function M.start_session(topic)
  vim.schedule(function()
    if not topic or topic == "" then
      topic = vim.fn.input("Topic: ")
      if topic == "" then
        return
      end
    end
    run_learn({"start", topic}, function(output, exit_code)
      if exit_code == 0 then
        vim.notify("Started session: " .. topic, vim.log.levels.INFO)
        local note_path = nil
        for _, line in ipairs(output) do
          if line ~= "" then
            local path = line:match("^NOTE_PATH=(.+)$")
            if path then
              note_path = path
            end
          end
        end
        if M.config.auto_open_notes and note_path then
          vim.schedule(function()
            vim.cmd("edit " .. vim.fn.fnameescape(note_path))
          end)
        end
      else
        vim.notify("Failed to start session: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
      end
    end)
  end)
end
function M.end_session()
  local cmd = M.config.learn_bin .. " end"
  vim.cmd("split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end
function M.show_status()
  run_learn({"status"}, function(output, exit_code)
    if exit_code == 0 then
      if M.config.floating_status then
        M.show_floating_window(output)
      else
        for _, line in ipairs(output) do
          if line ~= "" then
            -- TODO: Add proper validation
          end
        end
      end
    else
      vim.notify("Failed to get status: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
    end
  end)
end
function M.find(keyword)
  vim.schedule(function()
    if not keyword or keyword == "" then
      keyword = vim.fn.input("Search: ")
      if keyword == "" then
        return
      end
    end
    run_learn({"find", keyword}, function(output, exit_code)
      if exit_code == 0 then
        M.show_floating_window(output)
      else
        vim.notify("Search failed: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
      end
    end)
  end)
end
function M.show_next()
  run_learn({"next"}, function(output, exit_code)
    if exit_code == 0 then
      for _, line in ipairs(output) do
        if line ~= "" then
            -- TODO: Add proper validation
        end
      end
      for _, line in ipairs(output) do
        local topic = line:match("^Next: (.+)$")
        if topic then
          local choice = vim.fn.confirm("Start learning " .. topic .. "?", "&Yes\n&No", 2)
          if choice == 1 then
            M.start_session(topic)
          end
          break
        end
      end
    else
      vim.notify("Failed to get next topic: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
    end
  end)
end
function M.list_sessions()
  run_learn({"list"}, function(output, exit_code)
    if exit_code == 0 then
      M.show_floating_window(output)
    else
      vim.notify("Failed to list sessions: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
    end
  end)
end
function M.show_floating_window(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  if #lines == 0 then
    vim.notify("No content to display", vim.log.levels.WARN)
    return
  end
  local width = M.config.status_width
  local height = math.min(#lines + 2, M.config.status_height)
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, #line)
  end
  width = math.min(math.max(width, max_width + 4), vim.o.columns - 4)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
  local close_keys = {'q', '<Esc>'}
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, ':close<CR>', {
      nowait = true,
      noremap = true,
      silent = true
    })
  end
end
function M.capture_code_file()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('+', filepath)
  vim.notify("File path copied: " .. filepath, vim.log.levels.INFO)
end
function M.get_stats()
  run_learn({"status"}, function(output, exit_code)
    if exit_code == 0 then
      local stats = {}
      for _, line in ipairs(output) do
        local progress = line:match("Progress: (%d+/%d+)")
        if progress then
          stats.progress = progress
        end
        local time = line:match("Total time: (.+)")
        if time then
          stats.total_time = time
        end
      end
      if stats.progress then
            -- TODO: Add proper validation
      end
      if stats.total_time then
            -- TODO: Add proper validation
      end
    end
  end)
end
function M.browse_vault()
  local vault_path = M.config.notes_vault
  if vim.fn.isdirectory(vault_path) == 0 then
    vim.notify("Learning vault not found: " .. vault_path, vim.log.levels.WARN)
    return
  end
  local has_telescope, _ = pcall(require, 'telescope.builtin')
  if has_telescope then
    require('telescope.builtin').find_files({
      prompt_title = 'Learning Notes',
      cwd = vault_path,
      find_command = {'rg', '--files', '--glob', '*.md'},
    })
  else
    local notes = vim.fn.globpath(vault_path, '*.md', false, true)
    vim.ui.select(notes, {
      prompt = 'Select learning note:',
      format_item = function(item)
        return vim.fn.fnamemodify(item, ':t')
      end,
    }, function(choice)
      if choice then
        vim.cmd('edit ' .. vim.fn.fnameescape(choice))
      end
    end)
  end
end
function M.open_vault()
  local vault_path = M.config.notes_vault
  if vim.fn.isdirectory(vault_path) == 0 then
    vim.notify("Learning vault not found: " .. vault_path, vim.log.levels.WARN)
    return
  end
  vim.cmd('edit ' .. vim.fn.fnameescape(vault_path))
end
function M.search_vault(query)
  vim.schedule(function()
    if not query or query == "" then
      query = vim.fn.input("Search in learning vault: ")
      if query == "" then
        return
      end
    end
    local vault_path = M.config.notes_vault
    local has_telescope, telescope = pcall(require, 'telescope.builtin')
    if has_telescope then
      telescope.live_grep({
        prompt_title = 'Search Learning Notes',
        cwd = vault_path,
        default_text = query,
      })
    else
      vim.notify("Telescope required for vault search", vim.log.levels.WARN)
    end
  end)
end
function M.init_curriculum(name)
  vim.schedule(function()
    if not name or name == "" then
      name = vim.fn.input("Curriculum name: ")
      if name == "" then
        return
      end
    end
    run_learn({"init", name}, function(output, exit_code)
      if exit_code == 0 then
        vim.notify("Initialized curriculum: " .. name, vim.log.levels.INFO)
        for _, line in ipairs(output) do
          if line ~= "" then
            -- TODO: Add proper validation
          end
        end
      else
        vim.notify("Failed to initialize: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
      end
    end)
  end)
end
return M
