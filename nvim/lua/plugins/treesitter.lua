return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local languages = {
                "bash",
                "c",
                "cpp",
                "css",
                "go",
                "html",
                "javascript",
                "latex",
                "lua",
                "markdown",
                "markdown_inline",
                "python",
                "query",
                "razor",
                "regex",
                "typst",
                "vim",
                "vimdoc",
            }

            local filetypes = vim.iter(languages)
                :map(vim.treesitter.language.get_filetypes)
                :flatten(1)
                :totable()

            require('nvim-treesitter').install(languages):await(function()
                local function start()
                    vim.treesitter.start()
                end

                if vim.list_contains(filetypes, vim.bo.filetype) then
                    start()
                end
                vim.api.nvim_create_autocmd('FileType', {
                    group = vim.api.nvim_create_augroup("treesitter.filetype", { clear = true }),
                    pattern = filetypes,
                    callback = function()
                        start()
                    end
                })
            end)
        end,
    },
}

--[[ Notes
-- Dockerfile tree-sitter looks better then simple regex,
-- but still isn't consistent enough. Regex is fine.
-- Dockerfile highlighting is better handled via dockerfile lsp.
]] --
