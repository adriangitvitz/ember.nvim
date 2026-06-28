local M = {}
function M.attach(bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
  vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Go to references" }))
  vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))
  vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
  vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
  vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
  vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
  vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
  vim.keymap.set("n", "gl", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))
  vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))
  vim.keymap.set("n", "<leader>dq", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Diagnostics to loclist" }))
  vim.keymap.set("n", "[e", function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
  end, vim.tbl_extend("force", opts, { desc = "Previous error" }))
  vim.keymap.set("n", "]e", function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
  end, vim.tbl_extend("force", opts, { desc = "Next error" }))
  vim.keymap.set("n", "<leader>de", function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
  end, vim.tbl_extend("force", opts, { desc = "Go to first error" }))
  local function trigger_completion() vim.lsp.completion.get() end
  for _, lhs in ipairs({ "<C-l>", "<C-Space>", "<C-@>", "<Nul>" }) do
    vim.keymap.set("i", lhs, trigger_completion,
      vim.tbl_extend("force", opts, { desc = "Trigger LSP completion (" .. lhs .. ")" }))
  end
end
return M
