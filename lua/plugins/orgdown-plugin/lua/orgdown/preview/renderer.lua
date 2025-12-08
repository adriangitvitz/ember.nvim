local M = {}
local headings = require("orgdown.preview.elements.headings")
local lists = require("orgdown.preview.elements.lists")
local code = require("orgdown.preview.elements.code")
local tables = require("orgdown.preview.elements.tables")
local links = require("orgdown.preview.elements.links")
local blockquotes = require("orgdown.preview.elements.blockquotes")
local hr = require("orgdown.preview.elements.hr")
local images = require("orgdown.preview.elements.images")
local ns_name = "orgdown_preview"
local ns_id = nil
local function get_namespace()
  if not ns_id then
    ns_id = vim.api.nvim_create_namespace(ns_name)
  end
  return ns_id
end
local function apply_extmarks(bufnr, extmarks)
  local ns = get_namespace()
  for _, ext in ipairs(extmarks) do
    local line = ext.line
    local col = ext.col or 0
    local opts = ext.opts or {}
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if line >= line_count then
      goto continue
    end
    local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""
    col = math.min(col, #line_content)
    if opts.end_col then
      opts.end_col = math.min(opts.end_col, #line_content)
    end
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, line, col, opts)
    ::continue::
  end
end
local function render_line(line, line_nr, state)
  local extmarks = {}
  if state.in_code_block then
    if code.is_fence_end(line) then
      state.in_code_block = false
      state.code_language = nil
      return "", {}, state
    end
    local rendered, line_extmarks = code.render_code_line(line, line_nr, state.code_language)
    return rendered, line_extmarks, state
  end
  local is_fence, lang = code.is_fence_start(line)
  if is_fence then
    state.in_code_block = true
    state.code_language = lang
    local label = lang and ("─── " .. lang .. " ") or "─── code "
    local rendered = label .. string.rep("─", 40 - #label)
    local line_extmarks = {
      {
        line = line_nr,
        col = 0,
        opts = {
          end_col = #rendered,
          hl_group = "OrgdownCodeBlock",
        },
      },
    }
    return rendered, line_extmarks, state
  end
  if headings.is_heading(line) then
    local rendered, line_extmarks = headings.render(line, line_nr)
    return rendered, line_extmarks, state
  end
  if hr.is_hr(line) then
    local rendered, line_extmarks = hr.render(line, line_nr, 60)
    return rendered, line_extmarks, state
  end
  if blockquotes.is_blockquote(line) then
    local rendered, line_extmarks = blockquotes.render(line, line_nr)
    return rendered, line_extmarks, state
  end
  if lists.is_unordered(line) or lists.is_ordered(line) then
    local rendered, line_extmarks = lists.render(line, line_nr)
    if links.has_link(rendered) then
      local link_rendered, link_extmarks = links.render(rendered, line_nr)
      rendered = link_rendered
      for _, ext in ipairs(link_extmarks) do
        table.insert(line_extmarks, ext)
      end
    end
    return rendered, line_extmarks, state
  end
  local rendered = line
  if images.has_image(rendered) then
    local img_rendered, img_extmarks = images.render(rendered, line_nr)
    rendered = img_rendered
    for _, ext in ipairs(img_extmarks) do
      table.insert(extmarks, ext)
    end
  end
  if links.has_link(rendered) then
    local link_rendered, link_extmarks = links.render(rendered, line_nr)
    rendered = link_rendered
    for _, ext in ipairs(link_extmarks) do
      table.insert(extmarks, ext)
    end
  end
  if code.has_inline_code(rendered) then
    local code_rendered, code_extmarks = code.render_inline(rendered, line_nr)
    rendered = code_rendered
    for _, ext in ipairs(code_extmarks) do
      table.insert(extmarks, ext)
    end
  end
  return rendered, extmarks, state
end
function M.render(source_bufnr, target_bufnr)
  local source_lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
  local state = {
    in_code_block = false,
    code_language = nil,
    in_table = false,
  }
  local rendered_lines = {}
  local all_extmarks = {}
  local line_map = {}
  local preview_line = 1
  local i = 1
  while i <= #source_lines do
    local line = source_lines[i]
    line_map[i] = preview_line
    if not state.in_code_block and tables.is_table_row(line) then
      local table_lines, table_extmarks, end_line = tables.render_table(source_lines, i - 1)
      for _, tl in ipairs(table_lines) do
        table.insert(rendered_lines, tl)
        preview_line = preview_line + 1
      end
      for _, ext in ipairs(table_extmarks) do
        ext.line = ext.line + #rendered_lines - #table_lines
        table.insert(all_extmarks, ext)
      end
      i = end_line + 2
      goto continue
    end
    local rendered, extmarks, new_state = render_line(line, preview_line - 1, state)
    state = new_state
    table.insert(rendered_lines, rendered)
    for _, ext in ipairs(extmarks) do
      table.insert(all_extmarks, ext)
    end
    preview_line = preview_line + 1
    i = i + 1
    ::continue::
  end
  local ns = get_namespace()
  vim.api.nvim_buf_clear_namespace(target_bufnr, ns, 0, -1)
  local was_modifiable = vim.api.nvim_buf_get_option(target_bufnr, "modifiable")
  vim.api.nvim_buf_set_option(target_bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(target_bufnr, 0, -1, false, rendered_lines)
  apply_extmarks(target_bufnr, all_extmarks)
  vim.api.nvim_buf_set_option(target_bufnr, "modifiable", was_modifiable)
  vim.b[target_bufnr].orgdown_line_map = line_map
  return line_map
end
function M.clear(bufnr)
  local ns = get_namespace()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end
function M.get_namespace()
  return get_namespace()
end
return M
