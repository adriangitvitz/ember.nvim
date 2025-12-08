local M = {}
local history = {}
function M.get_link_at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local col = cursor[2] + 1
  local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
  if not line then
    return nil
  end
  local pattern = "%[([^%]]+)%]%(([^%)]+)%)"
  local start_pos = 1
  while true do
    local link_start, link_end, text, url = line:find(pattern, start_pos)
    if not link_start then
      break
    end
    if col >= link_start and col <= link_end then
      local link_type = M.get_link_type(url)
      return {
        url = url,
        text = text,
        type = link_type,
        line = line_num,
        start_col = link_start,
        end_col = link_end,
      }
    end
    start_pos = link_end + 1
  end
  pattern = "%[%[([^%]]+)%]%]"
  start_pos = 1
  while true do
    local link_start, link_end, link_text = line:find(pattern, start_pos)
    if not link_start then
      break
    end
    if col >= link_start and col <= link_end then
      return {
        url = link_text,
        text = link_text,
        type = "wiki",
        line = line_num,
        start_col = link_start,
        end_col = link_end,
      }
    end
    start_pos = link_end + 1
  end
  pattern = "<(https?://[^>]+)>"
  start_pos = 1
  while true do
    local link_start, link_end, url = line:find(pattern, start_pos)
    if not link_start then
      break
    end
    if col >= link_start and col <= link_end then
      return {
        url = url,
        text = url,
        type = "url",
        line = line_num,
        start_col = link_start,
        end_col = link_end,
      }
    end
    start_pos = link_end + 1
  end
  return nil
end
function M.get_link_type(url)
  if url:match("^https?://") or url:match("^mailto:") then
    return "url"
  elseif url:match("^#") then
    return "heading"
  elseif url:match("#") then
    return "file_heading"
  else
    return "file"
  end
end
local function push_history()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local file = vim.api.nvim_buf_get_name(bufnr)
  table.insert(history, {
    file = file,
    line = cursor[1],
    col = cursor[2],
    bufnr = bufnr,
  })
  while #history > 50 do
    table.remove(history, 1)
  end
end
local function find_heading_by_slug(slug, bufnr)
  local ts = require("orgdown.treesitter")
  local headings = ts.get_headings(bufnr)
  local pattern = slug:gsub("-", "[%- ]"):lower()
  for _, heading in ipairs(headings) do
    local heading_slug = heading.text:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
    if heading_slug:match(pattern) or heading.text:lower():match(pattern) then
      return heading.line
    end
  end
  return nil
end
local function open_url(url)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = { "open", url }
  elseif vim.fn.has("unix") == 1 then
    cmd = { "xdg-open", url }
  elseif vim.fn.has("win32") == 1 then
    cmd = { "cmd", "/c", "start", "", url }
  else
    vim.notify("Cannot open URL: unsupported platform", vim.log.levels.ERROR)
    return
  end
  vim.fn.jobstart(cmd, { detach = true })
end
function M.follow(opts)
  opts = opts or {}
  local config = require("orgdown.config")
  local create_missing = opts.create_missing
  if create_missing == nil then
    create_missing = config.get("navigation.create_missing")
  end
  local link = M.get_link_at_cursor()
  if not link then
    vim.notify("No link under cursor", vim.log.levels.WARN)
    return false
  end
  push_history()
  if link.type == "url" then
    open_url(link.url)
    return true
  elseif link.type == "heading" then
    local slug = link.url:sub(2)
    local line = find_heading_by_slug(slug, 0)
    if line then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return true
    else
      vim.notify("Heading not found: " .. slug, vim.log.levels.WARN)
      return false
    end
  elseif link.type == "file" or link.type == "file_heading" then
    local file_path = link.url
    local heading_slug = nil
    if link.type == "file_heading" then
      local parts = vim.split(link.url, "#", { plain = true })
      file_path = parts[1]
      heading_slug = parts[2]
    end
    local current_file = vim.api.nvim_buf_get_name(0)
    local current_dir = vim.fn.fnamemodify(current_file, ":h")
    if not file_path:match("^/") and not file_path:match("^~") then
      file_path = current_dir .. "/" .. file_path
    end
    file_path = vim.fn.expand(file_path)
    if vim.fn.filereadable(file_path) == 0 then
      if create_missing then
        local parent_dir = vim.fn.fnamemodify(file_path, ":h")
        vim.fn.mkdir(parent_dir, "p")
        local file = io.open(file_path, "w")
        if file then
          file:close()
          vim.notify("Created: " .. file_path, vim.log.levels.INFO)
        end
      else
        vim.notify("File not found: " .. file_path, vim.log.levels.WARN)
        return false
      end
    end
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    if heading_slug then
      local line = find_heading_by_slug(heading_slug, 0)
      if line then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
      end
    end
    return true
  elseif link.type == "wiki" then
    local file_name = link.url:gsub("%s+", "-") .. ".md"
    local current_file = vim.api.nvim_buf_get_name(0)
    local current_dir = vim.fn.fnamemodify(current_file, ":h")
    local file_path = current_dir .. "/" .. file_name
    if vim.fn.filereadable(file_path) == 0 and create_missing then
      local file = io.open(file_path, "w")
      if file then
        file:write("# " .. link.url .. "\n\n")
        file:close()
        vim.notify("Created: " .. file_path, vim.log.levels.INFO)
      end
    elseif vim.fn.filereadable(file_path) == 0 then
      vim.notify("File not found: " .. file_path, vim.log.levels.WARN)
      return false
    end
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    return true
  end
  return false
