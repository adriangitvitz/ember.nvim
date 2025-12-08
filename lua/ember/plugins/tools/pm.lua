return {
  "pm.nvim",
  name = "pm",
  virtual = true,
  event = "VeryLazy",
  config = function()
    if vim.fn.executable("pm") ~= 1 then
      return
    end
    require("pm").setup({
      pm_bin = "pm",
      cache_timeout = 30,
      float = {
        border = "rounded",
        width = 0.6,
        height = 0.6,
      },
      statusline = {
        show_workspace = true,
        show_task_count = true,
        show_time_tracking = true,
      },
    })
  end,
}
