local M = {}
local fzf = require("picker.fzf")
local actions = require("picker.actions")
local utils = require("picker.utils")
local function get_help_tags()
  local tags = {}
  local seen = {}
  local tagfiles = vim.fn.globpath(vim.o.runtimepath, "doc/tags", false, true)
  for _, tagfile in ipairs(tagfiles) do
    if vim.fn.filereadable(tagfile) == 1 then
      local lines = vim.fn.readfile(tagfile)
      for _, line in ipairs(lines) do
        local tag = line:match("^([^\t]+)")
        if tag and not seen[tag] then
          seen[tag] = true
          table.insert(tags, tag)
        end
      end
    end
  end
  table.sort(tags)
  return tags
end
function M.help_tags(opts)
  opts = opts or {}
  local tags = get_help_tags()
  if #tags == 0 then
    utils.notify("No help tags found", vim.log.levels.WARN)
    return
  end
  fzf.run({
    items = tags,
    prompt = opts.prompt or "Help",
    on_select = function(selection, action)
      actions.open_help(selection, action)
    end,
  })
end
function M.help_grep(opts)
  opts = opts or {}
  local rg_path = require("picker.config").get().rg_path
  if not utils.check_executable(rg_path, "Install ripgrep") then
    return
  end
  local help_dirs = vim.fn.globpath(vim.o.runtimepath, "doc", false, true)
  local search_paths = {}
  for _, dir in ipairs(help_dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      table.insert(search_paths, vim.fn.shellescape(dir))
    end
  end
  if #search_paths == 0 then
    utils.notify("No help directories found", vim.log.levels.WARN)
    return
  end
  local search_path = table.concat(search_paths, " ")
  local fzf_cmd = string.format(
    "%s --disabled --ansi --layout=reverse --info=inline "
      .. '--prompt="Help Grep> " '
      .. "--delimiter=: "
      .. '--bind="change:reload:%s --line-number --column --no-heading --color=always --type-add \'help:*.txt\' --type help {q} %s || true" '
      .. "--expect=ctrl-x,ctrl-v,ctrl-t "
      .. "--multi",
    require("picker.config").get().fzf_path,
    rg_path,
    search_path
  )
  local tmpfile = vim.fn.tempname()
  fzf_cmd = fzf_cmd .. " > " .. tmpfile
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.fn.termopen(fzf_cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        if exit_code == 0 then
          local lines = vim.fn.readfile(tmpfile)
          local action = lines[1]
          for i = 2, #lines do
            if lines[i] ~= "" then
              local file = lines[i]:match("^([^:]+)")
              if file then
                vim.cmd("help " .. vim.fn.fnamemodify(file, ":t:r"))
              end
            end
          end
        end
        vim.fn.delete(tmpfile)
      end)
    end,
  })
  vim.cmd("startinsert")
end
return M
