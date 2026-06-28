return {
  "orgdown.nvim",
  name = "orgdown",
  virtual = true,
  ft = { "markdown" },
  config = function()
    require("orgdown").setup({
      modules = {
        preview = false,
        agenda = true,
        babel = true,
        folding = true,
        navigation = true,
        capture = true,
        vault = true,
      },
      agenda = {
        files = {
          "~/vault/**/*.md",
        },
        todo_keywords = {
          todo = { "TODO", "NEXT", "WAITING" },
          done = { "DONE", "CANCELLED" },
        },
        date_format = "%Y-%m-%d",
        week_start = 1,
      },
      babel = {
        confirm_execution = true,
        timeout_ms = 30000,
        results_format = "drawer",
        languages = {
          lua = { enabled = true },
          vim = { enabled = true },
          sh = { enabled = true, shell = "bash" },
          python = { enabled = true, cmd = "python3" },
          javascript = { enabled = true, cmd = "node" },
        },
      },
      folding = {
        default_state = "all_open",
      },
      navigation = {
        follow_links = true,
        create_missing = true,
      },
      capture = {
        default_file = vim.fn.expand("~/vault/inbox/inbox.md"),
        templates = {
          t = {
            name = "Todo",
            template = "- [ ] %?",
            file = vim.fn.expand("~/vault/inbox/todos.md"),
          },
          s = {
            name = "Scheduled Todo",
            template = "- [ ] %? SCHEDULED: %t",
            file = vim.fn.expand("~/vault/inbox/todos.md"),
          },
          n = {
            name = "Note",
            template = "## %?\n\n",
            file = vim.fn.expand("~/vault/inbox/notes.md"),
          },
          j = {
            name = "Journal",
            template = "## %T\n\n%?",
            file = vim.fn.expand("~/vault/inbox/journal.md"),
          },
        },
      },
      vault = {
        root = vim.fn.expand("~/vault"),
        daily = {
          enabled = true,
          date_format = "%Y-%m-%d",
          template = "templates/daily.md",
        },
        inbox = { file = "inbox/inbox.md" },
        store = { binary = "orgdown-store", path = "~/.orgdown" },
        topics = {},
      },
      keymaps = {
        preview_toggle = false,
        preview_refresh = false,
        agenda_open = false,
        agenda_day = false,
        agenda_week = false,
        agenda_todos = false,
        todo_cycle = false,
        babel_execute = false,
        babel_execute_all = false,
        babel_clear_results = false,
        next_heading = false,
        prev_heading = false,
        parent_heading = false,
        next_sibling = false,
        prev_sibling = false,
        follow_link = false,
        go_back = false,
        outline_toggle = false,
        fold_toggle = false,
        fold_all = false,
        unfold_all = false,
        capture = false,
        checkbox_toggle = false,
        vault_open = false,
        vault_daily = false,
        vault_inbox = false,
        vault_new = false,
        vault_search = false,
        vault_backlinks = false,
        vault_links = false,
        learn_start = false,
        learn_end = false,
        learn_status = false,
        learn_next = false,
      },
    })
  end,
  keys = {
    { "<leader>op", function() require("orgdown.preview").toggle() end, desc = "Preview toggle", ft = "markdown" },
    { "<leader>oP", function() require("orgdown.preview").refresh() end, desc = "Preview refresh", ft = "markdown" },
    { "<leader>oa", function() require("orgdown.agenda").open() end, desc = "Agenda" },
    { "<leader>od", function() require("orgdown.agenda").open_day() end, desc = "Agenda day" },
    { "<leader>ow", function() require("orgdown.agenda").open_week() end, desc = "Agenda week" },
    { "<leader>ot", function() require("orgdown.agenda").open_todos() end, desc = "Agenda todos" },
    { "<leader>oe", function() require("orgdown.babel").execute() end, desc = "Execute block", ft = "markdown" },
    { "<leader>oE", function() require("orgdown.babel").execute_all() end, desc = "Execute all", ft = "markdown" },
    { "<leader>oC", function() require("orgdown.babel").clear_results() end, desc = "Clear results", ft = "markdown" },
    { "<leader>oo", function() require("orgdown.navigation").toggle_outline() end, desc = "Outline", ft = "markdown" },
    { "]]", function() require("orgdown.navigation").next_heading() end, desc = "Next heading", ft = "markdown" },
    { "[[", function() require("orgdown.navigation").prev_heading() end, desc = "Prev heading", ft = "markdown" },
    { "g[", function() require("orgdown.navigation").parent_heading() end, desc = "Parent heading", ft = "markdown" },
    { "<CR>", function() require("orgdown.navigation").follow_link() end, desc = "Follow link", ft = "markdown" },
    { "<BS>", function() require("orgdown.navigation").go_back() end, desc = "Go back", ft = "markdown" },
    { "<leader>on", function() require("orgdown.capture").capture() end, desc = "Capture" },
    { "<leader>oT", function() require("orgdown.capture").capture("t") end, desc = "Capture todo" },
    { "<leader>os", function() require("orgdown.capture").capture("s") end, desc = "Capture scheduled" },
    { "<leader>oj", function() require("orgdown.capture").capture("j") end, desc = "Capture journal" },
    { "<C-Space>", function()
      local state = require("orgdown.agenda.state")
      state.toggle_checkbox()
    end, desc = "Toggle checkbox", ft = "markdown" },
    { "<leader>ov", function() require("orgdown.vault").open() end, desc = "Vault browser" },
    { "<leader>oD", function() require("orgdown.vault").daily() end, desc = "Daily note" },
    { "<leader>oi", function() require("orgdown.vault").inbox() end, desc = "Inbox" },
    { "<leader>oN", function() require("orgdown.vault").new() end, desc = "New note" },
    { "<leader>o/", function() require("orgdown.vault").search() end, desc = "Search notes" },
    { "<leader>ob", function() require("orgdown.vault").backlinks() end, desc = "Backlinks", ft = "markdown" },
    { "<leader>ol", function() require("orgdown.vault").links() end, desc = "Outgoing links", ft = "markdown" },
    { "<leader>oL", function() require("orgdown.navigation").insert_link() end, desc = "Insert link", ft = "markdown" },
    { "<leader>ols", function() require("orgdown.agenda.learning").start_interactive() end, desc = "Learn start" },
    { "<leader>ole", function() require("orgdown.agenda.learning").end_interactive() end, desc = "Learn end" },
    { "<leader>oll", function() require("orgdown.agenda.learning").show_status_window() end, desc = "Learn status" },
    { "<leader>oln", function()
      local learning = require("orgdown.agenda.learning")
      local suggestion = learning.suggest_next()
      if suggestion then
        vim.notify(suggestion.topic .. " (" .. suggestion.reason .. ")", vim.log.levels.INFO)
      end
    end, desc = "Learn next" },
  },
}
