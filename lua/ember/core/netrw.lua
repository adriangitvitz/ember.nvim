local M = {}
function M.setup()
  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 1
  vim.g.netrw_browse_split = 0
  vim.g.netrw_winsize = 25
  vim.g.netrw_keepdir = 0
  vim.g.netrw_localcopydircmd = 'cp -r'
  vim.g.netrw_sizestyle = "H"
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'netrw',
    callback = function()
      local opts = { buffer = true, silent = true }
      vim.keymap.set('n', 'h', '-', opts)
      vim.keymap.set('n', 'l', '<CR>', opts)
      vim.keymap.set('n', '.', 'gh', opts)
      vim.keymap.set('n', 'q', ':bd<CR>', opts)
      vim.keymap.set('n', 'a', '%', opts)
      vim.keymap.set('n', 'd', function()
        local dir_name = vim.fn.input("Directory name: ")
        if dir_name ~= "" then
          vim.fn.mkdir(vim.fn.getcwd() .. "/" .. dir_name, "p")
          vim.cmd('edit ' .. vim.fn.getcwd())
        end
      end, { buffer = true, desc = "Create directory" })
      vim.keymap.set('n', 'r', 'R', opts)
      vim.keymap.set('n', 'D', function()
        local file = vim.fn.expand("<cfile>")
        if file ~= "" then
          local confirm = vim.fn.input("Delete " .. file .. "? (y/n): ")
          if confirm:lower() == "y" then
            local full_path = vim.fn.getcwd() .. "/" .. file
            if vim.fn.isdirectory(full_path) == 1 then
              vim.fn.delete(full_path, "rf")
            else
              vim.fn.delete(full_path)
            end
            vim.cmd('edit ' .. vim.fn.getcwd())
          end
        end
      end, { buffer = true, desc = "Delete file/directory" })
      vim.keymap.set('n', 'c', 'mc', opts)
      vim.keymap.set('n', 'x', 'mx', opts)
    end,
  })
  vim.keymap.set('n', '-', ':Explore<CR>', { desc = 'Open parent directory', silent = true })
  vim.keymap.set('n', '<leader>e', ':Explore<CR>', { desc = 'Open file explorer', silent = true })
  vim.keymap.set('n', '<leader>E', ':Lexplore<CR>', { desc = 'Open file explorer (side)', silent = true })
end
return M
