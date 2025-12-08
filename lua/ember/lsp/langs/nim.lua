local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'nim',
    callback = function()
      local cmd, name
      if utils.lsp_available('nimlangserver') then
        cmd = { 'nimlangserver' }
        name = 'nimlangserver'
      elseif utils.lsp_available('nimlsp') then
        cmd = { 'nimlsp' }
        name = 'nimlsp'
      else
        return
      end
      if config.cmd then
        cmd = config.cmd
      end
      local root_dir = utils.find_root({ '*.nimble', 'nim.cfg', '.git' })
      vim.lsp.start({
        name = name,
        cmd = cmd,
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        single_file_support = true,
        init_options = {
          formatting = { enable = true },
          inlayHints = {
            enable = true,
            typeHints = { enable = true },
            parameterHints = { enable = true },
          },
        },
      })
    end,
  })
end
return M
