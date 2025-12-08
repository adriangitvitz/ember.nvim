local M = {}
local config = require("orgdown.config")
local store = require("orgdown.vault.store")
local index = require("orgdown.vault.index")
local state = {
  initialized = false,
  auto_index_autocmd = nil,
}
function M.setup(opts)
  opts = opts or {}
  local available, version = store.is_available()
  if not available then
    vim.notify(
      "[orgdown.vault] orgdown-store not found. Install it from crystal/orgdown-store",
      vim.log.levels.WARN
    )
    return
  end
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  if vim.fn.isdirectory(vault_root) == 0 then
    vim.fn.mkdir(vault_root, "p")
  end
  local dirs = { "daily", "topics", "templates", "archive" }
  for _, dir in ipairs(dirs) do
    local path = vault_root .. "/" .. dir
    if vim.fn.isdirectory(path) == 0 then
      vim.fn.mkdir(path, "p")
    end
  end
  local topics = config.get("vault.topics") or {}
  for _, topic in ipairs(topics) do
    local path = vault_root .. "/topics/" .. topic
    if vim.fn.isdirectory(path) == 0 then
      vim.fn.mkdir(path, "p")
    end
  end
  if config.get("vault.auto_index") then
    M.setup_auto_index()
  end
  state.initialized = true
end
function M.setup_auto_index()
  if state.auto_index_autocmd then
    vim.api.nvim_del_autocmd(state.auto_index_autocmd)
  end
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  state.auto_index_autocmd = vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = { vault_root .. "/*.md", vault_root .. "/**/*.md" },
    callback = function(args)
      index.index_file(args.file, function(ok, err)
        if not ok then
          vim.notify("[orgdown.vault] Index error: " .. (err or "unknown"), vim.log.levels.DEBUG)
        end
      end)
    end,
    desc = "Auto-index vault files on save",
  })
end
function M.open(topic)
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  if topic then
    local path = vault_root .. "/topics/" .. topic
    if vim.fn.isdirectory(path) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    else
      vim.notify("[orgdown.vault] Topic not found: " .. topic, vim.log.levels.WARN)
    end
    return
  end
  local topics = config.get("vault.topics") or {}
  if #topics == 0 then
    local topics_dir = vault_root .. "/topics"
    if vim.fn.isdirectory(topics_dir) == 1 then
      local dirs = vim.fn.readdir(topics_dir, function(name)
        return vim.fn.isdirectory(topics_dir .. "/" .. name) == 1
      end)
      topics = dirs or {}
    end
  end
  if #topics == 0 then
    vim.notify("[orgdown.vault] No topics found. Create folders in " .. vault_root .. "/topics/", vim.log.levels.WARN)
    return
  end
  vim.ui.select(topics, {
    prompt = "Select topic:",
  }, function(selected)
    if selected then
      M.open(selected)
    end
  end)
end
function M.daily()
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local templates = require("orgdown.vault.templates")
  local date_format = config.get("vault.daily.date_format") or "%Y-%m-%d"
  local filename = os.date(date_format) .. ".md"
  local filepath = vault_root .. "/daily/" .. filename
  local is_new = vim.fn.filereadable(filepath) == 0
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  if is_new then
    local context = {
      title = os.date("%A, %B %d, %Y"),
      id = "daily/" .. os.date(date_format),
    }
    local template_content
    local template_path = config.get("vault.daily.template")
    if template_path then
      template_path = vim.fn.expand(vault_root .. "/" .. template_path)
      if vim.fn.filereadable(template_path) == 1 then
        template_content = templates.expand_file(template_path, context)
      end
    end
    if not template_content then
      local default_path = vault_root .. "/templates/daily.md"
      if vim.fn.filereadable(default_path) == 1 then
        template_content = templates.expand_file(default_path, context)
      end
    end
    if template_content then
      local lines = vim.split(template_content, "\n")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    else
      local default = [[# {{date_weekday}}
## Tasks
- [ ]
## Notes
]]
      local expanded = templates.expand(default, context)
      local lines = vim.split(expanded, "\n")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end
    vim.cmd("normal! 5G$")
  end
