local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'crystal',
    callback = function()
      if not utils.lsp_available('crystalline') then return end
      local root_dir = utils.find_root({ 'shard.yml', 'shard.lock', '.git' })
      vim.lsp.start({
        name = 'crystalline',
        cmd = config.cmd or { 'crystalline' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        single_file_support = true,
      })
    end,
  })
end
return M
