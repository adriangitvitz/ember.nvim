local M = {}
function M.has_git()
  return vim.fn.executable("git") == 1
end
function M.get_root(path)
  path = path or vim.fn.getcwd()
  local result = vim.fn.systemlist({ "git", "-C", path, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and result[1] then
    return result[1]
  end
  return nil
end
function M.get_branch(root)
  root = root or M.get_root()
  if not root then
    return nil
  end
  local result = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD" })
  if vim.v.shell_error == 0 and result[1] then
    return result[1]
  end
  return nil
end
function M.get_status(root)
  root = root or M.get_root()
  if not root then
    return {}
  end
  local result = vim.fn.systemlist({ "git", "-C", root, "status", "--porcelain=v1", "-u" })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  local files = {}
  for _, line in ipairs(result) do
    if line ~= "" then
      local status = line:sub(1, 2)
      local path = line:sub(4)
      local old_path, new_path = path:match("^(.+) %-> (.+)$")
      if old_path then
        path = new_path
      end
      local file = {
        path = path,
        absolute = root .. "/" .. path,
        status = status,
        staged = status:sub(1, 1) ~= " " and status:sub(1, 1) ~= "?",
        unstaged = status:sub(2, 2) ~= " ",
        untracked = status == "??",
        conflicted = status == "UU" or status == "AA" or status == "DD",
      }
      if file.conflicted then
        file.type = "conflicted"
      elseif file.staged and file.unstaged then
        file.type = "both"
      elseif file.staged then
        file.type = "staged"
      elseif file.unstaged then
        file.type = "unstaged"
      elseif file.untracked then
        file.type = "untracked"
      end
      table.insert(files, file)
    end
  end
  return files
end
function M.get_diff_stats(root, path)
  root = root or M.get_root()
  if not root then
    return nil
  end
  local result = vim.fn.systemlist({ "git", "-C", root, "diff", "--numstat", "--", path })
  if vim.v.shell_error ~= 0 or #result == 0 then
    return nil
  end
  local added, deleted = result[1]:match("^(%d+)%s+(%d+)")
  if added then
    return {
      additions = tonumber(added),
      deletions = tonumber(deleted),
    }
  end
  return nil
end
function M.get_file_content(root, path, rev)
  root = root or M.get_root()
  if not root then
    return nil
  end
  local ref = rev and (rev .. ":" .. path) or (":" .. path)
  local result = vim.fn.systemlist({ "git", "-C", root, "show", ref })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return result
end
function M.get_staged_content(root, path)
  return M.get_file_content(root, path, nil)
end
function M.get_head_content(root, path)
  return M.get_file_content(root, path, "HEAD")
end
function M.stage_file(root, path)
  root = root or M.get_root()
  if not root then
    return false
  end
  vim.fn.system({ "git", "-C", root, "add", "--", path })
  return vim.v.shell_error == 0
end
function M.unstage_file(root, path)
  root = root or M.get_root()
  if not root then
    return false
  end
  vim.fn.system({ "git", "-C", root, "reset", "HEAD", "--", path })
  return vim.v.shell_error == 0
end
function M.restore_file(root, path)
  root = root or M.get_root()
  if not root then
    return false
  end
  vim.fn.system({ "git", "-C", root, "checkout", "--", path })
  return vim.v.shell_error == 0
end
function M.get_file_history(root, path, opts)
  root = root or M.get_root()
  opts = opts or {}
  if not root then
    return {}
  end
  local args = { "git", "-C", root, "log", "--pretty=format:%H|%an|%ae|%ad|%s", "--date=short" }
  if opts.max_count then
    table.insert(args, "-n")
    table.insert(args, tostring(opts.max_count))
  end
  if path then
    table.insert(args, "--follow")
    table.insert(args, "--")
    table.insert(args, path)
  end
  local result = vim.fn.systemlist(args)
  if vim.v.shell_error ~= 0 then
    return {}
  end
  local commits = {}
  for _, line in ipairs(result) do
    if line ~= "" then
      local hash, author, email, date, subject = line:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.*)$")
      if hash then
        table.insert(commits, {
          hash = hash,
          short_hash = hash:sub(1, 8),
          author = author,
          email = email,
          date = date,
          subject = subject,
        })
      end
    end
  end
  return commits
end
function M.get_diff(root, rev1, rev2, path)
  root = root or M.get_root()
  if not root then
    return nil
  end
  local args = { "git", "-C", root, "diff" }
  if rev1 then
    table.insert(args, rev1)
  end
  if rev2 then
    table.insert(args, rev2)
  end
  if path then
    table.insert(args, "--")
    table.insert(args, path)
  end
  local result = vim.fn.systemlist(args)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return result
end
return M
