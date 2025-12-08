local M = {}
function M.lsp_available(cmd)
  return vim.fn.executable(cmd) == 1
end
function M.find_root(patterns)
  local current_dir = vim.fn.expand('%:p:h')
  local root = vim.fs.find(patterns, {
    path = current_dir,
    upward = true,
  })[1]
  return root and vim.fn.fnamemodify(root, ':h') or current_dir
end
function M.start_lsp_if_available(config)
  local cmd = type(config.cmd) == 'table' and config.cmd[1] or config.cmd
  if not M.lsp_available(cmd) then
    return false
  end
  vim.lsp.start(config)
  return true
end
function M.get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    }
  }
  capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
  capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
  capabilities.textDocument.completion.completionItem.deprecatedSupport = true
  capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
  capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
  capabilities.textDocument.codeAction = {
    dynamicRegistration = false,
    codeActionLiteralSupport = {
      codeActionKind = {
        valueSet = {
          "",
          "quickfix",
          "refactor",
          "refactor.extract",
          "refactor.inline",
          "refactor.rewrite",
          "source",
          "source.organizeImports",
        },
      },
    },
  }
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }
  return capabilities
end
return M
