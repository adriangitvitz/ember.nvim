local M = {}
function M.setup()
  local opt = vim.opt
  opt.synmaxcol = 200
  opt.redrawtime = 10000
  opt.lazyredraw = true
  opt.updatetime = 100
  opt.regexpengine = 1
  opt.termguicolors = true
  opt.syntax = "on"
  vim.cmd("filetype plugin indent on")
  vim.o.winborder = "rounded"
  if os.getenv("SSH_CONNECTION") or os.getenv("SSH_CLIENT") or os.getenv("SSH_TTY") then
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
      },
      paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
        ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
      },
    }
  end
  opt.clipboard = "unnamedplus"
  opt.number = true
  opt.relativenumber = true
  opt.signcolumn = "yes"
  opt.wrap = false
  opt.scrolloff = 8
  opt.sidescrolloff = 8
  opt.cursorline = false
  opt.ignorecase = true
  opt.smartcase = true
  opt.hlsearch = true
  opt.incsearch = true
  opt.expandtab = true
  opt.shiftwidth = 2
  opt.tabstop = 2
  opt.softtabstop = 2
  opt.smartindent = true
  opt.autoindent = true
  opt.splitbelow = true
  opt.splitright = true
  opt.backup = false
  opt.writebackup = false
  opt.swapfile = false
  opt.undofile = true
  opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
  opt.mouse = "a"
  opt.completeopt = { "menu", "menuone", "noselect" }
  opt.pumheight = 15
  opt.pumblend = 10
  opt.timeoutlen = 500
  opt.hidden = true
  opt.cmdheight = 1
  opt.showmode = false
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("EmberWindowOptions", { clear = true }),
    callback = function()
      local bt = vim.bo.buftype
      local ft = vim.bo.filetype
      if bt == "" and ft ~= "dashboard" and ft ~= "netrw" then
        vim.wo.number = true
        vim.wo.relativenumber = true
        vim.wo.signcolumn = "yes"
      end
    end,
  })
end
return M
