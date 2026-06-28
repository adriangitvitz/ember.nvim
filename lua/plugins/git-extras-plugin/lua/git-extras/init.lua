-- git-extras: commit / branch / gh PR helpers built on the existing picker.
local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "git-extras" })
end

local function git_root()
  local out = vim.fn.systemlist({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] then return out[1] end
  return nil
end

local function has_executable(cmd, hint)
  if vim.fn.executable(cmd) == 1 then return true end
  notify(cmd .. " not found in PATH" .. (hint and (" — " .. hint) or ""), vim.log.levels.ERROR)
  return false
end

-- ── COMMIT ──────────────────────────────────────────────────────────────────
-- Open a scratch buffer with a commit-message template. Save (`:w`) to commit.
-- Empty message or buffer-discard cancels.
function M.commit(opts)
  opts = opts or {}
  local root = git_root()
  if not root then return notify("Not in a git repository", vim.log.levels.ERROR) end

  -- Check there's something to commit
  local staged = vim.fn.systemlist({ "git", "-C", root, "diff", "--cached", "--name-only" })
  if #staged == 0 and not opts.allow_empty then
    return notify("Nothing staged. Stage hunks (<leader>gs) or files first.", vim.log.levels.WARN)
  end

  -- Build the buffer with status comment block
  local lines = { "", "" }
  table.insert(lines, "# Commit on branch: " .. (vim.fn.systemlist({ "git", "-C", root, "branch", "--show-current" })[1] or "?"))
  table.insert(lines, "# Lines starting with # will be ignored.")
  table.insert(lines, "#")
  table.insert(lines, "# Files staged for this commit:")
  for _, f in ipairs(staged) do
    table.insert(lines, "#   " .. f)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "gitcommit"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, "COMMIT_MSG")

  vim.cmd("botright 12split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("startinsert")

  -- On :w, run git commit -F <tmpfile>; on :q discard.
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local msg_lines = {}
      for _, l in ipairs(content) do
        if not l:match("^#") then table.insert(msg_lines, l) end
      end
      -- Trim trailing empty lines
      while #msg_lines > 0 and msg_lines[#msg_lines]:match("^%s*$") do
        table.remove(msg_lines)
      end
      if #msg_lines == 0 then
        notify("Empty commit message — aborted", vim.log.levels.WARN)
        return
      end
      local tmp = vim.fn.tempname()
      vim.fn.writefile(msg_lines, tmp)
      local result = vim.fn.systemlist({ "git", "-C", root, "commit", "-F", tmp })
      vim.fn.delete(tmp)
      if vim.v.shell_error == 0 then
        notify("Committed: " .. msg_lines[1])
        vim.bo[buf].modified = false
        vim.api.nvim_buf_delete(buf, { force = true })
      else
        notify("git commit failed:\n" .. table.concat(result, "\n"), vim.log.levels.ERROR)
      end
    end,
  })
end

function M.commit_amend()
  local root = git_root()
  if not root then return notify("Not in a git repository", vim.log.levels.ERROR) end
  vim.fn.system({ "git", "-C", root, "commit", "--amend", "--no-edit" })
  if vim.v.shell_error == 0 then
    notify("Amended HEAD commit")
  else
    notify("Amend failed", vim.log.levels.ERROR)
  end
end

-- ── BRANCHES ────────────────────────────────────────────────────────────────
function M.branch_picker()
  local root = git_root()
  if not root then return notify("Not in a git repository", vim.log.levels.ERROR) end
  local ok, picker = pcall(require, "picker")
  if not ok then return notify("picker plugin unavailable", vim.log.levels.ERROR) end

  local lines = vim.fn.systemlist({ "git", "-C", root, "branch", "--all", "--sort=-committerdate", "--format=%(refname:short)" })
  if vim.v.shell_error ~= 0 then return notify("git branch failed", vim.log.levels.ERROR) end

  local seen, branches = {}, {}
  for _, b in ipairs(lines) do
    local clean = b:gsub("^%s+", ""):gsub("%s+$", "")
    -- Strip "origin/" but keep first occurrence of each branch name
    local local_name = clean:gsub("^origin/", "")
    if clean ~= "" and clean ~= "origin/HEAD" and not clean:match("^origin/HEAD") and not seen[local_name] then
      seen[local_name] = true
      table.insert(branches, clean)
    end
  end

  picker.run({
    items = branches,
    prompt = "Checkout branch",
    on_select = function(selection)
      if not selection or selection == "" then return end
      local branch = selection:gsub("^origin/", "")
      local result = vim.fn.systemlist({ "git", "-C", root, "checkout", branch })
      if vim.v.shell_error == 0 then
        notify("Checked out: " .. branch)
        vim.cmd("checktime")  -- reload changed buffers
      else
        notify("Checkout failed:\n" .. table.concat(result, "\n"), vim.log.levels.ERROR)
      end
    end,
  })
end

