local M = {}
M.last_error = nil
M.config = {
  format_on_save = true,
  format_timeout = 3000,
  notify_on_error = true,
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format", "black" },
    rust = { lsp = true },
    go = { "gofmt", "goimports" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    markdown = { "prettier" },
    c = { "clang_format" },
    cpp = { "clang_format" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
    zig = { lsp = true },
    nim = { lsp = true },
    crystal = { "crystal_format" },
    odin = { lsp = true },
  },
  formatters = {
    stylua = {
      cmd = "stylua",
      args = { "-" },
      stdin = true,
    },
    ruff_format = {
      cmd = "ruff",
      args = { "format", "-" },
      stdin = true,
    },
    black = {
      cmd = "black",
      args = { "-q", "-" },
      stdin = true,
    },
    prettier = {
      cmd = "prettier",
      args = function()
        return { "--stdin-filepath", vim.api.nvim_buf_get_name(0) }
      end,
      stdin = true,
    },
    gofmt = {
      cmd = "gofmt",
      stdin = true,
    },
    goimports = {
      cmd = "goimports",
      stdin = true,
    },
    clang_format = {
      cmd = "clang-format",
      args = function()
        local filename = vim.api.nvim_buf_get_name(0)
        if filename == "" then
          local ft = vim.bo.filetype
          filename = ft == "cpp" and "temp.cpp" or "temp.c"
        end
        return { "--assume-filename=" .. filename }
      end,
      stdin = true,
    },
    shfmt = {
      cmd = "shfmt",
      args = { "-i", "2", "-" },
      stdin = true,
    },
    crystal_format = {
      cmd = "crystal",
      args = { "tool", "format", "-" },
      stdin = true,
    },
  },
}
local function has_cmd(cmd)
  return vim.fn.executable(cmd) == 1
end
local function get_formatters(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local formatters = M.config.formatters_by_ft[ft]
  if not formatters then
    return nil, true
  end
  if formatters.lsp then
    return nil, true
  end
  local available = {}
  for _, name in ipairs(formatters) do
    local formatter = M.config.formatters[name]
    if formatter and has_cmd(formatter.cmd) then
      table.insert(available, { name = name, config = formatter })
    end
  end
  if #available == 0 then
    return nil, true
  end
  return available, false
end
local function run_formatter(formatter, content, callback)
  local config = formatter.config
  local args = config.args
  if type(args) == "function" then
    args = args()
  end
  args = args or {}
  local stdout = {}
  local stderr = {}
  local job_id = vim.fn.jobstart(vim.list_extend({ config.cmd }, args), {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr, data)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          local err = table.concat(stderr, "\n")
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
          M.last_error = {
            file = filename,
            message = err,
            time = os.time(),
          }
          callback(nil, "Format failed: " .. filename .. " (run :FormatError for details)")
        else
          if stdout[#stdout] == "" then
            table.remove(stdout)
          end
          callback(stdout)
        end
      end)
    end,
  })
  if job_id <= 0 then
    callback(nil, "Failed to start formatter: " .. config.cmd)
    return
  end
  if config.stdin then
    vim.fn.chansend(job_id, content)
    vim.fn.chanclose(job_id, "stdin")
  end
end
local function format_lsp(bufnr, callback, async)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local formatting_clients = vim.tbl_filter(function(client)
    return client.server_capabilities.documentFormattingProvider
  end, clients)
  if #formatting_clients == 0 then
    callback(nil, "No LSP client supports formatting")
    return
  end
  vim.lsp.buf.format({
    bufnr = bufnr,
    timeout_ms = M.config.format_timeout,
    async = async ~= false,
  })
  callback({})
end
function M.format(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  if not vim.bo[bufnr].modifiable then
    if M.config.notify_on_error then
      vim.notify("Buffer is not modifiable", vim.log.levels.WARN)
    end
    return
  end
  local formatters, use_lsp = get_formatters(bufnr)
  if use_lsp then
    format_lsp(bufnr, function(_, err)
      if err and M.config.notify_on_error then
        vim.notify(err, vim.log.levels.WARN)
      end
    end, opts.async)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local formatter = formatters[1]
  run_formatter(formatter, content, function(result, err)
    if err then
      if M.config.notify_on_error then
        vim.notify(err, vim.log.levels.ERROR)
      end
      return
    end
    if not result or #result == 0 then
      return
    end
    local new_content = table.concat(result, "\n")
    if new_content == content then
      return
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, result)
    if opts.async == false then
    end
  end)
end
function M.format_and_save(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local view = vim.fn.winsaveview()
  M.format({
    bufnr = bufnr,
    async = false,
  })
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.fn.winrestview, view)
      vim.cmd("silent write")
    end
  end)
