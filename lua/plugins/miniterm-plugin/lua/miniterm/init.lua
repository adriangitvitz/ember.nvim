local M = {}
local terminals = {}
local config = {
    border = 'rounded',
    dimensions = {
        height = 0.8,
        width = 0.8,
    },
    hl = 'Normal',
}
local terminal_configs = {
    default = {
        dimensions = {
            height = 0.8,
            width = 0.8,
        },
    },
    horizontal = {
        dimensions = {
            height = 0.3,
            width = 1.0,
            x = 0.0,
            y = 0.7,
        },
    },
    vertical = {
        dimensions = {
            height = 1.0,
            width = 0.3,
            x = 0.7,
            y = 0.0,
        },
    },
    full = {
        dimensions = {
            height = 0.9,
            width = 0.9,
        },
    }
}
local function create_floating_window(dims)
    local width = math.floor(vim.o.columns * dims.width)
    local height = math.floor(vim.o.lines * dims.height)
    local col = dims.x and math.floor(vim.o.columns * dims.x) or math.floor((vim.o.columns - width) / 2)
    local row = dims.y and math.floor(vim.o.lines * dims.y) or math.floor((vim.o.lines - height) / 2)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].buflisted = false
    local win_opts = {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = config.border,
    }
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    vim.wo[win].winhighlight = 'Normal:' .. config.hl
    return buf, win
end
local Terminal = {}
Terminal.__index = Terminal
function Terminal:new(opts)
    opts = opts or {}
    local term = {
        cmd = opts.cmd or os.getenv('SHELL'),
        dimensions = opts.dimensions or config.dimensions,
        buf = nil,
        win = nil,
        job_id = nil,
        is_open = false,
    }
    setmetatable(term, Terminal)
    return term
end
function Terminal:open()
    if self.is_open and self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_set_current_win(self.win)
        return
    end
    if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
        local buf, win = create_floating_window(self.dimensions)
        vim.api.nvim_buf_delete(buf, { force = true })
        win = vim.api.nvim_open_win(self.buf, true, {
            relative = 'editor',
            width = math.floor(vim.o.columns * self.dimensions.width),
            height = math.floor(vim.o.lines * self.dimensions.height),
            col = self.dimensions.x and math.floor(vim.o.columns * self.dimensions.x) or
                 math.floor((vim.o.columns - math.floor(vim.o.columns * self.dimensions.width)) / 2),
            row = self.dimensions.y and math.floor(vim.o.lines * self.dimensions.y) or
                 math.floor((vim.o.lines - math.floor(vim.o.lines * self.dimensions.height)) / 2),
            style = 'minimal',
            border = config.border,
        })
        self.win = win
    else
        self.buf, self.win = create_floating_window(self.dimensions)
        self.job_id = vim.fn.termopen(self.cmd)
    end
    self.is_open = true
    self:set_keymaps()
    vim.cmd('startinsert')
end
function Terminal:close()
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_close(self.win, true)
        self.win = nil
    end
    self.is_open = false
end
function Terminal:toggle()
    if self.is_open then
        self:close()
    else
        self:open()
    end
end
function Terminal:set_keymaps()
    if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
        return
    end
    local opts = { buffer = self.buf, silent = true }
    vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
    vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
    vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
    vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
    vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end
function M.setup(opts)
    config = vim.tbl_deep_extend('force', config, opts or {})
    terminals.default = Terminal:new({ dimensions = terminal_configs.default.dimensions })
    terminals.horizontal = Terminal:new({ dimensions = terminal_configs.horizontal.dimensions })
    terminals.vertical = Terminal:new({ dimensions = terminal_configs.vertical.dimensions })
    terminals.lazygit = Terminal:new({
      cmd = 'lazygit',
      dimensions = terminal_configs.full.dimensions
    })
    terminals.lazydocker = Terminal:new({
        cmd = 'lazydocker',
        dimensions = terminal_configs.full.dimensions
    })
    terminals.ghdash = Terminal:new({
        cmd = 'gh dash',
        dimensions = terminal_configs.full.dimensions
    })
    _G._horizontal_term_toggle = function() terminals.horizontal:toggle() end
    _G._vertical_term_toggle = function() terminals.vertical:toggle() end
    _G._lazydocker_toggle = function() terminals.lazydocker:toggle() end
    _G._lazygit_toggle = function() terminals.lazygit:toggle() end
    _G._ghdash_toggle = function() terminals.ghdash:toggle() end
    vim.api.nvim_create_autocmd('TermOpen', {
        pattern = '*',
        callback = function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn = 'no'
            vim.opt_local.foldcolumn = '0'
        end,
    })
end
function M.toggle()
    terminals.default:toggle()
end
function M.open()
    terminals.default:open()
end
function M.close()
    terminals.default:close()
end
function M.new(opts)
    return Terminal:new(opts)
end
return M
