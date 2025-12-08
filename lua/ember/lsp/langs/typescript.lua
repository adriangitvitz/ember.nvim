local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    callback = function()
      if not utils.lsp_available('typescript-language-server') then return end
      local root_dir = utils.find_root({
        'tsconfig.json', 'package.json', 'jsconfig.json', '.git'
      })
      local settings = vim.tbl_deep_extend("force", {
        typescript = {
          inlayHints = {
            includeInlayParameterNameHints = 'all',
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
          },
          suggest = {
            includeCompletionsForImportStatements = true,
            autoImports = true,
          },
          updateImportsOnFileMove = { enabled = 'always' },
        },
        javascript = {
          inlayHints = {
            includeInlayParameterNameHints = 'all',
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
          },
          suggest = {
            includeCompletionsForImportStatements = true,
            autoImports = true,
          },
          updateImportsOnFileMove = { enabled = 'always' },
        },
        completions = {
          completeFunctionCalls = true,
        },
      }, config.settings or {})
      vim.lsp.start({
        name = 'ts_ls',
        cmd = config.cmd or { 'typescript-language-server', '--stdio' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        init_options = {
          hostInfo = 'neovim',
          preferences = {
            quotePreference = 'single',
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
            importModuleSpecifierPreference = 'shortest',
          },
        },
        settings = settings,
      })
    end,
  })
end
return M
