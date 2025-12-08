local M = {}
local config = require("orgdown.config")
local index = require("orgdown.vault.index")
local function analyze_filename(filename)
  local base = filename:gsub("%.md$", "")
  local learning_topic = base:match("^learning%-(.+)%-(%d%d%d%d%d%d%d%d)%-(%d+)$")
  if learning_topic then
    return "learning", learning_topic:gsub("%-", "-") .. ".md"
  end
  local task_desc = base:match("^%d%d%d%d%d%d%d%d%-%d+%-task%-(.+)$")
  if task_desc then
    return "projects", task_desc:gsub("%-", "-") .. ".md"
  end
  local desc = base:match("^%d%d%d%d%d%d%d%d%-%d+%-(.+)$")
  if desc then
    local desc_lower = desc:lower()
    if desc_lower:match("learn") or desc_lower:match("study") then
      return "learning", desc:gsub("%-", "-") .. ".md"
    elseif desc_lower:match("project") or desc_lower:match("task") or desc_lower:match("kagi") or desc_lower:match("mcp") then
      return "projects", desc:gsub("%-", "-") .. ".md"
    else
      return "general", desc:gsub("%-", "-") .. ".md"
    end
  end
  if base == "inbox" then
    return "_root", "inbox.md"
  end
  if base == "todos" then
    return "_root", "todos.md"
  end
  return "general", filename
end
function M.analyze(source_dir)
  source_dir = vim.fn.expand(source_dir)
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local plan = {}
  local files = vim.fn.glob(source_dir .. "/*.md", false, true)
  for _, filepath in ipairs(files) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    local topic, new_name = analyze_filename(filename)
    local dest
    if topic == "_root" then
      dest = vault_root .. "/" .. new_name
    else
      dest = vault_root .. "/topics/" .. topic .. "/" .. new_name
    end
    local exists = vim.fn.filereadable(dest) == 1
    table.insert(plan, {
      source = filepath,
      dest = dest,
      topic = topic,
      new_name = new_name,
      exists = exists,
      reason = topic == "_root" and "Special file" or "Detected from filename pattern",
    })
  end
  return plan
end
function M.show_plan(plan)
  local lines = {
    "# Migration Plan",
    "",
    "Source -> Destination [Topic]",
    string.rep("-", 60),
  }
  for _, item in ipairs(plan) do
    local status = item.exists and "[EXISTS]" or "[NEW]"
    local source_name = vim.fn.fnamemodify(item.source, ":t")
    table.insert(lines, string.format(
      "%s %s -> %s [%s]",
      status,
      source_name,
      item.new_name,
      item.topic
    ))
  end
  table.insert(lines, "")
  table.insert(lines, string.rep("-", 60))
  table.insert(lines, string.format("Total: %d files", #plan))
  local exists_count = 0
  for _, item in ipairs(plan) do
    if item.exists then
      exists_count = exists_count + 1
    end
  end
  if exists_count > 0 then
    table.insert(lines, string.format("Warning: %d files already exist at destination", exists_count))
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
end
function M.execute(plan, opts)
  opts = opts or {}
  local skip_existing = opts.skip_existing ~= false
  local dry_run = opts.dry_run or false
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local migrated = 0
  local skipped = 0
  local errors = {}
  for _, item in ipairs(plan) do
    if item.exists and skip_existing then
      skipped = skipped + 1
      goto continue
    end
    if dry_run then
      vim.notify(string.format("[DRY RUN] Would copy: %s -> %s", item.source, item.dest), vim.log.levels.INFO)
      migrated = migrated + 1
      goto continue
    end
    local dest_dir = vim.fn.fnamemodify(item.dest, ":h")
    if vim.fn.isdirectory(dest_dir) == 0 then
      vim.fn.mkdir(dest_dir, "p")
    end
    local ok = vim.fn.writefile(vim.fn.readfile(item.source), item.dest)
    if ok == 0 then
      migrated = migrated + 1
      index.index_file(item.dest)
    else
      table.insert(errors, "Failed to copy: " .. item.source)
    end
    ::continue::
  end
  return migrated, skipped, errors
end
function M.migrate(source_dir)
  source_dir = source_dir or "~/.debug-notes"
  source_dir = vim.fn.expand(source_dir)
  if vim.fn.isdirectory(source_dir) == 0 then
    vim.notify("[orgdown.vault] Source directory not found: " .. source_dir, vim.log.levels.ERROR)
    return
  end
  local plan = M.analyze(source_dir)
  if #plan == 0 then
    vim.notify("[orgdown.vault] No markdown files found in: " .. source_dir, vim.log.levels.INFO)
    return
  end
  M.show_plan(plan)
  vim.ui.select({ "Execute migration", "Dry run", "Cancel" }, {
    prompt = "Migration action:",
  }, function(choice)
    if not choice or choice == "Cancel" then
      vim.notify("[orgdown.vault] Migration cancelled", vim.log.levels.INFO)
      return
    end
    local dry_run = choice == "Dry run"
    local migrated, skipped, errors = M.execute(plan, { dry_run = dry_run })
    if dry_run then
      vim.notify(
        string.format("[orgdown.vault] Dry run complete: %d would be migrated, %d would be skipped", migrated, skipped),
        vim.log.levels.INFO
      )
    else
      vim.notify(
        string.format("[orgdown.vault] Migration complete: %d migrated, %d skipped", migrated, skipped),
        vim.log.levels.INFO
      )
      if #errors > 0 then
        vim.notify("[orgdown.vault] Errors:\n" .. table.concat(errors, "\n"), vim.log.levels.WARN)
      end
    end
  end)
end
function M.migrate_templates(source_dir)
  source_dir = source_dir or "~/.debug-notes/.templates"
  source_dir = vim.fn.expand(source_dir)
  if vim.fn.isdirectory(source_dir) == 0 then
    vim.notify("[orgdown.vault] Templates directory not found: " .. source_dir, vim.log.levels.WARN)
    return
  end
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local templates_dir = vault_root .. "/templates"
  if vim.fn.isdirectory(templates_dir) == 0 then
    vim.fn.mkdir(templates_dir, "p")
  end
  local files = vim.fn.glob(source_dir .. "/*.md", false, true)
  local copied = 0
  for _, filepath in ipairs(files) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    local dest = templates_dir .. "/" .. filename
    if vim.fn.filereadable(dest) == 0 then
      local ok = vim.fn.writefile(vim.fn.readfile(filepath), dest)
      if ok == 0 then
        copied = copied + 1
      end
    end
  end
  vim.notify(
    string.format("[orgdown.vault] Copied %d templates to %s", copied, templates_dir),
    vim.log.levels.INFO
  )
end
return M
