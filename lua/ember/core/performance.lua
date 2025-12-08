local M = {}
function M.setup()
  local augroup = vim.api.nvim_create_augroup
  local autocmd = vim.api.nvim_create_autocmd
  vim.g.LargeFile = 1024 * 1024 * 10
  augroup("LargeFile", { clear = true })
  autocmd("BufReadPre", {
    group = "LargeFile",
    callback = function()
      local size = vim.fn.getfsize(vim.fn.expand("<afile>"))
      if size > vim.g.LargeFile or size == -2 then
        vim.bo.swapfile = false
        vim.bo.undolevels = -1
        vim.opt_local.synmaxcol = 100
        vim.opt_local.foldmethod = "manual"
        vim.opt_local.cursorline = false
        vim.notify("Large file mode enabled", vim.log.levels.INFO)
      end
    end,
  })
  autocmd("FileType", {
    pattern = "python",
    callback = function()
      vim.opt_local.synmaxcol = 120
      vim.cmd("syntax sync minlines=30 maxlines=100")
    end,
  })
  autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
      vim.cmd("syntax sync minlines=50 maxlines=100")
      vim.opt_local.synmaxcol = 200
    end,
  })
  autocmd("FileType", {
    pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    callback = function()
      vim.opt_local.synmaxcol = 80
      vim.opt_local.regexpengine = 0
      vim.cmd("syntax sync minlines=10 maxlines=30")
    end,
  })
end
return M
