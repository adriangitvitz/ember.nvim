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
      local function resolve_python()
        local env_venv = os.getenv('VIRTUAL_ENV')
        if env_venv and vim.uv.fs_stat(env_venv .. '/bin/python') then
          return env_venv .. '/bin/python'
        end
        if root_dir then
          for _, name in ipairs({ '.venv', 'venv' }) do
            local p = root_dir .. '/' .. name .. '/bin/python'
            if vim.uv.fs_stat(p) then return p end
          end
        end
        return nil
      end

      local python_path = resolve_python()
      if python_path then
        settings.python.pythonPath = python_path
      end

      vim.lsp.start({
        name = 'pyright',
        cmd = config.cmd or { 'pyright-langserver', '--stdio' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        settings = settings,
      })
    end,
  })
end
return M
