local M = {}
function M.setup()
  local augroup = vim.api.nvim_create_augroup
  local autocmd = vim.api.nvim_create_autocmd
  augroup("YankHighlight", { clear = true })
  autocmd("TextYankPost", {
    group = "YankHighlight",
    callback = function()
      vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
  })
  augroup("TrimWhitespace", { clear = true })
  autocmd("BufWritePre", {
    group = "TrimWhitespace",
    pattern = "*",
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      vim.cmd([[%s/\s\+$//e]])
      vim.api.nvim_win_set_cursor(0, cursor)
    end,
  })
  augroup("ResizeSplits", { clear = true })
  autocmd("VimResized", {
    group = "ResizeSplits",
    callback = function()
      vim.cmd("tabdo wincmd =")
    end,
  })
  augroup("LastPosition", { clear = true })
  autocmd("BufReadPost", {
    group = "LastPosition",
    callback = function()
      local mark = vim.api.nvim_buf_get_mark(0, '"')
      local line_count = vim.api.nvim_buf_line_count(0)
      if mark[1] > 0 and mark[1] <= line_count then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })
  vim.filetype.add({
    extension = {
      odin = "odin",
      nim = "nim",
      nims = "nim",
      nimble = "nim",
      zig = "zig",
      zon = "zig",
      cr = "crystal",
    },
    filename = {
      ["shard.yml"] = "yaml",
      ["shard.lock"] = "yaml",
      ["build.zig"] = "zig",
    },
  })
end
return M
