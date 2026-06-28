return {
  "leetcode-plugin",
  name = "leetcode",
  virtual = true,
  config = function()
    require("leetcode").setup({
      lang = "python3",
      picker = { provider = "telescope" },
      injector = {
        python3 = {
          before = { "from typing import List, Optional, Dict, Tuple" },
        },
        cpp = {
          before = { "#include <bits/stdc++.h>", "using namespace std;" },
        },
      },
      description = { position = "left", width = "40%", show_stats = true },
      console = { open_on_runcode = true, dir = "row" },
      editor = { reset_previous_code = true, fold_imports = true },
    })
  end,
  keys = {
    { "<leader>lm", "<cmd>Leet menu<CR>",        desc = "Leet menu" },
    { "<leader>ll", "<cmd>Leet list<CR>",        desc = "Leet list" },
    { "<leader>lD", "<cmd>Leet daily<CR>",       desc = "Leet daily" },
    { "<leader>lR", "<cmd>Leet random<CR>",      desc = "Leet random" },
    { "<leader>lx", "<cmd>Leet run<CR>",         desc = "Leet run (execute)" },
    { "<leader>lt", "<cmd>Leet test<CR>",        desc = "Leet test" },
    { "<leader>lu", "<cmd>Leet submit<CR>",      desc = "Leet submit" },
    { "<leader>lc", "<cmd>Leet console<CR>",     desc = "Leet console" },
    { "<leader>li", "<cmd>Leet info<CR>",        desc = "Leet info" },
    { "<leader>lL", "<cmd>Leet lang<CR>",        desc = "Leet language" },
    { "<leader>lk", "<cmd>Leet last_submit<CR>", desc = "Leet last submit" },
    { "<leader>lq", "<cmd>Leet exit<CR>",        desc = "Leet exit" },
  },
}
