local M = {}
local debounce_timers = {}
local pending_callbacks = {}
local DEBOUNCE_DELAYS = {
  ['textDocument/completion'] = 50,
  ['textDocument/hover'] = 100,
  ['textDocument/signatureHelp'] = 50,
  ['textDocument/publishDiagnostics'] = 200,
  ['textDocument/documentSymbol'] = 300,
  ['textDocument/semanticTokens/full'] = 500,
}
local function get_buffer_timers(bufnr)
  if not debounce_timers[bufnr] then
    debounce_timers[bufnr] = {}
  end
  return debounce_timers[bufnr]
end
local function get_pending_callbacks(bufnr, method)
  if not pending_callbacks[bufnr] then
    pending_callbacks[bufnr] = {}
  end
  if not pending_callbacks[bufnr][method] then
    pending_callbacks[bufnr][method] = {}
  end
  return pending_callbacks[bufnr][method]
end
function M.debounced_request(method, params, callback, bufnr, client_id)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local delay = DEBOUNCE_DELAYS[method] or 100
  local timers = get_buffer_timers(bufnr)
  local callbacks = get_pending_callbacks(bufnr, method)
  if timers[method] then
    timers[method]:stop()
    timers[method]:close()
  end
  table.insert(callbacks, { callback = callback, params = params })
  timers[method] = vim.loop.new_timer()
  timers[method]:start(delay, 0, vim.schedule_wrap(function()
    local last_params = callbacks[#callbacks].params
    local all_callbacks = vim.deepcopy(callbacks)
    pending_callbacks[bufnr][method] = {}
    timers[method]:close()
    timers[method] = nil
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then return end
    local request_fn = client._lsp_enhanced_original_request or client.request
    request_fn(client, method, last_params, function(err, result, ctx)
      for _, cb_data in ipairs(all_callbacks) do
        if cb_data.callback then
          cb_data.callback(err, result, ctx)
        end
      end
    end, bufnr)
  end))
end
function M.clear_buffer(bufnr)
  if debounce_timers[bufnr] then
    for _, timer in pairs(debounce_timers[bufnr]) do
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    end
    debounce_timers[bufnr] = nil
  end
  pending_callbacks[bufnr] = nil
end
function M.set_delay(method, delay_ms)
  DEBOUNCE_DELAYS[method] = delay_ms
end
function M.get_delay(method)
  return DEBOUNCE_DELAYS[method] or 100
end
return M
