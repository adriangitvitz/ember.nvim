return {
  "quicksearch.nvim",
  name = "quicksearch",
  virtual = true,
  event = "VeryLazy",
  config = function()
    require("quicksearch").setup({
      search = {
        case_mode = "smart",
        use_regex = false,
        follow_symlinks = false,
      },
      quickfix = {
        auto_open = true,
        auto_focus = true,
        max_height = 15,
      },
    })
  end,
}
