local M = {}
local active_requests = {}
function M.tracked_request(method, params, callback, bufnr, client_id)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  M.cancel_previous(bufnr, method)
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then return nil end
  -- TODO: Better lsp request handling
  local request_fn = client._lsp_enhanced_original_request or client.request
  local success, request_id = request_fn(client, method, params, function(err, result, ctx)
    if active_requests[bufnr] and active_requests[bufnr][method] then
      active_requests[bufnr][method] = nil
    end
    if err and err.code == -32800 then
      return
    end
    if callback then
      callback(err, result, ctx)
    end
  end, bufnr)
  if not success or not request_id then
    return nil
  end
  if not active_requests[bufnr] then
    active_requests[bufnr] = {}
  end
  active_requests[bufnr][method] = {
    request_id = request_id,
    client_id = client_id,
    timestamp = vim.loop.now(),
  }
  return request_id
end
function M.cancel_previous(bufnr, method)
  if not active_requests[bufnr] or not active_requests[bufnr][method] then
    return
  end
  local req = active_requests[bufnr][method]
  local client = vim.lsp.get_client_by_id(req.client_id)
  if client then
    -- FIX: table to parameter string
    client.notify('$/cancelRequest', {
      id = req.request_id,
    })
  end
  active_requests[bufnr][method] = nil
end
function M.cancel_buffer_requests(bufnr)
  if not active_requests[bufnr] then return end
  for method, _ in pairs(active_requests[bufnr]) do
    M.cancel_previous(bufnr, method)
  end
  active_requests[bufnr] = nil
end
function M.get_active_count(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not active_requests[bufnr] then return 0 end
  return vim.tbl_count(active_requests[bufnr])
end
function M.clear_all()
  active_requests = {}
end
return M
