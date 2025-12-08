return {
  "midnight-ember",
  name = "midnight-ember",
  priority = 1000,
  lazy = false,
  dir = require("ember").path,
  config = function()
    vim.cmd.colorscheme("midnight-ember")
  end,
}
