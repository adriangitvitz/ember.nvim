local M = {}
local terminals = {}
local config = {
    border = 'rounded',
    dimensions = {
        height = 0.8,
        width = 0.8,
    },
    hl = 'Normal',
    winblend = 10,
}
local terminal_configs = {
    default = {
        layout = 'float',
        dimensions = {
            height = 0.8,
            width = 0.8,
        },
    },
    horizontal = {
        layout = 'split',
        size_ratio = 0.3,
    },
    vertical = {
        layout = 'vsplit',
        size_ratio = 0.3,
    },
    full = {
        layout = 'float',
        dimensions = {
            height = 0.9,
            width = 0.9,
        },
    },
}

local function ensure_buf(buf)
    if buf and vim.api.nvim_buf_is_valid(buf) then
        return buf, false
    end
    local b = vim.api.nvim_create_buf(false, true)
    vim.bo[b].bufhidden = 'hide'
    vim.bo[b].buflisted = false
    return b, true
end

local function open_float(buf, term)
    local dims = term.dimensions
    local width = math.floor(vim.o.columns * dims.width)
    local height = math.floor(vim.o.lines * dims.height)
    local col = dims.x and math.floor(vim.o.columns * dims.x)
        or math.floor((vim.o.columns - width) / 2)
    local row = dims.y and math.floor(vim.o.lines * dims.y)
        or math.floor((vim.o.lines - height) / 2)
    local b, fresh = ensure_buf(buf)
    local win = vim.api.nvim_open_win(b, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = config.border,
    })
    vim.wo[win].winhighlight = 'Normal:' .. config.hl
    vim.wo[win].winblend = config.winblend or 0
    return b, win, fresh
end

local function open_split(buf, term)
    local size = term.size or math.floor(vim.o.lines * (term.size_ratio or 0.3))
    local b, fresh = ensure_buf(buf)
    if fresh then
        vim.cmd('botright ' .. size .. 'split')
        vim.api.nvim_win_set_buf(0, b)
    else
        vim.cmd('botright sbuffer ' .. b)
        vim.cmd('resize ' .. size)
    end
    return b, vim.api.nvim_get_current_win(), fresh
end

local function open_vsplit(buf, term)
    local size = term.size or math.floor(vim.o.columns * (term.size_ratio or 0.3))
    local b, fresh = ensure_buf(buf)
    if fresh then
        vim.cmd('botright ' .. size .. 'vsplit')
        vim.api.nvim_win_set_buf(0, b)
    else
        vim.cmd('botright vertical sbuffer ' .. b)
        vim.cmd('vertical resize ' .. size)
    end
    return b, vim.api.nvim_get_current_win(), fresh
end

local openers = {
    float = open_float,
    split = open_split,
    vsplit = open_vsplit,
}

local Terminal = {}
Terminal.__index = Terminal
function Terminal:new(opts)
    opts = opts or {}
    local term = {
        cmd = opts.cmd or os.getenv('SHELL'),
        layout = opts.layout or 'float',
        dimensions = opts.dimensions or config.dimensions,
        size = opts.size,
        size_ratio = opts.size_ratio,
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
    local opener = openers[self.layout] or open_float
    local buf, win, fresh = opener(self.buf, self)
    self.buf, self.win = buf, win
    if fresh then
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
    vim.keymap.set('t', '<C-w>q', [[<C-\><C-n><Cmd>close<CR>]], opts)
end
function M.setup(opts)
    config = vim.tbl_deep_extend('force', config, opts or {})
    terminals.default = Terminal:new({
        layout = terminal_configs.default.layout,
        dimensions = terminal_configs.default.dimensions,
    })
    terminals.horizontal = Terminal:new({
        layout = terminal_configs.horizontal.layout,
        size_ratio = terminal_configs.horizontal.size_ratio,
    })
    terminals.vertical = Terminal:new({
        layout = terminal_configs.vertical.layout,
        size_ratio = terminal_configs.vertical.size_ratio,
    })
    terminals.lazygit = Terminal:new({
        cmd = 'lazygit',
        layout = terminal_configs.full.layout,
        dimensions = terminal_configs.full.dimensions,
    })
    terminals.lazydocker = Terminal:new({
        cmd = 'lazydocker',
        layout = terminal_configs.full.layout,
        dimensions = terminal_configs.full.dimensions,
    })
    terminals.ghdash = Terminal:new({
        cmd = 'gh dash',
        layout = terminal_configs.full.layout,
        dimensions = terminal_configs.full.dimensions,
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
    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
        pattern = 'term://*',
        callback = function() vim.cmd('startinsert') end,
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
