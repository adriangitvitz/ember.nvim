local M = {}
local fzf = require("picker.fzf")
local actions = require("picker.actions")
local utils = require("picker.utils")
local function get_buffer_list()
  local buffers = {}
  local current = vim.api.nvim_get_current_buf()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      local name = vim.api.nvim_buf_get_name(bufnr)
      local modified = vim.bo[bufnr].modified and "[+]" or ""
      local readonly = vim.bo[bufnr].readonly and "[RO]" or ""
      local current_marker = bufnr == current and "%" or " "
      if name == "" then
        name = "[No Name]"
      else
        name = utils.relative_path(name)
      end
      local line = string.format("%s%d: %s %s%s", current_marker, bufnr, name, modified, readonly)
      table.insert(buffers, line)
    end
  end
  return buffers
end
function M.buffers(opts)
  opts = opts or {}
  local buffer_list = get_buffer_list()
  if #buffer_list == 0 then
    utils.notify("No buffers", vim.log.levels.INFO)
    return
  end
  fzf.run({
    items = buffer_list,
    prompt = opts.prompt or "Buffers",
    preview_cmd = nil,
    on_select = function(selection, action)
      actions.open_buffer(selection, action)
    end,
  })
end
function M.delete_buffers(opts)
  opts = opts or {}
  local buffer_list = get_buffer_list()
  if #buffer_list == 0 then
    utils.notify("No buffers to delete", vim.log.levels.INFO)
    return
  end
  fzf.run({
    items = buffer_list,
    prompt = opts.prompt or "Delete Buffers",
    on_select = function(selection)
      local bufnr = tonumber(selection:match("^.(%d+):"))
      if bufnr then
        vim.api.nvim_buf_delete(bufnr, { force = false })
        utils.notify("Deleted buffer " .. bufnr, vim.log.levels.INFO)
      end
    end,
    on_multi_select = function(selections)
      for _, sel in ipairs(selections) do
        local bufnr = tonumber(sel:match("^.(%d+):"))
        if bufnr then
          pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
        end
      end
      utils.notify("Deleted " .. #selections .. " buffers", vim.log.levels.INFO)
    end,
  })
end
return M
