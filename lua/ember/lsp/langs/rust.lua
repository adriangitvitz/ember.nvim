local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'rust',
    callback = function()
      if not utils.lsp_available('rust-analyzer') then return end
      local root_dir = utils.find_root({ 'Cargo.toml', 'rust-project.json', '.git' })
      local settings = vim.tbl_deep_extend("force", {
        ['rust-analyzer'] = {
          cargo = {
            allFeatures = true,
            loadOutDirsFromCheck = true,
            runBuildScripts = true,
            buildScripts = { enable = true },
          },
          checkOnSave = {
            enable = true,
            allFeatures = true,
            command = 'clippy',
            extraArgs = { '--no-deps' },
          },
          procMacro = {
            enable = true,
            ignored = {
              ['async-trait'] = { 'async_trait' },
              ['napi-derive'] = { 'napi' },
              ['async-recursion'] = { 'async_recursion' },
              ['tracing'] = { 'instrument' },
            },
          },
          inlayHints = {
            bindingModeHints = { enable = true },
            chainingHints = { enable = true },
            closingBraceHints = { enable = true, minLines = 25 },
            closureReturnTypeHints = { enable = 'with_block' },
            lifetimeElisionHints = { enable = 'skip_trivial', useParameterNames = true },
            maxLength = 25,
            parameterHints = { enable = true },
            reborrowHints = { enable = 'mutable' },
            renderColons = true,
            typeHints = {
              enable = true,
              hideClosureInitialization = false,
              hideNamedConstructor = false,
            },
          },
          completion = {
            callable = { snippets = 'fill_arguments' },
            postfix = { enable = true },
            autoimport = { enable = true },
          },
          diagnostics = {
            enable = true,
            experimental = { enable = true },
          },
          imports = {
            granularity = { group = 'module' },
            prefix = 'self',
          },
          lens = {
            enable = true,
            references = { enable = true },
            implementations = { enable = true },
          },
        },
      }, config.settings or {})
      vim.lsp.start({
        name = 'rust_analyzer',
        cmd = config.cmd or { 'rust-analyzer' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        settings = settings,
      })
    end,
  })
end
return M
