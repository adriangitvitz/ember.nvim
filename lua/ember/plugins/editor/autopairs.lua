return {
  "autopairs.nvim",
  name = "autopairs",
  virtual = true,
  event = "InsertEnter",
  config = function()
    require("autopairs").setup({})
  end,
}
