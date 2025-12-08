local M = {}
local config = require("picker.config")
local utils = require("picker.utils")
local fzf = require("picker.fzf")
local actions = require("picker.actions")
local function build_fd_cmd(opts)
  opts = opts or {}
  local cfg = config.get()
  local args = { cfg.fd_path }
  if opts.type == "file" then
    table.insert(args, "--type=f")
  elseif opts.type == "directory" then
    table.insert(args, "--type=d")
  end
  if opts.hidden or cfg.search.include_hidden then
    table.insert(args, "--hidden")
  end
  if opts.follow or cfg.search.follow_symlinks then
    table.insert(args, "--follow")
  end
  table.insert(args, "--exclude=.git")
  table.insert(args, "--exclude=node_modules")
  table.insert(args, "--exclude=__pycache__")
  table.insert(args, "--exclude=.venv")
  table.insert(args, "--exclude=target")
  table.insert(args, "--color=always")
  if cfg.search.max_results then
    table.insert(args, "--max-results=" .. cfg.search.max_results)
  end
  return table.concat(args, " ")
end
function M.find_files(opts)
  opts = opts or {}
  local fd_path = config.get().fd_path
  if not utils.check_executable(fd_path, "Install fd: https://github.com/sharkdp/fd") then
    return
  end
  local root = opts.cwd or utils.get_project_root()
  local fd_cmd = build_fd_cmd({ type = "file", hidden = opts.hidden })
  fzf.run({
    source_cmd = "cd " .. vim.fn.shellescape(root) .. " && " .. fd_cmd,
    prompt = opts.prompt or "Files",
    preview_cmd = fzf.file_preview_cmd(),
    on_select = function(selection, action)
      local path = root .. "/" .. selection
      actions.open_file(path, nil, nil, action)
    end,
    on_multi_select = function(selections, action)
      if #selections > 5 then
        actions.send_to_quickfix(
          vim.tbl_map(function(s)
            return root .. "/" .. s
          end, selections),
          "Find Files"
        )
      else
        for _, sel in ipairs(selections) do
          local path = root .. "/" .. sel
          actions.open_file(path, nil, nil, action)
        end
      end
    end,
  })
end
function M.find_directories(opts)
  opts = opts or {}
  local fd_path = config.get().fd_path
  if not utils.check_executable(fd_path, "Install fd: https://github.com/sharkdp/fd") then
    return
  end
  local root = opts.cwd or utils.get_project_root()
  local fd_cmd = build_fd_cmd({ type = "directory", hidden = opts.hidden })
  fzf.run({
    source_cmd = "cd " .. vim.fn.shellescape(root) .. " && " .. fd_cmd,
    prompt = opts.prompt or "Directories",
    on_select = function(selection)
      local path = root .. "/" .. selection
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    end,
  })
end
function M.find_all(opts)
  opts = opts or {}
  local fd_path = config.get().fd_path
  if not utils.check_executable(fd_path, "Install fd: https://github.com/sharkdp/fd") then
    return
  end
  local root = opts.cwd or utils.get_project_root()
  local fd_cmd = build_fd_cmd({ hidden = opts.hidden })
  fzf.run({
    source_cmd = "cd " .. vim.fn.shellescape(root) .. " && " .. fd_cmd,
    prompt = opts.prompt or "Find",
    preview_cmd = fzf.file_preview_cmd(),
    on_select = function(selection, action)
      local path = root .. "/" .. selection
      if utils.is_directory(path) then
        vim.cmd("edit " .. vim.fn.fnameescape(path))
      else
        actions.open_file(path, nil, nil, action)
      end
    end,
  })
end
return M
