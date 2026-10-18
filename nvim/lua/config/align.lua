---@param marker string
---@param lines string[]
---@param padding string | nil
---@return string[] 
local function align_on(marker, lines, padding)
    if padding == nil then
        padding = " "
    end

    local marker_indices = {}
    for lineno, line in ipairs(lines) do
        local found = line:find(marker, 1, true)
        if found ~= nil then
            marker_indices[lineno] = found
        end
    end

    local max_index = vim.fn.max(marker_indices)

    local result = lines
    for i = 1, #lines do
        if marker_indices[i] ~= nil then
            result[i] = lines[i]:sub(1, marker_indices[i] - 1)
                    .. string.rep(padding, max_index - marker_indices[i])
                    .. lines[i]:sub(marker_indices[i])
        end
    end
    return result
end

vim.api.nvim_create_user_command("Align", function(p)
    if p.range ~= 2 then
        vim.notify("must give range", vim.log.levels.ERROR)
        return
    end
    local start = p.line1 - 1
    local end_ = p.line2
    local lines = vim.api.nvim_buf_get_lines(0, start, end_, true)
    local aligned = align_on(p.args, lines)
    vim.api.nvim_buf_set_lines(0, start, end_, true, aligned)
end, {nargs = 1, range = true})

vim.keymap.set("x", "<leader>a=", ":'<,'>Align =<CR><esc>")
vim.keymap.set("x", "<leader>a:", ":'<,'>Align :<CR><esc>")
