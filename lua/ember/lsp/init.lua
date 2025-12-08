local M = {}
local utils = require("ember.lsp.utils")
function M.on_attach(client, bufnr)
  local config = require("ember.config")
  if config.lsp.keymaps.enabled then
    require("ember.lsp.keymaps").attach(bufnr)
  end
end
function M.setup()
  local config = require("ember.config")
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
    vim.lsp.handlers.hover, { border = config.ui.border }
  )
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
    vim.lsp.handlers.signature_help, { border = config.ui.border }
  )
  vim.diagnostic.config({
    float = { border = config.ui.border },
    virtual_text = config.lsp.handlers.diagnostic.virtual_text,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✘",
        [vim.diagnostic.severity.WARN] = "▲",
        [vim.diagnostic.severity.HINT] = "⚑",
        [vim.diagnostic.severity.INFO] = "»",
      },
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  })
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
      M.on_attach(vim.lsp.get_client_by_id(ev.data.client_id), ev.buf)
    end,
  })
  require("ember.lsp.langs").setup()
end
M.utils = utils
return M
