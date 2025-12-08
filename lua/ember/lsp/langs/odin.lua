local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'odin',
    callback = function()
      if not utils.lsp_available('ols') then return end
      local root_dir = utils.find_root({ 'ols.json', 'odinfmt.json', '.git' })
      vim.lsp.start({
        name = 'ols',
        cmd = config.cmd or { 'ols' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        single_file_support = true,
        init_options = {
          enable_document_symbols = true,
          enable_code_lens = true,
          enable_hover = true,
          enable_semantic_tokens = true,
          enable_inlay_hints = true,
          enable_procedure_context = true,
          enable_snippets = true,
        },
      })
    end,
  })
end
return M
