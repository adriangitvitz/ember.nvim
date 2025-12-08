local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'python',
    callback = function()
      if not utils.lsp_available('pyright-langserver') then return end
      local root_dir = utils.find_root({
        'pyproject.toml', 'setup.py', 'setup.cfg',
        'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git'
      })
      local settings = vim.tbl_deep_extend("force", {
        python = {
          analysis = {
            typeCheckingMode = "standard",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = "openFilesOnly",
            autoImportCompletions = true,
            inlayHints = {
              variableTypes = true,
              functionReturnTypes = true,
              parameterTypes = true,
            },
          },
        }
      }, config.settings or {})
      vim.lsp.start({
        name = 'pyright',
        cmd = config.cmd or { 'pyright-langserver', '--stdio' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        settings = settings,
        on_init = function(client)
          local venv = os.getenv('VIRTUAL_ENV')
          if venv then
            client.config.settings.python.pythonPath = venv .. '/bin/python'
          end
        end,
      })
    end,
  })
end
return M
