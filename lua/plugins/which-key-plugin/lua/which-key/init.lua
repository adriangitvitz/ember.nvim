local M = {}
M.config = {
  delay = 150,
  max_height = 10,
  border = "rounded",
  layout = "horizontal",
  columns = 4,
  icons = {
    separator = "→",
    group = "+",
  },
}
M.groups = {}
local ns = vim.api.nvim_create_namespace("which_key")
local state = {
  active = false,
  win = nil,
  buf = nil,
  timer = nil,
  trigger_suspended = false,
}
function M.register(mappings, opts)
  opts = opts or {}
  local prefix = opts.prefix or ""
  for key, mapping in pairs(mappings) do
    local full_key = prefix .. key
    if type(mapping) == "string" then
      M.groups[full_key] = { desc = mapping }
    elseif type(mapping) == "table" then
      if mapping.name or mapping[1] then
        M.groups[full_key] = {
          desc = mapping.name or mapping[2] or mapping.desc,
          group = mapping.name ~= nil,
        }
      end
      if mapping.name then
        for k, v in pairs(mapping) do
          if k ~= "name" and type(k) == "string" then
            M.register({ [k] = v }, { prefix = full_key })
          end
        end
      end
    end
  end
end
local function normalize_lhs(lhs)
  local leader = vim.g.mapleader or "\\"
  lhs = lhs:gsub("<[Ll]eader>", leader)
  lhs = lhs:gsub("<[Ss]pace>", " ")
  return lhs
end
local function close_popup()
  if state.timer then
    pcall(vim.fn.timer_stop, state.timer)
    state.timer = nil
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
    state.win = nil
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
    state.buf = nil
  end
end
local function cleanup()
  close_popup()
  state.active = false
end
local function suspend_trigger()
  if state.trigger_suspended then return end
  state.trigger_suspended = true
  local leader = vim.g.mapleader or "\\"
  pcall(vim.keymap.del, "n", leader)
  pcall(vim.keymap.del, "v", leader)
end
local function resume_trigger()
  if not state.trigger_suspended then return end
  local leader = vim.g.mapleader or "\\"
  vim.keymap.set("n", leader, function()
    M.start(leader)
  end, { nowait = true, desc = "which-key" })
  vim.keymap.set("v", leader, function()
    M.start(leader)
  end, { nowait = true, desc = "which-key" })
  state.trigger_suspended = false
