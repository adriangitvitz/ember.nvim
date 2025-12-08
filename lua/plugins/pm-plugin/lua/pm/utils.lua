local M = {}
function M.parse_json(str)
  local ok, result = pcall(vim.fn.json_decode, str)
  if ok then
    return result
  end
  return nil
end
function M.encode_json(tbl)
  local ok, result = pcall(vim.fn.json_encode, tbl)
  if ok then
    return result
  end
  return nil
end
function M.notify(message, level)
  local config = require('pm.config')
  if not config.options.notifications.enabled then
    return
  end
  level = level or vim.log.levels.INFO
  vim.notify(message, level, {
    title = 'PM',
    timeout = config.options.notifications.timeout,
  })
end
function M.parse_minimal_task(line)
  local status_icon, rest = line:match('^%s*(%[.%])%s+(.+)')
  if not status_icon then
    return nil
  end
  local status
  if status_icon == '[ ]' then
    status = 'todo'
  elseif status_icon == '[~]' then
    status = 'doing'
  elseif status_icon == '[x]' then
    status = 'done'
  elseif status_icon == '[!]' then
    status = 'blocked'
  end
  local title, cl, id = rest:match('^(.-)%s+cl:(%S*)%s+%((.-)%)$')
  if not title then
    return nil
  end
  return {
    id = id,
    title = title,
    status = status,
    changelist = cl ~= '' and cl or nil,
  }
end
function M.format_status_icon(status)
  if status == 'todo' then
    return '[ ]'
  elseif status == 'doing' then
    return '[~]'
  elseif status == 'done' then
    return '[x]'
  elseif status == 'blocked' then
    return '[!]'
  end
  return '[ ]'
end
function M.format_priority(priority)
  if priority == 0 then
    return 'LOW'
  elseif priority == 1 then
    return 'NORM'
  elseif priority == 2 then
    return 'HIGH'
  elseif priority == 3 then
    return 'CRIT'
  end
  return 'NORM'
end
function M.parse_priority(input)
  input = input:lower()
  if input == 'l' or input == 'low' then
    return 'low'
  elseif input == 'n' or input == 'normal' then
    return 'normal'
  elseif input == 'h' or input == 'high' then
    return 'high'
  elseif input == 'c' or input == 'critical' then
    return 'critical'
  end
  return 'normal'
end
function M.format_duration(seconds)
  if not seconds or seconds == 0 then
    return '0m'
  end
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  if hours > 0 then
    return string.format('%dh %dm', hours, minutes)
  else
    return string.format('%dm', minutes)
  end
end
function M.split(str, delimiter)
  local result = {}
  for match in (str .. delimiter):gmatch('(.-)' .. delimiter) do
    table.insert(result, match)
  end
  return result
end
function M.trim(str)
  return str:match('^%s*(.-)%s*$')
end
return M
