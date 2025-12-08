return {
  "slimline.nvim",
  name = "slimline",
  virtual = true,
  event = "VeryLazy",
  config = function()
    require("slimline").setup({
      bold = true,
      style = "bg",
      components = {
        left = { "mode", "git", "path" },
        center = {},
        right = { "diagnostics", "filetype_lsp", "progress" },
      },
      configs = {
        mode = {
          verbose = false,
        },
        path = {
          shorten = true,
        },
        git = {
          icons = {
            branch = " ",
          },
        },
      },
      sep = {
        left = "",
        right = "",
      },
    })
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
  end,
}