end
function M.inbox()
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local inbox_file = config.get("vault.inbox.file") or "inbox.md"
  local filepath = vault_root .. "/" .. inbox_file
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end
function M.new(opts)
  opts = opts or {}
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local templates = require("orgdown.vault.templates")
  local topic = opts.topic
  if not topic then
    local topics = config.get("vault.topics") or {}
    if #topics > 0 then
      vim.ui.select(topics, {
        prompt = "Select topic:",
      }, function(selected)
        if selected then
          opts.topic = selected
          M.new(opts)
        end
      end)
      return
    end
  end
  local title = opts.title
  if not title then
    vim.ui.input({
      prompt = "Note title: ",
    }, function(input)
      if input and input ~= "" then
        opts.title = input
        M.new(opts)
      end
    end)
    return
  end
  local filename = title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "") .. ".md"
  local filepath
  if topic then
    filepath = vault_root .. "/topics/" .. topic .. "/" .. filename
  else
    filepath = vault_root .. "/" .. filename
  end
  if vim.fn.filereadable(filepath) == 1 then
    vim.notify("[orgdown.vault] File already exists: " .. filepath, vim.log.levels.WARN)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  local context = {
    title = title,
    topic = topic or "",
    id = index.path_to_id(filepath),
  }
  local template_content
  local template_file = opts.template
  if not template_file and topic then
    local topic_template = vault_root .. "/templates/" .. topic .. ".md"
    if vim.fn.filereadable(topic_template) == 1 then
      template_file = topic_template
    end
  end
  if not template_file then
    local default_template = vault_root .. "/templates/note.md"
    if vim.fn.filereadable(default_template) == 1 then
      template_file = default_template
    end
  end
  if template_file and vim.fn.filereadable(template_file) == 1 then
    template_content = templates.expand_file(template_file, context)
  end
  if template_content then
    local lines = vim.split(template_content, "\n")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  else
    local default = "# {{title}}\n\n*Created: {{datetime}}*\n\n"
    local expanded = templates.expand(default, context)
    local lines = vim.split(expanded, "\n")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end
  vim.cmd("normal! G")
end
function M.search(query)
  if not query then
    vim.ui.input({
      prompt = "Search notes: ",
    }, function(input)
      if input and input ~= "" then
        M.search(input)
      end
    end)
    return
  end
  local results = index.search(query)
  if #results == 0 then
    vim.notify("[orgdown.vault] No notes found for: " .. query, vim.log.levels.INFO)
    return
  end
  local qf_items = {}
  for _, item in ipairs(results) do
    local data = item.data or item
    table.insert(qf_items, {
      filename = data.path,
      text = data.title or data.id,
    })
  end
  vim.fn.setqflist(qf_items)
  vim.cmd("copen")
end
function M.backlinks()
  local filepath = vim.fn.expand("%:p")
  local note_id = index.path_to_id(filepath)
  local backlinks = index.get_backlinks(note_id)
  if #backlinks == 0 then
    vim.notify("[orgdown.vault] No backlinks found", vim.log.levels.INFO)
    return
  end
  local qf_items = {}
  for _, link_id in ipairs(backlinks) do
    local data = index.get(link_id)
    if data then
      table.insert(qf_items, {
        filename = data.path,
        text = data.title or link_id,
      })
    else
      table.insert(qf_items, {
        filename = index.id_to_path(link_id),
        text = link_id,
      })
    end
  end
  vim.fn.setqflist(qf_items)
  vim.cmd("copen")
end
function M.links()
  local filepath = vim.fn.expand("%:p")
  local note_id = index.path_to_id(filepath)
  local links = index.get_links(note_id)
  if #links == 0 then
    vim.notify("[orgdown.vault] No outgoing links found", vim.log.levels.INFO)
    return
  end
  local qf_items = {}
  for _, link_id in ipairs(links) do
    local data = index.get(link_id)
    if data then
      table.insert(qf_items, {
        filename = data.path,
        text = data.title or link_id,
      })
    else
      table.insert(qf_items, {
        filename = index.id_to_path(link_id),
        text = link_id,
      })
    end
  end
  vim.fn.setqflist(qf_items)
  vim.cmd("copen")
end
function M.reindex()
  vim.notify("[orgdown.vault] Indexing vault...", vim.log.levels.INFO)
  index.index_vault(function(indexed, errors)
    vim.notify(
      string.format("[orgdown.vault] Indexed %d files (%d errors)", indexed, errors),
      vim.log.levels.INFO
    )
  end)
end
function M.health()
  local available, version = store.is_available()
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  return {
    store_available = available,
    store_version = version,
    vault_root = vault_root,
    vault_exists = vim.fn.isdirectory(vault_root) == 1,
    initialized = state.initialized,
  }
end
function M.migrate(source_dir)
  local migrate = require("orgdown.vault.migrate")
  migrate.migrate(source_dir)
end
function M.migrate_templates(source_dir)
  local migrate = require("orgdown.vault.migrate")
  migrate.migrate_templates(source_dir)
end
M.store = store
M.index = index
M.templates = require("orgdown.vault.templates")
return M
