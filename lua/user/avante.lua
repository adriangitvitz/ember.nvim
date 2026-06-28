require("avante_lib").load()

local models = require("user.avante_models")

require("avante").setup({
  provider = "openrouter",
  auto_suggestions_provider = nil,
  mode = "agentic",

  providers = {
    openrouter = {
      __inherited_from = "openai",
      endpoint = "https://openrouter.ai/api/v1",
      model = "anthropic/claude-sonnet-4.5",
      api_key_name = "OPENROUTER_API_KEY",
      timeout = 30000,
      model_names = models.read("openrouter"),
      extra_request_body = {
        temperature = 0.2,
        max_completion_tokens = 16384,
      },
    },

    lmstudio = {
      __inherited_from = "openai",
      endpoint = "http://localhost:1234/v1",
      model = "qwen2.5-coder-14b-instruct",
      api_key_name = "",
      timeout = 60000,
      disable_tools = true,
      model_names = models.read("lmstudio"),
      extra_request_body = {
        temperature = 0.2,
        max_tokens = 8192,
      },
    },

    mlx = {
      __inherited_from = "openai",
      endpoint = "http://localhost:8080/v1",
      model = "mlx-community/Qwen2.5-Coder-32B-Instruct-4bit",
      api_key_name = "",
      timeout = 60000,
      disable_tools = true,
      model_names = models.read("mlx"),
      extra_request_body = {
        temperature = 0.2,
        max_tokens = 8192,
      },
    },
  },

  behaviour = {
    auto_suggestions = false,
    auto_set_keymaps = true,
    auto_apply_diff_after_generation = false,
    minimize_diff = true,
  },

  windows = {
    position = "right",
    width = 35,
    sidebar_header = { enabled = true, align = "center" },
  },

  hints = { enabled = true },

  selector = {
    provider = function(selector)
      local ok, fzf = pcall(require, "picker.fzf")
      if not ok then
        vim.notify("avante selector: picker.fzf not available", vim.log.levels.ERROR)
        return
      end

      local titles = {}
      local id_by_title = {}
      for _, item in ipairs(selector.items or {}) do
        table.insert(titles, item.title)
        id_by_title[item.title] = item.id
      end

      if selector.default_item_id then
        for i, t in ipairs(titles) do
          if id_by_title[t] == selector.default_item_id then
            table.remove(titles, i)
            table.insert(titles, 1, t)
            break
          end
        end
      end

      fzf.run({
        items = titles,
        prompt = selector.title or "Select",
        on_select = function(line)
          if not line or line == "" then return end
          local id = id_by_title[line] or line
          if selector.on_select then selector.on_select({ id }) end
        end,
      })
    end,
  },
})

pcall(function()
  require("which-key").register({
    ["<leader>a"] = { name = "+avante" },
  })
end)

local function pick_and_refresh()
  local ok, fzf = pcall(require, "picker.fzf")
  if not ok then
    models.refresh()
    return
  end
  local options = vim.list_extend({ "all" }, models.providers())
  fzf.run({
    items = options,
    prompt = "Refresh which provider?",
    on_select = function(choice)
      if not choice or choice == "" then return end
      models.refresh(choice == "all" and nil or choice)
    end,
  })
end

vim.api.nvim_create_user_command("AvanteRefreshModels", function(opts)
  local arg = vim.trim(opts.args or "")
  if arg ~= "" then
    models.refresh(arg)
  else
    pick_and_refresh()
  end
end, {
  nargs = "?",
  complete = function() return models.providers() end,
  desc = "Refresh cached model lists for avante providers (openrouter|lmstudio|mlx)",
})

vim.keymap.set("n", "<leader>aM", function() pick_and_refresh() end,
  { desc = "Avante: refresh model catalog" })

local function ask_with_selection(opts)
  local s_line = vim.fn.line("v")
  local e_line = vim.fn.line(".")
  local s_col  = vim.fn.col("v")
  local e_col  = vim.fn.col(".")
  if s_line > e_line or (s_line == e_line and s_col > e_col) then
    s_line, e_line, s_col, e_col = e_line, s_line, e_col, s_col
  end
  local lines = vim.api.nvim_buf_get_lines(0, s_line - 1, e_line, false)
  local content = table.concat(lines, "\n")
  local filepath = vim.api.nvim_buf_get_name(0)
  local filetype = vim.bo.filetype

  local Range = require("avante.range")
  local SelectionResult = require("avante.selection_result")
  local range = Range:new(
    { lnum = s_line, col = s_col },
    { lnum = e_line, col = e_col }
  )
  local selection = SelectionResult:new(filepath, filetype, content, range)

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  vim.schedule(function()
    require("avante.api").ask(vim.tbl_extend("force", { selection = selection }, opts or {}))
  end)
end

vim.keymap.set({ "v", "x" }, "<leader>aa", function() ask_with_selection() end,
  { desc = "Avante: ask with visual selection" })
vim.keymap.set({ "v", "x" }, "<leader>ae", function()
  local line1 = vim.fn.line("v")
  local line2 = vim.fn.line(".")
  if line1 > line2 then line1, line2 = line2, line1 end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  vim.schedule(function() require("avante.api").edit(nil, line1, line2) end)
end, { desc = "Avante: edit visual selection" })