end
local function enable_format_on_save(bufnr)
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = bufnr,
    group = vim.api.nvim_create_augroup("FormatOnSave" .. bufnr, { clear = true }),
    callback = function()
      M.format({ bufnr = bufnr, async = false })
    end,
  })
end
local function disable_format_on_save(bufnr)
  pcall(vim.api.nvim_del_augroup_by_name, "FormatOnSave" .. bufnr)
end
function M.toggle_format_on_save()
  M.config.format_on_save = not M.config.format_on_save
  local msg = M.config.format_on_save and "Format on save enabled" or "Format on save disabled"
  vim.notify(msg, vim.log.levels.INFO)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      if M.config.format_on_save then
        enable_format_on_save(bufnr)
      else
        disable_format_on_save(bufnr)
      end
    end
  end
end
function M.list_formatters()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local formatters, use_lsp = get_formatters(bufnr)
  local lines = { "Formatters for " .. ft .. ":" }
  if use_lsp then
    table.insert(lines, "  • LSP (fallback)")
  elseif formatters then
    for _, f in ipairs(formatters) do
      table.insert(lines, "  • " .. f.name .. " (" .. f.config.cmd .. ")")
    end
  else
    table.insert(lines, "  (none configured)")
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  if opts.formatters then
    M.config.formatters = vim.tbl_deep_extend("force", M.config.formatters, opts.formatters)
  end
  if opts.formatters_by_ft then
    M.config.formatters_by_ft = vim.tbl_deep_extend("force", M.config.formatters_by_ft, opts.formatters_by_ft)
  end
  vim.api.nvim_create_user_command("Format", function()
    M.format()
  end, { desc = "Format buffer" })
  vim.api.nvim_create_user_command("FormatToggle", function()
    M.toggle_format_on_save()
  end, { desc = "Toggle format on save" })
  vim.api.nvim_create_user_command("FormatList", function()
    M.list_formatters()
  end, { desc = "List formatters" })
  vim.api.nvim_create_user_command("FormatError", function()
    if M.last_error then
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(M.last_error.message, "\n"))
      vim.bo[buf].filetype = "text"
      vim.bo[buf].bufhidden = "wipe"
      vim.cmd("botright split")
      vim.api.nvim_win_set_buf(0, buf)
      vim.api.nvim_win_set_height(0, math.min(15, vim.api.nvim_buf_line_count(buf)))
    else
      vim.notify("No format errors", vim.log.levels.INFO)
    end
  end, { desc = "Show last format error" })
  vim.keymap.set("n", "<leader>cf", M.format, { desc = "Format buffer" })
  vim.keymap.set("n", "<leader>cF", M.toggle_format_on_save, { desc = "Toggle format on save" })
  vim.keymap.set("n", "<leader>ce", "<cmd>FormatError<CR>", { desc = "Show format error" })
  if M.config.format_on_save then
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      group = vim.api.nvim_create_augroup("FormatSetup", { clear = true }),
      callback = function(args)
        enable_format_on_save(args.buf)
      end,
    })
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        enable_format_on_save(bufnr)
      end
    end
  end
end
return M