end
local function get_children(prefix, mode)
  mode = mode or "n"
  local children = {}
  local seen = {}
  local keymaps = vim.api.nvim_get_keymap(mode)
  local buf_keymaps = vim.api.nvim_buf_get_keymap(0, mode)
  for _, km in ipairs(buf_keymaps) do
    table.insert(keymaps, km)
  end
  for _, km in ipairs(keymaps) do
    if km.desc and km.desc:match("which%-key") then
      goto continue
    end
    local lhs = normalize_lhs(km.lhs)
    if #lhs > #prefix and lhs:sub(1, #prefix) == prefix then
      local next_char = lhs:sub(#prefix + 1, #prefix + 1)
      if not seen[next_char] then
        seen[next_char] = true
        local has_more = #lhs > #prefix + 1
        local desc = nil
        local group_key = prefix .. next_char
        if M.groups[group_key] then
          desc = M.groups[group_key].desc
        elseif not has_more and km.desc then
          desc = km.desc
        end
        table.insert(children, {
          key = next_char,
          desc = desc or (has_more and "group" or "?"),
          group = has_more,
        })
      elseif #lhs > #prefix + 1 then
        for _, child in ipairs(children) do
          if child.key == next_char then
            child.group = true
            break
          end
        end
      end
    end
    ::continue::
  end
  table.sort(children, function(a, b)
    if a.group ~= b.group then return a.group end
    return a.key < b.key
  end)
  return children
end
local function show_popup(prefix, children)
  close_popup()
  if #children == 0 then return false end
  local items = {}
  for _, child in ipairs(children) do
    local key_display = child.key
    if key_display == " " then key_display = "SPC"
    elseif key_display == "\t" then key_display = "TAB" end
    local icon = child.group and M.config.icons.group or M.config.icons.separator
    table.insert(items, {
      key = key_display,
      icon = icon,
      desc = child.desc,
      group = child.group,
    })
  end
  local num_cols = M.config.columns
  local col_width = math.floor((vim.o.columns - 4) / num_cols)
  local num_rows = math.ceil(#items / num_cols)
  local lines = {}
  local highlights = {}
  for row = 1, num_rows do
    local line_parts = {}
    local row_highlights = {}
    local col_offset = 0
    for col = 1, num_cols do
      local idx = (col - 1) * num_rows + row
      if idx <= #items then
        local item = items[idx]
        local entry = string.format("  %-3s %s %-" .. (col_width - 10) .. "s", item.key, item.icon, item.desc)
        entry = entry:sub(1, col_width)
        table.insert(line_parts, entry)
        table.insert(row_highlights, {
          col_start = col_offset + 2,
          key_end = col_offset + 2 + #item.key,
          desc_end = col_offset + #entry,
          group = item.group,
        })
        col_offset = col_offset + col_width
      else
        table.insert(line_parts, string.rep(" ", col_width))
        col_offset = col_offset + col_width
      end
    end
    table.insert(lines, table.concat(line_parts, ""))
    table.insert(highlights, row_highlights)
  end
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  vim.bo[state.buf].bufhidden = "wipe"
  local width = vim.o.columns - 2
  local height = math.min(num_rows, M.config.max_height)
  local title = prefix
  local leader = vim.g.mapleader or "\\"
  if title:sub(1, #leader) == leader then
    title = "<leader>" .. title:sub(#leader + 1)
  end
  state.win = vim.api.nvim_open_win(state.buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = vim.o.lines - height - 3,
    col = 1,
    style = "minimal",
    border = M.config.border,
    title = " " .. title .. " ",
    title_pos = "center",
  })
  vim.wo[state.win].winhl = "Normal:WhichKeyFloat,FloatBorder:WhichKeyBorder"
  for line_idx, row_hls in ipairs(highlights) do
    for _, hl in ipairs(row_hls) do
      vim.api.nvim_buf_add_highlight(state.buf, ns, "WhichKey", line_idx - 1, hl.col_start, hl.key_end)
      vim.api.nvim_buf_add_highlight(state.buf, ns, hl.group and "WhichKeyGroup" or "WhichKeyDesc", line_idx - 1, hl.key_end, hl.desc_end)
    end
  end
  return true
end
local function find_mapping(lhs, mode)
  for _, km in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    if normalize_lhs(km.lhs) == lhs then return km end
  end
  for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do
    if normalize_lhs(km.lhs) == lhs then return km end
  end
  return nil
end
function M.start(initial_prefix)
  if state.active then
    return
  end
  local mode = vim.fn.mode()
  if mode ~= "n" and mode ~= "v" and mode ~= "x" then return end
  local map_mode = (mode == "n") and "n" or "v"
  local prefix = initial_prefix
  local leader = vim.g.mapleader or "\\"
  local children = get_children(prefix, map_mode)
  if #children == 0 then return end
  state.active = true
  state.timer = vim.fn.timer_start(M.config.delay, function()
    vim.schedule(function()
      if state.active then
        show_popup(prefix, get_children(prefix, map_mode))
        vim.cmd("redraw")
      end
    end)
  end)
  while state.active do
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or not char or char == "" then
      cleanup()
      break
    end
    local key = vim.fn.keytrans(char)
    if key == "<Esc>" then
      cleanup()
      break
    end
    if key == "<BS>" then
      if #prefix > #leader then
        prefix = prefix:sub(1, -2)
        close_popup()
        local back_children = get_children(prefix, map_mode)
        if #back_children > 0 then
          show_popup(prefix, back_children)
          vim.cmd("redraw")
        else
          cleanup()
          break
        end
      else
        cleanup()
        break
      end
    else
      local decoded = vim.api.nvim_replace_termcodes(char, true, true, true)
      local new_prefix = prefix .. decoded
      local new_children = get_children(new_prefix, map_mode)
      if #new_children > 0 then
        prefix = new_prefix
        close_popup()
        show_popup(prefix, new_children)
        vim.cmd("redraw")
      else
        cleanup()
        local mapping = find_mapping(new_prefix, map_mode)
        if mapping then
          if mapping.callback then
            vim.schedule(function()
              pcall(mapping.callback)
            end)
          else
            suspend_trigger()
            local keys = vim.api.nvim_replace_termcodes(new_prefix, true, true, true)
            vim.api.nvim_feedkeys(keys, "m", false)
            vim.defer_fn(resume_trigger, 50)
          end
        else
          vim.notify("No mapping: " .. new_prefix, vim.log.levels.WARN)
        end
        return
      end
    end
  end
  if state.active then
    cleanup()
  end
end
local function setup_highlights()
  vim.api.nvim_set_hl(0, "WhichKey", { fg = "#e9bd47", bold = true, default = true })
  vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = "#88c4a8", default = true })
  vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = "#8a8a8a", default = true })
  vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = "#c1c1c1", default = true })
  vim.api.nvim_set_hl(0, "WhichKeyFloat", { link = "NormalFloat", default = true })
  vim.api.nvim_set_hl(0, "WhichKeyBorder", { link = "FloatBorder", default = true })
end
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  setup_highlights()
  M.register({
    ["<leader>"] = {
      name = "Leader",
      b = {
        name = "Buffer/Bookmarks",
        c = "Close buffer",
        d = "Close buffer",
        j = "Jump to buffer",
        m = { name = "Bookmarks" },
        o = "Close other buffers",
        p = "Pin/unpin buffer",
        r = "Restore closed buffer",
      },
      c = { name = "Code" },
      d = { name = "Diagnostics" },
      e = { name = "Explorer" },
      f = { name = "Find/Files" },
      g = { name = "Git" },
      h = { name = "Help" },
      l = { name = "LSP" },
      n = { name = "Notes" },
      o = { name = "Orgdown" },
      p = { name = "Project/PM" },
      q = { name = "Quit/Session" },
      r = { name = "Rename" },
      s = { name = "Search" },
      t = { name = "Terminal" },
      u = { name = "UI" },
      w = { name = "Window" },
      x = { name = "Quickfix" },
      y = {
        name = "Eval",
        e = { name = "Pyeval" },
      },
    },
  })
  local leader = vim.g.mapleader or "\\"
  vim.keymap.set("n", leader, function()
    M.start(leader)
  end, { nowait = true, desc = "which-key" })
  vim.keymap.set("v", leader, function()
    M.start(leader)
  end, { nowait = true, desc = "which-key" })
  vim.api.nvim_create_user_command("WhichKey", function(args)
    local prefix = args.args ~= "" and normalize_lhs(args.args) or leader
    M.start(prefix)
  end, { nargs = "?", desc = "Show which-key popup" })
end
return M
