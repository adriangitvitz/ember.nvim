return {
  "lsp-enhanced.nvim",
  name = "lsp-enhanced",
  virtual = true,
  event = "LspAttach",
  config = function()
    require("lsp-enhanced").setup({
      completion = {
        enabled = true,
        ranking = true,
        filtering = true,
        deduplicate = true,
        debounce_ms = 50,
        max_items = 100,
      },
      diagnostics = {
        enabled = true,
        virtual_text = true,
        signs = {
          error = "✘",
          warn = "▲",
          hint = "⚑",
          info = "»",
        },
      },
      hover = {
        enabled = true,
        border = "rounded",
        max_width = 80,
        max_height = 20,
        focusable = true,
        syntax_highlighting = true,
      },
      request = { debounce = false, cancellation = false, batching = false },
    })
  end,
}
