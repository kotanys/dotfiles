---@class AlignOnOpts
---@field padding string? Padding string to use for alignment. Should be a single character string. Default " ".
---@field index integer? Marker index in each line. First is denoted by 1, last by -1.
---@field plain boolean? True for literal string matching, false for regex matching. Default true.

---@class AlignOpts
---@field default_user_command boolean? Create a default :Align command. Default true.
---@field default_maps boolean? Create default keymaps. Default true.

---Find index of n'th from the end entry of pattern in s.
---@param s string
---@param pattern string
---@param n integer
---@param plain boolean
---@return integer?
local function find_last_nth(s, pattern, n, plain)
    local tail = {}
    local ptr = 1

    ---@type integer?
    local last = 0
    while last ~= nil do
        last = s:find(pattern, last + 1, plain)
        tail[ptr] = last
        ptr = ptr + 1
    end
    return tail[ptr - n - 1]
end

---Find index of n'th entry of pattern in s.
---@param s string
---@param pattern string
---@param n integer
---@param plain boolean
---@return integer?
local function find_nth(s, pattern, n, plain)
    if n < 0 then
        return find_last_nth(s, pattern, math.abs(n), plain)
    end

    ---@type integer?
    local last = 0
    while n > 0 and last ~= nil do
        last = s:find(pattern, last + 1, plain)
        n = n - 1
    end
    return last ~= nil and last > 0 and last or nil
end

---@param s string
---@param index integer Index in s *before* which function should count padding
---@param padding string
---@return integer padding_count
local function count_of_padding(s, index, padding)
    local padding_count = 0
    for i = index-1, 0, -1 do
        if s:sub(i,i) == padding then
            padding_count = padding_count + 1
        else
            break
        end
    end
    return padding_count
end

---@param marker string Alignment marker
---@param lines string[] Input lines
---@param opts AlignOnOpts? Alignment options. nil for defaults
---@return string[] aligned Lines with alignment
local function align_on(marker, lines, opts)
    if opts == nil then
        opts = {}
    end
    local padding = opts.padding and opts.padding or " "
    local index = opts.index and opts.index or 1
    local plain = opts.plain
    if plain == nil then
        plain = true
    end

    local marker_indices = {}
    local marker_dests = {}
    for lineno, line in ipairs(lines) do
        local found = find_nth(line, marker, index, plain)
        if found ~= nil then
            local padding_count = count_of_padding(line, found, padding)
            marker_indices[lineno] = found
            marker_dests[lineno] = found - padding_count + 1
        end
    end

    local dest = vim.fn.max(marker_dests)

    local result = lines
    for i = 1, #lines do
        if marker_indices[i] ~= nil then
            result[i] = lines[i]:sub(1, marker_dests[i] - 1)
                .. string.rep(padding, dest - marker_dests[i])
                .. lines[i]:sub(marker_indices[i])
        end
    end
    return result
end

---@param p vim.api.keyset.create_user_command.command_args
local user_command = function(p)
    if p.range ~= 2 then
        vim.notify("must give range", vim.log.levels.ERROR)
        return
    end
    local start = p.line1 - 1
    local end_ = p.line2
    local lines = vim.api.nvim_buf_get_lines(0, start, end_, true)
    local aligned = align_on(p.fargs[1], lines, {
        index = p.fargs[2] and tonumber(p.fargs[2]),
        plain = not p.bang,
    })
    vim.api.nvim_buf_set_lines(0, start, end_, true, aligned)
end

---@param opts AlignOpts?
local function setup(opts)
    if opts == nil then
        opts = {}
    end
    local default_user_command = opts.default_user_command
    if default_user_command == nil then
        default_user_command = true
    end
    local default_maps = opts.default_maps
    if default_maps == nil then
        default_maps = true
    end

    if default_user_command then
        vim.api.nvim_create_user_command("Align", user_command,
            { nargs = "+", range = true, bang = true })
    end

    if default_maps then
        vim.keymap.set("x", "<leader>a=", ":'<,'>Align =<CR><esc>")
        vim.keymap.set("x", "<leader>a:", ":'<,'>Align :<CR><esc>")
    end
end

return {
    setup = setup,
    align_on = align_on,
    user_command = user_command,
}
