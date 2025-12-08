local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'go', 'gomod', 'gowork', 'gotmpl' },
    callback = function()
      if not utils.lsp_available('gopls') then return end
      local root_dir = utils.find_root({ 'go.work', 'go.mod', '.git' })
      local settings = vim.tbl_deep_extend("force", {
        gopls = {
          gofumpt = true,
          staticcheck = true,
          vulncheck = 'Imports',
          analyses = {
            unusedparams = true,
            unusedwrite = true,
            unusedvariable = true,
            useany = true,
            nilness = true,
            shadow = true,
          },
          usePlaceholders = true,
          completeUnimported = true,
          completionDocumentation = true,
          deepCompletion = true,
          matcher = 'Fuzzy',
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
          codelenses = {
            gc_details = false,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
          },
          semanticTokens = true,
        },
      }, config.settings or {})
      vim.lsp.start({
        name = 'gopls',
        cmd = config.cmd or { 'gopls' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        settings = settings,
      })
    end,
  })
end
return M
