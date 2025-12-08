local M = {}
function M.has_link(line)
  return line:match("%[.-%]%(.-%)") ~= nil
end
function M.find_links(line)
  local links = {}
  local pos = 1
  while true do
    local start_pos = line:find("%[", pos)
    if not start_pos then
      break
    end
    local text_end = line:find("%]", start_pos)
    if not text_end then
      break
    end
    local url_start = line:find("%(", text_end)
    if not url_start or url_start ~= text_end + 1 then
      pos = start_pos + 1
      goto continue
    end
    local url_end = line:find("%)", url_start)
    if not url_end then
      pos = start_pos + 1
      goto continue
    end
    local text = line:sub(start_pos + 1, text_end - 1)
    local url = line:sub(url_start + 1, url_end - 1)
    table.insert(links, {
      text = text,
      url = url,
      start_col = start_pos - 1,
      end_col = url_end,
      raw = line:sub(start_pos, url_end),
    })
    pos = url_end + 1
    ::continue::
  end
  return links
end
function M.render(line, line_nr)
  local links = M.find_links(line)
  if #links == 0 then
    return line, {}
  end
  local extmarks = {}
  local rendered = line
  for i = #links, 1, -1 do
    local link = links[i]
    local replacement = link.text
    table.insert(extmarks, {
      line = line_nr,
      col = link.start_col,
      opts = {
        end_col = link.start_col + #replacement,
        hl_group = "OrgdownLink",
      },
    })
    rendered = rendered:sub(1, link.start_col) .. replacement .. rendered:sub(link.end_col + 1)
  end
  return rendered, extmarks
end
function M.is_external(url)
  return url:match("^https?://") ~= nil or url:match("^mailto:") ~= nil
end
function M.is_local_file(url)
  return not M.is_external(url) and url:match("^[^#]") ~= nil
end
function M.is_anchor(url)
  return url:match("^#") ~= nil
end
function M.parse_url(url)
  local file, anchor = url:match("^(.-)#(.+)$")
  if file and anchor then
    return file ~= "" and file or nil, anchor
  end
  if url:match("^#") then
    return nil, url:sub(2)
  end
  return url, nil
end
return M
