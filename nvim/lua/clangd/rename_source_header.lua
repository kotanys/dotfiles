local M = {}

---@param str string
---@param find string
---@param replace string
---@return string
local function replace_last_occurrence(str, find, replace)
    local pattern = "(.*)" .. find .. "(.*)"
    local before, after = str:match(pattern)
    if before and after then
        return before .. replace .. after
    end
    return str
end

---@param filename string
---@param search string
---@param replace string
---@param bufnr integer?
local function buf_substitute(filename, search, replace, bufnr)
    local buffer_was_created_here = bufnr == nil
    local was_modified_before = false
    if not bufnr then
        bufnr = vim.api.nvim_create_buf(false, false) -- listed=false, scratch=false
        vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = bufnr })
        vim.api.nvim_buf_set_name(bufnr, filename)
        vim.api.nvim_buf_call(bufnr, vim.cmd.edit)
    else
        was_modified_before = vim.api.nvim_get_option_value('modified', { buf = bufnr })
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local modified_lines = {}
    for _, line in ipairs(lines) do
        local modified_line = line:gsub(search, replace)
        table.insert(modified_lines, modified_line)
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, modified_lines)
    if not was_modified_before then
        vim.api.nvim_buf_call(bufnr, vim.cmd.update)
    end
    if buffer_was_created_here then
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end
end

---@param old_buf_path string
---@param new_buf_path string
---@param client vim.lsp.Client
local function fix_cmake_lists(old_buf_path, new_buf_path, client)
    local dir = vim.fn.fnamemodify(old_buf_path, ":h")
    local cmake_path = nil
    while old_buf_path ~= client.root_dir do
        local test_path = vim.fn.simplify(dir .. "/CMakeLists.txt")
        local exists = vim.uv.fs_stat(test_path, nil) ~= nil ---@diagnostic disable-line: param-type-mismatch
        if exists then
            cmake_path = test_path
            break
        end
        dir = vim.fn.fnamemodify(dir, ":h")
    end
    if cmake_path == nil then return end
    local cmake_bufnr = nil
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        if buf_name == cmake_path then
            cmake_bufnr = bufnr
        end
    end

    local old_name = vim.fn.fnamemodify(old_buf_path, ":t")
    local new_name = vim.fn.fnamemodify(new_buf_path, ":t")
    buf_substitute(cmake_path, old_name, new_name, cmake_bufnr)
end

---@param old_buf_name string
---@param new_buf_name string
---@param client vim.lsp.Client
local function rename_async(old_buf_name, new_buf_name, client)
    vim.uv.fs_rename(old_buf_name, new_buf_name, function(fs_err, success)
        if not success then
            error(fs_err)
        end
        vim.schedule(function()
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                local buf_name = vim.api.nvim_buf_get_name(bufnr)
                if buf_name == old_buf_name then
                    vim.api.nvim_buf_set_name(bufnr, new_buf_name)
                end
            end
            fix_cmake_lists(old_buf_name, new_buf_name, client)
        end)
    end
    )
end

---@param bufnr integer
---@param client vim.lsp.Client
function M.rename_source_header(client, bufnr)
    local method_name = 'textDocument/switchSourceHeader'
    if not client or not client:supports_method(method_name) then ---@diagnostic disable-line param-type-mismatch
        return vim.notify(('method %s is not supported by any servers active on the current buffer'):format(method_name))
    end
    local params = vim.lsp.util.make_text_document_params(bufnr)
    client:request(method_name, params, function(err, result) ---@diagnostic disable-line param-type-mismatch
        if err then
            error(tostring(err))
        end
        if not result then
            vim.notify('corresponding file cannot be determined')
            return
        end
        local old_other = vim.uri_to_fname(result)
        local old_path = vim.uri_to_fname(params.uri)
        local old_name = vim.fn.fnamemodify(old_path, ":t:r")
        local new_name = vim.fn.input("New Name: ", old_name)
        if new_name == "" then return end

        local new_path = replace_last_occurrence(old_path, old_name, new_name)
        local new_other = replace_last_occurrence(old_other, old_name, new_name)
        local msg = "Rename:\n"
            .. old_path .. " -> " .. new_path .. "\n"
            .. old_other .. " -> " .. new_other .. "\n"

        if vim.fn.confirm(msg, "&Yes\n&No") == 1 then
            rename_async(old_path, new_path, client)
            rename_async(old_other, new_other, client)
        end
    end, bufnr)
end

return M
