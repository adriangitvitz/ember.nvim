local M = {}
function M.has_image(line)
  return line:match("!%[.-%]%(.-%)") ~= nil
end
function M.find_images(line)
  local images = {}
  local pos = 1
  while true do
    local start_pos = line:find("!%[", pos)
    if not start_pos then
      break
    end
    local alt_end = line:find("%]", start_pos)
    if not alt_end then
      break
    end
    local url_start = line:find("%(", alt_end)
    if not url_start or url_start ~= alt_end + 1 then
      pos = start_pos + 1
      goto continue
    end
    local url_end = line:find("%)", url_start)
    if not url_end then
      pos = start_pos + 1
      goto continue
    end
    local alt = line:sub(start_pos + 2, alt_end - 1)
    local url = line:sub(url_start + 1, url_end - 1)
    table.insert(images, {
      alt = alt,
      url = url,
      start_col = start_pos - 1,
      end_col = url_end,
      raw = line:sub(start_pos, url_end),
    })
    pos = url_end + 1
    ::continue::
  end
  return images
end
function M.render(line, line_nr)
  local images = M.find_images(line)
  if #images == 0 then
    return line, {}
  end
  local extmarks = {}
  local rendered = line
  for i = #images, 1, -1 do
    local image = images[i]
    local alt_text = image.alt ~= "" and image.alt or "image"
    local replacement = "[IMG: " .. alt_text .. "]"
    table.insert(extmarks, {
      line = line_nr,
      col = image.start_col,
      opts = {
        end_col = image.start_col + #replacement,
        hl_group = "OrgdownImage",
      },
    })
    rendered = rendered:sub(1, image.start_col) .. replacement .. rendered:sub(image.end_col + 1)
  end
  return rendered, extmarks
end
return M
