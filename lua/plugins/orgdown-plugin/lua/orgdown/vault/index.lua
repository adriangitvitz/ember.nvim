local M = {}
local store = require("orgdown.vault.store")
local config = require("orgdown.config")
local function extract_title(lines)
  for _, line in ipairs(lines) do
    local title = line:match("^#%s+(.+)$")
    if title then
      return vim.trim(title)
    end
  end
  return nil
end
local function extract_tags(lines)
  local tags = {}
  local in_frontmatter = false
  for i, line in ipairs(lines) do
    if i == 1 and line == "---" then
      in_frontmatter = true
    elseif in_frontmatter then
      if line == "---" then
        in_frontmatter = false
      else
        local tag_line = line:match("^tags:%s*%[(.+)%]$")
        if tag_line then
          for tag in tag_line:gmatch("[^,%s]+") do
            table.insert(tags, tag:gsub('"', ""):gsub("'", ""))
          end
        end
      end
    end
    for tag in line:gmatch("#([%w%-_]+)") do
      if not vim.tbl_contains(tags, tag) then
        table.insert(tags, tag)
      end
    end
  end
  return tags
end
local function count_todos(lines)
  local todos = 0
  local done = 0
  for _, line in ipairs(lines) do
    if line:match("^%s*%-%s*%[%s%]") then
      todos = todos + 1
    elseif line:match("^%s*%-%s*%[[xX]%]") then
      done = done + 1
    end
    if line:match("TODO:") or line:match("TODO%s") then
      todos = todos + 1
    elseif line:match("DONE:") or line:match("DONE%s") then
      done = done + 1
    end
  end
  return todos, done
end
local function extract_links(lines)
  local links = {}
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  for _, line in ipairs(lines) do
    for path in line:gmatch("%[.-%]%((.-)%)") do
      if not path:match("^https?://") and not path:match("^#") then
        local note_id = path:gsub("%.md$", ""):gsub("^%./", "")
        if not vim.tbl_contains(links, note_id) then
          table.insert(links, note_id)
        end
      end
    end
    for note_id in line:gmatch("%[%[(.-)%]%]") do
      if not vim.tbl_contains(links, note_id) then
        table.insert(links, note_id)
      end
    end
  end
  return links
end
local function extract_topic(filepath)
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local topics_dir = vim.fn.expand(vault_root .. "/topics")
  if filepath:find(topics_dir, 1, true) then
    local relative = filepath:sub(#topics_dir + 2)
    local topic = relative:match("^([^/]+)")
    if topic then
      return topic
    end
  end
  return "general"
end
function M.path_to_id(filepath)
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  filepath = vim.fn.fnamemodify(filepath, ":p")
  if filepath:find(vault_root, 1, true) == 1 then
    local relative = filepath:sub(#vault_root + 2)
    return relative:gsub("%.md$", "")
  end
  return vim.fn.fnamemodify(filepath, ":t:r")
end
function M.id_to_path(note_id)
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  return vault_root .. "/" .. note_id .. ".md"
end
function M.index_file(filepath, callback)
  filepath = vim.fn.fnamemodify(filepath, ":p")
  local lines = vim.fn.readfile(filepath)
  if not lines then
    local err = "Could not read file: " .. filepath
    if callback then
      callback(false, err)
      return true, nil
    end
    return false, err
  end
  if #lines == 0 then
    lines = {}
  end
  local note_id = M.path_to_id(filepath)
  local title = extract_title(lines) or vim.fn.fnamemodify(filepath, ":t:r")
  local tags = extract_tags(lines)
  local todos, done = count_todos(lines)
  local topic = extract_topic(filepath)
  local links = extract_links(lines)
  local stat = vim.loop.fs_stat(filepath)
  local modified = stat and os.date("!%Y-%m-%dT%H:%M:%SZ", stat.mtime.sec) or os.date("!%Y-%m-%dT%H:%M:%SZ")
  local metadata = {
    id = note_id,
    title = title,
    path = filepath,
    topic = topic,
    tags = tags,
    todos = todos,
    done = done,
    modified = modified,
    word_count = select(2, table.concat(lines, " "):gsub("%S+", "")),
  }
  if callback then
    store.notes_put_async(note_id, metadata, function(ok, err)
      if ok then
        store.links_update(note_id, links)
      end
      callback(ok, err)
    end)
    return true, nil
  else
    local ok, err = store.notes_put(note_id, metadata)
    if ok then
      store.links_update(note_id, links)
    end
    return ok, err
  end
end
function M.index_vault(callback)
  local vault_root = vim.fn.expand(config.get("vault.root") or "~/notes")
  local files = vim.fn.globpath(vault_root, "**/*.md", false, true)
  if callback then
    local indexed = 0
    local errors = 0
    local total = #files
    local function process_next(i)
      if i > total then
        callback(indexed, errors)
        return
      end
      M.index_file(files[i], function(ok, _)
        if ok then
          indexed = indexed + 1
        else
          errors = errors + 1
        end
        vim.schedule(function()
          process_next(i + 1)
        end)
      end)
    end
    process_next(1)
  else
    local indexed = 0
    local errors = 0
    for _, file in ipairs(files) do
      local ok, _ = M.index_file(file)
      if ok then
        indexed = indexed + 1
      else
        errors = errors + 1
      end
    end
    return indexed, errors
  end
end
function M.get(note_id)
  local data, _ = store.notes_get(note_id)
  return data
end
function M.search(query)
  local results, _ = store.notes_search(query)
  return results
end
function M.find_by_topic(topic)
  local results, _ = store.notes_find("topic", topic)
  return results
end
function M.find_by_tag(tag)
  local results, _ = store.notes_find("tags", tag)
  return results
end
function M.get_backlinks(note_id)
  local backlinks, _ = store.links_to(note_id)
  return backlinks
end
function M.get_links(note_id)
  local links, _ = store.links_from(note_id)
  return links
end
return M
