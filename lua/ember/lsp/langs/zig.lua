local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'zig',
    callback = function()
      if not utils.lsp_available('zls') then return end
      local root_dir = utils.find_root({ 'build.zig', 'build.zig.zon', 'zls.json', '.git' })
      local settings = vim.tbl_deep_extend("force", {
        zls = {
          enable_semantic_tokens = true,
          enable_inlay_hints = true,
          inlay_hints_show_builtin = true,
          inlay_hints_exclude_single_argument = true,
          inlay_hints_hide_redundant_param_names = true,
          enable_autofix = true,
          enable_import_detection = true,
          enable_ast_check_diagnostics = true,
          enable_build_on_save = true,
          build_on_save_step = 'check',
          enable_snippets = true,
          operator_completions = true,
          include_at_in_builtins = true,
        },
      }, config.settings or {})
      vim.lsp.start({
        name = 'zls',
        cmd = config.cmd or { 'zls' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        settings = settings,
      })
    end,
  })
end
return M
