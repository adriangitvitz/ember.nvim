local M = {}
M.path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
function M.setup(opts)
  local config = require("ember.config").setup(opts)
  M.ensure_user_dir()
  local loader = require("ember.loader")
  loader.disable_builtins()
  if config.core.options then
    require("ember.core.options").setup()
  end
  if config.core.autocmds then
    require("ember.core.autocmds").setup()
  end
  if config.core.performance then
    require("ember.core.performance").setup()
  end
  if config.core.keymaps then
    require("ember.core.keymaps").setup()
  end
  if config.netrw.enabled then
    require("ember.core.netrw").setup()
  end
  require("ember.lsp").setup()
  loader.setup_treesitter()

  pcall(function()
    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    require("nvim-treesitter").install({
      "markdown", "markdown_inline",
      "python", "lua", "javascript", "typescript", "tsx",
      "zig", "c", "cpp", "rust", "go", "gomod", "gosum",
      "odin", "nim",
      "json", "yaml", "toml", "html", "css", "bash",
      "regex", "comment", "diff", "gitcommit", "gitignore",
      "vim", "vimdoc",
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("EmberTreesitter", { clear = true }),
      callback = function()
        if not pcall(vim.treesitter.start) then return end
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end)

  loader.load_all_bundled()
  loader.refresh()

  local themes = require("ember.themes")
  themes.setup()
  themes.load(config.ui.colorscheme)

  M.setup_plugins(config)
  require("ember.icons").setup_highlights()
  require("ember.todo").setup()
  pcall(require, "user")
end
function M.setup_plugins(config)
  pcall(function() require("slimline").setup() end)
  pcall(function() require("autopairs").setup() end)
  pcall(function()
    require("lsp-enhanced").setup({
      request = { debounce = false, cancellation = false, batching = false },
    })
  end)
  pcall(function()
    require("miniterm").setup()
    vim.keymap.set({ "n", "t" }, "<C-\\>", function()
      require("miniterm").toggle()
    end, { desc = "Toggle terminal" })
    vim.keymap.set("n", "<leader>tt", function()
      require("miniterm").toggle()
    end, { desc = "Toggle terminal" })
    vim.keymap.set("n", "<leader>th", function()
      _G._horizontal_term_toggle()
    end, { desc = "Toggle horizontal terminal" })
    vim.keymap.set("n", "<leader>tv", function()
      _G._vertical_term_toggle()
    end, { desc = "Toggle vertical terminal" })
    vim.keymap.set("n", "<leader>tg", function()
      _G._lazygit_toggle()
    end, { desc = "Toggle lazygit" })
    vim.keymap.set("n", "<leader>td", function()
      _G._lazydocker_toggle()
    end, { desc = "Toggle lazydocker" })
  end)
  pcall(function()
    require("pm").setup()
    if vim.fn.executable("pm") == 1 then
      vim.keymap.set("n", "<leader>pp", function() require("pm").projects() end, { desc = "Find projects" })
      vim.keymap.set("n", "<leader>pt", function() require("pm").tasks() end, { desc = "Find tasks" })
      vim.keymap.set("n", "<leader>pw", function() require("pm").workspaces() end, { desc = "Find workspaces" })
      vim.keymap.set("n", "<leader>pa", "<cmd>PmTaskAdd<CR>", { desc = "Add task" })
      vim.keymap.set("n", "<leader>pv", "<cmd>PmTaskView<CR>", { desc = "View task" })
      vim.keymap.set("n", "<leader>px", "<cmd>PmTaskToggle<CR>", { desc = "Toggle task status" })
      vim.keymap.set("n", "<leader>ps", "<cmd>PmTimeStart<CR>", { desc = "Start time tracking" })
      vim.keymap.set("n", "<leader>pS", "<cmd>PmTimeStop<CR>", { desc = "Stop time tracking" })
      vim.keymap.set("n", "<leader>pr", "<cmd>PmTimeReport today<CR>", { desc = "Time report (today)" })
      vim.keymap.set("n", "<leader>pR", "<cmd>PmTimeReport week<CR>", { desc = "Time report (week)" })
    end
  end)
  pcall(function() require("pyeval").setup() end)
  pcall(function() require("quicksearch").setup() end)
  pcall(function()
    require("notelinks").setup()
    local ui = require("notelinks.ui")
    vim.keymap.set("n", "<leader>nf", ui.find_notes, { desc = "Find notes" })
    vim.keymap.set("n", "<leader>ns", ui.search_notes, { desc = "Search notes" })
    vim.keymap.set("n", "<leader>nb", ui.show_backlinks, { desc = "Show backlinks" })
    vim.keymap.set("n", "<leader>nl", ui.select_note_to_link, { desc = "Link to note" })
    vim.keymap.set("n", "<leader>nc", ui.create_note_with_template, { desc = "Create note" })
  end)
  pcall(function()
    local orgdown_spec = require("ember.plugins.tools.orgdown")
    if orgdown_spec.config then
      orgdown_spec.config()
    end
    if orgdown_spec.keys then
      for _, keymap in ipairs(orgdown_spec.keys) do
        local lhs = keymap[1]
        local rhs = keymap[2]
        local opts = { desc = keymap.desc }
        if keymap.ft then
          vim.api.nvim_create_autocmd("FileType", {
            pattern = keymap.ft,
            callback = function()
              vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { buffer = true }))
            end,
          })
        else
          vim.keymap.set("n", lhs, rhs, opts)
        end
      end
    end
  end)
  pcall(function()
    require("render-markdown").setup({
      heading = { sign = false },
      checkbox = {
        unchecked = { icon = "[ ]" },
        checked = { icon = "[x]" },
      },
      file_types = { "markdown", "Avante" },
    })
  end)
  pcall(function() require("kb").setup() end)
  pcall(function() require("picker").setup() end)
  pcall(function() require("gitsigns").setup() end)
  pcall(function() require("git-extras").setup() end)
  pcall(function() require("format").setup() end)
  pcall(function() require("which-key").setup() end)
  pcall(function() require("bookmarks").setup() end)
  pcall(function()
    local bento = require("bento")
    local compat = require("bento.ember-compat")

    bento.setup({
      main_keymap = ";",
      lock_char = "",
      ordering_metric = nil,
      ui = {
        mode = "tabline",
        tabline = {
          left_page_symbol = "<",
          right_page_symbol = ">",
          separator_symbol = "|",
        },
      },
    })

    compat.setup()

    vim.keymap.set("n", ";", "<Cmd>lua require('bento.ui').handle_main_keymap()<CR>",
      { desc = "Buffer manager" })

    vim.keymap.set("n", "<Tab>", compat.next_buffer, { desc = "Next buffer" })
    vim.keymap.set("n", "<S-Tab>", compat.prev_buffer, { desc = "Previous buffer" })
    vim.keymap.set("n", "[b", compat.prev_buffer, { desc = "Previous buffer" })
    vim.keymap.set("n", "]b", compat.next_buffer, { desc = "Next buffer" })
    vim.keymap.set("n", "<leader>bp", function() bento.toggle_lock() end,
      { desc = "Pin/unpin buffer" })
    vim.keymap.set("n", "<leader>bc", function()
      vim.api.nvim_buf_delete(0, { force = false })
    end, { desc = "Close buffer" })
    vim.keymap.set("n", "<leader>bd", function()
      vim.api.nvim_buf_delete(0, { force = false })
    end, { desc = "Close buffer" })
    vim.keymap.set("n", "<leader>bo", compat.close_other_buffers,
      { desc = "Close other buffers" })
    vim.keymap.set("n", "<leader>br", compat.restore_buffer,
      { desc = "Restore closed buffer" })
    vim.keymap.set("n", "<A-,>", function()
      compat.move_buffer(vim.api.nvim_get_current_buf(), -1)
    end, { desc = "Move buffer left" })
    vim.keymap.set("n", "<A-.>", function()
      compat.move_buffer(vim.api.nvim_get_current_buf(), 1)
    end, { desc = "Move buffer right" })

    for i = 1, 9 do
      vim.keymap.set("n", "<leader>" .. i, function()
        compat.goto_buffer(i)
      end, { desc = "Go to buffer " .. i })
    end
  end)
  pcall(function()
    require("searchr").setup({
      keymaps = {
        open = "<leader>sr",
        open_word = "<leader>sw",
      },
    })
  end)
  pcall(function()
    local telescope_dir = vim.fn.stdpath("config") .. "/lua/plugins/telescope.nvim"
    if not vim.uv.fs_stat(telescope_dir) then
      return
    end
    local spec = require("ember.plugins.tools.leetcode")
    if spec.config then spec.config() end
    if spec.keys then
      for _, k in ipairs(spec.keys) do
        vim.keymap.set("n", k[1], k[2], { desc = k.desc })
      end
    end
  end)
end
function M.ensure_user_dir()
  local config_path = vim.fn.stdpath("config")
  local user_dir = config_path .. "/lua/user"
  local template_dir = M.path .. "/.user-template"
  if M.path ~= config_path then
    return
  end
  if not vim.uv.fs_stat(user_dir) then
    if vim.uv.fs_stat(template_dir) then
      vim.fn.system({ "cp", "-r", template_dir, user_dir })
      vim.notify("ember.nvim: Created lua/user/ directory for customization", vim.log.levels.INFO)
    else
      vim.fn.mkdir(user_dir .. "/plugins", "p")
      local f = io.open(user_dir .. "/init.lua", "w")
      if f then
        f:write("-- User customizations\nreturn {}\n")
        f:close()
      end
      f = io.open(user_dir .. "/config.lua", "w")
      if f then
        f:write("-- User configuration overrides\nreturn {}\n")
        f:close()
      end
    end
  end
end
return M
