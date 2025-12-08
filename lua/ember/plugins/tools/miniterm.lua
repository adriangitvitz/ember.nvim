return {
  "miniterm.nvim",
  name = "miniterm",
  virtual = true,
  event = "VeryLazy",
  config = function()
    require("miniterm").setup({
      border = "rounded",
      dimensions = {
        height = 0.8,
        width = 0.8,
      },
    })
  end,
}
