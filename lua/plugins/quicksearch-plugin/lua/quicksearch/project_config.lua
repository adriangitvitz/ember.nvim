local M = {}
local project_cache = {}
local function get_project_root()
  local utils = require("quicksearch.utils")
  return utils.get_project_root()
end
function M.load_project_config(project_root)
  if project_cache[project_root] then
    return project_cache[project_root]
  end
  local config_path = project_root .. "/.quicksearch.lua"
  if vim.fn.filereadable(config_path) == 0 then
    project_cache[project_root] = {}
    return {}
  end
  local success, result = pcall(dofile, config_path)
  if success and type(result) == "table" then
    project_cache[project_root] = result
    return result
  else
    if success == false then
      vim.notify(
        string.format("Failed to load .quicksearch.lua: %s", tostring(result)),
        vim.log.levels.WARN
      )
    end
    project_cache[project_root] = {}
    return {}
  end
end
function M.get_merged_config()
  local config = require("quicksearch.config")
  local global_config = config.get()
  local project_root = get_project_root()
  local project_config = M.load_project_config(project_root)
  return vim.tbl_deep_extend("force", global_config, project_config)
end
function M.clear_cache(project_root)
  if project_root then
    project_cache[project_root] = nil
  else
    project_cache = {}
  end
end
return M
