-- Ember compatibility layer for bento.nvim
-- Provides emberline-style features: navigation, ordering, pinning behavior, restore

local M = {}

-- Recently closed buffers for restore
local recently_closed = {}
local MAX_RECENTLY_CLOSED = 10

function M.setup()
    -- Hook into buffer deletion for restore functionality
    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = vim.api.nvim_create_augroup("BentoEmberCompat", { clear = true }),
        callback = function(args)
            M.on_buffer_delete(args.buf)
        end,
    })
end

-- Get bento module (lazy load to avoid circular deps)
local function get_bento()
    return require("bento")
end

-- Sync bento.marks with the current listed buffers.
-- Mirrors ui.lua's update_marks() and mutates bento.marks in place so the
-- reference held by ui.lua stays valid. Needed because navigation reads
-- bento.marks, which otherwise only populates after the bento menu is opened.
local function sync_marks()
    local bento = get_bento()
    local utils = require("bento.utils")

    -- Drop invalid buffers
    for i = #bento.marks, 1, -1 do
        if not utils.buffer_is_valid(bento.marks[i].buf_id, bento.marks[i].filename) then
            table.remove(bento.marks, i)
        end
    end

    -- Add newly listed valid buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if utils.buffer_is_valid(buf, name) then
            local found = false
            for _, mark in ipairs(bento.marks) do
                if mark.buf_id == buf then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(bento.marks, { filename = name, buf_id = buf })
            end
        end
    end
end

-- Get buffer index in marks list
function M.get_buffer_index(buf_id)
    local bento = get_bento()
    for i, mark in ipairs(bento.marks) do
        if mark.buf_id == buf_id then
            return i
        end
    end
    return nil
end

-- Navigate to previous buffer
function M.prev_buffer()
    sync_marks()
    local bento = get_bento()
    local marks = bento.marks
    if #marks == 0 then return end

    local current = vim.api.nvim_get_current_buf()
    local idx = M.get_buffer_index(current)

    if not idx then
        vim.cmd("buffer " .. marks[#marks].buf_id)
        return
    end

    local prev_idx = idx - 1
    if prev_idx < 1 then prev_idx = #marks end
    vim.cmd("buffer " .. marks[prev_idx].buf_id)
end

-- Navigate to next buffer
function M.next_buffer()
    sync_marks()
    local bento = get_bento()
    local marks = bento.marks
    if #marks == 0 then return end

    local current = vim.api.nvim_get_current_buf()
    local idx = M.get_buffer_index(current)

    if not idx then
        vim.cmd("buffer " .. marks[1].buf_id)
        return
    end

    local next_idx = idx + 1
    if next_idx > #marks then next_idx = 1 end
    vim.cmd("buffer " .. marks[next_idx].buf_id)
end

-- Go to buffer at position (1-indexed)
function M.goto_buffer(position)
    sync_marks()
    local bento = get_bento()
    local marks = bento.marks
    if marks[position] then
        vim.cmd("buffer " .. marks[position].buf_id)
    end
end

-- Move buffer in the list
function M.move_buffer(buf_id, direction)
    local bento = get_bento()
    local idx = M.get_buffer_index(buf_id)
    if not idx then return end

    local new_idx = idx + direction
    if new_idx < 1 or new_idx > #bento.marks then return end

    -- Swap in marks table
    bento.marks[idx], bento.marks[new_idx] = bento.marks[new_idx], bento.marks[idx]

    require("bento.ui").refresh_menu()
end

-- Sort locked buffers to the left (emberline pin behavior)
function M.sort_locked_to_left()
    local bento = get_bento()
    local locked = {}
    local unlocked = {}

    for _, mark in ipairs(bento.marks) do
        if bento.is_locked(mark.buf_id) then
            table.insert(locked, mark)
        else
            table.insert(unlocked, mark)
        end
    end

    -- Rebuild marks: locked first
    bento.marks = {}
    for _, mark in ipairs(locked) do
        table.insert(bento.marks, mark)
    end
    for _, mark in ipairs(unlocked) do
        table.insert(bento.marks, mark)
    end
end

-- Track deleted buffers for restore
function M.on_buffer_delete(buf_id)
    -- Only track if buffer is valid and has a name
    if not vim.api.nvim_buf_is_valid(buf_id) then
        return
    end

    local buf_name = vim.api.nvim_buf_get_name(buf_id)
    if buf_name and buf_name ~= "" then
        -- Don't add duplicates
        for i, path in ipairs(recently_closed) do
            if path == buf_name then
                table.remove(recently_closed, i)
                break
            end
        end

        table.insert(recently_closed, 1, buf_name)
        if #recently_closed > MAX_RECENTLY_CLOSED then
            table.remove(recently_closed)
        end
    end
end

-- Restore most recently closed buffer
function M.restore_buffer()
    if #recently_closed == 0 then
        vim.notify("No recently closed buffers", vim.log.levels.INFO)
        return
    end

    local path = table.remove(recently_closed, 1)
    if vim.fn.filereadable(path) == 1 then
        vim.cmd.edit(path)
    else
        vim.notify("File no longer exists: " .. path, vim.log.levels.WARN)
    end
end

-- Close other buffers (respecting locked/pinned)
function M.close_other_buffers()
    local bento = get_bento()
    local current = vim.api.nvim_get_current_buf()

    for _, mark in ipairs(bento.marks) do
        if mark.buf_id ~= current and not bento.is_locked(mark.buf_id) then
            pcall(vim.api.nvim_buf_delete, mark.buf_id, { force = false })
        end
    end
end

-- Get recently closed buffers list (for debugging/display)
function M.get_recently_closed()
    return recently_closed
end

return M
