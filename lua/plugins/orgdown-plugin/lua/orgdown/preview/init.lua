local M = {}
local renderer = require("orgdown.preview.renderer")
local window = require("orgdown.preview.window")
local highlights = require("orgdown.preview.highlights")
local utils = require("orgdown.utils")
local events = require("orgdown.events")
local state = {
  attached_buffers = {},
  debounce_timers = {},
}
function M.setup(opts)
  opts = opts or {}
  local config = require("orgdown.config")
  local highlight_config = config.get("highlights") or {}
  highlights.setup(highlight_config)
end
function M.is_open()
  return window.is_open()
end
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not window.is_open() then
    return
  end
  local preview_bufnr = window.get_bufnr()
  if not preview_bufnr then
    return
  end
  renderer.render(bufnr, preview_bufnr)
end
function M.open(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  if not utils.is_markdown_buffer(bufnr) then
    vim.notify("[orgdown] Preview only available for markdown files", vim.log.levels.WARN)
    return
  end
  local config = require("orgdown.config")
  local preview_config = config.get("preview") or {}
  opts = vim.tbl_deep_extend("force", preview_config, opts or {})
  local winnr, preview_bufnr = window.open(opts)
  window.set_source(bufnr)
  renderer.render(bufnr, preview_bufnr)
  M.attach(bufnr)
  events.emit(events.EVENTS.PREVIEW_OPENED, {
    source_bufnr = bufnr,
    preview_bufnr = preview_bufnr,
    winnr = winnr,
  })
  window.focus_source()
end
function M.close()
  local source_bufnr = window.get_source_bufnr()
  if source_bufnr then
    M.detach(source_bufnr)
  end
  window.close()
  events.emit(events.EVENTS.PREVIEW_CLOSED, {
    source_bufnr = source_bufnr,
  })
end
function M.toggle()
  local current_bufnr = vim.api.nvim_get_current_buf()
  if window.is_open() then
    local source_bufnr = window.get_source_bufnr()
    if source_bufnr == current_bufnr then
      M.close()
    else
      if utils.is_markdown_buffer(current_bufnr) then
        if source_bufnr then
          M.detach(source_bufnr)
        end
        window.set_source(current_bufnr)
        M.refresh(current_bufnr)
        M.attach(current_bufnr)
      else
        M.close()
      end
    end
  else
    M.open()
  end
end
function M.attach(bufnr)
  if state.attached_buffers[bufnr] then
    return
  end
  local config = require("orgdown.config")
  local live_update = config.get("preview.live_update")
  local debounce_ms = config.get("preview.debounce_ms") or 150
  local scroll_sync = config.get("preview.scroll_sync")
  local refresh_debounced = utils.debounce(function()
    if window.is_open() and window.get_source_bufnr() == bufnr then
      M.refresh(bufnr)
    end
  end, debounce_ms)
  local group = vim.api.nvim_create_augroup("orgdown_preview_" .. bufnr, { clear = true })
  if live_update then
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = group,
      buffer = bufnr,
      callback = function()
        refresh_debounced()
      end,
    })
  end
  if scroll_sync then
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = group,
      buffer = bufnr,
      callback = utils.throttle(function()
        if window.is_open() and window.get_source_bufnr() == bufnr then
          local cursor = vim.api.nvim_win_get_cursor(0)
          window.sync_scroll(0, cursor[1])
        end
      end, 16),
    })
  end
  vim.api.nvim_create_autocmd("BufUnload", {
    group = group,
    buffer = bufnr,
    callback = function()
      M.detach(bufnr)
      if window.get_source_bufnr() == bufnr then
        M.close()
      end
    end,
  })
  state.attached_buffers[bufnr] = group
end
function M.detach(bufnr)
  local group = state.attached_buffers[bufnr]
  if group then
    pcall(vim.api.nvim_del_augroup_by_id, group)
    state.attached_buffers[bufnr] = nil
  end
  local timer = state.debounce_timers[bufnr]
  if timer then
    timer:stop()
    timer:close()
    state.debounce_timers[bufnr] = nil
  end
end
function M.focus()
  window.focus()
end
function M.focus_source()
  window.focus_source()
end
function M.get_winnr()
  return window.get_winnr()
end
function M.get_bufnr()
  return window.get_bufnr()
end
return M
