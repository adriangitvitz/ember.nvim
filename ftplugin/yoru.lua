-- Yoru filetype settings.
-- Loaded automatically when a buffer's filetype is set to `yoru`.

vim.bo.commentstring = "// %s"
vim.bo.comments      = "s1:/*,mb:*,ex:*/,://"
vim.bo.expandtab     = true
vim.bo.shiftwidth    = 2
vim.bo.softtabstop   = 2
vim.bo.tabstop       = 2
vim.bo.autoindent    = true
vim.bo.smartindent   = true

vim.opt_local.synmaxcol = 3000
