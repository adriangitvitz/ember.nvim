return {
  "emberline.nvim",
  name = "emberline",
  virtual = true,
  event = "VeryLazy",
  config = function()
    local emberline = require("emberline")

    emberline.setup({
      icons = {
        filetype = false,
        modified = "[+]",
        pinned = "",
        close = "×",
      },
      separator = {
        left = "▎",
        right = "",
      },
      max_name_length = 25,
      padding = 1,
      clickable = true,
      focus_on_close = "left",
      sidebar_filetypes = { "NvimTree", "neo-tree", "undotree", "netrw" },
    })

    -- Keymaps
    local map = vim.keymap.set

    -- Buffer navigation
    map("n", "[b", emberline.prev_buffer, { desc = "Previous buffer" })
    map("n", "]b", emberline.next_buffer, { desc = "Next buffer" })

    -- Jump to buffer by position (1-9)
    for i = 1, 9 do
      map("n", "<leader>" .. i, function()
        emberline.goto_buffer(i)
      end, { desc = "Go to buffer " .. i })
    end

    -- Buffer actions
    map("n", "<leader>bp", emberline.toggle_pin, { desc = "Pin/unpin buffer" })
    map("n", "<leader>bc", emberline.close_buffer, { desc = "Close buffer" })
    map("n", "<leader>bo", emberline.close_other_buffers, { desc = "Close other buffers" })
    map("n", "<leader>br", emberline.restore_buffer, { desc = "Restore closed buffer" })
    map("n", "<leader>bj", emberline.pick_buffer, { desc = "Jump to buffer (pick)" })

    -- Move buffers
    map("n", "<A-,>", emberline.move_buffer_left, { desc = "Move buffer left" })
    map("n", "<A-.>", emberline.move_buffer_right, { desc = "Move buffer right" })
  end,
}
