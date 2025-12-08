local M = {}
local batch_queues = {}
local BATCH_DELAYS = {
  ['textDocument/documentSymbol'] = 100,
  ['textDocument/semanticTokens/full'] = 150,
}
local MAX_BATCH_SIZE = 10
function M.batch_request(method, params, callback, client_id)
  local delay = BATCH_DELAYS[method]
  if not delay then
    local client = vim.lsp.get_client_by_id(client_id)
    if client then
      local request_fn = client._lsp_enhanced_original_request or client.request
      request_fn(client, method, params, callback)
    end
    return
  end
  if not batch_queues[method] then
    batch_queues[method] = {
      requests = {},
      timer = nil,
    }
  end
  local queue = batch_queues[method]
  table.insert(queue.requests, {
    params = params,
    callback = callback,
    client_id = client_id,
  })
  if #queue.requests >= MAX_BATCH_SIZE then
    M.flush_batch(method)
    return
  end
  if queue.timer then
    queue.timer:stop()
    queue.timer:close()
  end
  queue.timer = vim.loop.new_timer()
  queue.timer:start(delay, 0, vim.schedule_wrap(function()
    M.flush_batch(method)
  end))
end
function M.flush_batch(method)
  local queue = batch_queues[method]
  if not queue or #queue.requests == 0 then
    return
  end
  if queue.timer then
    queue.timer:stop()
    queue.timer:close()
    queue.timer = nil
  end
  local requests = queue.requests
  queue.requests = {}
  for _, req in ipairs(requests) do
    local client = vim.lsp.get_client_by_id(req.client_id)
    if client then
      local request_fn = client._lsp_enhanced_original_request or client.request
      request_fn(client, method, req.params, req.callback)
    end
  end
end
function M.flush_all()
  for method, _ in pairs(batch_queues) do
    M.flush_batch(method)
  end
end
function M.set_delay(method, delay_ms)
  BATCH_DELAYS[method] = delay_ms
end
function M.clear_all()
  M.flush_all()
  for _, queue in pairs(batch_queues) do
    if queue.timer then
      queue.timer:stop()
      queue.timer:close()
    end
  end
  batch_queues = {}
end
return M