end
function M.go_back()
  if #history == 0 then
    vim.notify("No history to go back to", vim.log.levels.WARN)
    return false
  end
  local entry = table.remove(history)
  local current_file = vim.api.nvim_buf_get_name(0)
  if entry.file ~= current_file and entry.file ~= "" then
    vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
  end
  vim.api.nvim_win_set_cursor(0, { entry.line, entry.col })
  return true
end
function M.create_link(url)
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" then
    vim.notify("Select text first to create a link", vim.log.levels.WARN)
    return
  end
  vim.cmd("normal! ")
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  if start_pos[2] ~= end_pos[2] then
    vim.notify("Link text must be on a single line", vim.log.levels.WARN)
    return
  end
  local line = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, start_pos[2], false)[1]
  local text = line:sub(start_pos[3], end_pos[3])
  if not url then
    url = vim.fn.input("Link URL: ")
    if url == "" then
      return
    end
  end
  local before = line:sub(1, start_pos[3] - 1)
  local after = line:sub(end_pos[3] + 1)
  local new_line = before .. "[" .. text .. "](" .. url .. ")" .. after
  vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, start_pos[2], false, { new_line })
end
function M.get_all_links(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ts = require("orgdown.treesitter")
  return ts.get_links(bufnr)
end
function M.get_history()
  return vim.deepcopy(history)
end
function M.clear_history()
  history = {}
end
local function get_relative_path(target_path)
  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.fnamemodify(current_file, ":h")
  local target_abs = vim.fn.fnamemodify(target_path, ":p")
  local result = vim.fn.systemlist({ "realpath", "--relative-to=" .. current_dir, target_abs })[1]
  if vim.v.shell_error ~= 0 or not result then
    return vim.fn.fnamemodify(target_path, ":t")
  end
  return result
end
function M.insert_link()
  local config = require("orgdown.config")
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local files = vim.fn.globpath(vault_root, "**/*.md", false, true)
  if #files == 0 then
    vim.notify("No notes found in vault: " .. vault_root, vim.log.levels.WARN)
    return
  end
  local items = {}
  local path_map = {}
  for _, filepath in ipairs(files) do
    local relative = filepath:sub(#vault_root + 2):gsub("%.md$", "")
    local title = vim.fn.fnamemodify(filepath, ":t:r")
    local display = title .. " — " .. relative
    table.insert(items, display)
    path_map[display] = filepath
  end
  table.sort(items)
  vim.ui.select(items, {
    prompt = "Select note to link:",
  }, function(choice)
    if not choice then
      return
    end
    local target_path = path_map[choice]
    local relative_path = get_relative_path(target_path)
    local title = choice:match("^([^—]+)"):gsub("%s+$", "")
    vim.ui.input({ prompt = "Link text: ", default = title }, function(text)
      if not text or text == "" then
        text = title
      end
      local cursor = vim.api.nvim_win_get_cursor(0)
      local row = cursor[1] - 1
      local col = cursor[2]
      local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
      local before = line:sub(1, col)
      local after = line:sub(col + 1)
      local link = "[" .. text .. "](" .. relative_path .. ")"
      local new_line = before .. link .. after
      vim.api.nvim_buf_set_lines(0, row, row + 1, false, { new_line })
      vim.api.nvim_win_set_cursor(0, { row + 1, col + #link })
    end)
  end)
end
return M
