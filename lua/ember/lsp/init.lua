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
  vim.diagnostic.config({
    float = { border = config.ui.border },
    virtual_text = config.lsp.handlers.diagnostic.virtual_text,
    virtual_lines = { current_line = true },
    jump = {
      on_jump = function(_, _) vim.diagnostic.open_float() end,
    },
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
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      M.on_attach(client, ev.buf)
      if client and client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
      end
    end,
  })
  require("ember.lsp.langs").setup()

  vim.api.nvim_create_user_command("LspInfo", function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      vim.notify("No LSP clients attached to current buffer", vim.log.levels.INFO)
      return
    end
    local lines = { "LSP clients on this buffer:" }
    for _, c in ipairs(clients) do
      table.insert(lines, string.format("  • %s (id=%d)", c.name, c.id))
      table.insert(lines, "      root_dir: " .. (c.config.root_dir or "(nil)"))
      local py = c.config.settings and c.config.settings.python and c.config.settings.python.pythonPath
      if py then
        table.insert(lines, "      pythonPath: " .. py)
      end
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show LSP clients on current buffer" })

  vim.api.nvim_create_user_command("LspRestart", function()
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      vim.lsp.stop_client(c.id, true)
    end
    vim.defer_fn(function() vim.cmd("edit") end, 200)
  end, { desc = "Restart LSP clients on current buffer" })

end
M.utils = utils
return M
