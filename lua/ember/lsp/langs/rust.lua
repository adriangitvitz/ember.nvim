local M = {}
local utils = require("ember.lsp.utils")

local clippy_running = false
local function run_clippy(root)
  if clippy_running then
    vim.notify("clippy: already running", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("cargo") ~= 1 then
    vim.notify("clippy: cargo not found in PATH", vim.log.levels.ERROR)
    return
  end
  clippy_running = true
  vim.notify("clippy: running…", vim.log.levels.INFO)
  local cmd = {
    "cargo", "clippy",
    "--workspace", "--all-targets", "--all-features",
    "--message-format=short",
  }
  vim.system(cmd, { cwd = root, text = true }, function(obj)
    local out = (obj.stderr or "") .. "\n" .. (obj.stdout or "")
    local items = {}
    for line in out:gmatch("[^\r\n]+") do
      local file, lnum, col, level, msg = line:match("^(.-):(%d+):(%d+):%s+(%a+):%s+(.*)$")
      if file and (level == "error" or level == "warning") then
        if not file:match("^/") then file = root .. "/" .. file end
        items[#items + 1] = {
          filename = file,
          lnum = tonumber(lnum),
          col = tonumber(col),
          type = level == "error" and "E" or "W",
          text = msg,
        }
      end
    end
    vim.schedule(function()
      clippy_running = false
      vim.fn.setqflist({}, " ", { title = "cargo clippy", items = items })
      if #items > 0 then
        vim.cmd("botright copen")
        vim.notify(string.format("clippy: %d item(s)", #items), vim.log.levels.WARN)
      else
        vim.cmd("cclose")
        if obj.code == 0 then
          vim.notify("clippy: clean ✓", vim.log.levels.INFO)
        else
          vim.notify("clippy: exited " .. tostring(obj.code), vim.log.levels.ERROR)
        end
      end
    end)
  end)
end

function M.setup(config)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'rust',
    callback = function()
      if not utils.lsp_available('rust-analyzer') then return end
      local root_dir = utils.find_root({ 'Cargo.toml', 'rust-project.json', '.git' })
      local settings = vim.tbl_deep_extend("force", {
        ['rust-analyzer'] = {
          cargo = {
            allFeatures = false,
            loadOutDirsFromCheck = true,
            runBuildScripts = true,
            buildScripts = { enable = true },
          },
          checkOnSave = { enable = true, command = 'check' },
          numThreads = 8,
          cachePriming = { enable = false },
          procMacro = {
            enable = true,
            ignored = {
              ['async-trait'] = { 'async_trait' },
              ['napi-derive'] = { 'napi' },
              ['async-recursion'] = { 'async_recursion' },
              ['tracing'] = { 'instrument' },
            },
          },
          inlayHints = {
            bindingModeHints = { enable = true },
            chainingHints = { enable = true },
            closingBraceHints = { enable = true, minLines = 25 },
            closureReturnTypeHints = { enable = 'with_block' },
            lifetimeElisionHints = { enable = 'skip_trivial', useParameterNames = true },
            maxLength = 25,
            parameterHints = { enable = true },
            reborrowHints = { enable = 'mutable' },
            renderColons = true,
            typeHints = {
              enable = true,
              hideClosureInitialization = false,
              hideNamedConstructor = false,
            },
          },
          completion = {
            callable = { snippets = 'fill_arguments' },
            postfix = { enable = true },
            autoimport = { enable = true },
          },
          diagnostics = {
            enable = true,
            experimental = { enable = true },
          },
          imports = {
            granularity = { group = 'module' },
            prefix = 'self',
          },
          lens = {
            enable = true,
            references = { enable = true },
            implementations = { enable = true },
          },
        },
      }, config.settings or {})
      vim.lsp.start({
        name = 'rust_analyzer',
        cmd = config.cmd or { 'rust-analyzer' },
        root_dir = root_dir,
        capabilities = utils.get_capabilities(),
        settings = settings,
      })
      vim.keymap.set('n', '<leader>cc', function() run_clippy(root_dir) end,
        { buffer = true, silent = true, desc = 'Cargo clippy (workspace)' })
      vim.api.nvim_buf_create_user_command(0, 'ClippyRun',
        function() run_clippy(root_dir) end, { desc = 'Run cargo clippy on the workspace' })
    end,
  })
end
return M
