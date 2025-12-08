local M = {}
M._capabilities_cache = {}
local SERVER_QUIRKS = {
  ['typescript-language-server'] = {
    handle_incomplete = true,
  },
  ['rust-analyzer'] = {
    trust_sort_text = true,
  },
  ['pyright'] = {
    deduplicate = true,
  },
  ['gopls'] = {
    trust_sort_text = true,
  },
  ['lua-language-server'] = {
    trust_sort_text = true,
  },
  ['clangd'] = {
    trust_sort_text = true,
  },
}
function M.get_capabilities(client_id)
  if M._capabilities_cache[client_id] then
    return M._capabilities_cache[client_id]
  end
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then return nil end
  M._capabilities_cache[client_id] = client.server_capabilities
  return client.server_capabilities
end
function M.supports(client_id, capability_path)
  local caps = M.get_capabilities(client_id)
  if not caps then return false end
  local parts = vim.split(capability_path, '.', { plain = true })
  local current = caps
  for _, part in ipairs(parts) do
    if type(current) ~= 'table' then return false end
    current = current[part]
    if current == nil then return false end
  end
  return current == true or (type(current) == 'table' and vim.tbl_count(current) > 0)
end
function M.get_completion_provider(client_id)
  local caps = M.get_capabilities(client_id)
  if not caps or not caps.completionProvider then return nil end
  return caps.completionProvider
end
function M.get_completion_item_kinds(client_id)
  local caps = M.get_capabilities(client_id)
  if not caps or not caps.completionProvider then return nil end
  if caps.completionProvider.completionItem and
     caps.completionProvider.completionItem.supportedItemKinds then
    return caps.completionProvider.completionItem.supportedItemKinds
  end
  return nil
end
function M.supports_snippets(client_id)
  return M.supports(client_id, 'completionProvider.completionItem.snippetSupport')
end
function M.get_completion_triggers(client_id)
  local provider = M.get_completion_provider(client_id)
  if not provider then return nil end
  return provider.triggerCharacters
end
function M.supports_completion_resolve(client_id)
  return M.supports(client_id, 'completionProvider.resolveProvider')
end
function M.supports_diagnostics(client_id)
  local caps = M.get_capabilities(client_id)
  return caps ~= nil
end
function M.supports_hover(client_id)
  return M.supports(client_id, 'hoverProvider')
end
function M.supports_signature_help(client_id)
  return M.supports(client_id, 'signatureHelpProvider')
end
function M.get_signature_triggers(client_id)
  local caps = M.get_capabilities(client_id)
  if not caps or not caps.signatureHelpProvider then return nil end
  return caps.signatureHelpProvider.triggerCharacters
end
function M.supports_definition(client_id)
  return M.supports(client_id, 'definitionProvider')
end
function M.supports_type_definition(client_id)
  return M.supports(client_id, 'typeDefinitionProvider')
end
function M.supports_references(client_id)
  return M.supports(client_id, 'referencesProvider')
end
function M.supports_formatting(client_id)
  return M.supports(client_id, 'documentFormattingProvider')
end
function M.supports_range_formatting(client_id)
  return M.supports(client_id, 'documentRangeFormattingProvider')
end
function M.supports_rename(client_id)
  return M.supports(client_id, 'renameProvider')
end
function M.get_server_quirks(client_id)
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then return {} end
  return SERVER_QUIRKS[client.name] or {}
end
function M.clear_cache(client_id)
  M._capabilities_cache[client_id] = nil
end
function M.clear_all_cache()
  M._capabilities_cache = {}
end
function M.get_clients_with_capability(capability_path, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local supporting_clients = {}
  for _, client in ipairs(clients) do
    if M.supports(client.id, capability_path) then
      table.insert(supporting_clients, client.id)
    end
  end
  return supporting_clients
end
function M.warn_unsupported(client_id, capability_path, feature_name)
  local client = vim.lsp.get_client_by_id(client_id)
  local client_name = client and client.name or 'unknown'
  vim.notify(
    string.format(
      '[lsp-enhanced] %s not available: server "%s" does not support %s',
      feature_name,
      client_name,
      capability_path
    ),
    vim.log.levels.WARN
  )
end
return M