function M.branch_create()
  local root = git_root()
  if not root then return notify("Not in a git repository", vim.log.levels.ERROR) end
  vim.ui.input({ prompt = "New branch name: " }, function(name)
    if not name or name == "" then return end
    local result = vim.fn.systemlist({ "git", "-C", root, "checkout", "-b", name })
    if vim.v.shell_error == 0 then
      notify("Created and checked out: " .. name)
    else
      notify("Create failed:\n" .. table.concat(result, "\n"), vim.log.levels.ERROR)
    end
  end)
end

-- ── GH (GitHub PRs) ─────────────────────────────────────────────────────────
function M.pr_list()
  if not has_executable("gh", "brew install gh && gh auth login") then return end
  local ok, picker = pcall(require, "picker")
  if not ok then return notify("picker plugin unavailable", vim.log.levels.ERROR) end

  notify("Loading PRs...")
  vim.system(
    { "gh", "pr", "list", "--limit", "50", "--json", "number,title,author,headRefName,isDraft" },
    { text = true },
    function(obj)
      vim.schedule(function()
        if obj.code ~= 0 then
          return notify("gh failed:\n" .. (obj.stderr or ""), vim.log.levels.ERROR)
        end
        local ok_json, prs = pcall(vim.json.decode, obj.stdout)
        if not ok_json or not prs or #prs == 0 then
          return notify("No open PRs", vim.log.levels.INFO)
        end
        local items, pr_by_line = {}, {}
        for _, pr in ipairs(prs) do
          local mark = pr.isDraft and "DRAFT" or "open "
          local line = string.format("#%-5d %s  %-20s  %s",
            pr.number, mark, "@" .. pr.author.login, pr.title)
          table.insert(items, line)
          pr_by_line[line] = pr
        end
        picker.run({
          items = items,
          prompt = "GitHub PRs",
          on_select = function(selection)
            local pr = pr_by_line[selection]
            if not pr then return end
            vim.ui.select({ "Checkout", "View in browser", "View diff" }, {
              prompt = string.format("PR #%d: %s", pr.number, pr.title),
            }, function(choice)
              if not choice then return end
              local cmd
              if choice == "Checkout" then cmd = { "gh", "pr", "checkout", tostring(pr.number) }
              elseif choice == "View in browser" then cmd = { "gh", "pr", "view", tostring(pr.number), "--web" }
              elseif choice == "View diff" then cmd = { "gh", "pr", "diff", tostring(pr.number) }
              end
              if choice == "View diff" then
                local diff = vim.fn.systemlist(cmd)
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, diff)
                vim.bo[buf].filetype = "diff"
                vim.bo[buf].bufhidden = "wipe"
                vim.cmd("botright vsplit")
                vim.api.nvim_win_set_buf(0, buf)
              else
                vim.fn.system(cmd)
                if vim.v.shell_error == 0 then
                  notify(choice .. " #" .. pr.number)
                  if choice == "Checkout" then vim.cmd("checktime") end
                else
                  notify(choice .. " failed", vim.log.levels.ERROR)
                end
              end
            end)
          end,
        })
      end)
    end
  )
end

function M.pr_view_web()
  if not has_executable("gh") then return end
  vim.fn.system({ "gh", "pr", "view", "--web" })
  if vim.v.shell_error ~= 0 then
    notify("No PR for current branch (or gh failed)", vim.log.levels.WARN)
  end
end

function M.pr_create()
  if not has_executable("gh") then return end
  -- gh pr create is interactive; punt to a terminal split.
  vim.cmd("botright split | terminal gh pr create")
end

-- ── SETUP ───────────────────────────────────────────────────────────────────
function M.setup()
  vim.api.nvim_create_user_command("GitCommit", function(o)
    M.commit({ allow_empty = o.bang })
  end, { bang = true, desc = "Open a commit-message buffer (write to commit)" })
  vim.api.nvim_create_user_command("GitCommitAmend", M.commit_amend, { desc = "Amend HEAD without editing message" })
  vim.api.nvim_create_user_command("GitBranches", M.branch_picker, { desc = "Pick and checkout a branch" })
  vim.api.nvim_create_user_command("GitBranchNew", M.branch_create, { desc = "Create and checkout a new branch" })
  vim.api.nvim_create_user_command("GhPrList", M.pr_list, { desc = "Pick a GitHub PR" })
  vim.api.nvim_create_user_command("GhPrWeb", M.pr_view_web, { desc = "Open current branch's PR in browser" })
  vim.api.nvim_create_user_command("GhPrCreate", M.pr_create, { desc = "gh pr create in a terminal split" })

  vim.keymap.set("n", "<leader>gc", M.commit, { desc = "Git: commit (open msg buffer)" })
  vim.keymap.set("n", "<leader>gC", M.branch_picker, { desc = "Git: checkout branch" })
  vim.keymap.set("n", "<leader>gN", M.branch_create, { desc = "Git: new branch" })
  vim.keymap.set("n", "<leader>gP", M.pr_list, { desc = "Git: list PRs (gh)" })
  vim.keymap.set("n", "<leader>gO", M.pr_view_web, { desc = "Git: open PR in browser (gh)" })
end

return M
