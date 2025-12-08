local M = {}
local config = require("orgdown.config")
local store_path = nil
local function get_binary()
  return config.get("vault.store.binary") or "orgdown-store"
end
local function get_store_path()
  if not store_path then
    store_path = config.get("vault.store.path")
    if store_path then
      store_path = vim.fn.expand(store_path)
    else
      store_path = vim.fn.expand("~/.orgdown")
    end
  end
  return store_path
end
local function execute(args)
  local binary = get_binary()
  local cmd = { binary }
  vim.list_extend(cmd, args)
  local env = vim.fn.environ()
  env.ORGDOWN_STORE_PATH = get_store_path()
  local result = vim.system(cmd, { env = env, text = true }):wait()
  if result.code == 0 then
    return true, result.stdout or "", nil
  else
    return false, "", result.stderr or "Unknown error"
  end
end
local function execute_async(args, callback)
  local binary = get_binary()
  local cmd = { binary }
  vim.list_extend(cmd, args)
  local env = vim.fn.environ()
  env.ORGDOWN_STORE_PATH = get_store_path()
  vim.system(cmd, { env = env, text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        callback(true, result.stdout or "", nil)
      else
        callback(false, "", result.stderr or "Unknown error")
      end
    end)
  end)
end
function M.notes_put(key, data)
  local json = vim.json.encode(data)
  local ok, output, err = execute({ "notes", "put", key, json })
  if not ok then
    return false, err
  end
  return true, nil
end
function M.notes_put_async(key, data, callback)
  local json = vim.json.encode(data)
  execute_async({ "notes", "put", key, json }, function(ok, _, err)
    callback(ok, err)
  end)
end
function M.notes_get(key)
  local ok, output, err = execute({ "notes", "get", key })
  if not ok then
    return nil, err
  end
  local data = vim.json.decode(output)
  return data, nil
end
function M.notes_delete(key)
  local ok, _, err = execute({ "notes", "delete", key })
  return ok, err
end
function M.notes_list()
  local ok, output, err = execute({ "notes", "list" })
  if not ok then
    return {}, err
  end
  local keys = vim.json.decode(output)
  return keys, nil
end
function M.notes_find(field, value)
  local ok, output, err = execute({ "notes", "find", field, value })
  if not ok then
    return {}, err
  end
  local results = vim.json.decode(output)
  return results, nil
end
function M.notes_search(query)
  local ok, output, err = execute({ "notes", "search", query })
  if not ok then
    return {}, err
  end
  local results = vim.json.decode(output)
  return results, nil
end
function M.links_add(source, target)
  local ok, _, err = execute({ "links", "add", source, target })
  return ok, err
end
function M.links_remove(source, target)
  local ok, _, err = execute({ "links", "remove", source, target })
  return ok, err
end
function M.links_from(source)
  local ok, output, err = execute({ "links", "from", source })
  if not ok then
    return {}, err
  end
  local links = vim.json.decode(output)
  return links, nil
end
function M.links_to(target)
  local ok, output, err = execute({ "links", "to", target })
  if not ok then
    return {}, err
  end
  local backlinks = vim.json.decode(output)
  return backlinks, nil
end
function M.links_update(source, targets)
  local json = vim.json.encode(targets)
  local ok, _, err = execute({ "links", "update", source, json })
  return ok, err
end
function M.is_available()
  local ok, output, _ = execute({ "version" })
  if ok then
    return true, vim.trim(output)
  end
  return false, nil
end
function M.reset_cache()
  store_path = nil
end
return M
