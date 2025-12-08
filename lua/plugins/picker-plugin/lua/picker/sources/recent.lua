local M = {}
local fzf = require("picker.fzf")
local actions = require("picker.actions")
local utils = require("picker.utils")
local function get_recent_files(opts)
  opts = opts or {}
  local limit = opts.limit or 100
  local cwd_only = opts.cwd_only or false
  local cwd = utils.get_project_root()
  local files = {}
  local seen = {}
  for _, file in ipairs(vim.v.oldfiles) do
    if #files >= limit then
      break
    end
    if seen[file] then
      goto continue
    end
    seen[file] = true
    if file:match("^term://") or file:match("^fugitive://") or file:match("^oil://") then
      goto continue
    end
    if vim.fn.filereadable(file) == 0 then
      goto continue
    end
    if cwd_only then
      if not file:find(cwd, 1, true) then
        goto continue
      end
    end
    local display = utils.relative_path(file, cwd)
    table.insert(files, display)
    ::continue::
  end
  return files, cwd
end
function M.recent(opts)
  opts = opts or {}
  local files, cwd = get_recent_files(opts)
  if #files == 0 then
    utils.notify("No recent files", vim.log.levels.INFO)
    return
  end
  fzf.run({
    items = files,
    prompt = opts.prompt or "Recent",
    preview_cmd = fzf.file_preview_cmd(),
    on_select = function(selection, action)
      local path = selection
      if not path:match("^/") then
        path = cwd .. "/" .. selection
      end
      actions.open_file(path, nil, nil, action)
    end,
    on_multi_select = function(selections, action)
      for _, sel in ipairs(selections) do
        local path = sel
        if not path:match("^/") then
          path = cwd .. "/" .. sel
        end
        actions.open_file(path, nil, nil, action)
      end
    end,
  })
end
function M.recent_project(opts)
  opts = opts or {}
  opts.cwd_only = true
  M.recent(opts)
end
return M
