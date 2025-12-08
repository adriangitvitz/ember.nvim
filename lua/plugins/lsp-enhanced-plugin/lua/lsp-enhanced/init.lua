local M = {}
local default_config = {
  completion = {
    enabled = true,
    ranking = true,
    filtering = true,
    cache = true,
    deduplicate = true,
    debounce_ms = 50,
    max_items = 100,
  },
  diagnostics = {
    enabled = true,
    virtual_text = {
      enabled = true,
      max_length = 50,
      prefix = '■ ',
    },
    signs = {
      enabled = true,
      error = '✘',
      warn = '▲',
      hint = '⚑',
      info = '»',
    },
    navigation = {
      enabled = true,
    },
  },
  hover = {
    enabled = true,
    border = 'rounded',
    max_width = 80,
    max_height = 20,
  },
  request = {
    debounce = true,
    cancellation = true,
    batching = false,
  },
}
M.config = {}
function M.setup(user_config)
  M.config = vim.tbl_deep_extend('force', default_config, user_config or {})
  if M.config.diagnostics.enabled then
    require('lsp-enhanced.diagnostics').setup(M.config.diagnostics)
  end
  if M.config.completion.enabled then
    require('lsp-enhanced.completion').setup(M.config.completion)
    M._setup_completion_override()
  end
  if M.config.hover.enabled then
    require('lsp-enhanced.hover').setup(M.config.hover)
    M._setup_hover_override()
  end
  if M.config.request.debounce or M.config.request.cancellation then
    M._setup_request_optimization()
  end
  local augroup = vim.api.nvim_create_augroup('LspEnhanced', { clear = true })
  vim.api.nvim_create_autocmd('BufDelete', {
    group = augroup,
    callback = function(args)
      if M.config.request.debounce then
        require('lsp-enhanced.request.debounce').clear_buffer(args.buf)
      end
      if M.config.request.cancellation then
        require('lsp-enhanced.request.cancellation').cancel_buffer_requests(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd('LspDetach', {
    group = augroup,
    callback = function(args)
      require('lsp-enhanced.capabilities').clear_cache(args.data.client_id)
    end,
  })
end
function M._setup_completion_override()
  local original_handler = vim.lsp.handlers['textDocument/completion']
  vim.lsp.handlers['textDocument/completion'] = function(err, result, ctx, config)
    if err or not result then
      return original_handler(err, result, ctx, config)
    end
    local completion = require('lsp-enhanced.completion')
    local enhanced_result = completion.process_completion_result(result)
    return original_handler(err, enhanced_result, ctx, config)
  end
end
function M._setup_request_optimization()
  local augroup = vim.api.nvim_create_augroup('LspEnhancedRequests', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then return end
      if not client._lsp_enhanced_original_request then
        client._lsp_enhanced_original_request = client.request
        client.request = function(first, second, third, fourth, fifth)
          local method, params, handler, bufnr
          if type(first) == 'string' then
            method = first
            params = second
            handler = third
            bufnr = fourth
          else
            method = second
            params = third
            handler = fourth
            bufnr = fifth
          end
          bufnr = bufnr or 0
          local should_debounce = M.config.request.debounce and (
            method == 'textDocument/completion' or
            method == 'textDocument/hover' or
            method == 'textDocument/signatureHelp'
          )
          local should_cancel = M.config.request.cancellation and (
            method == 'textDocument/completion' or
            method == 'textDocument/hover' or
            method == 'textDocument/documentSymbol' or
            method == 'textDocument/semanticTokens/full'
          )
          if should_debounce then
            local debounce = require('lsp-enhanced.request.debounce')
            return debounce.debounced_request(method, params, handler, bufnr, client.id)
          elseif should_cancel then
            local cancellation = require('lsp-enhanced.request.cancellation')
            return cancellation.tracked_request(method, params, handler, bufnr, client.id)
          else
            return client._lsp_enhanced_original_request(client, method, params, handler, bufnr)
          end
        end
      end
    end,
  })
end
function M._setup_hover_override()
  require('lsp-enhanced.hover').setup_handler_override()
end
function M.diagnostic_goto_next(opts)
  require('lsp-enhanced.diagnostics').goto_next(opts)
end
function M.diagnostic_goto_prev(opts)
  require('lsp-enhanced.diagnostics').goto_prev(opts)
end
function M.diagnostic_goto_first_error(opts)
  require('lsp-enhanced.diagnostics').goto_first_error(opts)
end
function M.diagnostic_show_float(opts)
  require('lsp-enhanced.diagnostics').show_float(opts)
end
function M.show_hover()
  require('lsp-enhanced.hover').show_hover()
end
function M.mark_completion_used(item)
  if not M.config.completion.ranking then return end
  require('lsp-enhanced.completion').mark_completion_used(item)
end
function M.get_diagnostic_counts(bufnr)
  return require('lsp-enhanced.diagnostics').get_counts(bufnr)
end
function M.get_completion_stats()
  return require('lsp-enhanced.completion').get_cache_stats()
end
function M.clear_caches()
  require('lsp-enhanced.completion').clear_caches()
end
function M.enable_all()
  if M.config.completion.enabled then
    require('lsp-enhanced.completion').enable()
  end
  if M.config.diagnostics.enabled then
    require('lsp-enhanced.diagnostics').enable()
  end
  if M.config.hover.enabled then
    require('lsp-enhanced.hover').enable()
  end
end
function M.disable_all()
  if M.config.completion.enabled then
    require('lsp-enhanced.completion').disable()
  end
  if M.config.diagnostics.enabled then
    require('lsp-enhanced.diagnostics').disable()
  end
  if M.config.hover.enabled then
    require('lsp-enhanced.hover').disable()
  end
end
function M.toggle_hover()
  require('lsp-enhanced.hover').toggle()
end
function M.toggle_completion()
  require('lsp-enhanced.completion').toggle()
end
function M.toggle_diagnostics()
  require('lsp-enhanced.diagnostics').toggle()
end
function M.version()
  return '1.0.0'
end
function M.check()
  vim.health = vim.health or require('health')
  vim.health.start('LSP Enhanced')
  if vim.fn.has('nvim-0.8.0') == 1 then
    vim.health.ok('Neovim version >= 0.8.0')
  else
    vim.health.error('Neovim version < 0.8.0', {'Upgrade to Neovim 0.8.0 or later'})
  end
  local clients = vim.lsp.get_clients()
  if #clients > 0 then
    vim.health.ok(string.format('%d LSP client(s) active', #clients))
    for _, client in ipairs(clients) do
      vim.health.info(string.format('  - %s (id: %d)', client.name, client.id))
    end
  else
    vim.health.warn('No LSP clients active')
  end
  if M.config.completion and M.config.completion.enabled then
    vim.health.ok('Completion enhancement enabled')
  end
  if M.config.diagnostics and M.config.diagnostics.enabled then
    vim.health.ok('Diagnostics enhancement enabled')
  end
  local ok, stats = pcall(M.get_completion_stats)
  if ok and stats then
    vim.health.info(string.format('Completion cache: %d/%d items',
      stats.completion_cache_size, stats.completion_cache_max))
    vim.health.info(string.format('Recency cache: %d/%d items',
      stats.recency_cache_size, stats.recency_cache_max))
  end
end
return M
