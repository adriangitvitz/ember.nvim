local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'lua',
    callback = function()
      if not utils.lsp_available('lua-language-server') then return end
      local root_dir = utils.find_root({
        '.luarc.json', '.luarc.jsonc', '.luacheckrc',
        '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git'
      })
      local is_nvim_config = vim.fn.expand('%:p'):match('nvim') ~= nil
      local settings = vim.tbl_deep_extend("force", {
        Lua = {
          runtime = {
            version = 'LuaJIT',
            path = vim.split(package.path, ';'),
          },
          diagnostics = {
            globals = is_nvim_config and { 'vim' } or {},
            disable = { 'missing-fields' },
          },
          workspace = {
            library = is_nvim_config and vim.api.nvim_get_runtime_file('', true) or {},
            checkThirdParty = false,
            maxPreload = 2000,
            preloadFileSize = 1000,
          },
          telemetry = { enable = false },
          completion = {
            callSnippet = 'Replace',
            keywordSnippet = 'Replace',
          },
          hint = {
            enable = true,
            setType = true,
            paramType = true,
            paramName = 'All',
            semicolon = 'Disable',
            arrayIndex = 'Disable',
          },
          format = {
            enable = false,
          },
        },
      }, config.settings or {})
      vim.lsp.start({
        name = 'lua_ls',
        cmd = config.cmd or { 'lua-language-server' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        settings = settings,
      })
    end,
  })
end
return M
