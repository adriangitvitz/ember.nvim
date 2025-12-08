local M = {}
local utils = require("ember.lsp.utils")
function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
    callback = function()
      if not utils.lsp_available('clangd') then return end
      local root_dir = utils.find_root({
        '.clangd', '.clang-tidy', '.clang-format',
        'compile_commands.json', 'compile_flags.txt',
        'configure.ac', 'Makefile', 'CMakeLists.txt', '.git'
      })
      local cmd = config.cmd or {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders',
        '--fallback-style=llvm',
        '--all-scopes-completion',
        '--pch-storage=memory',
        '-j=4',
        '--log=error',
      }
      local capabilities = utils.get_capabilities()
      capabilities.offsetEncoding = { 'utf-16' }
      vim.lsp.start({
        name = 'clangd',
        cmd = cmd,
        root_dir = root_dir,
        capabilities = capabilities,
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
          semanticHighlighting = true,
        },
        on_attach = function(client, bufnr)
          vim.keymap.set('n', '<leader>cs', function()
            local params = { uri = vim.uri_from_bufnr(bufnr) }
            vim.lsp.buf_request(bufnr, 'textDocument/switchSourceHeader', params, function(err, result)
              if result then
                vim.cmd('edit ' .. vim.uri_to_fname(result))
              end
            end)
          end, { buffer = bufnr, desc = 'Switch source/header' })
        end,
      })
    end,
  })
end
return M
