local config = require("notelinks.config")
local M = {}
local function exec_cli(args, opts)
  opts = opts or {}
  local cli_path = config.get().cli_path
  local cmd = { cli_path }
  vim.list_extend(cmd, args)
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  if exit_code ~= 0 then
    if not opts.silent then
      vim.notify("dn-tui error: " .. result, vim.log.levels.ERROR)
    end
    return nil, result
  end
  return result, nil
end
local function parse_json(json_str)
  local ok, result = pcall(vim.fn.json_decode, json_str)
  if not ok then
    return nil, "Failed to parse JSON"
  end
  return result, nil
end
function M.daily_note()
  local output, err = exec_cli({ "daily" })
  if err then
    return nil, err
  end
  return vim.trim(output), nil
end
function M.weekly_note()
  local output, err = exec_cli({ "weekly" })
  if err then
    return nil, err
  end
  return vim.trim(output), nil
end
function M.monthly_note()
  local output, err = exec_cli({ "monthly" })
  if err then
    return nil, err
  end
  return vim.trim(output), nil
end
function M.quarterly_note()
  local output, err = exec_cli({ "quarterly" })
  if err then
    return nil, err
  end
  return vim.trim(output), nil
end
function M.yearly_note()
  local output, err = exec_cli({ "yearly" })
  if err then
    return nil, err
  end
  return vim.trim(output), nil
end
function M.create_note(title, template)
  local args = { "create", title }
  if template then
    table.insert(args, "--template")
    table.insert(args, template)
  end
  local output, err = exec_cli(args)
  if err then
    return nil, err
  end
  return vim.trim(output), nil
end
function M.list_notes()
  local output, err = exec_cli({ "list", "--json" })
  if err then
    return nil, err
  end
  return parse_json(output)
end
function M.search_notes(query)
  local output, err = exec_cli({ "search", query, "--json" })
  if err then
    return nil, err
  end
  return parse_json(output)
end
function M.create_link(from_path, to_id)
  local _, err = exec_cli({ "link", from_path, to_id })
  if err then
    return nil, err
  end
  return true, nil
end
function M.get_backlinks(note_id)
  local output, err = exec_cli({ "backlinks", note_id, "--json" })
  if err then
    return nil, err
  end
  return parse_json(output)
end
function M.list_templates()
  local output, err = exec_cli({ "templates", "--json" })
  if err then
    return nil, err
  end
  return parse_json(output)
end
function M.get_current_note_id()
  local current_file = vim.fn.expand("%:p")
  local notes_dir = config.get().notes_dir
  if not vim.startswith(current_file, notes_dir) then
    return nil, "Current file is not a note"
  end
  local lines = vim.fn.readfile(current_file)
  local in_frontmatter = false
  local note_id = nil
  for _, line in ipairs(lines) do
    if line == "---" then
      if in_frontmatter then
        break
      else
        in_frontmatter = true
      end
    elseif in_frontmatter then
      local id_match = line:match("^id:%s*(.+)$")
      if id_match then
        note_id = vim.trim(id_match)
        break
      end
    end
  end
  if not note_id then
    return nil, "Could not find note ID in frontmatter"
  end
  return note_id, nil
end
return M
